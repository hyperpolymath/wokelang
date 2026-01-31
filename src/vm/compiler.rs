// SPDX-License-Identifier: PMPL-1.0-or-later
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
    depth: usize,
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
}

impl BytecodeCompiler {
    pub fn new() -> Self {
        Self {
            current_function: None,
            locals: Vec::new(),
            scope_depth: 0,
            function_indices: HashMap::new(),
        }
    }

    /// Compile a program to bytecode
    pub fn compile(&mut self, program: &Program) -> Result<CompiledProgram, CompileError> {
        let mut compiled = CompiledProgram::new();

        // First pass: register all functions
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                let func_idx = compiled.functions.len();
                self.function_indices
                    .insert(func.name.clone(), func_idx);

                // Create compiled function
                let compiled_func = CompiledFunction::new(func.name.clone(), func.params.len());
                compiled.functions.push(compiled_func);
            }
        }

        // Second pass: compile function bodies
        for (idx, item) in program.items.iter().enumerate() {
            if let TopLevelItem::Function(func) = item {
                let func_idx = *self.function_indices.get(&func.name).unwrap();
                self.compile_function(func, &mut compiled.functions[func_idx])?;

                // Set entry point to main
                if func.name == "main" {
                    compiled.entry = Some(func_idx);
                }
            }
        }

        Ok(compiled)
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
        for (i, param) in func.params.iter().enumerate() {
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

            _ => Err(CompileError::NotImplemented(format!(
                "Statement compilation: {:?}",
                stmt
            ))),
        }
    }

    /// Compile an expression
    fn compile_expr(&mut self, expr: &Expr, func: &mut CompiledFunction) -> Result<(), CompileError> {
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
                // Compile arguments
                for arg in args {
                    self.compile_expr(&arg.node, func)?;
                }

                // Emit call
                func.emit(OpCode::Call(args.len()));
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

            _ => Err(CompileError::NotImplemented(format!(
                "Expression compilation: {:?}",
                expr
            ))),
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
