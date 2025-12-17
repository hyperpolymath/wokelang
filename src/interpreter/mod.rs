mod value;

pub use value::Value;

use crate::ast::*;
use std::collections::HashMap;
use std::io::{self, Write};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum RuntimeError {
    #[error("Undefined variable: {0}")]
    UndefinedVariable(String),

    #[error("Undefined function: {0}")]
    UndefinedFunction(String),

    #[error("Type error: {0}")]
    TypeError(String),

    #[error("Division by zero")]
    DivisionByZero,

    #[error("Consent denied for: {0}")]
    ConsentDenied(String),

    #[error("Complaint: {0}")]
    Complaint(String),

    #[error("Index out of bounds: {0}")]
    IndexOutOfBounds(usize),

    #[error("Arity mismatch: expected {expected}, got {got}")]
    ArityMismatch { expected: usize, got: usize },
}

type Result<T> = std::result::Result<T, RuntimeError>;

/// Control flow signals for return statements
enum ControlFlow {
    Continue,
    Return(Value),
}

/// Runtime environment for variable bindings
#[derive(Clone)]
struct Environment {
    scopes: Vec<HashMap<String, Value>>,
}

impl Environment {
    fn new() -> Self {
        Self {
            scopes: vec![HashMap::new()],
        }
    }

    fn push_scope(&mut self) {
        self.scopes.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        self.scopes.pop();
    }

    fn define(&mut self, name: String, value: Value) {
        if let Some(scope) = self.scopes.last_mut() {
            scope.insert(name, value);
        }
    }

    fn get(&self, name: &str) -> Option<&Value> {
        for scope in self.scopes.iter().rev() {
            if let Some(value) = scope.get(name) {
                return Some(value);
            }
        }
        None
    }

    fn set(&mut self, name: &str, value: Value) -> bool {
        for scope in self.scopes.iter_mut().rev() {
            if scope.contains_key(name) {
                scope.insert(name.to_string(), value);
                return true;
            }
        }
        false
    }
}

/// The WokeLang interpreter
pub struct Interpreter {
    env: Environment,
    functions: HashMap<String, FunctionDef>,
    workers: HashMap<String, WorkerDef>,
    gratitude: Vec<(String, String)>,
    consent_cache: HashMap<String, bool>,
    verbose: bool,
    care_mode: bool,
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            env: Environment::new(),
            functions: HashMap::new(),
            workers: HashMap::new(),
            gratitude: Vec::new(),
            consent_cache: HashMap::new(),
            verbose: false,
            care_mode: true,
        }
    }

    pub fn run(&mut self, program: &Program) -> Result<()> {
        // First pass: collect all function and worker definitions
        for item in &program.items {
            match item {
                TopLevelItem::Function(f) => {
                    self.functions.insert(f.name.clone(), f.clone());
                }
                TopLevelItem::WorkerDef(w) => {
                    self.workers.insert(w.name.clone(), w.clone());
                }
                TopLevelItem::GratitudeDecl(g) => {
                    for entry in &g.entries {
                        self.gratitude
                            .push((entry.recipient.clone(), entry.reason.clone()));
                    }
                }
                TopLevelItem::Pragma(p) => {
                    match p.directive {
                        PragmaDirective::Verbose => self.verbose = p.enabled,
                        PragmaDirective::Care => self.care_mode = p.enabled,
                        PragmaDirective::Strict => {} // TODO
                    }
                }
                _ => {}
            }
        }

        // Show gratitude if verbose
        if self.verbose && !self.gratitude.is_empty() {
            println!("=== Gratitude ===");
            for (recipient, reason) in &self.gratitude {
                println!("  Thanks to {} for: {}", recipient, reason);
            }
            println!();
        }

        // Second pass: execute top-level items
        for item in &program.items {
            match item {
                TopLevelItem::ConsentBlock(c) => {
                    self.execute_consent_block(c)?;
                }
                TopLevelItem::Function(_)
                | TopLevelItem::WorkerDef(_)
                | TopLevelItem::GratitudeDecl(_)
                | TopLevelItem::Pragma(_) => {
                    // Already processed
                }
                _ => {}
            }
        }

        // Look for and execute main function
        if self.functions.contains_key("main") {
            self.call_function("main", vec![])?;
        }

        Ok(())
    }

    fn execute_statement(&mut self, stmt: &Statement) -> Result<ControlFlow> {
        match stmt {
            Statement::VarDecl(decl) => {
                let value = self.evaluate(&decl.value)?;
                if self.verbose {
                    if let Some(unit) = &decl.unit {
                        println!("  remember {} = {:?} measured in {}", decl.name, value, unit);
                    } else {
                        println!("  remember {} = {:?}", decl.name, value);
                    }
                }
                self.env.define(decl.name.clone(), value);
                Ok(ControlFlow::Continue)
            }
            Statement::Assignment(assign) => {
                let value = self.evaluate(&assign.value)?;
                if !self.env.set(&assign.target, value) {
                    return Err(RuntimeError::UndefinedVariable(assign.target.clone()));
                }
                Ok(ControlFlow::Continue)
            }
            Statement::Return(ret) => {
                let value = self.evaluate(&ret.value)?;
                Ok(ControlFlow::Return(value))
            }
            Statement::Conditional(cond) => {
                let condition = self.evaluate(&cond.condition)?;
                if condition.is_truthy() {
                    for stmt in &cond.then_branch {
                        if let ControlFlow::Return(v) = self.execute_statement(stmt)? {
                            return Ok(ControlFlow::Return(v));
                        }
                    }
                } else if let Some(else_branch) = &cond.else_branch {
                    for stmt in else_branch {
                        if let ControlFlow::Return(v) = self.execute_statement(stmt)? {
                            return Ok(ControlFlow::Return(v));
                        }
                    }
                }
                Ok(ControlFlow::Continue)
            }
            Statement::Loop(loop_stmt) => {
                let count = self.evaluate(&loop_stmt.count)?;
                let n = match count {
                    Value::Int(n) => n,
                    _ => return Err(RuntimeError::TypeError("Loop count must be an integer".into())),
                };

                for _ in 0..n {
                    for stmt in &loop_stmt.body {
                        if let ControlFlow::Return(v) = self.execute_statement(stmt)? {
                            return Ok(ControlFlow::Return(v));
                        }
                    }
                }
                Ok(ControlFlow::Continue)
            }
            Statement::AttemptBlock(attempt) => {
                self.env.push_scope();
                let result: Result<ControlFlow> = (|| {
                    for stmt in &attempt.body {
                        if let ControlFlow::Return(v) = self.execute_statement(stmt)? {
                            return Ok(ControlFlow::Return(v));
                        }
                    }
                    Ok(ControlFlow::Continue)
                })();
                self.env.pop_scope();

                match result {
                    Ok(cf) => Ok(cf),
                    Err(_) => {
                        if self.verbose {
                            println!("  Reassurance: {}", attempt.reassurance);
                        }
                        Ok(ControlFlow::Continue)
                    }
                }
            }
            Statement::ConsentBlock(consent) => {
                self.execute_consent_block(consent)?;
                Ok(ControlFlow::Continue)
            }
            Statement::Expression(expr) => {
                self.evaluate(expr)?;
                Ok(ControlFlow::Continue)
            }
            Statement::WorkerSpawn(spawn) => {
                if self.verbose {
                    println!("  Spawning worker: {}", spawn.worker_name);
                }
                // In a real implementation, this would spawn a thread/task
                // For now, we just execute the worker synchronously
                if let Some(worker) = self.workers.get(&spawn.worker_name).cloned() {
                    self.env.push_scope();
                    for stmt in &worker.body {
                        self.execute_statement(stmt)?;
                    }
                    self.env.pop_scope();
                }
                Ok(ControlFlow::Continue)
            }
            Statement::Complain(complain) => {
                if self.care_mode {
                    eprintln!("Complaint: {}", complain.message);
                }
                Ok(ControlFlow::Continue)
            }
            Statement::EmoteAnnotated(annotated) => {
                if self.verbose {
                    println!("  @{}", annotated.emote.name);
                }
                self.execute_statement(&annotated.statement)
            }
            Statement::Decide(decide) => {
                let scrutinee = self.evaluate(&decide.scrutinee)?;

                for arm in &decide.arms {
                    if self.pattern_matches(&arm.pattern, &scrutinee) {
                        self.env.push_scope();
                        // Bind pattern variables
                        if let Pattern::Identifier(name) = &arm.pattern {
                            self.env.define(name.clone(), scrutinee.clone());
                        }
                        for stmt in &arm.body {
                            if let ControlFlow::Return(v) = self.execute_statement(stmt)? {
                                self.env.pop_scope();
                                return Ok(ControlFlow::Return(v));
                            }
                        }
                        self.env.pop_scope();
                        break;
                    }
                }
                Ok(ControlFlow::Continue)
            }
        }
    }

    fn execute_consent_block(&mut self, consent: &ConsentBlock) -> Result<()> {
        let permission = &consent.permission;

        // Check cache first
        let granted = if let Some(&cached) = self.consent_cache.get(permission) {
            cached
        } else {
            // Ask user for consent
            print!("Permission requested: '{}'. Allow? [y/N]: ", permission);
            io::stdout().flush().unwrap();

            let mut input = String::new();
            io::stdin().read_line(&mut input).unwrap();
            let granted = input.trim().eq_ignore_ascii_case("y");

            self.consent_cache.insert(permission.clone(), granted);
            granted
        };

        if granted {
            self.env.push_scope();
            for stmt in &consent.body {
                self.execute_statement(stmt)?;
            }
            self.env.pop_scope();
        } else if self.verbose {
            println!("  Consent denied for: {}", permission);
        }

        Ok(())
    }

    fn pattern_matches(&self, pattern: &Pattern, value: &Value) -> bool {
        match pattern {
            Pattern::Wildcard => true,
            Pattern::Identifier(_) => true, // Identifier patterns always match and bind
            Pattern::Literal(lit) => {
                let lit_value = self.literal_to_value(lit);
                value == &lit_value
            }
        }
    }

    fn literal_to_value(&self, lit: &Literal) -> Value {
        match lit {
            Literal::Integer(n) => Value::Int(*n),
            Literal::Float(n) => Value::Float(*n),
            Literal::String(s) => Value::String(s.clone()),
            Literal::Bool(b) => Value::Bool(*b),
        }
    }

    fn evaluate(&mut self, expr: &Spanned<Expr>) -> Result<Value> {
        match &expr.node {
            Expr::Literal(lit) => Ok(self.literal_to_value(lit)),
            Expr::Identifier(name) => self
                .env
                .get(name)
                .cloned()
                .ok_or_else(|| RuntimeError::UndefinedVariable(name.clone())),
            Expr::Binary(op, left, right) => {
                let left_val = self.evaluate(left)?;
                let right_val = self.evaluate(right)?;
                self.apply_binary_op(*op, left_val, right_val)
            }
            Expr::Unary(op, operand) => {
                let val = self.evaluate(operand)?;
                self.apply_unary_op(*op, val)
            }
            Expr::Call(name, args) => {
                let arg_values: Vec<Value> = args
                    .iter()
                    .map(|a| self.evaluate(a))
                    .collect::<Result<_>>()?;

                // Check for built-in functions first
                if let Some(result) = self.call_builtin(name, &arg_values)? {
                    return Ok(result);
                }

                self.call_function(name, arg_values)
            }
            Expr::UnitMeasurement(inner, _unit) => {
                // For now, just evaluate the inner expression
                // A full implementation would track units
                self.evaluate(inner)
            }
            Expr::GratitudeLiteral(name) => {
                if self.verbose {
                    println!("  Expressing gratitude to: {}", name);
                }
                Ok(Value::String(format!("Thanks to {}", name)))
            }
            Expr::Array(elements) => {
                let values: Vec<Value> = elements
                    .iter()
                    .map(|e| self.evaluate(e))
                    .collect::<Result<_>>()?;
                Ok(Value::Array(values))
            }
        }
    }

    fn call_builtin(&mut self, name: &str, args: &[Value]) -> Result<Option<Value>> {
        match name {
            "print" => {
                for (i, arg) in args.iter().enumerate() {
                    if i > 0 {
                        print!(" ");
                    }
                    print!("{}", arg);
                }
                println!();
                Ok(Some(Value::Unit))
            }
            "len" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                match &args[0] {
                    Value::String(s) => Ok(Some(Value::Int(s.len() as i64))),
                    Value::Array(a) => Ok(Some(Value::Int(a.len() as i64))),
                    _ => Err(RuntimeError::TypeError("len() requires string or array".into())),
                }
            }
            "toString" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                Ok(Some(Value::String(args[0].to_string())))
            }
            "toInt" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                match &args[0] {
                    Value::String(s) => {
                        let n = s.parse::<i64>().map_err(|_| {
                            RuntimeError::TypeError(format!("Cannot convert '{}' to Int", s))
                        })?;
                        Ok(Some(Value::Int(n)))
                    }
                    Value::Float(f) => Ok(Some(Value::Int(*f as i64))),
                    Value::Int(n) => Ok(Some(Value::Int(*n))),
                    _ => Err(RuntimeError::TypeError("Cannot convert to Int".into())),
                }
            }
            _ => Ok(None), // Not a builtin
        }
    }

    fn call_function(&mut self, name: &str, args: Vec<Value>) -> Result<Value> {
        let func = self
            .functions
            .get(name)
            .cloned()
            .ok_or_else(|| RuntimeError::UndefinedFunction(name.to_string()))?;

        if func.params.len() != args.len() {
            return Err(RuntimeError::ArityMismatch {
                expected: func.params.len(),
                got: args.len(),
            });
        }

        // Print hello message
        if let Some(hello) = &func.hello {
            if self.verbose {
                println!("[{}] {}", name, hello);
            }
        }

        // Create new scope and bind parameters
        self.env.push_scope();
        for (param, arg) in func.params.iter().zip(args) {
            self.env.define(param.name.clone(), arg);
        }

        // Execute function body
        let mut result = Value::Unit;
        for stmt in &func.body {
            match self.execute_statement(stmt)? {
                ControlFlow::Return(v) => {
                    result = v;
                    break;
                }
                ControlFlow::Continue => {}
            }
        }

        self.env.pop_scope();

        // Print goodbye message
        if let Some(goodbye) = &func.goodbye {
            if self.verbose {
                println!("[{}] {}", name, goodbye);
            }
        }

        Ok(result)
    }

    fn apply_binary_op(&self, op: BinaryOp, left: Value, right: Value) -> Result<Value> {
        match op {
            BinaryOp::Add => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a + b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a + b)),
                (Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 + b)),
                (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a + b as f64)),
                (Value::String(a), Value::String(b)) => Ok(Value::String(a + &b)),
                (Value::String(a), b) => Ok(Value::String(a + &b.to_string())),
                (a, Value::String(b)) => Ok(Value::String(a.to_string() + &b)),
                _ => Err(RuntimeError::TypeError("Cannot add these types".into())),
            },
            BinaryOp::Sub => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a - b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a - b)),
                (Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 - b)),
                (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a - b as f64)),
                _ => Err(RuntimeError::TypeError("Cannot subtract these types".into())),
            },
            BinaryOp::Mul => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a * b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a * b)),
                (Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 * b)),
                (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a * b as f64)),
                _ => Err(RuntimeError::TypeError("Cannot multiply these types".into())),
            },
            BinaryOp::Div => match (left, right) {
                (_, Value::Int(0)) => Err(RuntimeError::DivisionByZero),
                (_, Value::Float(f)) if f == 0.0 => Err(RuntimeError::DivisionByZero),
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a / b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a / b)),
                (Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 / b)),
                (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a / b as f64)),
                _ => Err(RuntimeError::TypeError("Cannot divide these types".into())),
            },
            BinaryOp::Mod => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a % b)),
                _ => Err(RuntimeError::TypeError("Modulo requires integers".into())),
            },
            BinaryOp::Eq => Ok(Value::Bool(left == right)),
            BinaryOp::NotEq => Ok(Value::Bool(left != right)),
            BinaryOp::Lt => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a < b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a < b)),
                (Value::String(a), Value::String(b)) => Ok(Value::Bool(a < b)),
                _ => Err(RuntimeError::TypeError("Cannot compare these types".into())),
            },
            BinaryOp::Gt => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a > b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a > b)),
                (Value::String(a), Value::String(b)) => Ok(Value::Bool(a > b)),
                _ => Err(RuntimeError::TypeError("Cannot compare these types".into())),
            },
            BinaryOp::LtEq => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a <= b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a <= b)),
                (Value::String(a), Value::String(b)) => Ok(Value::Bool(a <= b)),
                _ => Err(RuntimeError::TypeError("Cannot compare these types".into())),
            },
            BinaryOp::GtEq => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a >= b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a >= b)),
                (Value::String(a), Value::String(b)) => Ok(Value::Bool(a >= b)),
                _ => Err(RuntimeError::TypeError("Cannot compare these types".into())),
            },
            BinaryOp::And => Ok(Value::Bool(left.is_truthy() && right.is_truthy())),
            BinaryOp::Or => Ok(Value::Bool(left.is_truthy() || right.is_truthy())),
        }
    }

    fn apply_unary_op(&self, op: UnaryOp, val: Value) -> Result<Value> {
        match op {
            UnaryOp::Neg => match val {
                Value::Int(n) => Ok(Value::Int(-n)),
                Value::Float(f) => Ok(Value::Float(-f)),
                _ => Err(RuntimeError::TypeError("Cannot negate this type".into())),
            },
            UnaryOp::Not => Ok(Value::Bool(!val.is_truthy())),
        }
    }
}

impl Default for Interpreter {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::lexer::Lexer;
    use crate::parser::Parser;

    fn run_program(source: &str) -> Result<()> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().expect("Lexer failed");
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().expect("Parser failed");
        let mut interpreter = Interpreter::new();
        interpreter.run(&program)
    }

    #[test]
    fn test_simple_arithmetic() {
        let source = r#"
            to main() {
                remember x = 1 + 2 * 3;
                remember y = (1 + 2) * 3;
            }
        "#;
        assert!(run_program(source).is_ok());
    }

    #[test]
    fn test_function_call() {
        let source = r#"
            to add(a: Int, b: Int) -> Int {
                give back a + b;
            }
            to main() {
                remember result = add(2, 3);
            }
        "#;
        assert!(run_program(source).is_ok());
    }

    #[test]
    fn test_conditional() {
        let source = r#"
            to main() {
                remember x = 10;
                when x > 5 {
                    remember y = "big";
                } otherwise {
                    remember y = "small";
                }
            }
        "#;
        assert!(run_program(source).is_ok());
    }

    #[test]
    fn test_loop() {
        let source = r#"
            to main() {
                remember count = 0;
                repeat 5 times {
                    count = count + 1;
                }
            }
        "#;
        assert!(run_program(source).is_ok());
    }
}
