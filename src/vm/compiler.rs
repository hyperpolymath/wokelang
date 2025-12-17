//! WokeLang Bytecode Compiler
//!
//! Compiles AST to bytecode for the VM.

use crate::ast::{
    BinaryOp, Expr, FunctionDef, Literal, Loop, Pattern, Program, Spanned,
    Statement, TopLevelItem, UnaryOp,
};
use crate::interpreter::Value;
use super::bytecode::{CompiledFunction, CompiledProgram, OpCode};
use std::collections::HashMap;

/// Bytecode compiler
pub struct BytecodeCompiler {
    /// The compiled program being built
    program: CompiledProgram,
    /// Current function being compiled
    current_function: Option<CompiledFunction>,
    /// Local variable name to slot mapping
    locals: HashMap<String, usize>,
    /// Function name to index mapping
    function_indices: HashMap<String, usize>,
    /// Loop break jump targets (for nested loops)
    break_targets: Vec<Vec<usize>>,
    /// Loop continue targets
    continue_targets: Vec<usize>,
}

impl BytecodeCompiler {
    pub fn new() -> Self {
        Self {
            program: CompiledProgram::new(),
            current_function: None,
            locals: HashMap::new(),
            function_indices: HashMap::new(),
            break_targets: Vec::new(),
            continue_targets: Vec::new(),
        }
    }

    /// Compile a program to bytecode
    pub fn compile(&mut self, program: &Program) -> Result<CompiledProgram, CompileError> {
        // First pass: register all function names
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                let idx = self.program.functions.len() + self.function_indices.len();
                self.function_indices.insert(func.name.clone(), idx);
            }
        }

        // Second pass: compile all items
        for item in &program.items {
            self.compile_item(item)?;
        }

        Ok(self.program.clone())
    }

    fn compile_item(&mut self, item: &TopLevelItem) -> Result<(), CompileError> {
        match item {
            TopLevelItem::Function(func) => {
                self.compile_function(func)?;
            }
            TopLevelItem::WorkerDef(worker) => {
                // Compile worker as a function
                let mut compiled = CompiledFunction::new(worker.name.clone(), 0);
                self.locals.clear();
                compiled.locals = 0;
                self.current_function = Some(compiled);

                for stmt in &worker.body {
                    self.compile_statement(stmt)?;
                }

                // Add implicit return
                if let Some(ref mut func) = self.current_function {
                    if func.code.is_empty() || !matches!(func.code.last(), Some(OpCode::Return)) {
                        let unit_idx = func.add_constant(Value::Unit);
                        func.emit(OpCode::Const(unit_idx));
                        func.emit(OpCode::Return);
                    }
                }

                if let Some(func) = self.current_function.take() {
                    self.program.add_function(func);
                }
            }
            TopLevelItem::ConsentBlock(consent) => {
                // Create an anonymous function for consent block
                let name = format!("__consent_{}__", consent.permission);
                let mut compiled = CompiledFunction::new(name, 0);
                self.locals.clear();
                self.current_function = Some(compiled);

                for stmt in &consent.body {
                    self.compile_statement(stmt)?;
                }

                if let Some(ref mut func) = self.current_function {
                    let unit_idx = func.add_constant(Value::Unit);
                    func.emit(OpCode::Const(unit_idx));
                    func.emit(OpCode::Return);
                }

                if let Some(func) = self.current_function.take() {
                    self.program.add_function(func);
                }
            }
            // Skip metadata items for bytecode
            TopLevelItem::GratitudeDecl(_) => {}
            TopLevelItem::SideQuestDef(_) => {}
            TopLevelItem::SuperpowerDecl(_) => {}
            TopLevelItem::ModuleImport(_) => {}
            TopLevelItem::ModuleExport(_) => {}
            TopLevelItem::Pragma(_) => {}
            TopLevelItem::TypeDef(_) => {}
            TopLevelItem::ConstDef(const_def) => {
                // Handle const definitions at compile time if possible
                // For now, store them as globals
                let name = const_def.name.clone();
                if let Some(value) = self.try_eval_const(&const_def.value.node) {
                    self.program.globals.insert(name, value);
                }
            }
        }
        Ok(())
    }

    fn compile_function(&mut self, func: &FunctionDef) -> Result<(), CompileError> {
        // Start a new function
        let mut compiled = CompiledFunction::new(func.name.clone(), func.params.len());

        // Set up locals for parameters
        self.locals.clear();
        for (i, param) in func.params.iter().enumerate() {
            self.locals.insert(param.name.clone(), i);
        }
        compiled.locals = func.params.len();

        self.current_function = Some(compiled);

        // Compile function body
        for stmt in &func.body {
            self.compile_statement(stmt)?;
        }

        // Add implicit return if needed
        if let Some(ref mut func) = self.current_function {
            if func.code.is_empty() || !matches!(func.code.last(), Some(OpCode::Return)) {
                let unit_idx = func.add_constant(Value::Unit);
                func.emit(OpCode::Const(unit_idx));
                func.emit(OpCode::Return);
            }
        }

        // Add function to program
        if let Some(compiled_func) = self.current_function.take() {
            self.program.add_function(compiled_func);
        }

        Ok(())
    }

    fn compile_statement(&mut self, stmt: &Statement) -> Result<(), CompileError> {
        match stmt {
            Statement::VarDecl(decl) => {
                // Compile the initializer
                self.compile_expr(&decl.value)?;

                // Allocate local slot
                let slot = self.allocate_local(&decl.name);
                self.emit(OpCode::StoreLocal(slot));
            }

            Statement::Assignment(assign) => {
                // Compile the value
                self.compile_expr(&assign.value)?;

                // Store to variable
                if let Some(&slot) = self.locals.get(&assign.target) {
                    self.emit(OpCode::StoreLocal(slot));
                } else {
                    self.emit(OpCode::StoreGlobal(assign.target.clone()));
                }
            }

            Statement::Return(ret) => {
                self.compile_expr(&ret.value)?;
                self.emit(OpCode::Return);
            }

            Statement::Conditional(cond) => {
                // Compile condition
                self.compile_expr(&cond.condition)?;

                // Jump over then-branch if false
                let jump_if_false = self.emit(OpCode::JumpIfFalse(0));

                // Compile then-branch
                for stmt in &cond.then_branch {
                    self.compile_statement(stmt)?;
                }

                if let Some(else_branch) = &cond.else_branch {
                    // Jump over else-branch
                    let jump_over_else = self.emit(OpCode::Jump(0));

                    // Patch the conditional jump
                    let else_start = self.current_offset();
                    self.patch_jump(jump_if_false, else_start);

                    // Compile else-branch
                    for stmt in else_branch {
                        self.compile_statement(stmt)?;
                    }

                    // Patch jump over else
                    let after_else = self.current_offset();
                    self.patch_jump(jump_over_else, after_else);
                } else {
                    // Patch the conditional jump
                    let after_if = self.current_offset();
                    self.patch_jump(jump_if_false, after_if);
                }
            }

            Statement::Loop(loop_stmt) => {
                self.compile_loop(loop_stmt)?;
            }

            Statement::Decide(decide) => {
                // Pattern matching - compile as a series of conditionals
                self.compile_expr(&decide.scrutinee)?;

                // Store scrutinee in a temp variable
                let scrutinee_slot = self.allocate_local("__scrutinee__");
                self.emit(OpCode::StoreLocal(scrutinee_slot));

                let mut end_jumps = Vec::new();

                for arm in &decide.arms {
                    // Load scrutinee for each arm
                    self.emit(OpCode::LoadLocal(scrutinee_slot));

                    // Compile pattern match
                    let skip_jump = self.compile_pattern(&arm.pattern)?;

                    // Compile arm body
                    for stmt in &arm.body {
                        self.compile_statement(stmt)?;
                    }

                    // Jump to end
                    let end_jump = self.emit(OpCode::Jump(0));
                    end_jumps.push(end_jump);

                    // Patch skip jump
                    let after_arm = self.current_offset();
                    self.patch_jump(skip_jump, after_arm);
                }

                // Patch all end jumps
                let after_decide = self.current_offset();
                for jump in end_jumps {
                    self.patch_jump(jump, after_decide);
                }
            }

            Statement::Expression(expr) => {
                self.compile_expr(expr)?;
                self.emit(OpCode::Pop);
            }

            Statement::AttemptBlock(attempt) => {
                // try/catch style - compile body with error handling setup
                for stmt in &attempt.body {
                    self.compile_statement(stmt)?;
                }
                // The reassurance is just metadata for now
            }

            Statement::ConsentBlock(consent) => {
                // Consent is checked at runtime
                for stmt in &consent.body {
                    self.compile_statement(stmt)?;
                }
            }

            Statement::Complain(complain) => {
                // Load error message
                let msg_idx = self.add_constant(Value::String(complain.message.clone()));
                self.emit(OpCode::Const(msg_idx));
                self.emit(OpCode::MakeOops);
                self.emit(OpCode::Return);
            }

            Statement::EmoteAnnotated(annotated) => {
                // Compile the inner statement, emote is metadata
                self.compile_statement(&annotated.statement)?;
            }

            // Worker-related statements
            Statement::WorkerSpawn(_) => {
                // Worker spawning handled at runtime
            }
            Statement::SendMessage(send) => {
                self.compile_expr(&send.value)?;
                // Message sending handled at runtime
            }
            Statement::ReceiveMessage(_) => {
                // Message receiving handled at runtime
            }
            Statement::AwaitWorker(_) => {
                // Worker awaiting handled at runtime
            }
            Statement::CancelWorker(_) => {
                // Worker cancellation handled at runtime
            }
        }
        Ok(())
    }

    fn compile_loop(&mut self, loop_stmt: &Loop) -> Result<(), CompileError> {
        // Compile the count expression
        self.compile_expr(&loop_stmt.count)?;

        // Store count in a temporary local
        let counter_slot = self.allocate_local("__counter__");
        self.emit(OpCode::StoreLocal(counter_slot));

        // Push break targets
        self.break_targets.push(Vec::new());

        let loop_start = self.current_offset();
        self.continue_targets.push(loop_start);

        // Check if counter > 0
        self.emit(OpCode::LoadLocal(counter_slot));
        let zero_idx = self.add_constant(Value::Int(0));
        self.emit(OpCode::Const(zero_idx));
        self.emit(OpCode::Gt);
        let exit_jump = self.emit(OpCode::JumpIfFalse(0));

        // Compile body
        for stmt in &loop_stmt.body {
            self.compile_statement(stmt)?;
        }

        // Decrement counter
        self.emit(OpCode::LoadLocal(counter_slot));
        let one_idx = self.add_constant(Value::Int(1));
        self.emit(OpCode::Const(one_idx));
        self.emit(OpCode::Sub);
        self.emit(OpCode::StoreLocal(counter_slot));

        // Jump back
        self.emit(OpCode::Jump(loop_start));

        // Patch exit
        let after_loop = self.current_offset();
        self.patch_jump(exit_jump, after_loop);

        // Patch breaks
        if let Some(breaks) = self.break_targets.pop() {
            for break_jump in breaks {
                self.patch_jump(break_jump, after_loop);
            }
        }
        self.continue_targets.pop();

        Ok(())
    }

    fn compile_pattern(&mut self, pattern: &Pattern) -> Result<usize, CompileError> {
        match pattern {
            Pattern::Wildcard => {
                // Always matches, just pop the value
                self.emit(OpCode::Pop);
                // Return a dummy jump that will be patched but never taken
                let always_true = self.add_constant(Value::Bool(true));
                self.emit(OpCode::Const(always_true));
                Ok(self.emit(OpCode::JumpIfFalse(0)))
            }

            Pattern::Literal(lit) => {
                // Compare against literal
                match lit {
                    Literal::Integer(n) => {
                        let idx = self.add_constant(Value::Int(*n));
                        self.emit(OpCode::Const(idx));
                    }
                    Literal::Float(n) => {
                        let idx = self.add_constant(Value::Float(*n));
                        self.emit(OpCode::Const(idx));
                    }
                    Literal::String(s) => {
                        let idx = self.add_constant(Value::String(s.clone()));
                        self.emit(OpCode::Const(idx));
                    }
                    Literal::Bool(b) => {
                        let idx = self.add_constant(Value::Bool(*b));
                        self.emit(OpCode::Const(idx));
                    }
                }
                self.emit(OpCode::Eq);
                Ok(self.emit(OpCode::JumpIfFalse(0)))
            }

            Pattern::Identifier(name) => {
                // Bind value to name
                let slot = self.allocate_local(name);
                self.emit(OpCode::StoreLocal(slot));
                // Always matches
                let always_true = self.add_constant(Value::Bool(true));
                self.emit(OpCode::Const(always_true));
                Ok(self.emit(OpCode::JumpIfFalse(0)))
            }

            Pattern::OkayPattern(binding) => {
                // Check if value is Okay
                self.emit(OpCode::Dup);
                self.emit(OpCode::IsOkay);
                let skip = self.emit(OpCode::JumpIfFalse(0));

                // If okay, extract inner value
                if let Some(name) = binding {
                    self.emit(OpCode::TryUnwrap);
                    let slot = self.allocate_local(name);
                    self.emit(OpCode::StoreLocal(slot));
                } else {
                    self.emit(OpCode::Pop);
                }

                Ok(skip)
            }

            Pattern::OopsPattern(binding) => {
                // Check if value is Oops (not Okay)
                self.emit(OpCode::Dup);
                self.emit(OpCode::IsOkay);
                self.emit(OpCode::Not);
                let skip = self.emit(OpCode::JumpIfFalse(0));

                // If oops, extract error
                if let Some(name) = binding {
                    // Extract error value (implementation specific)
                    let slot = self.allocate_local(name);
                    self.emit(OpCode::StoreLocal(slot));
                } else {
                    self.emit(OpCode::Pop);
                }

                Ok(skip)
            }

            Pattern::Constructor(name, patterns) => {
                // Constructor pattern matching
                // For now, just check if it matches the constructor name
                let name_idx = self.add_constant(Value::String(name.clone()));
                self.emit(OpCode::Const(name_idx));
                self.emit(OpCode::Eq);
                let skip = self.emit(OpCode::JumpIfFalse(0));

                // TODO: Match inner patterns
                for _ in patterns {
                    // Would need to extract fields and match against inner patterns
                }

                Ok(skip)
            }

            Pattern::Guard(inner, condition) => {
                // First match inner pattern
                let inner_skip = self.compile_pattern(inner)?;

                // Then check guard condition
                self.compile_expr(condition)?;
                let guard_skip = self.emit(OpCode::JumpIfFalse(0));

                // Both must pass - use the guard skip as the main skip
                // The inner_skip needs to also jump to the after-arm location
                Ok(guard_skip)
            }
        }
    }

    fn compile_expr(&mut self, spanned: &Spanned<Expr>) -> Result<(), CompileError> {
        let expr = &spanned.node;
        match expr {
            Expr::Literal(lit) => {
                match lit {
                    Literal::Integer(n) => {
                        let idx = self.add_constant(Value::Int(*n));
                        self.emit(OpCode::Const(idx));
                    }
                    Literal::Float(n) => {
                        let idx = self.add_constant(Value::Float(*n));
                        self.emit(OpCode::Const(idx));
                    }
                    Literal::String(s) => {
                        let idx = self.add_constant(Value::String(s.clone()));
                        self.emit(OpCode::Const(idx));
                    }
                    Literal::Bool(b) => {
                        let idx = self.add_constant(Value::Bool(*b));
                        self.emit(OpCode::Const(idx));
                    }
                }
            }

            Expr::Identifier(name) => {
                if let Some(&slot) = self.locals.get(name) {
                    self.emit(OpCode::LoadLocal(slot));
                } else if let Some(&func_idx) = self.function_indices.get(name) {
                    self.emit(OpCode::MakeClosure(func_idx));
                } else {
                    self.emit(OpCode::LoadGlobal(name.clone()));
                }
            }

            Expr::Binary(op, left, right) => {
                self.compile_expr(left)?;
                self.compile_expr(right)?;

                match op {
                    BinaryOp::Add => self.emit(OpCode::Add),
                    BinaryOp::Sub => self.emit(OpCode::Sub),
                    BinaryOp::Mul => self.emit(OpCode::Mul),
                    BinaryOp::Div => self.emit(OpCode::Div),
                    BinaryOp::Mod => self.emit(OpCode::Mod),
                    BinaryOp::Eq => self.emit(OpCode::Eq),
                    BinaryOp::NotEq => self.emit(OpCode::Ne),
                    BinaryOp::Lt => self.emit(OpCode::Lt),
                    BinaryOp::Gt => self.emit(OpCode::Gt),
                    BinaryOp::LtEq => self.emit(OpCode::Le),
                    BinaryOp::GtEq => self.emit(OpCode::Ge),
                    BinaryOp::And => self.emit(OpCode::And),
                    BinaryOp::Or => self.emit(OpCode::Or),
                };
            }

            Expr::Unary(op, operand) => {
                self.compile_expr(operand)?;
                match op {
                    UnaryOp::Neg => self.emit(OpCode::Neg),
                    UnaryOp::Not => self.emit(OpCode::Not),
                };
            }

            Expr::Call(name, args) => {
                // Push arguments
                for arg in args {
                    self.compile_expr(arg)?;
                }

                // Special built-in functions
                match name.as_str() {
                    "print" => {
                        self.emit(OpCode::Print);
                    }
                    "toString" => {
                        self.emit(OpCode::ToString);
                    }
                    "len" => {
                        self.emit(OpCode::Len);
                    }
                    _ => {
                        // Look up function
                        if let Some(&func_idx) = self.function_indices.get(name) {
                            self.emit(OpCode::MakeClosure(func_idx));
                            self.emit(OpCode::Call(args.len()));
                        } else {
                            // Dynamic call via global
                            self.emit(OpCode::LoadGlobal(name.clone()));
                            self.emit(OpCode::Call(args.len()));
                        }
                    }
                }
            }

            Expr::Array(elements) => {
                for elem in elements {
                    self.compile_expr(elem)?;
                }
                self.emit(OpCode::MakeArray(elements.len()));
            }

            Expr::ResultConstructor { is_okay, value } => {
                self.compile_expr(value)?;
                if *is_okay {
                    self.emit(OpCode::MakeOkay);
                } else {
                    self.emit(OpCode::MakeOops);
                }
            }

            Expr::Try(inner) => {
                self.compile_expr(inner)?;
                self.emit(OpCode::TryUnwrap);
            }

            Expr::Unwrap(inner) => {
                self.compile_expr(inner)?;
                self.emit(OpCode::TryUnwrap);
            }

            Expr::UnitMeasurement(value, _unit) => {
                // Compile the value, unit is metadata
                self.compile_expr(value)?;
            }

            Expr::GratitudeLiteral(name) => {
                // Gratitude literals are just strings
                let idx = self.add_constant(Value::String(name.clone()));
                self.emit(OpCode::Const(idx));
            }
        }
        Ok(())
    }

    /// Try to evaluate a constant expression at compile time
    fn try_eval_const(&self, expr: &Expr) -> Option<Value> {
        match expr {
            Expr::Literal(lit) => match lit {
                Literal::Integer(n) => Some(Value::Int(*n)),
                Literal::Float(n) => Some(Value::Float(*n)),
                Literal::String(s) => Some(Value::String(s.clone())),
                Literal::Bool(b) => Some(Value::Bool(*b)),
            },
            _ => None,
        }
    }

    // Helper methods

    fn emit(&mut self, op: OpCode) -> usize {
        if let Some(ref mut func) = self.current_function {
            func.emit(op)
        } else {
            0
        }
    }

    fn add_constant(&mut self, value: Value) -> usize {
        if let Some(ref mut func) = self.current_function {
            func.add_constant(value)
        } else {
            0
        }
    }

    fn current_offset(&self) -> usize {
        if let Some(ref func) = self.current_function {
            func.current_offset()
        } else {
            0
        }
    }

    fn patch_jump(&mut self, jump_idx: usize, target: usize) {
        if let Some(ref mut func) = self.current_function {
            func.patch_jump(jump_idx, target);
        }
    }

    fn allocate_local(&mut self, name: &str) -> usize {
        if let Some(&slot) = self.locals.get(name) {
            return slot;
        }

        let slot = if let Some(ref mut func) = self.current_function {
            let s = func.locals;
            func.locals += 1;
            s
        } else {
            0
        };

        self.locals.insert(name.to_string(), slot);
        slot
    }
}

impl Default for BytecodeCompiler {
    fn default() -> Self {
        Self::new()
    }
}

/// Compilation error
#[derive(Debug, Clone)]
pub struct CompileError {
    pub message: String,
}

impl std::fmt::Display for CompileError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Compile error: {}", self.message)
    }
}

impl std::error::Error for CompileError {}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;
    use crate::parser::Parser;

    fn compile_source(source: &str) -> Result<CompiledProgram, CompileError> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();

        let mut compiler = BytecodeCompiler::new();
        compiler.compile(&program)
    }

    #[test]
    fn test_compile_simple_function() {
        let source = r#"
            to add(a: Int, b: Int) -> Int {
                give back a + b;
            }
        "#;

        let program = compile_source(source).unwrap();
        assert_eq!(program.functions.len(), 1);
        assert_eq!(program.functions[0].name, "add");
        assert_eq!(program.functions[0].arity, 2);
    }

    #[test]
    fn test_compile_main() {
        let source = r#"
            to main() {
                remember x = 5;
                give back x;
            }
        "#;

        let program = compile_source(source).unwrap();
        assert!(program.entry.is_some());
    }

    #[test]
    fn test_compile_conditional() {
        let source = r#"
            to test(x: Int) -> Int {
                when x > 0 {
                    give back 1;
                } otherwise {
                    give back 0;
                }
            }
        "#;

        let program = compile_source(source).unwrap();
        let func = &program.functions[0];

        // Should have JumpIfFalse for condition
        assert!(func.code.iter().any(|op| matches!(op, OpCode::JumpIfFalse(_))));
    }
}
