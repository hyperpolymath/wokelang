// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Bytecode Compiler
//!
//! Compiles WokeLang AST to stack-based bytecode.

use crate::ast::*;
use crate::interpreter::Value;
use crate::vm::bytecode::{CompiledFunction, CompiledProgram, OpCode};
use std::collections::HashMap;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum CompileError {
    #[error("Undefined variable: {0}")]
    UndefinedVariable(String),

    #[error("Undefined function: {0}")]
    UndefinedFunction(String),

    #[error("Compilation not yet implemented: {0}")]
    NotImplemented(String),

    #[error("Internal compiler error: {0}")]
    Internal(String),
}

/// Local variable information
struct Local {
    name: String,
    #[allow(dead_code)] // scope depth; reserved for nested-scope resolution
    depth: usize,
}

/// Jump fix-ups for `break`/`continue` inside the innermost `while` loop.
struct LoopCtx {
    /// Where `continue` jumps to (re-test the loop condition).
    continue_target: usize,
    /// `break` jump-instruction indices, patched to just after the loop.
    break_jumps: Vec<usize>,
}

/// Compiler state
pub struct BytecodeCompiler {
    /// Current function being compiled
    current_function: Option<CompiledFunction>,
    /// Local variables in current scope
    locals: Vec<Local>,
    /// Current scope depth
    scope_depth: usize,
    /// Function names to indices
    function_indices: HashMap<String, usize>,
    /// Compiled program being built
    program: CompiledProgram,
    /// Stack of enclosing `while` loops (for `break`/`continue`)
    loop_stack: Vec<LoopCtx>,
}

impl BytecodeCompiler {
    pub fn new() -> Self {
        Self {
            current_function: None,
            locals: Vec::new(),
            scope_depth: 0,
            function_indices: HashMap::new(),
            program: CompiledProgram::new(),
            loop_stack: Vec::new(),
        }
    }

    /// Compile a program to bytecode
    pub fn compile(&mut self, program: &Program) -> Result<CompiledProgram, CompileError> {
        // Reset program for fresh compilation
        self.program = CompiledProgram::new();

        // First pass: register all functions
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                let func_idx = self.program.functions.len();
                self.function_indices.insert(func.name.clone(), func_idx);

                // Create compiled function
                let compiled_func = CompiledFunction::new(func.name.clone(), func.params.len());
                self.program.functions.push(compiled_func);
            }
        }

        // Record whether the `#care` consent-checking pragma is enabled, so the
        // VM enforces consent blocks (deny-by-default) rather than running them.
        for item in &program.items {
            if let TopLevelItem::Pragma(p) = item {
                if matches!(p.directive, PragmaDirective::Care) {
                    self.program.care = p.enabled;
                }
            }
        }

        // Second pass: compile function bodies
        for item in program.items.iter() {
            if let TopLevelItem::Function(func) = item {
                let func_idx = *self.function_indices.get(&func.name).unwrap();

                // Temporarily take the function out to avoid borrow issues
                let mut compiled_func = std::mem::replace(
                    &mut self.program.functions[func_idx],
                    CompiledFunction::new(String::new(), 0),
                );

                self.compile_function(func, &mut compiled_func)?;

                // Put it back
                self.program.functions[func_idx] = compiled_func;

                // Set entry point to main
                if func.name == "main" {
                    self.program.entry = Some(func_idx);
                }
            }
        }

        Ok(std::mem::take(&mut self.program))
    }

    /// Compile a function
    fn compile_function(
        &mut self,
        func: &FunctionDef,
        compiled_func: &mut CompiledFunction,
    ) -> Result<(), CompileError> {
        self.current_function = Some(compiled_func.clone());
        self.locals.clear();
        self.scope_depth = 0;

        // Add parameters as locals
        for param in func.params.iter() {
            self.add_local(param.name.clone());
        }

        // Compile function body
        for stmt in &func.body {
            self.compile_statement(stmt, compiled_func)?;
        }

        // Ensure function returns
        if !matches!(func.body.last(), Some(Statement::Return(_))) {
            // Push Unit and return
            let const_idx = compiled_func.add_constant(Value::Unit);
            compiled_func.emit(OpCode::Const(const_idx));
            compiled_func.emit(OpCode::Return);
        }

        self.current_function = None;
        Ok(())
    }

    /// Compile a statement
    fn compile_statement(
        &mut self,
        stmt: &Statement,
        func: &mut CompiledFunction,
    ) -> Result<(), CompileError> {
        match stmt {
            Statement::VarDecl(var_decl) => {
                // Compile the value expression
                self.compile_expr(&var_decl.value.node, func)?;

                // Store in local variable
                let local_idx = self.add_local(var_decl.name.clone());
                func.emit(OpCode::StoreLocal(local_idx));

                Ok(())
            }

            Statement::Assignment(assign) => {
                // Compile the value
                self.compile_expr(&assign.value.node, func)?;

                // Find the variable and store
                if let Some(local_idx) = self.resolve_local(&assign.target) {
                    func.emit(OpCode::StoreLocal(local_idx));
                } else {
                    func.emit(OpCode::StoreGlobal(assign.target.clone()));
                }

                Ok(())
            }

            Statement::Return(ret_stmt) => {
                // Compile return value
                self.compile_expr(&ret_stmt.value.node, func)?;
                func.emit(OpCode::Return);
                Ok(())
            }

            Statement::Expression(expr) => {
                // Compile expression
                self.compile_expr(&expr.node, func)?;
                // Pop result (expression statement discards value)
                func.emit(OpCode::Pop);
                Ok(())
            }

            Statement::Conditional(cond) => {
                // Compile condition
                self.compile_expr(&cond.condition.node, func)?;

                // Jump to else branch if false
                let jump_to_else = func.emit(OpCode::JumpIfFalse(0));

                // Compile then branch
                for stmt in &cond.then_branch {
                    self.compile_statement(stmt, func)?;
                }

                // Jump over else branch
                let jump_over_else = func.emit(OpCode::Jump(0));

                // Patch jump to else
                let else_start = func.current_offset();
                func.patch_jump(jump_to_else, else_start);

                // Compile else branch if present
                if let Some(else_branch) = &cond.else_branch {
                    for stmt in else_branch {
                        self.compile_statement(stmt, func)?;
                    }
                }

                // Patch jump over else
                let after_else = func.current_offset();
                func.patch_jump(jump_over_else, after_else);

                Ok(())
            }

            Statement::Loop(loop_stmt) => {
                // Compile loop count
                self.compile_expr(&loop_stmt.count.node, func)?;

                // Loop implementation
                let loop_start = func.current_offset();

                // Duplicate counter, check if > 0
                func.emit(OpCode::Dup);
                let zero_const = func.add_constant(Value::Int(0));
                func.emit(OpCode::Const(zero_const));
                func.emit(OpCode::Gt);

                // Exit loop if counter <= 0
                let exit_jump = func.emit(OpCode::JumpIfFalse(0));

                // Execute loop body
                for stmt in &loop_stmt.body {
                    self.compile_statement(stmt, func)?;
                }

                // Decrement counter
                func.emit(OpCode::Dup);
                let one_const = func.add_constant(Value::Int(1));
                func.emit(OpCode::Const(one_const));
                func.emit(OpCode::Sub);

                // Jump back to loop start
                func.emit(OpCode::Jump(loop_start));

                // Patch exit jump
                let after_loop = func.current_offset();
                func.patch_jump(exit_jump, after_loop);

                // Pop counter
                func.emit(OpCode::Pop);

                Ok(())
            }

            Statement::AttemptBlock(attempt) => {
                // Compile attempt body
                // Note: Real implementation would need exception handling
                // For now, just execute the body
                for stmt in &attempt.body {
                    self.compile_statement(stmt, func)?;
                }

                // TODO: Add proper Result error handling
                // The reassurance message is in attempt.reassurance

                Ok(())
            }

            Statement::ConsentBlock(consent) => {
                // Gate the body on a runtime consent check (`only if okay "..."`).
                // `CheckConsent` pushes a Bool; if denied, skip the body. Under
                // `#care` an ungranted permission is denied (deny-by-default,
                // mirroring the non-interactive interpreter); with `#care` off the
                // check passes. Seeding grants from `superpower` declarations is a
                // follow-up.
                func.emit(OpCode::CheckConsent(consent.permission.clone()));
                let skip_body = func.emit(OpCode::JumpIfFalse(0));

                for stmt in &consent.body {
                    self.compile_statement(stmt, func)?;
                }

                let after_body = func.current_offset();
                func.patch_jump(skip_body, after_body);
                Ok(())
            }

            Statement::Decide(decide) => {
                // Compile scrutinee (the value being matched)
                self.compile_expr(&decide.scrutinee.node, func)?;

                let mut arm_jumps = Vec::new();

                for arm in &decide.arms {
                    // For each pattern, check if it matches
                    match &arm.pattern {
                        Pattern::Literal(lit) => {
                            // Duplicate scrutinee for comparison
                            func.emit(OpCode::Dup);

                            // Push literal
                            let value = match lit {
                                Literal::Integer(n) => Value::Int(*n),
                                Literal::Float(f) => Value::Float(*f),
                                Literal::String(s) => Value::String(s.clone()),
                                Literal::Bool(b) => Value::Bool(*b),
                                Literal::Unit => Value::Unit,
                            };
                            let const_idx = func.add_constant(value);
                            func.emit(OpCode::Const(const_idx));

                            // Compare
                            func.emit(OpCode::Eq);

                            // If matches, execute arm body
                            let skip_arm = func.emit(OpCode::JumpIfFalse(0));

                            // Execute arm body
                            for stmt in &arm.body {
                                self.compile_statement(stmt, func)?;
                            }

                            // Jump to end of match
                            let to_end = func.emit(OpCode::Jump(0));
                            arm_jumps.push(to_end);

                            // Patch skip jump
                            func.patch_jump(skip_arm, func.current_offset());
                        }

                        Pattern::Constructor(name, inner) => {
                            // Handle Okay(x) / Oops(e) patterns
                            if name == "Okay" || name == "Oops" {
                                // Duplicate scrutinee
                                func.emit(OpCode::Dup);

                                // Check if it's the right constructor
                                func.emit(OpCode::IsOkay);
                                let is_okay_result = name == "Okay";

                                if !is_okay_result {
                                    // Negate for Oops pattern
                                    func.emit(OpCode::Not);
                                }

                                let skip_arm = func.emit(OpCode::JumpIfFalse(0));

                                // If inner pattern exists, bind the variable
                                if let Some(Pattern::Identifier(var_name)) = inner.as_deref() {
                                    // Unwrap the value (simplified - real impl would extract value)
                                    func.emit(OpCode::Dup);
                                    func.emit(OpCode::TryUnwrap);

                                    // Bind to variable
                                    let local_idx = self.add_local(var_name.clone());
                                    func.emit(OpCode::StoreLocal(local_idx));
                                }

                                // Execute arm body
                                for stmt in &arm.body {
                                    self.compile_statement(stmt, func)?;
                                }

                                // Jump to end
                                let to_end = func.emit(OpCode::Jump(0));
                                arm_jumps.push(to_end);

                                // Patch skip
                                func.patch_jump(skip_arm, func.current_offset());
                            }
                        }

                        Pattern::Identifier(name) => {
                            // Bind scrutinee to variable and execute body
                            func.emit(OpCode::Dup);
                            let local_idx = self.add_local(name.clone());
                            func.emit(OpCode::StoreLocal(local_idx));

                            // Execute arm body
                            for stmt in &arm.body {
                                self.compile_statement(stmt, func)?;
                            }

                            // Jump to end
                            let to_end = func.emit(OpCode::Jump(0));
                            arm_jumps.push(to_end);
                        }

                        Pattern::Wildcard => {
                            // Always matches - execute body
                            for stmt in &arm.body {
                                self.compile_statement(stmt, func)?;
                            }

                            // Jump to end
                            let to_end = func.emit(OpCode::Jump(0));
                            arm_jumps.push(to_end);
                        }
                    }
                }

                // Pop scrutinee
                func.emit(OpCode::Pop);

                // Patch all jumps to end
                let end_offset = func.current_offset();
                for jump_idx in arm_jumps {
                    func.patch_jump(jump_idx, end_offset);
                }

                Ok(())
            }

            Statement::While(while_loop) => {
                // Re-evaluate the condition at the top of every iteration.
                let loop_start = func.current_offset();
                self.compile_expr(&while_loop.condition.node, func)?;
                let exit_jump = func.emit(OpCode::JumpIfFalse(0));

                // `continue` re-tests the condition; `break` exits the loop.
                self.loop_stack.push(LoopCtx {
                    continue_target: loop_start,
                    break_jumps: Vec::new(),
                });

                for stmt in &while_loop.body {
                    self.compile_statement(stmt, func)?;
                }

                // Back-edge to the condition, then patch the false-exit.
                func.emit(OpCode::Jump(loop_start));
                let after_loop = func.current_offset();
                func.patch_jump(exit_jump, after_loop);

                // Patch every `break` in this loop to jump past it.
                let ctx = self.loop_stack.pop().expect("loop_stack underflow");
                for bj in ctx.break_jumps {
                    func.patch_jump(bj, after_loop);
                }
                Ok(())
            }

            Statement::Break(_span) => {
                let jump_idx = func.emit(OpCode::Jump(0));
                match self.loop_stack.last_mut() {
                    Some(ctx) => {
                        ctx.break_jumps.push(jump_idx);
                        Ok(())
                    }
                    None => Err(CompileError::Internal(
                        "`break` used outside of a while loop".to_string(),
                    )),
                }
            }

            Statement::Continue(_span) => match self.loop_stack.last() {
                Some(ctx) => {
                    let target = ctx.continue_target;
                    func.emit(OpCode::Jump(target));
                    Ok(())
                }
                None => Err(CompileError::Internal(
                    "`continue` used outside of a while loop".to_string(),
                )),
            },

            Statement::Complain(complain) => {
                // `complain "msg"` raises a runtime error carrying the message.
                let msg_idx = func.add_constant(Value::String(complain.message.clone()));
                func.emit(OpCode::Const(msg_idx));
                func.emit(OpCode::Throw);
                Ok(())
            }

            Statement::EmoteAnnotated(emote) => {
                // The emote tag is metadata; compile the underlying statement.
                self.compile_statement(&emote.statement, func)
            }

            _ => Err(CompileError::NotImplemented(format!(
                "Statement compilation: {:?}",
                stmt
            ))),
        }
    }

    /// Compile an expression
    fn compile_expr(
        &mut self,
        expr: &Expr,
        func: &mut CompiledFunction,
    ) -> Result<(), CompileError> {
        match expr {
            Expr::Literal(lit) => {
                let value = match lit {
                    Literal::Integer(n) => Value::Int(*n),
                    Literal::Float(f) => Value::Float(*f),
                    Literal::String(s) => Value::String(s.clone()),
                    Literal::Bool(b) => Value::Bool(*b),
                    Literal::Unit => Value::Unit,
                };
                let const_idx = func.add_constant(value);
                func.emit(OpCode::Const(const_idx));
                Ok(())
            }

            Expr::Identifier(name) => {
                if let Some(local_idx) = self.resolve_local(name) {
                    func.emit(OpCode::LoadLocal(local_idx));
                } else {
                    func.emit(OpCode::LoadGlobal(name.clone()));
                }
                Ok(())
            }

            Expr::Binary(op, left, right) => {
                // Compile operands
                self.compile_expr(&left.node, func)?;
                self.compile_expr(&right.node, func)?;

                // Emit operation
                let opcode = match op {
                    BinaryOp::Add => OpCode::Add,
                    BinaryOp::Sub => OpCode::Sub,
                    BinaryOp::Mul => OpCode::Mul,
                    BinaryOp::Div => OpCode::Div,
                    BinaryOp::Mod => OpCode::Mod,
                    BinaryOp::Eq => OpCode::Eq,
                    BinaryOp::NotEq => OpCode::Ne,
                    BinaryOp::Lt => OpCode::Lt,
                    BinaryOp::Gt => OpCode::Gt,
                    BinaryOp::LtEq => OpCode::Le,
                    BinaryOp::GtEq => OpCode::Ge,
                    BinaryOp::And => OpCode::And,
                    BinaryOp::Or => OpCode::Or,
                };
                func.emit(opcode);
                Ok(())
            }

            Expr::Unary(op, operand) => {
                self.compile_expr(&operand.node, func)?;
                let opcode = match op {
                    UnaryOp::Neg => OpCode::Neg,
                    UnaryOp::Not => OpCode::Not,
                };
                func.emit(opcode);
                Ok(())
            }

            Expr::Call(func_name, args) => {
                // Resolve the callee to its function-table index. The arity is
                // recovered at runtime from the called function's definition.
                let func_idx = *self
                    .function_indices
                    .get(func_name)
                    .ok_or_else(|| CompileError::UndefinedFunction(func_name.clone()))?;

                // Compile arguments left-to-right so they sit on top of the
                // stack in parameter order, ready to become the callee's locals.
                for arg in args {
                    self.compile_expr(&arg.node, func)?;
                }

                // Emit call to the resolved function index.
                func.emit(OpCode::Call(func_idx));
                Ok(())
            }

            Expr::Array(elements) => {
                // Compile elements
                for elem in elements {
                    self.compile_expr(&elem.node, func)?;
                }

                // Create array
                func.emit(OpCode::MakeArray(elements.len()));
                Ok(())
            }

            Expr::Index(array, index) => {
                // Compile array/collection
                self.compile_expr(&array.node, func)?;
                // Compile index
                self.compile_expr(&index.node, func)?;
                // Emit index operation
                func.emit(OpCode::Index);
                Ok(())
            }

            Expr::Okay(value) => {
                // Compile the wrapped value
                self.compile_expr(&value.node, func)?;
                // Wrap in Okay constructor
                func.emit(OpCode::MakeOkay);
                Ok(())
            }

            Expr::Oops(value) => {
                // Compile the error value
                self.compile_expr(&value.node, func)?;
                // Wrap in Oops constructor
                func.emit(OpCode::MakeOops);
                Ok(())
            }

            Expr::Unwrap(value) => {
                // Compile the Result value
                self.compile_expr(&value.node, func)?;
                // Try to unwrap (propagates Oops if error)
                func.emit(OpCode::TryUnwrap);
                Ok(())
            }

            Expr::CallExpr(callee, args) => {
                // Compile the callee expression (should evaluate to a closure)
                self.compile_expr(&callee.node, func)?;

                // Compile arguments
                for arg in args {
                    self.compile_expr(&arg.node, func)?;
                }

                // Call the closure
                func.emit(OpCode::Call(args.len()));
                Ok(())
            }

            Expr::Lambda(lambda) => {
                // Create a new function for the lambda
                let lambda_name = format!("<lambda_{}>", self.scope_depth);
                let mut lambda_func = CompiledFunction::new(lambda_name, lambda.params.len());

                // Enter new scope for lambda
                self.scope_depth += 1;
                let old_locals = std::mem::take(&mut self.locals);

                // Add parameters as locals
                for param in &lambda.params {
                    self.add_local(param.name.clone());
                    lambda_func.locals += 1;
                }

                // Compile lambda body
                match &lambda.body {
                    LambdaBody::Expr(expr) => {
                        self.compile_expr(&expr.node, &mut lambda_func)?;
                        lambda_func.emit(OpCode::Return);
                    }
                    LambdaBody::Block(stmts) => {
                        for stmt in stmts {
                            self.compile_statement(stmt, &mut lambda_func)?;
                        }
                        // Implicit return of Unit if no explicit return
                        let unit_const = lambda_func.add_constant(Value::Unit);
                        lambda_func.emit(OpCode::Const(unit_const));
                        lambda_func.emit(OpCode::Return);
                    }
                }

                // Restore scope
                self.scope_depth -= 1;
                self.locals = old_locals;

                // Add lambda function to program
                let func_idx = self.program.add_function(lambda_func);

                // Create closure from function
                func.emit(OpCode::MakeClosure(func_idx));
                Ok(())
            }

            Expr::RecordLiteral(_type_name, fields) => {
                // Push each field as a (key, value) pair: key constant, then value.
                // `MakeRecord` pops them into a structural record (the type name is
                // compile-time only).
                for (key, value_expr) in fields {
                    let key_idx = func.add_constant(Value::String(key.clone()));
                    func.emit(OpCode::Const(key_idx));
                    self.compile_expr(&value_expr.node, func)?;
                }
                func.emit(OpCode::MakeRecord(fields.len()));
                Ok(())
            }

            Expr::FieldAccess(object, field) => {
                // `obj.field` lowers to indexing the record by the field name.
                self.compile_expr(&object.node, func)?;
                let key_idx = func.add_constant(Value::String(field.clone()));
                func.emit(OpCode::Const(key_idx));
                func.emit(OpCode::Index);
                Ok(())
            }

            Expr::UnitMeasurement(inner, _unit) => {
                // Units of measure are a compile-time concern; at runtime the
                // value is just the underlying number.
                self.compile_expr(&inner.node, func)
            }

            Expr::GratitudeLiteral(text) => {
                // A gratitude literal is a string-valued acknowledgement.
                let idx = func.add_constant(Value::String(text.clone()));
                func.emit(OpCode::Const(idx));
                Ok(())
            }
            // All `Expr` variants are now handled; `Lambda`/`CallExpr` closure
            // *calls* still need a calling-convention fix (tracked separately).
        }
    }

    /// Add a local variable
    fn add_local(&mut self, name: String) -> usize {
        let idx = self.locals.len();
        self.locals.push(Local {
            name,
            depth: self.scope_depth,
        });
        idx
    }

    /// Resolve a local variable by name
    fn resolve_local(&self, name: &str) -> Option<usize> {
        for (idx, local) in self.locals.iter().enumerate().rev() {
            if local.name == name {
                return Some(idx);
            }
        }
        None
    }
}

impl Default for BytecodeCompiler {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compiler_new() {
        let compiler = BytecodeCompiler::new();
        assert_eq!(compiler.scope_depth, 0);
    }
}
