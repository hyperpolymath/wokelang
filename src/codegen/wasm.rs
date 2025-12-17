use crate::ast::*;
use std::collections::HashMap;
use thiserror::Error;
use wasm_encoder::{
    CodeSection, ExportKind, ExportSection, Function, FunctionSection, Instruction, Module,
    TypeSection, ValType,
};

#[derive(Error, Debug)]
pub enum CompileError {
    #[error("Unsupported feature: {0}")]
    Unsupported(String),

    #[error("Undefined variable: {0}")]
    UndefinedVariable(String),

    #[error("Undefined function: {0}")]
    UndefinedFunction(String),

    #[error("Type error: {0}")]
    TypeError(String),
}

type Result<T> = std::result::Result<T, CompileError>;

/// Compiles WokeLang to WebAssembly
pub struct WasmCompiler {
    /// Function name to index mapping
    functions: HashMap<String, u32>,
    /// Function signatures (param count, return count)
    signatures: HashMap<String, (Vec<ValType>, Vec<ValType>)>,
    /// Local variable mappings per function
    locals: HashMap<String, u32>,
    /// Current local index
    local_index: u32,
}

impl WasmCompiler {
    pub fn new() -> Self {
        Self {
            functions: HashMap::new(),
            signatures: HashMap::new(),
            locals: HashMap::new(),
            local_index: 0,
        }
    }

    /// Compile a WokeLang program to WASM binary
    pub fn compile(&mut self, program: &Program) -> Result<Vec<u8>> {
        let mut module = Module::new();

        // Collect function definitions first
        let mut func_defs: Vec<&FunctionDef> = Vec::new();
        for item in &program.items {
            if let TopLevelItem::Function(f) = item {
                func_defs.push(f);
            }
        }

        // Build type section (function signatures)
        let mut types = TypeSection::new();
        for (idx, func) in func_defs.iter().enumerate() {
            let params: Vec<ValType> = func.params.iter().map(|_| ValType::I64).collect();
            let results: Vec<ValType> = if func.return_type.is_some() {
                vec![ValType::I64]
            } else {
                vec![]
            };

            types.ty().function(params.clone(), results.clone());
            self.functions.insert(func.name.clone(), idx as u32);
            self.signatures
                .insert(func.name.clone(), (params, results));
        }
        module.section(&types);

        // Build function section (type indices)
        let mut functions = FunctionSection::new();
        for idx in 0..func_defs.len() {
            functions.function(idx as u32);
        }
        module.section(&functions);

        // Build export section
        let mut exports = ExportSection::new();
        for (name, idx) in &self.functions {
            exports.export(name, ExportKind::Func, *idx);
        }
        module.section(&exports);

        // Build code section
        let mut codes = CodeSection::new();
        for func in &func_defs {
            let wasm_func = self.compile_function(func)?;
            codes.function(&wasm_func);
        }
        module.section(&codes);

        Ok(module.finish())
    }

    fn compile_function(&mut self, func: &FunctionDef) -> Result<Function> {
        self.locals.clear();
        self.local_index = 0;

        // Register parameters as locals
        for param in &func.params {
            self.locals.insert(param.name.clone(), self.local_index);
            self.local_index += 1;
        }

        // Count additional locals needed
        let additional_locals = self.count_locals(&func.body);

        let mut wasm_func = Function::new(vec![(additional_locals, ValType::I64)]);

        // Compile function body
        for stmt in &func.body {
            self.compile_statement(stmt, &mut wasm_func)?;
        }

        // Add implicit return if no explicit return
        if func.return_type.is_none() {
            wasm_func.instruction(&Instruction::End);
        } else {
            // If there's a return type but no return statement, push 0
            wasm_func.instruction(&Instruction::End);
        }

        Ok(wasm_func)
    }

    fn count_locals(&self, stmts: &[Statement]) -> u32 {
        let mut count = 0;
        for stmt in stmts {
            match stmt {
                Statement::VarDecl(_) => count += 1,
                Statement::Conditional(c) => {
                    count += self.count_locals(&c.then_branch);
                    if let Some(else_branch) = &c.else_branch {
                        count += self.count_locals(else_branch);
                    }
                }
                Statement::Loop(l) => {
                    count += self.count_locals(&l.body);
                }
                Statement::AttemptBlock(a) => {
                    count += self.count_locals(&a.body);
                }
                _ => {}
            }
        }
        count
    }

    fn compile_statement(&mut self, stmt: &Statement, func: &mut Function) -> Result<()> {
        match stmt {
            Statement::VarDecl(decl) => {
                // Compile the value expression
                self.compile_expr(&decl.value, func)?;

                // Store in local
                let local_idx = self.local_index;
                self.locals.insert(decl.name.clone(), local_idx);
                self.local_index += 1;

                func.instruction(&Instruction::LocalSet(local_idx));
            }

            Statement::Assignment(assign) => {
                // Compile the value expression
                self.compile_expr(&assign.value, func)?;

                // Store in local
                let local_idx = *self
                    .locals
                    .get(&assign.target)
                    .ok_or_else(|| CompileError::UndefinedVariable(assign.target.clone()))?;

                func.instruction(&Instruction::LocalSet(local_idx));
            }

            Statement::Return(ret) => {
                self.compile_expr(&ret.value, func)?;
                func.instruction(&Instruction::Return);
            }

            Statement::Conditional(cond) => {
                // Compile condition
                self.compile_expr(&cond.condition, func)?;

                // If-else block
                func.instruction(&Instruction::If(wasm_encoder::BlockType::Empty));

                for s in &cond.then_branch {
                    self.compile_statement(s, func)?;
                }

                if let Some(else_branch) = &cond.else_branch {
                    func.instruction(&Instruction::Else);
                    for s in else_branch {
                        self.compile_statement(s, func)?;
                    }
                }

                func.instruction(&Instruction::End);
            }

            Statement::Loop(loop_stmt) => {
                // Compile loop count
                self.compile_expr(&loop_stmt.count, func)?;

                // Store count in a local
                let count_local = self.local_index;
                self.local_index += 1;
                func.instruction(&Instruction::LocalSet(count_local));

                // Loop structure
                func.instruction(&Instruction::Block(wasm_encoder::BlockType::Empty));
                func.instruction(&Instruction::Loop(wasm_encoder::BlockType::Empty));

                // Check if count > 0
                func.instruction(&Instruction::LocalGet(count_local));
                func.instruction(&Instruction::I64Const(0));
                func.instruction(&Instruction::I64LeS);
                func.instruction(&Instruction::BrIf(1)); // Break out if count <= 0

                // Execute body
                for s in &loop_stmt.body {
                    self.compile_statement(s, func)?;
                }

                // Decrement counter
                func.instruction(&Instruction::LocalGet(count_local));
                func.instruction(&Instruction::I64Const(1));
                func.instruction(&Instruction::I64Sub);
                func.instruction(&Instruction::LocalSet(count_local));

                // Continue loop
                func.instruction(&Instruction::Br(0));

                func.instruction(&Instruction::End); // End loop
                func.instruction(&Instruction::End); // End block
            }

            Statement::Expression(expr) => {
                self.compile_expr(expr, func)?;
                func.instruction(&Instruction::Drop); // Discard result
            }

            Statement::ConsentBlock(_) => {
                // Consent blocks are runtime-only, skip in WASM
                // Could be implemented with host imports
            }

            Statement::AttemptBlock(attempt) => {
                // Try-catch can be implemented with WASM exception handling
                // For now, just compile the body
                for s in &attempt.body {
                    self.compile_statement(s, func)?;
                }
            }

            Statement::Complain(_) => {
                // Would need host import for console output
            }

            Statement::WorkerSpawn(_) => {
                return Err(CompileError::Unsupported(
                    "Workers not supported in WASM".into(),
                ));
            }

            Statement::EmoteAnnotated(annotated) => {
                // Emote tags are metadata, compile the inner statement
                self.compile_statement(&annotated.statement, func)?;
            }

            Statement::Decide(decide) => {
                // Pattern matching - simplified to if-else chain
                self.compile_expr(&decide.scrutinee, func)?;
                let scrutinee_local = self.local_index;
                self.local_index += 1;
                func.instruction(&Instruction::LocalSet(scrutinee_local));

                for (i, arm) in decide.arms.iter().enumerate() {
                    let is_last = i == decide.arms.len() - 1;

                    match &arm.pattern {
                        Pattern::Wildcard => {
                            // Wildcard always matches
                            for s in &arm.body {
                                self.compile_statement(s, func)?;
                            }
                            break;
                        }
                        Pattern::Literal(lit) => {
                            // Compare with literal
                            func.instruction(&Instruction::LocalGet(scrutinee_local));
                            self.compile_literal(lit, func)?;
                            func.instruction(&Instruction::I64Eq);

                            func.instruction(&Instruction::If(wasm_encoder::BlockType::Empty));
                            for s in &arm.body {
                                self.compile_statement(s, func)?;
                            }

                            if !is_last {
                                func.instruction(&Instruction::Else);
                            }
                        }
                        Pattern::Identifier(name) => {
                            // Bind the value to the identifier
                            func.instruction(&Instruction::LocalGet(scrutinee_local));
                            let bind_local = self.local_index;
                            self.locals.insert(name.clone(), bind_local);
                            self.local_index += 1;
                            func.instruction(&Instruction::LocalSet(bind_local));

                            for s in &arm.body {
                                self.compile_statement(s, func)?;
                            }
                            break;
                        }
                        Pattern::OkayPattern(_) | Pattern::OopsPattern(_) => {
                            // Result patterns - simplified: just execute body for now
                            // Full implementation would check discriminant tag
                            for s in &arm.body {
                                self.compile_statement(s, func)?;
                            }
                        }
                        Pattern::Constructor(_, _) => {
                            // Constructor patterns - not fully supported in WASM yet
                            return Err(CompileError::Unsupported(
                                "Constructor patterns not yet supported in WASM".into(),
                            ));
                        }
                        Pattern::Guard(inner_pattern, _condition) => {
                            // Guard patterns - compile inner pattern first
                            // Full implementation would evaluate guard condition
                            match inner_pattern.as_ref() {
                                Pattern::Wildcard => {
                                    for s in &arm.body {
                                        self.compile_statement(s, func)?;
                                    }
                                    break;
                                }
                                _ => {
                                    return Err(CompileError::Unsupported(
                                        "Complex guard patterns not yet supported in WASM".into(),
                                    ));
                                }
                            }
                        }
                    }
                }

                // Close all if blocks
                for arm in &decide.arms {
                    if !matches!(arm.pattern, Pattern::Wildcard | Pattern::Identifier(_)) {
                        func.instruction(&Instruction::End);
                    }
                }
            }
        }

        Ok(())
    }

    fn compile_expr(&mut self, expr: &Spanned<Expr>, func: &mut Function) -> Result<()> {
        match &expr.node {
            Expr::Literal(lit) => {
                self.compile_literal(lit, func)?;
            }

            Expr::Identifier(name) => {
                let local_idx = *self
                    .locals
                    .get(name)
                    .ok_or_else(|| CompileError::UndefinedVariable(name.clone()))?;
                func.instruction(&Instruction::LocalGet(local_idx));
            }

            Expr::Binary(op, left, right) => {
                self.compile_expr(left, func)?;
                self.compile_expr(right, func)?;

                match op {
                    BinaryOp::Add => func.instruction(&Instruction::I64Add),
                    BinaryOp::Sub => func.instruction(&Instruction::I64Sub),
                    BinaryOp::Mul => func.instruction(&Instruction::I64Mul),
                    BinaryOp::Div => func.instruction(&Instruction::I64DivS),
                    BinaryOp::Mod => func.instruction(&Instruction::I64RemS),
                    BinaryOp::Eq => func.instruction(&Instruction::I64Eq),
                    BinaryOp::NotEq => func.instruction(&Instruction::I64Ne),
                    BinaryOp::Lt => func.instruction(&Instruction::I64LtS),
                    BinaryOp::Gt => func.instruction(&Instruction::I64GtS),
                    BinaryOp::LtEq => func.instruction(&Instruction::I64LeS),
                    BinaryOp::GtEq => func.instruction(&Instruction::I64GeS),
                    BinaryOp::And => func.instruction(&Instruction::I64And),
                    BinaryOp::Or => func.instruction(&Instruction::I64Or),
                };
            }

            Expr::Unary(op, operand) => {
                match op {
                    UnaryOp::Neg => {
                        func.instruction(&Instruction::I64Const(0));
                        self.compile_expr(operand, func)?;
                        func.instruction(&Instruction::I64Sub);
                    }
                    UnaryOp::Not => {
                        self.compile_expr(operand, func)?;
                        func.instruction(&Instruction::I64Eqz);
                    }
                };
            }

            Expr::Call(name, args) => {
                // Compile arguments
                for arg in args {
                    self.compile_expr(arg, func)?;
                }

                // Call function
                let func_idx = *self
                    .functions
                    .get(name)
                    .ok_or_else(|| CompileError::UndefinedFunction(name.clone()))?;
                func.instruction(&Instruction::Call(func_idx));
            }

            Expr::Array(_) => {
                return Err(CompileError::Unsupported(
                    "Arrays not yet supported in WASM compilation".into(),
                ));
            }

            Expr::UnitMeasurement(inner, _) => {
                // Just compile the inner expression, ignore units
                self.compile_expr(inner, func)?;
            }

            Expr::GratitudeLiteral(_) => {
                // Push 0 as placeholder
                func.instruction(&Instruction::I64Const(0));
            }

            Expr::ResultConstructor { is_okay, value } => {
                // Result types: compile the inner value
                // In a full implementation, we'd use a tagged union representation
                self.compile_expr(value, func)?;
                // Push a tag to indicate Okay(1) or Oops(0)
                if *is_okay {
                    // For Okay, we keep the value as-is (simplified)
                } else {
                    // For Oops, we could negate or use a different representation
                    // Simplified: just compile the inner expression
                }
            }

            Expr::Try(inner) => {
                // Try operator (?): compile inner expression
                // Full implementation would check if it's Oops and return early
                self.compile_expr(inner, func)?;
            }

            Expr::Unwrap(inner) => {
                // Unwrap: compile inner expression
                // Full implementation would trap on Oops
                self.compile_expr(inner, func)?;
            }
        }

        Ok(())
    }

    fn compile_literal(&self, lit: &Literal, func: &mut Function) -> Result<()> {
        match lit {
            Literal::Integer(n) => {
                func.instruction(&Instruction::I64Const(*n));
            }
            Literal::Float(f) => {
                // Convert to i64 bits for now (simplified)
                func.instruction(&Instruction::I64Const(f.to_bits() as i64));
            }
            Literal::Bool(b) => {
                func.instruction(&Instruction::I64Const(if *b { 1 } else { 0 }));
            }
            Literal::String(_) => {
                // Strings would need memory allocation
                // For now, push 0 as placeholder
                func.instruction(&Instruction::I64Const(0));
            }
        }
        Ok(())
    }
}

impl Default for WasmCompiler {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;
    use crate::parser::Parser;

    fn compile(source: &str) -> Result<Vec<u8>> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().expect("Lexer failed");
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().expect("Parser failed");
        let mut compiler = WasmCompiler::new();
        compiler.compile(&program)
    }

    #[test]
    fn test_compile_simple_function() {
        let source = r#"
            to add(a: Int, b: Int) -> Int {
                give back a + b;
            }
        "#;
        let wasm = compile(source).unwrap();
        assert!(!wasm.is_empty());
        // WASM magic number
        assert_eq!(&wasm[0..4], b"\0asm");
    }

    #[test]
    fn test_compile_factorial() {
        let source = r#"
            to factorial(n: Int) -> Int {
                when n <= 1 {
                    give back 1;
                }
                give back n * factorial(n - 1);
            }
        "#;
        let wasm = compile(source).unwrap();
        assert!(!wasm.is_empty());
    }

    #[test]
    fn test_compile_loop() {
        let source = r#"
            to sum_to_n(n: Int) -> Int {
                remember total = 0;
                remember i = n;
                repeat n times {
                    total = total + i;
                    i = i - 1;
                }
                give back total;
            }
        "#;
        let wasm = compile(source).unwrap();
        assert!(!wasm.is_empty());
    }
}
