//! WokeLang Standard Library
//!
//! This module provides the standard library for WokeLang, offering
//! common functionality with consent-aware operations.

pub mod io;
pub mod json;
pub mod math;
pub mod net;
pub mod time;

use crate::interpreter::Value;
use crate::security::CapabilityRegistry;
use std::collections::HashMap;

/// Standard library function signature
pub type StdlibFn = fn(&[Value], &mut CapabilityRegistry) -> Result<Value, StdlibError>;

/// Error type for standard library operations
#[derive(Debug, Clone)]
pub enum StdlibError {
    /// Wrong number of arguments
    ArityError { expected: usize, got: usize },
    /// Wrong argument type
    TypeError { expected: String, got: String },
    /// Capability not granted
    PermissionDenied(String),
    /// I/O error
    IoError(String),
    /// Network error
    NetworkError(String),
    /// Parse error
    ParseError(String),
    /// Other runtime error
    RuntimeError(String),
}

impl std::fmt::Display for StdlibError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            StdlibError::ArityError { expected, got } => {
                write!(f, "Expected {} arguments, got {}", expected, got)
            }
            StdlibError::TypeError { expected, got } => {
                write!(f, "Expected {}, got {}", expected, got)
            }
            StdlibError::PermissionDenied(cap) => {
                write!(f, "Permission denied: {}", cap)
            }
            StdlibError::IoError(msg) => write!(f, "I/O error: {}", msg),
            StdlibError::NetworkError(msg) => write!(f, "Network error: {}", msg),
            StdlibError::ParseError(msg) => write!(f, "Parse error: {}", msg),
            StdlibError::RuntimeError(msg) => write!(f, "Runtime error: {}", msg),
        }
    }
}

impl std::error::Error for StdlibError {}

/// The standard library registry
pub struct StdlibRegistry {
    functions: HashMap<String, StdlibFn>,
}

impl StdlibRegistry {
    pub fn new() -> Self {
        let mut registry = Self {
            functions: HashMap::new(),
        };
        registry.register_all();
        registry
    }

    /// Register all standard library functions
    fn register_all(&mut self) {
        // Math functions
        self.register("std.math.abs", math::abs);
        self.register("std.math.sqrt", math::sqrt);
        self.register("std.math.pow", math::pow);
        self.register("std.math.sin", math::sin);
        self.register("std.math.cos", math::cos);
        self.register("std.math.tan", math::tan);
        self.register("std.math.floor", math::floor);
        self.register("std.math.ceil", math::ceil);
        self.register("std.math.round", math::round);
        self.register("std.math.min", math::min);
        self.register("std.math.max", math::max);
        self.register("std.math.random", math::random);
        self.register("std.math.pi", math::pi);
        self.register("std.math.e", math::e);

        // I/O functions (require consent)
        self.register("std.io.readFile", io::read_file);
        self.register("std.io.writeFile", io::write_file);
        self.register("std.io.appendFile", io::append_file);
        self.register("std.io.exists", io::exists);
        self.register("std.io.delete", io::delete);
        self.register("std.io.listDir", io::list_dir);
        self.register("std.io.createDir", io::create_dir);
        self.register("std.io.readLine", io::read_line);

        // JSON functions
        self.register("std.json.parse", json::parse);
        self.register("std.json.stringify", json::stringify);
        self.register("std.json.get", json::get);
        self.register("std.json.set", json::set);

        // Time functions
        self.register("std.time.now", time::now);
        self.register("std.time.format", time::format);
        self.register("std.time.parse", time::parse);
        self.register("std.time.sleep", time::sleep);
        self.register("std.time.timestamp", time::timestamp);
        self.register("std.time.elapsed", time::elapsed);

        // Network functions (require consent)
        self.register("std.net.httpGet", net::http_get);
        self.register("std.net.httpPost", net::http_post);
        self.register("std.net.download", net::download);
    }

    /// Register a function
    fn register(&mut self, name: &str, func: StdlibFn) {
        self.functions.insert(name.to_string(), func);
    }

    /// Get a function by name
    pub fn get(&self, name: &str) -> Option<&StdlibFn> {
        self.functions.get(name)
    }

    /// Check if a function exists
    pub fn has(&self, name: &str) -> bool {
        self.functions.contains_key(name)
    }

    /// List all available functions
    pub fn list(&self) -> Vec<&str> {
        self.functions.keys().map(|s| s.as_str()).collect()
    }

    /// Call a standard library function
    pub fn call(
        &self,
        name: &str,
        args: &[Value],
        capabilities: &mut CapabilityRegistry,
    ) -> Result<Value, StdlibError> {
        if let Some(func) = self.functions.get(name) {
            func(args, capabilities)
        } else {
            Err(StdlibError::RuntimeError(format!(
                "Unknown function: {}",
                name
            )))
        }
    }
}

impl Default for StdlibRegistry {
    fn default() -> Self {
        Self::new()
    }
}

/// Helper to check argument count
pub fn check_arity(args: &[Value], expected: usize) -> Result<(), StdlibError> {
    if args.len() != expected {
        Err(StdlibError::ArityError {
            expected,
            got: args.len(),
        })
    } else {
        Ok(())
    }
}

/// Helper to check argument count range
pub fn check_arity_range(args: &[Value], min: usize, max: usize) -> Result<(), StdlibError> {
    if args.len() < min || args.len() > max {
        Err(StdlibError::ArityError {
            expected: min,
            got: args.len(),
        })
    } else {
        Ok(())
    }
}

/// Helper to extract a string argument
pub fn expect_string(value: &Value, _arg_name: &str) -> Result<String, StdlibError> {
    match value {
        Value::String(s) => Ok(s.clone()),
        other => Err(StdlibError::TypeError {
            expected: "String".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Helper to extract an integer argument
pub fn expect_int(value: &Value, _arg_name: &str) -> Result<i64, StdlibError> {
    match value {
        Value::Int(n) => Ok(*n),
        other => Err(StdlibError::TypeError {
            expected: "Int".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Helper to extract a float argument
pub fn expect_float(value: &Value, _arg_name: &str) -> Result<f64, StdlibError> {
    match value {
        Value::Float(n) => Ok(*n),
        Value::Int(n) => Ok(*n as f64),
        other => Err(StdlibError::TypeError {
            expected: "Float".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

/// Helper to extract a boolean argument
pub fn expect_bool(value: &Value, _arg_name: &str) -> Result<bool, StdlibError> {
    match value {
        Value::Bool(b) => Ok(*b),
        other => Err(StdlibError::TypeError {
            expected: "Bool".to_string(),
            got: format!("{:?}", other),
        }),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_registry_creation() {
        let registry = StdlibRegistry::new();
        assert!(registry.has("std.math.abs"));
        assert!(registry.has("std.io.readFile"));
        assert!(registry.has("std.json.parse"));
        assert!(registry.has("std.time.now"));
        assert!(!registry.has("nonexistent"));
    }

    #[test]
    fn test_check_arity() {
        let args = vec![Value::Int(1), Value::Int(2)];
        assert!(check_arity(&args, 2).is_ok());
        assert!(check_arity(&args, 3).is_err());
    }
}
