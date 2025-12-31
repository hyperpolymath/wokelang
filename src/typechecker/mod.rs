//! Type inference and checking for WokeLang
//!
//! This module implements Hindley-Milner style type inference with
//! support for WokeLang's types including Result types.

use crate::ast::*;
use std::collections::HashMap;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum TypeError {
    #[error("Type mismatch: expected {expected}, got {actual}")]
    TypeMismatch { expected: String, actual: String },

    #[error("Undefined variable: {0}")]
    UndefinedVariable(String),

    #[error("Undefined function: {0}")]
    UndefinedFunction(String),

    #[error("Cannot infer type: {0}")]
    InferenceError(String),

    #[error("Arity mismatch: expected {expected} arguments, got {actual}")]
    ArityMismatch { expected: usize, actual: usize },

    #[error("Type annotation required: {0}")]
    AnnotationRequired(String),

    #[error("Cannot index type: {0}")]
    CannotIndex(String),

    #[error("Cannot call non-function: {0}")]
    NotCallable(String),
}

type Result<T> = std::result::Result<T, TypeError>;

/// Internal representation of inferred types
#[derive(Debug, Clone, PartialEq)]
pub enum InferredType {
    Int,
    Float,
    String,
    Bool,
    Unit,
    Array(Box<InferredType>),
    Result { ok: Box<InferredType>, err: Box<InferredType> },
    Maybe(Box<InferredType>),
    Function { params: Vec<InferredType>, ret: Box<InferredType> },
    /// Unknown type, to be inferred
    Unknown(u32),
    /// Type variable
    TypeVar(String),
}

impl std::fmt::Display for InferredType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            InferredType::Int => write!(f, "Int"),
            InferredType::Float => write!(f, "Float"),
            InferredType::String => write!(f, "String"),
            InferredType::Bool => write!(f, "Bool"),
            InferredType::Unit => write!(f, "Unit"),
            InferredType::Array(inner) => write!(f, "[{}]", inner),
            InferredType::Result { ok, err } => write!(f, "Result[{}, {}]", ok, err),
            InferredType::Maybe(inner) => write!(f, "Maybe {}", inner),
            InferredType::Function { params, ret } => {
                let param_str: Vec<std::string::String> = params.iter().map(|p| p.to_string()).collect();
                write!(f, "({}) -> {}", param_str.join(", "), ret)
            }
            InferredType::Unknown(id) => write!(f, "?{}", id),
            InferredType::TypeVar(name) => write!(f, "{}", name),
        }
    }
}

/// Type environment tracking variable and function types
#[derive(Clone)]
struct TypeEnv {
    scopes: Vec<HashMap<String, InferredType>>,
    functions: HashMap<String, InferredType>,
}

impl TypeEnv {
    fn new() -> Self {
        Self {
            scopes: vec![HashMap::new()],
            functions: HashMap::new(),
        }
    }

    fn push_scope(&mut self) {
        self.scopes.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        self.scopes.pop();
    }

    fn define(&mut self, name: String, ty: InferredType) {
        if let Some(scope) = self.scopes.last_mut() {
            scope.insert(name, ty);
        }
    }

    fn get(&self, name: &str) -> Option<&InferredType> {
        for scope in self.scopes.iter().rev() {
            if let Some(ty) = scope.get(name) {
                return Some(ty);
            }
        }
        // Also check if it's a function
        self.functions.get(name)
    }

    fn get_function(&self, name: &str) -> Option<&InferredType> {
        self.functions.get(name)
    }

    fn define_function(&mut self, name: String, ty: InferredType) {
        self.functions.insert(name, ty);
    }
}

/// The type checker
pub struct TypeChecker {
    env: TypeEnv,
    /// Counter for generating fresh type variables
    next_type_var: u32,
    /// Substitution map for type unification
    substitutions: HashMap<u32, InferredType>,
}

impl Default for TypeChecker {
    fn default() -> Self {
        Self::new()
    }
}

impl TypeChecker {
    pub fn new() -> Self {
        let mut tc = Self {
            env: TypeEnv::new(),
            next_type_var: 0,
            substitutions: HashMap::new(),
        };
        tc.register_builtins();
        tc
    }

    /// Register builtin functions for type checking
    fn register_builtins(&mut self) {
        // print(...) -> Unit - accepts any number of any type arguments
        // We model this as accepting a single Any-ish type for now
        self.env.define_function(
            "print".to_string(),
            InferredType::Function {
                params: vec![], // Variadic - we'll handle specially
                ret: Box::new(InferredType::Unit),
            },
        );

        // len(String) -> Int  OR  len(Array<T>) -> Int
        // For now, use a fresh type var since we lack proper generics
        self.env.define_function(
            "len".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(999)], // Any indexable type
                ret: Box::new(InferredType::Int),
            },
        );

        // toString(any) -> String
        self.env.define_function(
            "toString".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(998)], // Any type
                ret: Box::new(InferredType::String),
            },
        );

        // toInt(String|Float|Int) -> Int
        self.env.define_function(
            "toInt".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(997)], // String, Float, or Int
                ret: Box::new(InferredType::Int),
            },
        );

        // isOkay(Result<T, E>) -> Bool
        self.env.define_function(
            "isOkay".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(996)], // Result type
                ret: Box::new(InferredType::Bool),
            },
        );

        // isOops(Result<T, E>) -> Bool
        self.env.define_function(
            "isOops".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(995)], // Result type
                ret: Box::new(InferredType::Bool),
            },
        );

        // unwrapOr(Result<T, E>, T) -> T
        self.env.define_function(
            "unwrapOr".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(994), InferredType::Unknown(993)],
                ret: Box::new(InferredType::Unknown(994)),
            },
        );

        // getError(Result<T, E>) -> String
        self.env.define_function(
            "getError".to_string(),
            InferredType::Function {
                params: vec![InferredType::Unknown(992)],
                ret: Box::new(InferredType::String),
            },
        );

    }

    /// Generate a fresh type variable
    fn fresh_type_var(&mut self) -> InferredType {
        let id = self.next_type_var;
        self.next_type_var += 1;
        InferredType::Unknown(id)
    }

    /// Apply substitutions to resolve type variables
    fn apply_substitutions(&self, ty: &InferredType) -> InferredType {
        match ty {
            InferredType::Unknown(id) => {
                if let Some(resolved) = self.substitutions.get(id) {
                    self.apply_substitutions(resolved)
                } else {
                    ty.clone()
                }
            }
            InferredType::Array(inner) => {
                InferredType::Array(Box::new(self.apply_substitutions(inner)))
            }
            InferredType::Result { ok, err } => InferredType::Result {
                ok: Box::new(self.apply_substitutions(ok)),
                err: Box::new(self.apply_substitutions(err)),
            },
            InferredType::Maybe(inner) => {
                InferredType::Maybe(Box::new(self.apply_substitutions(inner)))
            }
            InferredType::Function { params, ret } => InferredType::Function {
                params: params.iter().map(|p| self.apply_substitutions(p)).collect(),
                ret: Box::new(self.apply_substitutions(ret)),
            },
            _ => ty.clone(),
        }
    }

    /// Unify two types, recording substitutions
    fn unify(&mut self, t1: &InferredType, t2: &InferredType) -> Result<()> {
        let t1 = self.apply_substitutions(t1);
        let t2 = self.apply_substitutions(t2);

        match (&t1, &t2) {
            // Same types unify
            (InferredType::Int, InferredType::Int) => Ok(()),
            (InferredType::Float, InferredType::Float) => Ok(()),
            (InferredType::String, InferredType::String) => Ok(()),
            (InferredType::Bool, InferredType::Bool) => Ok(()),
            (InferredType::Unit, InferredType::Unit) => Ok(()),

            // Int and Float can unify (Int promotes to Float)
            (InferredType::Int, InferredType::Float) => Ok(()),
            (InferredType::Float, InferredType::Int) => Ok(()),

            // Unknown types get substituted
            (InferredType::Unknown(id), other) => {
                self.substitutions.insert(*id, other.clone());
                Ok(())
            }
            (other, InferredType::Unknown(id)) => {
                self.substitutions.insert(*id, other.clone());
                Ok(())
            }

            // Arrays unify if inner types unify
            (InferredType::Array(a), InferredType::Array(b)) => self.unify(a, b),

            // Results unify if both ok and err types unify
            (InferredType::Result { ok: ok1, err: err1 }, InferredType::Result { ok: ok2, err: err2 }) => {
                self.unify(ok1, ok2)?;
                self.unify(err1, err2)
            }

            // Maybe types unify if inner types unify
            (InferredType::Maybe(a), InferredType::Maybe(b)) => self.unify(a, b),

            // Functions unify if params and return types unify
            (InferredType::Function { params: p1, ret: r1 }, InferredType::Function { params: p2, ret: r2 }) => {
                if p1.len() != p2.len() {
                    return Err(TypeError::ArityMismatch {
                        expected: p1.len(),
                        actual: p2.len(),
                    });
                }
                for (a, b) in p1.iter().zip(p2.iter()) {
                    self.unify(a, b)?;
                }
                self.unify(r1, r2)
            }

            // Type variables with the same name unify
            (InferredType::TypeVar(a), InferredType::TypeVar(b)) if a == b => Ok(()),

            // Type variables can unify with any type (polymorphic)
            // In a full implementation, we'd track type var bindings
            (InferredType::TypeVar(_), _) => Ok(()),
            (_, InferredType::TypeVar(_)) => Ok(()),

            _ => Err(TypeError::TypeMismatch {
                expected: t1.to_string(),
                actual: t2.to_string(),
            }),
        }
    }

    /// Convert AST Type to InferredType
    fn ast_type_to_inferred(&self, ty: &Type) -> InferredType {
        match ty {
            Type::Basic(name) => match name.as_str() {
                "Int" => InferredType::Int,
                "Float" => InferredType::Float,
                "String" => InferredType::String,
                "Bool" => InferredType::Bool,
                "Unit" => InferredType::Unit,
                "Result" => InferredType::Result {
                    ok: Box::new(InferredType::Unknown(0)),
                    err: Box::new(InferredType::String),
                },
                _ => InferredType::TypeVar(name.clone()),
            },
            Type::Array(inner) => InferredType::Array(Box::new(self.ast_type_to_inferred(inner))),
            Type::Optional(inner) => InferredType::Maybe(Box::new(self.ast_type_to_inferred(inner))),
            Type::Reference(inner) => self.ast_type_to_inferred(inner),
            Type::Function(params, ret) => InferredType::Function {
                params: params.iter().map(|p| self.ast_type_to_inferred(p)).collect(),
                ret: Box::new(self.ast_type_to_inferred(ret)),
            },
            Type::Generic(name, args) => {
                let inferred_args: Vec<_> = args.iter().map(|a| self.ast_type_to_inferred(a)).collect();
                match name.as_str() {
                    "Result" if args.len() == 2 => InferredType::Result {
                        ok: Box::new(inferred_args[0].clone()),
                        err: Box::new(inferred_args[1].clone()),
                    },
                    "Result" if args.len() == 1 => InferredType::Result {
                        ok: Box::new(inferred_args[0].clone()),
                        err: Box::new(InferredType::String),
                    },
                    "Maybe" | "Option" if args.len() == 1 => {
                        InferredType::Maybe(Box::new(inferred_args[0].clone()))
                    }
                    "Array" if args.len() == 1 => {
                        InferredType::Array(Box::new(inferred_args[0].clone()))
                    }
                    _ => {
                        // For now, treat unknown generics as type variables
                        // In the future, we'd look up the generic type definition
                        InferredType::TypeVar(format!("{}<{}>", name,
                            args.iter().map(|a| format!("{:?}", a)).collect::<Vec<_>>().join(", ")))
                    }
                }
            },
            Type::TypeVar(name) => InferredType::TypeVar(name.clone()),
        }
    }

    /// Type check a program
    pub fn check_program(&mut self, program: &Program) -> Result<()> {
        // First pass: collect function signatures
        for item in &program.items {
            if let TopLevelItem::Function(f) = item {
                self.register_function(f)?;
            }
        }

        // Second pass: type check function bodies
        for item in &program.items {
            match item {
                TopLevelItem::Function(f) => self.check_function(f)?,
                TopLevelItem::ConsentBlock(c) => {
                    self.env.push_scope();
                    for stmt in &c.body {
                        self.check_statement(stmt, &InferredType::Unit)?;
                    }
                    self.env.pop_scope();
                }
                _ => {}
            }
        }

        Ok(())
    }

    fn register_function(&mut self, func: &FunctionDef) -> Result<()> {
        let params: Vec<InferredType> = func
            .params
            .iter()
            .map(|p| {
                p.ty.as_ref()
                    .map(|t| self.ast_type_to_inferred(t))
                    .unwrap_or_else(|| self.fresh_type_var())
            })
            .collect();

        let ret = func
            .return_type
            .as_ref()
            .map(|t| self.ast_type_to_inferred(t))
            .unwrap_or(InferredType::Unit);

        let func_type = InferredType::Function {
            params,
            ret: Box::new(ret),
        };

        self.env.define_function(func.name.clone(), func_type);
        Ok(())
    }

    fn check_function(&mut self, func: &FunctionDef) -> Result<()> {
        self.env.push_scope();

        // Add parameters to scope
        for param in &func.params {
            let param_type = param
                .ty
                .as_ref()
                .map(|t| self.ast_type_to_inferred(t))
                .unwrap_or_else(|| self.fresh_type_var());
            self.env.define(param.name.clone(), param_type);
        }

        // Check body statements
        let expected_return = func
            .return_type
            .as_ref()
            .map(|t| self.ast_type_to_inferred(t))
            .unwrap_or(InferredType::Unit);

        for stmt in &func.body {
            self.check_statement(stmt, &expected_return)?;
        }

        self.env.pop_scope();
        Ok(())
    }

    fn check_statement(&mut self, stmt: &Statement, expected_return: &InferredType) -> Result<()> {
        match stmt {
            Statement::VarDecl(decl) => {
                let expr_type = self.infer_expr(&decl.value)?;
                self.env.define(decl.name.clone(), expr_type);
                Ok(())
            }

            Statement::Assignment(assign) => {
                let var_type = self
                    .env
                    .get(&assign.target)
                    .ok_or_else(|| TypeError::UndefinedVariable(assign.target.clone()))?
                    .clone();
                let expr_type = self.infer_expr(&assign.value)?;
                self.unify(&var_type, &expr_type)
            }

            Statement::Return(ret) => {
                let expr_type = self.infer_expr(&ret.value)?;
                self.unify(expected_return, &expr_type)
            }

            Statement::Conditional(cond) => {
                let cond_type = self.infer_expr(&cond.condition)?;
                self.unify(&InferredType::Bool, &cond_type)?;

                self.env.push_scope();
                for s in &cond.then_branch {
                    self.check_statement(s, expected_return)?;
                }
                self.env.pop_scope();

                if let Some(else_branch) = &cond.else_branch {
                    self.env.push_scope();
                    for s in else_branch {
                        self.check_statement(s, expected_return)?;
                    }
                    self.env.pop_scope();
                }

                Ok(())
            }

            Statement::Loop(loop_stmt) => {
                let count_type = self.infer_expr(&loop_stmt.count)?;
                self.unify(&InferredType::Int, &count_type)?;

                self.env.push_scope();
                for s in &loop_stmt.body {
                    self.check_statement(s, expected_return)?;
                }
                self.env.pop_scope();

                Ok(())
            }

            Statement::Expression(expr) => {
                self.infer_expr(expr)?;
                Ok(())
            }

            Statement::AttemptBlock(attempt) => {
                self.env.push_scope();
                for s in &attempt.body {
                    self.check_statement(s, expected_return)?;
                }
                self.env.pop_scope();
                Ok(())
            }

            Statement::ConsentBlock(consent) => {
                self.env.push_scope();
                for s in &consent.body {
                    self.check_statement(s, expected_return)?;
                }
                self.env.pop_scope();
                Ok(())
            }

            Statement::Decide(decide) => {
                let scrutinee_type = self.infer_expr(&decide.scrutinee)?;

                for arm in &decide.arms {
                    self.env.push_scope();
                    self.bind_pattern_types(&arm.pattern, &scrutinee_type)?;
                    for s in &arm.body {
                        self.check_statement(s, expected_return)?;
                    }
                    self.env.pop_scope();
                }

                Ok(())
            }

            Statement::EmoteAnnotated(annotated) => {
                self.check_statement(&annotated.statement, expected_return)
            }

            Statement::Complain(_) | Statement::WorkerSpawn(_) => Ok(()),
        }
    }

    fn bind_pattern_types(&mut self, pattern: &Pattern, expected_type: &InferredType) -> Result<()> {
        match pattern {
            Pattern::Identifier(name) => {
                self.env.define(name.clone(), expected_type.clone());
                Ok(())
            }
            Pattern::Wildcard | Pattern::Literal(_) => Ok(()),
            Pattern::Constructor(name, inner) => {
                match name.as_str() {
                    "Okay" => {
                        if let Some(inner_pat) = inner {
                            let ok_type = if let InferredType::Result { ok, .. } = expected_type {
                                (**ok).clone()
                            } else {
                                self.fresh_type_var()
                            };
                            self.bind_pattern_types(inner_pat, &ok_type)?;
                        }
                    }
                    "Oops" => {
                        if let Some(inner_pat) = inner {
                            let err_type = if let InferredType::Result { err, .. } = expected_type {
                                (**err).clone()
                            } else {
                                InferredType::String
                            };
                            self.bind_pattern_types(inner_pat, &err_type)?;
                        }
                    }
                    _ => {
                        if let Some(inner_pat) = inner {
                            let fresh = self.fresh_type_var();
                            self.bind_pattern_types(inner_pat, &fresh)?;
                        }
                    }
                }
                Ok(())
            }
        }
    }

    fn infer_expr(&mut self, expr: &Spanned<Expr>) -> Result<InferredType> {
        match &expr.node {
            Expr::Literal(lit) => Ok(match lit {
                Literal::Integer(_) => InferredType::Int,
                Literal::Float(_) => InferredType::Float,
                Literal::String(_) => InferredType::String,
                Literal::Bool(_) => InferredType::Bool,
            }),

            Expr::Identifier(name) => self
                .env
                .get(name)
                .cloned()
                .ok_or_else(|| TypeError::UndefinedVariable(name.clone())),

            Expr::Binary(op, left, right) => {
                let left_type = self.infer_expr(left)?;
                let right_type = self.infer_expr(right)?;

                match op {
                    BinaryOp::Add => {
                        // String concatenation or numeric addition
                        let left_resolved = self.apply_substitutions(&left_type);
                        if matches!(left_resolved, InferredType::String) {
                            self.unify(&right_type, &InferredType::String)?;
                            Ok(InferredType::String)
                        } else {
                            self.unify(&left_type, &right_type)?;
                            let resolved = self.apply_substitutions(&left_type);
                            if matches!(resolved, InferredType::Float) {
                                Ok(InferredType::Float)
                            } else {
                                Ok(InferredType::Int)
                            }
                        }
                    }
                    BinaryOp::Sub | BinaryOp::Mul | BinaryOp::Div | BinaryOp::Mod => {
                        self.unify(&left_type, &right_type)?;
                        let resolved = self.apply_substitutions(&left_type);
                        if matches!(resolved, InferredType::Float) {
                            Ok(InferredType::Float)
                        } else {
                            Ok(InferredType::Int)
                        }
                    }
                    BinaryOp::Eq | BinaryOp::NotEq | BinaryOp::Lt | BinaryOp::Gt | BinaryOp::LtEq | BinaryOp::GtEq => {
                        self.unify(&left_type, &right_type)?;
                        Ok(InferredType::Bool)
                    }
                    BinaryOp::And | BinaryOp::Or => {
                        self.unify(&InferredType::Bool, &left_type)?;
                        self.unify(&InferredType::Bool, &right_type)?;
                        Ok(InferredType::Bool)
                    }
                }
            }

            Expr::Unary(op, operand) => {
                let operand_type = self.infer_expr(operand)?;
                match op {
                    UnaryOp::Neg => Ok(operand_type),
                    UnaryOp::Not => {
                        self.unify(&InferredType::Bool, &operand_type)?;
                        Ok(InferredType::Bool)
                    }
                }
            }

            Expr::Call(name, args) => {
                // Handle built-in functions
                match name.as_str() {
                    "print" => return Ok(InferredType::Unit),
                    "toString" => return Ok(InferredType::String),
                    "len" => return Ok(InferredType::Int),
                    "isOkay" | "isOops" => return Ok(InferredType::Bool),
                    "unwrapOr" => {
                        if args.len() >= 2 {
                            let default_type = self.infer_expr(&args[1])?;
                            return Ok(default_type);
                        }
                        return Ok(self.fresh_type_var());
                    }
                    "getError" => return Ok(InferredType::String),
                    "toInt" => return Ok(InferredType::Int),
                    "toFloat" => return Ok(InferredType::Float),
                    _ => {}
                }

                // Check if it's a variable holding a function (closure)
                if let Some(var_type) = self.env.get(name).cloned() {
                    if let InferredType::Function { params, ret } = var_type {
                        if params.len() != args.len() {
                            return Err(TypeError::ArityMismatch {
                                expected: params.len(),
                                actual: args.len(),
                            });
                        }
                        for (param_type, arg) in params.iter().zip(args.iter()) {
                            let arg_type = self.infer_expr(arg)?;
                            self.unify(param_type, &arg_type)?;
                        }
                        return Ok((*ret).clone());
                    }
                }

                // Check defined functions
                let func_type = self
                    .env
                    .get_function(name)
                    .cloned()
                    .ok_or_else(|| TypeError::UndefinedFunction(name.clone()))?;

                if let InferredType::Function { params, ret } = func_type {
                    // Empty params means variadic (like print, speak)
                    if !params.is_empty() && params.len() != args.len() {
                        return Err(TypeError::ArityMismatch {
                            expected: params.len(),
                            actual: args.len(),
                        });
                    }

                    // Type check arguments against parameters (skip for variadic)
                    for (param_type, arg) in params.iter().zip(args.iter()) {
                        let arg_type = self.infer_expr(arg)?;
                        self.unify(&param_type, &arg_type)?;
                    }

                    // For variadic functions, still infer arg types for side effects
                    if params.is_empty() {
                        for arg in args {
                            let _ = self.infer_expr(arg)?;
                        }
                    }

                    Ok((*ret).clone())
                } else {
                    Err(TypeError::NotCallable(func_type.to_string()))
                }
            }

            Expr::CallExpr(callee, args) => {
                let callee_type = self.infer_expr(callee)?;

                if let InferredType::Function { params, ret } = callee_type {
                    if params.len() != args.len() {
                        return Err(TypeError::ArityMismatch {
                            expected: params.len(),
                            actual: args.len(),
                        });
                    }

                    for (param_type, arg) in params.iter().zip(args.iter()) {
                        let arg_type = self.infer_expr(arg)?;
                        self.unify(&param_type, &arg_type)?;
                    }

                    Ok((*ret).clone())
                } else {
                    Err(TypeError::NotCallable(callee_type.to_string()))
                }
            }

            Expr::Array(elements) => {
                if elements.is_empty() {
                    Ok(InferredType::Array(Box::new(self.fresh_type_var())))
                } else {
                    let first_type = self.infer_expr(&elements[0])?;
                    for elem in &elements[1..] {
                        let elem_type = self.infer_expr(elem)?;
                        self.unify(&first_type, &elem_type)?;
                    }
                    Ok(InferredType::Array(Box::new(first_type)))
                }
            }

            Expr::Index(target, index) => {
                let target_type = self.infer_expr(target)?;
                let index_type = self.infer_expr(index)?;
                self.unify(&InferredType::Int, &index_type)?;

                match target_type {
                    InferredType::Array(inner) => Ok((*inner).clone()),
                    InferredType::String => Ok(InferredType::String),
                    _ => Err(TypeError::CannotIndex(target_type.to_string())),
                }
            }

            Expr::Okay(inner) => {
                let inner_type = self.infer_expr(inner)?;
                Ok(InferredType::Result {
                    ok: Box::new(inner_type),
                    err: Box::new(InferredType::String),
                })
            }

            Expr::Oops(inner) => {
                let inner_type = self.infer_expr(inner)?;
                Ok(InferredType::Result {
                    ok: Box::new(self.fresh_type_var()),
                    err: Box::new(inner_type),
                })
            }

            Expr::Unwrap(inner) => {
                let inner_type = self.infer_expr(inner)?;
                if let InferredType::Result { ok, .. } = inner_type {
                    Ok((*ok).clone())
                } else {
                    // Unwrap on non-Result returns the value as-is
                    Ok(inner_type)
                }
            }

            Expr::Lambda(lambda) => {
                self.env.push_scope();

                let param_types: Vec<InferredType> = lambda
                    .params
                    .iter()
                    .map(|p| {
                        let ty = p.ty.as_ref()
                            .map(|t| self.ast_type_to_inferred(t))
                            .unwrap_or_else(|| self.fresh_type_var());
                        self.env.define(p.name.clone(), ty.clone());
                        ty
                    })
                    .collect();

                let ret_type = match &lambda.body {
                    LambdaBody::Expr(expr) => self.infer_expr(expr)?,
                    LambdaBody::Block(stmts) => {
                        let expected_ret = lambda.return_type
                            .as_ref()
                            .map(|t| self.ast_type_to_inferred(t))
                            .unwrap_or_else(|| self.fresh_type_var());
                        for stmt in stmts {
                            self.check_statement(stmt, &expected_ret)?;
                        }
                        expected_ret
                    }
                };

                self.env.pop_scope();

                Ok(InferredType::Function {
                    params: param_types,
                    ret: Box::new(ret_type),
                })
            }

            Expr::UnitMeasurement(inner, _unit) => {
                // For now, unit measurements are transparent
                self.infer_expr(inner)
            }

            Expr::GratitudeLiteral(_) => Ok(InferredType::String),
        }
    }

    /// Get errors collected during type checking
    pub fn errors(&self) -> Vec<String> {
        Vec::new()
    }
}
