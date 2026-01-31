// SPDX-License-Identifier: PMPL-1.0-or-later
//! WokeLang Interpreter
//!
//! Tree-walking interpreter for executing WokeLang AST directly.

pub mod value;

pub use value::{ChannelHandle, CapturedEnv, Closure, Value};

use crate::ast::*;
use std::collections::HashMap;
use std::rc::Rc;
use std::cell::RefCell;

/// Interpreter runtime error
#[derive(Debug)]
pub struct RuntimeError {
    pub message: String,
}

impl std::fmt::Display for RuntimeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Runtime error: {}", self.message)
    }
}

impl std::error::Error for RuntimeError {}

/// Environment for variable bindings
#[derive(Debug, Clone)]
pub struct Environment {
    bindings: HashMap<String, Value>,
    parent: Option<Rc<RefCell<Environment>>>,
}

impl Environment {
    pub fn new() -> Self {
        Self {
            bindings: HashMap::new(),
            parent: None,
        }
    }

    pub fn with_parent(parent: Rc<RefCell<Environment>>) -> Self {
        Self {
            bindings: HashMap::new(),
            parent: Some(parent),
        }
    }

    pub fn define(&mut self, name: String, value: Value) {
        self.bindings.insert(name, value);
    }

    pub fn get(&self, name: &str) -> Option<Value> {
        if let Some(value) = self.bindings.get(name) {
            Some(value.clone())
        } else if let Some(parent) = &self.parent {
            parent.borrow().get(name)
        } else {
            None
        }
    }

    pub fn set(&mut self, name: &str, value: Value) -> Result<(), RuntimeError> {
        if self.bindings.contains_key(name) {
            self.bindings.insert(name.to_string(), value);
            Ok(())
        } else if let Some(parent) = &self.parent {
            parent.borrow_mut().set(name, value)
        } else {
            Err(RuntimeError {
                message: format!("Undefined variable: {}", name),
            })
        }
    }
}

impl Default for Environment {
    fn default() -> Self {
        Self::new()
    }
}

/// Control flow signal for handling returns, breaks, etc.
#[derive(Debug, Clone)]
enum ControlFlow {
    None,
    Return(Value),
}

/// The interpreter
pub struct Interpreter {
    environment: Rc<RefCell<Environment>>,
    functions: HashMap<String, FunctionDef>,
    control_flow: ControlFlow,
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            environment: Rc::new(RefCell::new(Environment::new())),
            functions: HashMap::new(),
            control_flow: ControlFlow::None,
        }
    }

    /// Run a program
    pub fn run(&mut self, program: &Program) -> Result<Value, RuntimeError> {
        // Collect all functions
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                self.functions.insert(func.name.clone(), func.clone());
            }
        }

        // Execute main function if it exists
        if let Some(main_func) = self.functions.get("main").cloned() {
            self.execute_function(&main_func, vec![])
        } else {
            Ok(Value::Unit)
        }
    }

    /// Execute a function
    fn execute_function(
        &mut self,
        func: &FunctionDef,
        args: Vec<Value>,
    ) -> Result<Value, RuntimeError> {
        // Create new scope
        let new_env = Rc::new(RefCell::new(Environment::with_parent(
            Rc::clone(&self.environment),
        )));
        let old_env = std::mem::replace(&mut self.environment, new_env);

        // Bind parameters
        if func.params.len() != args.len() {
            return Err(RuntimeError {
                message: format!(
                    "Function {} expects {} arguments, got {}",
                    func.name,
                    func.params.len(),
                    args.len()
                ),
            });
        }

        for (param, arg) in func.params.iter().zip(args.iter()) {
            self.environment.borrow_mut().define(param.name.clone(), arg.clone());
        }

        // Execute function body
        let mut result = Value::Unit;
        for stmt in &func.body {
            result = self.execute_statement(stmt)?;

            // Check for return
            if let ControlFlow::Return(val) = &self.control_flow {
                result = val.clone();
                self.control_flow = ControlFlow::None;
                break;
            }
        }

        // Restore environment
        self.environment = old_env;

        Ok(result)
    }

    /// Execute a statement
    fn execute_statement(&mut self, stmt: &Statement) -> Result<Value, RuntimeError> {
        match stmt {
            Statement::VarDecl(var_decl) => {
                let value = self.eval_expr(&var_decl.value)?;
                self.environment.borrow_mut().define(var_decl.name.clone(), value);
                Ok(Value::Unit)
            }

            Statement::Assignment(assignment) => {
                let value = self.eval_expr(&assignment.value)?;
                self.environment.borrow_mut().set(&assignment.target, value)?;
                Ok(Value::Unit)
            }

            Statement::Return(return_stmt) => {
                let value = self.eval_expr(&return_stmt.value)?;
                self.control_flow = ControlFlow::Return(value.clone());
                Ok(value)
            }

            Statement::Conditional(conditional) => {
                let condition = self.eval_expr(&conditional.condition)?;

                if condition.is_truthy() {
                    let mut result = Value::Unit;
                    for stmt in &conditional.then_branch {
                        result = self.execute_statement(stmt)?;
                        if !matches!(self.control_flow, ControlFlow::None) {
                            return Ok(result);
                        }
                    }
                    Ok(result)
                } else if let Some(else_branch) = &conditional.else_branch {
                    let mut result = Value::Unit;
                    for stmt in else_branch {
                        result = self.execute_statement(stmt)?;
                        if !matches!(self.control_flow, ControlFlow::None) {
                            return Ok(result);
                        }
                    }
                    Ok(result)
                } else {
                    Ok(Value::Unit)
                }
            }

            Statement::Loop(loop_stmt) => {
                let count = self.eval_expr(&loop_stmt.count)?;
                let iterations = match count {
                    Value::Int(n) if n >= 0 => n as usize,
                    Value::Int(n) => {
                        return Err(RuntimeError {
                            message: format!("Loop count must be non-negative, got {}", n),
                        })
                    }
                    _ => {
                        return Err(RuntimeError {
                            message: "Loop count must be an integer".to_string(),
                        })
                    }
                };

                let mut result = Value::Unit;
                for _ in 0..iterations {
                    for stmt in &loop_stmt.body {
                        result = self.execute_statement(stmt)?;
                        if !matches!(self.control_flow, ControlFlow::None) {
                            return Ok(result);
                        }
                    }
                }
                Ok(result)
            }

            Statement::AttemptBlock(attempt) => {
                // Execute attempt block, catching errors
                let mut result = Value::Unit;
                let mut had_error = false;

                for stmt in &attempt.body {
                    match self.execute_statement(stmt) {
                        Ok(val) => result = val,
                        Err(_err) => {
                            had_error = true;
                            // Use reassurance message
                            result = Value::Oops(attempt.reassurance.clone());
                            break;
                        }
                    }
                    if !matches!(self.control_flow, ControlFlow::None) {
                        return Ok(result);
                    }
                }

                if !had_error {
                    result = Value::Okay(Box::new(result));
                }
                Ok(result)
            }

            Statement::ConsentBlock(consent) => {
                // For now, execute unconditionally
                // TODO: Add actual consent checking with capabilities
                let mut result = Value::Unit;
                for stmt in &consent.body {
                    result = self.execute_statement(stmt)?;
                    if !matches!(self.control_flow, ControlFlow::None) {
                        return Ok(result);
                    }
                }
                Ok(result)
            }

            Statement::Expression(expr) => {
                self.eval_expr(expr)
            }

            Statement::WorkerSpawn(_worker) => {
                // Stub: Worker support not yet implemented
                Ok(Value::Unit)
            }

            Statement::Complain(complain) => {
                Err(RuntimeError { message: complain.message.clone() })
            }

            Statement::EmoteAnnotated(emote) => {
                // Execute the underlying statement, ignoring the emote annotation
                self.execute_statement(&emote.statement)
            }

            Statement::Decide(decide) => {
                let value = self.eval_expr(&decide.scrutinee)?;

                // Try each pattern
                for arm in &decide.arms {
                    if self.pattern_matches(&arm.pattern, &value)? {
                        let mut result = Value::Unit;
                        for stmt in &arm.body {
                            result = self.execute_statement(stmt)?;
                            if !matches!(self.control_flow, ControlFlow::None) {
                                return Ok(result);
                            }
                        }
                        return Ok(result);
                    }
                }

                Err(RuntimeError {
                    message: "No pattern matched in decide statement".to_string(),
                })
            }
        }
    }

    /// Evaluate an expression
    fn eval_expr(&mut self, expr: &Spanned<Expr>) -> Result<Value, RuntimeError> {
        match &expr.node {
            Expr::Literal(lit) => Ok(self.eval_literal(lit)),

            Expr::Identifier(name) => {
                self.environment.borrow().get(name).ok_or_else(|| RuntimeError {
                    message: format!("Undefined variable: {}", name),
                })
            }

            Expr::Binary(op, left, right) => {
                let left_val = self.eval_expr(left)?;
                let right_val = self.eval_expr(right)?;
                self.eval_binary_op(*op, left_val, right_val)
            }

            Expr::Unary(op, operand) => {
                let val = self.eval_expr(operand)?;
                self.eval_unary_op(*op, val)
            }

            Expr::Call(func_name, args) => {
                let arg_vals: Result<Vec<_>, _> = args.iter().map(|arg| self.eval_expr(arg)).collect();
                let arg_vals = arg_vals?;

                if let Some(func) = self.functions.get(func_name).cloned() {
                    self.execute_function(&func, arg_vals)
                } else {
                    Err(RuntimeError {
                        message: format!("Undefined function: {}", func_name),
                    })
                }
            }

            Expr::CallExpr(callee, args) => {
                let func_val = self.eval_expr(callee)?;
                let arg_vals: Result<Vec<_>, _> = args.iter().map(|arg| self.eval_expr(arg)).collect();
                let arg_vals = arg_vals?;

                match func_val {
                    Value::Function(closure) => {
                        self.execute_closure(&closure, arg_vals)
                    }
                    _ => Err(RuntimeError {
                        message: format!("Cannot call non-function value: {:?}", func_val),
                    }),
                }
            }

            Expr::Array(elements) => {
                let vals: Result<Vec<_>, _> = elements.iter().map(|e| self.eval_expr(e)).collect();
                Ok(Value::Array(vals?))
            }

            Expr::Index(array, index) => {
                let array_val = self.eval_expr(array)?;
                let index_val = self.eval_expr(index)?;

                match (array_val, index_val) {
                    (Value::Array(arr), Value::Int(idx)) => {
                        if idx < 0 || idx as usize >= arr.len() {
                            Err(RuntimeError {
                                message: format!("Index {} out of bounds (length {})", idx, arr.len()),
                            })
                        } else {
                            Ok(arr[idx as usize].clone())
                        }
                    }
                    (Value::String(s), Value::Int(idx)) => {
                        let chars: Vec<char> = s.chars().collect();
                        if idx < 0 || idx as usize >= chars.len() {
                            Err(RuntimeError {
                                message: format!("Index {} out of bounds (length {})", idx, chars.len()),
                            })
                        } else {
                            Ok(Value::String(chars[idx as usize].to_string()))
                        }
                    }
                    (arr, idx) => Err(RuntimeError {
                        message: format!("Cannot index {:?} with {:?}", arr, idx),
                    }),
                }
            }

            Expr::Okay(val) => {
                let inner = self.eval_expr(val)?;
                Ok(Value::Okay(Box::new(inner)))
            }

            Expr::Oops(val) => {
                let inner = self.eval_expr(val)?;
                match inner {
                    Value::String(s) => Ok(Value::Oops(s)),
                    _ => Err(RuntimeError {
                        message: "Oops requires a string message".to_string(),
                    }),
                }
            }

            Expr::Unwrap(val) => {
                let inner = self.eval_expr(val)?;
                match inner {
                    Value::Okay(v) => Ok(*v),
                    Value::Oops(msg) => Err(RuntimeError { message: msg }),
                    _ => Err(RuntimeError {
                        message: "Cannot unwrap non-Result value".to_string(),
                    }),
                }
            }

            Expr::Lambda(lambda) => {
                // Capture current environment
                let bindings = self.environment.borrow().bindings.clone();
                let env = Rc::new(RefCell::new(CapturedEnv::from_map(bindings)));

                Ok(Value::Function(Closure {
                    params: lambda.params.clone(),
                    body: lambda.body.clone(),
                    env,
                }))
            }

            Expr::UnitMeasurement(value, unit) => {
                // For now, just evaluate the value and ignore the unit
                // TODO: Implement proper unit tracking
                let val = self.eval_expr(value)?;
                match val {
                    Value::Int(_) | Value::Float(_) => Ok(val),
                    _ => Err(RuntimeError {
                        message: format!("Cannot apply unit '{}' to non-numeric value", unit),
                    }),
                }
            }

            Expr::GratitudeLiteral(name) => {
                // Return a string for now
                // TODO: Implement proper gratitude tracking
                Ok(Value::String(format!("Thanks to {}", name)))
            }
        }
    }

    /// Execute a closure
    fn execute_closure(&mut self, closure: &Closure, args: Vec<Value>) -> Result<Value, RuntimeError> {
        if closure.params.len() != args.len() {
            return Err(RuntimeError {
                message: format!(
                    "Closure expects {} arguments, got {}",
                    closure.params.len(),
                    args.len()
                ),
            });
        }

        // Create new environment with captured environment as parent
        let captured_bindings = closure.env.borrow().bindings.clone();
        let new_env = Rc::new(RefCell::new(Environment::new()));

        // Add captured bindings
        for (name, value) in captured_bindings {
            new_env.borrow_mut().define(name, value);
        }

        // Bind parameters
        for (param, arg) in closure.params.iter().zip(args.iter()) {
            new_env.borrow_mut().define(param.name.clone(), arg.clone());
        }

        let old_env = std::mem::replace(&mut self.environment, new_env);

        // Execute closure body
        let result = match &closure.body {
            LambdaBody::Expr(expr) => self.eval_expr(expr),
            LambdaBody::Block(stmts) => {
                let mut res = Value::Unit;
                for stmt in stmts {
                    res = self.execute_statement(stmt)?;
                    if !matches!(self.control_flow, ControlFlow::None) {
                        break;
                    }
                }
                Ok(res)
            }
        };

        // Restore environment
        self.environment = old_env;

        result
    }

    /// Evaluate a literal
    fn eval_literal(&self, lit: &Literal) -> Value {
        match lit {
            Literal::Integer(n) => Value::Int(*n),
            Literal::Float(f) => Value::Float(*f),
            Literal::String(s) => Value::String(s.clone()),
            Literal::Bool(b) => Value::Bool(*b),
            Literal::Unit => Value::Unit,
        }
    }

    /// Evaluate binary operation
    fn eval_binary_op(&self, op: BinaryOp, left: Value, right: Value) -> Result<Value, RuntimeError> {
        match (op, left, right) {
            // Arithmetic
            (BinaryOp::Add, Value::Int(a), Value::Int(b)) => Ok(Value::Int(a + b)),
            (BinaryOp::Add, Value::Float(a), Value::Float(b)) => Ok(Value::Float(a + b)),
            (BinaryOp::Add, Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 + b)),
            (BinaryOp::Add, Value::Float(a), Value::Int(b)) => Ok(Value::Float(a + b as f64)),
            (BinaryOp::Add, Value::String(a), Value::String(b)) => Ok(Value::String(a + &b)),

            (BinaryOp::Sub, Value::Int(a), Value::Int(b)) => Ok(Value::Int(a - b)),
            (BinaryOp::Sub, Value::Float(a), Value::Float(b)) => Ok(Value::Float(a - b)),
            (BinaryOp::Sub, Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 - b)),
            (BinaryOp::Sub, Value::Float(a), Value::Int(b)) => Ok(Value::Float(a - b as f64)),

            (BinaryOp::Mul, Value::Int(a), Value::Int(b)) => Ok(Value::Int(a * b)),
            (BinaryOp::Mul, Value::Float(a), Value::Float(b)) => Ok(Value::Float(a * b)),
            (BinaryOp::Mul, Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 * b)),
            (BinaryOp::Mul, Value::Float(a), Value::Int(b)) => Ok(Value::Float(a * b as f64)),

            (BinaryOp::Div, Value::Int(a), Value::Int(b)) => {
                if b == 0 {
                    Err(RuntimeError { message: "Division by zero".to_string() })
                } else {
                    Ok(Value::Int(a / b))
                }
            }
            (BinaryOp::Div, Value::Float(a), Value::Float(b)) => Ok(Value::Float(a / b)),
            (BinaryOp::Div, Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 / b)),
            (BinaryOp::Div, Value::Float(a), Value::Int(b)) => Ok(Value::Float(a / b as f64)),

            (BinaryOp::Mod, Value::Int(a), Value::Int(b)) => {
                if b == 0 {
                    Err(RuntimeError { message: "Modulo by zero".to_string() })
                } else {
                    Ok(Value::Int(a % b))
                }
            }

            // Comparison
            (BinaryOp::Eq, a, b) => Ok(Value::Bool(a == b)),
            (BinaryOp::NotEq, a, b) => Ok(Value::Bool(a != b)),

            (BinaryOp::Lt, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a < b)),
            (BinaryOp::Lt, Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a < b)),
            (BinaryOp::Lt, Value::Int(a), Value::Float(b)) => Ok(Value::Bool((a as f64) < b)),
            (BinaryOp::Lt, Value::Float(a), Value::Int(b)) => Ok(Value::Bool(a < (b as f64))),

            (BinaryOp::LtEq, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a <= b)),
            (BinaryOp::LtEq, Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a <= b)),
            (BinaryOp::LtEq, Value::Int(a), Value::Float(b)) => Ok(Value::Bool((a as f64) <= b)),
            (BinaryOp::LtEq, Value::Float(a), Value::Int(b)) => Ok(Value::Bool(a <= (b as f64))),

            (BinaryOp::Gt, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a > b)),
            (BinaryOp::Gt, Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a > b)),
            (BinaryOp::Gt, Value::Int(a), Value::Float(b)) => Ok(Value::Bool((a as f64) > b)),
            (BinaryOp::Gt, Value::Float(a), Value::Int(b)) => Ok(Value::Bool(a > (b as f64))),

            (BinaryOp::GtEq, Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a >= b)),
            (BinaryOp::GtEq, Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a >= b)),
            (BinaryOp::GtEq, Value::Int(a), Value::Float(b)) => Ok(Value::Bool((a as f64) >= b)),
            (BinaryOp::GtEq, Value::Float(a), Value::Int(b)) => Ok(Value::Bool(a >= (b as f64))),

            // Logical
            (BinaryOp::And, a, b) => Ok(Value::Bool(a.is_truthy() && b.is_truthy())),
            (BinaryOp::Or, a, b) => Ok(Value::Bool(a.is_truthy() || b.is_truthy())),

            (op, left, right) => Err(RuntimeError {
                message: format!("Cannot apply {:?} to {:?} and {:?}", op, left, right),
            }),
        }
    }

    /// Evaluate unary operation
    fn eval_unary_op(&self, op: UnaryOp, operand: Value) -> Result<Value, RuntimeError> {
        match (op, operand) {
            (UnaryOp::Neg, Value::Int(n)) => Ok(Value::Int(-n)),
            (UnaryOp::Neg, Value::Float(f)) => Ok(Value::Float(-f)),
            (UnaryOp::Not, val) => Ok(Value::Bool(!val.is_truthy())),
            (op, val) => Err(RuntimeError {
                message: format!("Cannot apply {:?} to {:?}", op, val),
            }),
        }
    }

    /// Check if a pattern matches a value
    fn pattern_matches(&mut self, pattern: &Pattern, value: &Value) -> Result<bool, RuntimeError> {
        match pattern {
            Pattern::Literal(lit) => {
                let lit_val = self.eval_literal(lit);
                Ok(lit_val == *value)
            }
            Pattern::Identifier(_name) => {
                // Identifiers always match and bind
                // TODO: Bind the value to the identifier
                Ok(true)
            }
            Pattern::Wildcard => Ok(true),
            Pattern::Constructor(name, inner_pattern) => {
                match (name.as_str(), value) {
                    ("Okay", Value::Okay(inner)) => {
                        if let Some(pat) = inner_pattern {
                            self.pattern_matches(pat, inner)
                        } else {
                            Ok(true)
                        }
                    }
                    ("Oops", Value::Oops(_)) => Ok(true),
                    _ => Ok(false),
                }
            }
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

    #[test]
    fn test_interpreter_new() {
        let interp = Interpreter::new();
        assert_eq!(interp.functions.len(), 0);
    }

    #[test]
    fn test_environment() {
        let mut env = Environment::new();
        env.define("x".to_string(), Value::Int(42));
        assert_eq!(env.get("x"), Some(Value::Int(42)));
    }

    #[test]
    fn test_eval_literal() {
        let mut interp = Interpreter::new();

        let int_lit = Spanned { node: Expr::Literal(Literal::Integer(42)), span: Span::default() };
        assert_eq!(interp.eval_expr(&int_lit).unwrap(), Value::Int(42));

        let bool_lit = Spanned { node: Expr::Literal(Literal::Bool(true)), span: Span::default() };
        assert_eq!(interp.eval_expr(&bool_lit).unwrap(), Value::Bool(true));

        let str_lit = Spanned { node: Expr::Literal(Literal::String("hello".to_string())), span: Span::default() };
        assert_eq!(interp.eval_expr(&str_lit).unwrap(), Value::String("hello".to_string()));
    }

    #[test]
    fn test_eval_binary_arithmetic() {
        let mut interp = Interpreter::new();

        let left = Box::new(Spanned { node: Expr::Literal(Literal::Integer(10)), span: Span::default() });
        let right = Box::new(Spanned { node: Expr::Literal(Literal::Integer(5)), span: Span::default() });

        let add = Spanned { node: Expr::Binary(BinaryOp::Add, left.clone(), right.clone()), span: Span::default() };
        assert_eq!(interp.eval_expr(&add).unwrap(), Value::Int(15));

        let sub = Spanned { node: Expr::Binary(BinaryOp::Sub, left.clone(), right.clone()), span: Span::default() };
        assert_eq!(interp.eval_expr(&sub).unwrap(), Value::Int(5));

        let mul = Spanned { node: Expr::Binary(BinaryOp::Mul, left.clone(), right.clone()), span: Span::default() };
        assert_eq!(interp.eval_expr(&mul).unwrap(), Value::Int(50));

        let div = Spanned { node: Expr::Binary(BinaryOp::Div, left, right), span: Span::default() };
        assert_eq!(interp.eval_expr(&div).unwrap(), Value::Int(2));
    }

    #[test]
    fn test_eval_binary_comparison() {
        let mut interp = Interpreter::new();

        let left = Box::new(Spanned { node: Expr::Literal(Literal::Integer(10)), span: Span::default() });
        let right = Box::new(Spanned { node: Expr::Literal(Literal::Integer(5)), span: Span::default() });

        let lt = Spanned { node: Expr::Binary(BinaryOp::Lt, left.clone(), right.clone()), span: Span::default() };
        assert_eq!(interp.eval_expr(&lt).unwrap(), Value::Bool(false));

        let gt = Spanned { node: Expr::Binary(BinaryOp::Gt, left.clone(), right.clone()), span: Span::default() };
        assert_eq!(interp.eval_expr(&gt).unwrap(), Value::Bool(true));

        let eq = Spanned { node: Expr::Binary(BinaryOp::Eq, left, right), span: Span::default() };
        assert_eq!(interp.eval_expr(&eq).unwrap(), Value::Bool(false));
    }

    #[test]
    fn test_eval_unary() {
        let mut interp = Interpreter::new();

        let val = Box::new(Spanned { node: Expr::Literal(Literal::Integer(42)), span: Span::default() });
        let neg = Spanned { node: Expr::Unary(UnaryOp::Neg, val), span: Span::default() };
        assert_eq!(interp.eval_expr(&neg).unwrap(), Value::Int(-42));

        let bool_val = Box::new(Spanned { node: Expr::Literal(Literal::Bool(true)), span: Span::default() });
        let not = Spanned { node: Expr::Unary(UnaryOp::Not, bool_val), span: Span::default() };
        assert_eq!(interp.eval_expr(&not).unwrap(), Value::Bool(false));
    }

    #[test]
    fn test_var_decl_and_access() {
        let mut interp = Interpreter::new();

        // remember x = 42;
        let var_decl = Statement::VarDecl(VarDecl {
            name: "x".to_string(),
            value: Spanned { node: Expr::Literal(Literal::Integer(42)), span: Span::default() },
            unit: None,
            span: Span::default(),
        });

        interp.execute_statement(&var_decl).unwrap();

        // Access x
        let ident = Spanned { node: Expr::Identifier("x".to_string()), span: Span::default() };
        assert_eq!(interp.eval_expr(&ident).unwrap(), Value::Int(42));
    }

    #[test]
    fn test_assignment() {
        let mut interp = Interpreter::new();

        // remember x = 10;
        interp.execute_statement(&Statement::VarDecl(VarDecl {
            name: "x".to_string(),
            value: Spanned { node: Expr::Literal(Literal::Integer(10)), span: Span::default() },
            unit: None,
            span: Span::default(),
        })).unwrap();

        // x = 20;
        interp.execute_statement(&Statement::Assignment(Assignment {
            target: "x".to_string(),
            value: Spanned { node: Expr::Literal(Literal::Integer(20)), span: Span::default() },
            span: Span::default(),
        })).unwrap();

        let ident = Spanned { node: Expr::Identifier("x".to_string()), span: Span::default() };
        assert_eq!(interp.eval_expr(&ident).unwrap(), Value::Int(20));
    }

    #[test]
    fn test_conditional() {
        let mut interp = Interpreter::new();

        // when true { remember x = 1; }
        let conditional = Statement::Conditional(Conditional {
            condition: Spanned { node: Expr::Literal(Literal::Bool(true)), span: Span::default() },
            then_branch: vec![Statement::VarDecl(VarDecl {
                name: "x".to_string(),
                value: Spanned { node: Expr::Literal(Literal::Integer(1)), span: Span::default() },
                unit: None,
                span: Span::default(),
            })],
            else_branch: None,
            span: Span::default(),
        });

        interp.execute_statement(&conditional).unwrap();

        let ident = Spanned { node: Expr::Identifier("x".to_string()), span: Span::default() };
        assert_eq!(interp.eval_expr(&ident).unwrap(), Value::Int(1));
    }

    #[test]
    fn test_loop() {
        let mut interp = Interpreter::new();

        // remember count = 0;
        interp.execute_statement(&Statement::VarDecl(VarDecl {
            name: "count".to_string(),
            value: Spanned { node: Expr::Literal(Literal::Integer(0)), span: Span::default() },
            unit: None,
            span: Span::default(),
        })).unwrap();

        // repeat 5 times { count = count + 1; }
        let loop_stmt = Statement::Loop(Loop {
            count: Spanned { node: Expr::Literal(Literal::Integer(5)), span: Span::default() },
            body: vec![Statement::Assignment(Assignment {
                target: "count".to_string(),
                value: Spanned {
                    node: Expr::Binary(
                        BinaryOp::Add,
                        Box::new(Spanned { node: Expr::Identifier("count".to_string()), span: Span::default() }),
                        Box::new(Spanned { node: Expr::Literal(Literal::Integer(1)), span: Span::default() }),
                    ),
                    span: Span::default(),
                },
                span: Span::default(),
            })],
            span: Span::default(),
        });

        interp.execute_statement(&loop_stmt).unwrap();

        let ident = Spanned { node: Expr::Identifier("count".to_string()), span: Span::default() };
        assert_eq!(interp.eval_expr(&ident).unwrap(), Value::Int(5));
    }

    #[test]
    fn test_array_literal_and_index() {
        let mut interp = Interpreter::new();

        // [1, 2, 3]
        let array = Spanned {
            node: Expr::Array(vec![
                Spanned { node: Expr::Literal(Literal::Integer(1)), span: Span::default() },
                Spanned { node: Expr::Literal(Literal::Integer(2)), span: Span::default() },
                Spanned { node: Expr::Literal(Literal::Integer(3)), span: Span::default() },
            ]),
            span: Span::default(),
        };

        let arr_val = interp.eval_expr(&array).unwrap();
        assert!(matches!(arr_val, Value::Array(_)));

        // arr[1]
        let index = Spanned {
            node: Expr::Index(
                Box::new(array),
                Box::new(Spanned { node: Expr::Literal(Literal::Integer(1)), span: Span::default() }),
            ),
            span: Span::default(),
        };

        assert_eq!(interp.eval_expr(&index).unwrap(), Value::Int(2));
    }

    #[test]
    fn test_result_types() {
        let mut interp = Interpreter::new();

        // Okay(42)
        let okay = Spanned {
            node: Expr::Okay(Box::new(Spanned {
                node: Expr::Literal(Literal::Integer(42)),
                span: Span::default(),
            })),
            span: Span::default(),
        };

        match interp.eval_expr(&okay).unwrap() {
            Value::Okay(v) => assert_eq!(*v, Value::Int(42)),
            _ => panic!("Expected Okay"),
        }

        // Oops("error")
        let oops = Spanned {
            node: Expr::Oops(Box::new(Spanned {
                node: Expr::Literal(Literal::String("error".to_string())),
                span: Span::default(),
            })),
            span: Span::default(),
        };

        match interp.eval_expr(&oops).unwrap() {
            Value::Oops(msg) => assert_eq!(msg, "error"),
            _ => panic!("Expected Oops"),
        }
    }

    #[test]
    fn test_string_concatenation() {
        let mut interp = Interpreter::new();

        let left = Box::new(Spanned {
            node: Expr::Literal(Literal::String("hello".to_string())),
            span: Span::default(),
        });
        let right = Box::new(Spanned {
            node: Expr::Literal(Literal::String(" world".to_string())),
            span: Span::default(),
        });

        let concat = Spanned {
            node: Expr::Binary(BinaryOp::Add, left, right),
            span: Span::default(),
        };

        assert_eq!(interp.eval_expr(&concat).unwrap(), Value::String("hello world".to_string()));
    }
}
