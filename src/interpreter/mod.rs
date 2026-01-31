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

/// The interpreter
pub struct Interpreter {
    environment: Rc<RefCell<Environment>>,
    functions: HashMap<String, FunctionDef>,
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            environment: Rc::new(RefCell::new(Environment::new())),
            functions: HashMap::new(),
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
        _args: Vec<Value>,
    ) -> Result<Value, RuntimeError> {
        // Create new scope
        let new_env = Rc::new(RefCell::new(Environment::with_parent(
            Rc::clone(&self.environment),
        )));
        let old_env = std::mem::replace(&mut self.environment, new_env);

        // Execute function body
        let mut result = Value::Unit;
        for stmt in &func.body {
            result = self.execute_statement(stmt)?;
        }

        // Restore environment
        self.environment = old_env;

        Ok(result)
    }

    /// Execute a statement
    fn execute_statement(&mut self, _stmt: &Statement) -> Result<Value, RuntimeError> {
        // Stub implementation
        Ok(Value::Unit)
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
}
