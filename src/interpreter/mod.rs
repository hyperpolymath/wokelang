mod value;

pub use value::Value;

use crate::ast::*;
use crate::lexer::Lexer;
use crate::parser::Parser;
use std::collections::HashMap;
use std::collections::HashSet;
use std::io::{self, Write};
use std::path::PathBuf;
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

    #[error("Oops: {0}")]
    OopsError(String),

    #[error("Unwrap failed on Oops: {0}")]
    UnwrapError(String),

    #[error("Module not found: {0}")]
    ModuleNotFound(String),

    #[error("Module error: {0}")]
    ModuleError(String),
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

/// Represents a loaded module
#[derive(Clone)]
pub struct Module {
    pub name: String,
    pub path: PathBuf,
    pub exports: HashSet<String>,
    pub functions: HashMap<String, FunctionDef>,
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
    /// Loaded modules by qualified path
    modules: HashMap<String, Module>,
    /// Module search paths
    module_paths: Vec<PathBuf>,
    /// Current module exports
    exports: HashSet<String>,
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
            modules: HashMap::new(),
            module_paths: vec![PathBuf::from(".")],
            exports: HashSet::new(),
        }
    }

    /// Add a module search path
    pub fn add_module_path(&mut self, path: PathBuf) {
        self.module_paths.push(path);
    }

    /// Load a module from a qualified path (e.g., "std.io" -> "std/io.woke")
    fn load_module(&mut self, path: &QualifiedName) -> Result<()> {
        let module_path_str = path.parts.join(".");

        // Check if already loaded
        if self.modules.contains_key(&module_path_str) {
            return Ok(());
        }

        // Convert qualified name to file path
        let relative_path = path.parts.join("/") + ".woke";

        // Search for module in module paths
        let mut found_path: Option<PathBuf> = None;
        for search_path in &self.module_paths {
            let full_path = search_path.join(&relative_path);
            if full_path.exists() {
                found_path = Some(full_path);
                break;
            }
        }

        let file_path = found_path.ok_or_else(|| {
            RuntimeError::ModuleNotFound(format!("{} (searched: {})", module_path_str, relative_path))
        })?;

        // Read and parse the module
        let source = std::fs::read_to_string(&file_path)
            .map_err(|e| RuntimeError::ModuleError(format!("Failed to read module: {}", e)))?;

        let lexer = Lexer::new(&source);
        let tokens = lexer.tokenize()
            .map_err(|e| RuntimeError::ModuleError(format!("Lexer error in module: {:?}", e)))?;

        let mut parser = Parser::new(tokens, &source);
        let program = parser.parse()
            .map_err(|e| RuntimeError::ModuleError(format!("Parser error in module: {:?}", e)))?;

        // Create a new module
        let mut module = Module {
            name: module_path_str.clone(),
            path: file_path,
            exports: HashSet::new(),
            functions: HashMap::new(),
        };

        // Process module items
        for item in &program.items {
            match item {
                TopLevelItem::Function(f) => {
                    module.functions.insert(f.name.clone(), f.clone());
                }
                TopLevelItem::ModuleExport(e) => {
                    module.exports.insert(e.name.clone());
                }
                _ => {}
            }
        }

        // Store the module
        self.modules.insert(module_path_str, module);

        Ok(())
    }

    /// Import items from a module
    fn import_module(&mut self, import: &ModuleImport) -> Result<()> {
        self.load_module(&import.path)?;

        let module_path_str = import.path.parts.join(".");
        let module = self.modules.get(&module_path_str)
            .ok_or_else(|| RuntimeError::ModuleNotFound(module_path_str.clone()))?
            .clone();

        // Import exported functions with optional rename
        let prefix = import.rename.as_ref().unwrap_or(&module_path_str);

        for (name, func) in &module.functions {
            if module.exports.contains(name) {
                // Import with qualified name or alias
                let imported_name = if import.rename.is_some() {
                    format!("{}_{}", prefix, name)
                } else if import.path.parts.len() == 1 {
                    name.clone()
                } else {
                    // Use last part of path as prefix
                    let last = import.path.parts.last().unwrap();
                    format!("{}_{}", last, name)
                };
                self.functions.insert(imported_name, func.clone());
            }
        }

        Ok(())
    }

    pub fn run(&mut self, program: &Program) -> Result<()> {
        // First pass: process module imports (must be done first)
        for item in &program.items {
            if let TopLevelItem::ModuleImport(import) = item {
                self.import_module(import)?;
            }
        }

        // Second pass: collect all function and worker definitions
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
                TopLevelItem::ModuleExport(e) => {
                    self.exports.insert(e.name.clone());
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

        // Third pass: execute top-level items
        for item in &program.items {
            match item {
                TopLevelItem::ConsentBlock(c) => {
                    self.execute_consent_block(c)?;
                }
                TopLevelItem::Function(_)
                | TopLevelItem::WorkerDef(_)
                | TopLevelItem::GratitudeDecl(_)
                | TopLevelItem::Pragma(_)
                | TopLevelItem::ModuleImport(_)
                | TopLevelItem::ModuleExport(_) => {
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
                        // Bind pattern variables using bind_pattern
                        let guard_passed = self.bind_pattern(&arm.pattern, &scrutinee)?;
                        if !guard_passed {
                            self.env.pop_scope();
                            continue; // Guard failed, try next arm
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
            Pattern::OkayPattern(_) => matches!(value, Value::Okay(_)),
            Pattern::OopsPattern(_) => matches!(value, Value::Oops(_)),
            Pattern::Constructor(name, inner_patterns) => {
                // Handle known constructors
                match (name.as_str(), value) {
                    ("Okay", Value::Okay(inner)) => {
                        if inner_patterns.is_empty() {
                            true
                        } else if inner_patterns.len() == 1 {
                            self.pattern_matches(&inner_patterns[0], inner)
                        } else {
                            false
                        }
                    }
                    ("Oops", Value::Oops(_)) => inner_patterns.is_empty(),
                    _ => false,
                }
            }
            Pattern::Guard(inner, _condition) => {
                // First check if inner pattern matches
                // Guard condition will be evaluated during binding
                self.pattern_matches(inner, value)
            }
        }
    }

    fn bind_pattern(&mut self, pattern: &Pattern, value: &Value) -> Result<bool> {
        match pattern {
            Pattern::Wildcard => Ok(true),
            Pattern::Identifier(name) => {
                self.env.define(name.clone(), value.clone());
                Ok(true)
            }
            Pattern::Literal(_) => Ok(true), // Already matched
            Pattern::OkayPattern(Some(name)) => {
                if let Value::Okay(inner) = value {
                    self.env.define(name.clone(), (**inner).clone());
                }
                Ok(true)
            }
            Pattern::OkayPattern(None) => Ok(true),
            Pattern::OopsPattern(Some(name)) => {
                if let Value::Oops(msg) = value {
                    self.env.define(name.clone(), Value::String(msg.clone()));
                }
                Ok(true)
            }
            Pattern::OopsPattern(None) => Ok(true),
            Pattern::Constructor(name, inner_patterns) => {
                match (name.as_str(), value) {
                    ("Okay", Value::Okay(inner)) if inner_patterns.len() == 1 => {
                        self.bind_pattern(&inner_patterns[0], inner)
                    }
                    _ => Ok(true),
                }
            }
            Pattern::Guard(inner, condition) => {
                // First bind inner pattern
                self.bind_pattern(inner, value)?;
                // Then evaluate guard condition
                let cond_result = self.evaluate(condition)?;
                Ok(cond_result.is_truthy())
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
            Expr::ResultConstructor { is_okay, value } => {
                let inner_value = self.evaluate(value)?;
                if *is_okay {
                    Ok(Value::Okay(Box::new(inner_value)))
                } else {
                    // For Oops, the value should be a string message
                    match inner_value {
                        Value::String(msg) => Ok(Value::Oops(msg)),
                        other => Ok(Value::Oops(other.to_string())),
                    }
                }
            }
            Expr::Try(inner) => {
                let value = self.evaluate(inner)?;
                match value {
                    Value::Okay(v) => Ok(*v),
                    Value::Oops(e) => Err(RuntimeError::OopsError(e)),
                    // Non-Result values pass through
                    other => Ok(other),
                }
            }
            Expr::Unwrap(inner) => {
                let value = self.evaluate(inner)?;
                match value {
                    Value::Okay(v) => Ok(*v),
                    Value::Oops(e) => Err(RuntimeError::UnwrapError(e)),
                    // Non-Result values pass through
                    other => Ok(other),
                }
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
            "isOkay" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                Ok(Some(Value::Bool(args[0].is_okay())))
            }
            "isOops" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                Ok(Some(Value::Bool(args[0].is_oops())))
            }
            "getOkay" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                match &args[0] {
                    Value::Okay(v) => Ok(Some((**v).clone())),
                    _ => Err(RuntimeError::TypeError("getOkay requires an Okay value".into())),
                }
            }
            "getOops" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArityMismatch {
                        expected: 1,
                        got: args.len(),
                    });
                }
                match &args[0] {
                    Value::Oops(msg) => Ok(Some(Value::String(msg.clone()))),
                    _ => Err(RuntimeError::TypeError("getOops requires an Oops value".into())),
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
