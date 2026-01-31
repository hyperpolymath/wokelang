// SPDX-License-Identifier: PMPL-1.0-or-later
//! WokeLang Type Checker
//!
//! Static type analysis and inference for WokeLang programs.

use crate::ast::*;
use std::collections::HashMap;
use std::fmt;

/// Type checking error
#[derive(Debug)]
pub struct TypeError {
    pub message: String,
}

impl std::fmt::Display for TypeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl std::error::Error for TypeError {}

/// Type in the type system
#[derive(Debug, Clone, PartialEq)]
pub enum TypeInfo {
    Int,
    Float,
    String,
    Bool,
    Unit,
    Array(Box<TypeInfo>),
    Function(Vec<TypeInfo>, Box<TypeInfo>),
    /// Type variable for inference
    Var(usize),
    /// Unknown type (for gradual typing)
    Unknown,
}

impl fmt::Display for TypeInfo {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            TypeInfo::Int => write!(f, "Int"),
            TypeInfo::Float => write!(f, "Float"),
            TypeInfo::String => write!(f, "String"),
            TypeInfo::Bool => write!(f, "Bool"),
            TypeInfo::Unit => write!(f, "Unit"),
            TypeInfo::Array(inner) => write!(f, "[{}]", inner),
            TypeInfo::Function(params, ret) => {
                write!(f, "(")?;
                for (i, param) in params.iter().enumerate() {
                    if i > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}", param)?;
                }
                write!(f, ") -> {}", ret)
            }
            TypeInfo::Var(id) => write!(f, "T{}", id),
            TypeInfo::Unknown => write!(f, "?"),
        }
    }
}

/// Type environment
pub struct TypeEnv {
    bindings: HashMap<String, TypeInfo>,
    next_var: usize,
}

impl TypeEnv {
    pub fn new() -> Self {
        Self {
            bindings: HashMap::new(),
            next_var: 0,
        }
    }

    pub fn define(&mut self, name: String, ty: TypeInfo) {
        self.bindings.insert(name, ty);
    }

    pub fn get(&self, name: &str) -> Option<&TypeInfo> {
        self.bindings.get(name)
    }

    pub fn fresh_var(&mut self) -> TypeInfo {
        let id = self.next_var;
        self.next_var += 1;
        TypeInfo::Var(id)
    }
}

impl Default for TypeEnv {
    fn default() -> Self {
        Self::new()
    }
}

/// The type checker
pub struct TypeChecker {
    env: TypeEnv,
}

impl TypeChecker {
    pub fn new() -> Self {
        Self {
            env: TypeEnv::new(),
        }
    }

    /// Type check a complete program
    pub fn check_program(&mut self, program: &Program) -> Result<(), TypeError> {
        // Collect all function signatures
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                self.check_function(func)?;
            }
        }

        Ok(())
    }

    /// Type check a function
    fn check_function(&mut self, _func: &FunctionDef) -> Result<TypeInfo, TypeError> {
        // Stub implementation - always succeeds for now
        Ok(TypeInfo::Unit)
    }

    /// Type check an expression
    fn check_expr(&mut self, _expr: &Expr) -> Result<TypeInfo, TypeError> {
        // Stub implementation
        Ok(TypeInfo::Unknown)
    }

    /// Type check a statement
    fn check_statement(&mut self, _stmt: &Statement) -> Result<(), TypeError> {
        // Stub implementation
        Ok(())
    }
}

impl Default for TypeChecker {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_type_checker_new() {
        let checker = TypeChecker::new();
        assert_eq!(checker.env.bindings.len(), 0);
    }

    #[test]
    fn test_type_env() {
        let mut env = TypeEnv::new();
        env.define("x".to_string(), TypeInfo::Int);
        assert_eq!(env.get("x"), Some(&TypeInfo::Int));
    }

    #[test]
    fn test_fresh_var() {
        let mut env = TypeEnv::new();
        let v1 = env.fresh_var();
        let v2 = env.fresh_var();
        assert_ne!(v1, v2);
    }
}
