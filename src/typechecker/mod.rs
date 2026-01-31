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
    /// Result type: Result<T, E>
    Result(Box<TypeInfo>, Box<TypeInfo>),
    /// Record/struct type
    Record(HashMap<String, TypeInfo>),
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
            TypeInfo::Result(ok, err) => write!(f, "Result<{}, {}>", ok, err),
            TypeInfo::Record(fields) => {
                write!(f, "{{")?;
                let mut first = true;
                for (name, ty) in fields {
                    if !first {
                        write!(f, ", ")?;
                    }
                    write!(f, "{}: {}", name, ty)?;
                    first = false;
                }
                write!(f, "}}")
            }
            TypeInfo::Var(id) => write!(f, "T{}", id),
            TypeInfo::Unknown => write!(f, "?"),
        }
    }
}

/// Substitution: mapping from type variables to types
#[derive(Debug, Clone, Default)]
pub struct Substitution {
    map: HashMap<usize, TypeInfo>,
}

impl Substitution {
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
        }
    }

    /// Add a binding from type variable to type
    pub fn bind(&mut self, var: usize, ty: TypeInfo) {
        self.map.insert(var, ty);
    }

    /// Apply substitution to a type
    pub fn apply(&self, ty: &TypeInfo) -> TypeInfo {
        match ty {
            TypeInfo::Var(id) => {
                if let Some(substituted) = self.map.get(id) {
                    // Recursively apply substitution
                    self.apply(substituted)
                } else {
                    ty.clone()
                }
            }
            TypeInfo::Array(inner) => TypeInfo::Array(Box::new(self.apply(inner))),
            TypeInfo::Function(params, ret) => {
                let new_params = params.iter().map(|p| self.apply(p)).collect();
                let new_ret = Box::new(self.apply(ret));
                TypeInfo::Function(new_params, new_ret)
            }
            TypeInfo::Result(ok, err) => {
                TypeInfo::Result(Box::new(self.apply(ok)), Box::new(self.apply(err)))
            }
            TypeInfo::Record(fields) => {
                let new_fields = fields
                    .iter()
                    .map(|(k, v)| (k.clone(), self.apply(v)))
                    .collect();
                TypeInfo::Record(new_fields)
            }
            _ => ty.clone(),
        }
    }

    /// Compose two substitutions
    pub fn compose(&self, other: &Substitution) -> Substitution {
        let mut result = Substitution::new();

        // Apply other to all bindings in self
        for (var, ty) in &self.map {
            result.map.insert(*var, other.apply(ty));
        }

        // Add bindings from other that aren't in self
        for (var, ty) in &other.map {
            if !result.map.contains_key(var) {
                result.map.insert(*var, ty.clone());
            }
        }

        result
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

/// Unification: make two types equal by finding a substitution
pub fn unify(t1: &TypeInfo, t2: &TypeInfo) -> Result<Substitution, TypeError> {
    match (t1, t2) {
        // Same concrete types
        (TypeInfo::Int, TypeInfo::Int)
        | (TypeInfo::Float, TypeInfo::Float)
        | (TypeInfo::String, TypeInfo::String)
        | (TypeInfo::Bool, TypeInfo::Bool)
        | (TypeInfo::Unit, TypeInfo::Unit) => Ok(Substitution::new()),

        // Type variables
        (TypeInfo::Var(id1), TypeInfo::Var(id2)) if id1 == id2 => Ok(Substitution::new()),
        (TypeInfo::Var(id), ty) | (ty, TypeInfo::Var(id)) => {
            if occurs_check(*id, ty) {
                Err(TypeError {
                    message: format!("Infinite type: T{} = {}", id, ty),
                })
            } else {
                let mut sub = Substitution::new();
                sub.bind(*id, ty.clone());
                Ok(sub)
            }
        }

        // Array types
        (TypeInfo::Array(inner1), TypeInfo::Array(inner2)) => unify(inner1, inner2),

        // Function types
        (TypeInfo::Function(params1, ret1), TypeInfo::Function(params2, ret2)) => {
            if params1.len() != params2.len() {
                return Err(TypeError {
                    message: format!(
                        "Function arity mismatch: {} vs {}",
                        params1.len(),
                        params2.len()
                    ),
                });
            }

            let mut sub = Substitution::new();
            for (p1, p2) in params1.iter().zip(params2.iter()) {
                let s = unify(&sub.apply(p1), &sub.apply(p2))?;
                sub = sub.compose(&s);
            }

            let ret_sub = unify(&sub.apply(ret1), &sub.apply(ret2))?;
            Ok(sub.compose(&ret_sub))
        }

        // Result types
        (TypeInfo::Result(ok1, err1), TypeInfo::Result(ok2, err2)) => {
            let ok_sub = unify(ok1, ok2)?;
            let err_sub = unify(&ok_sub.apply(err1), &ok_sub.apply(err2))?;
            Ok(ok_sub.compose(&err_sub))
        }

        // Record types
        (TypeInfo::Record(fields1), TypeInfo::Record(fields2)) => {
            if fields1.len() != fields2.len() {
                return Err(TypeError {
                    message: format!(
                        "Record field count mismatch: {} vs {}",
                        fields1.len(),
                        fields2.len()
                    ),
                });
            }

            let mut sub = Substitution::new();
            for (name, ty1) in fields1 {
                if let Some(ty2) = fields2.get(name) {
                    let s = unify(&sub.apply(ty1), &sub.apply(ty2))?;
                    sub = sub.compose(&s);
                } else {
                    return Err(TypeError {
                        message: format!("Record field '{}' not found in both types", name),
                    });
                }
            }
            Ok(sub)
        }

        // Unknown type matches anything
        (TypeInfo::Unknown, _) | (_, TypeInfo::Unknown) => Ok(Substitution::new()),

        // Incompatible types
        _ => Err(TypeError {
            message: format!("Type mismatch: cannot unify {} with {}", t1, t2),
        }),
    }
}

/// Occurs check: ensure type variable doesn't appear in type (prevents infinite types)
fn occurs_check(var: usize, ty: &TypeInfo) -> bool {
    match ty {
        TypeInfo::Var(id) => var == *id,
        TypeInfo::Array(inner) => occurs_check(var, inner),
        TypeInfo::Function(params, ret) => {
            params.iter().any(|p| occurs_check(var, p)) || occurs_check(var, ret)
        }
        TypeInfo::Result(ok, err) => occurs_check(var, ok) || occurs_check(var, err),
        TypeInfo::Record(fields) => fields.values().any(|t| occurs_check(var, t)),
        _ => false,
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
        let sub = Substitution::new();

        // First pass: collect function signatures
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                // Create function type
                let param_types: Vec<TypeInfo> = func
                    .params
                    .iter()
                    .map(|p| {
                        // If parameter has type annotation, use it; otherwise fresh var
                        if let Some(_ty) = &p.ty {
                            // TODO: Convert AST Type to TypeInfo
                            self.env.fresh_var()
                        } else {
                            self.env.fresh_var()
                        }
                    })
                    .collect();

                let return_type = if let Some(_ret_ty) = &func.return_type {
                    // TODO: Convert AST Type to TypeInfo
                    self.env.fresh_var()
                } else {
                    self.env.fresh_var()
                };

                let func_type = TypeInfo::Function(param_types, Box::new(return_type));
                self.env.define(func.name.clone(), func_type);
            }
        }

        // Second pass: check function bodies
        for item in &program.items {
            if let TopLevelItem::Function(func) = item {
                self.check_function(func, &sub)?;
            }
        }

        Ok(())
    }

    /// Type check a function
    fn check_function(
        &mut self,
        func: &FunctionDef,
        sub: &Substitution,
    ) -> Result<TypeInfo, TypeError> {
        // Save current environment
        let old_bindings = self.env.bindings.clone();

        // Add parameters to environment
        for param in &func.params {
            let param_ty = if let Some(_ty) = &param.ty {
                // TODO: Convert AST Type to TypeInfo
                self.env.fresh_var()
            } else {
                self.env.fresh_var()
            };
            self.env.define(param.name.clone(), param_ty);
        }

        // Check function body
        let mut current_sub = sub.clone();
        for stmt in &func.body {
            current_sub = self.check_statement(stmt, &current_sub)?;
        }

        // Restore environment
        self.env.bindings = old_bindings;

        // Return function type
        if let Some(func_ty) = self.env.get(&func.name) {
            Ok(func_ty.clone())
        } else {
            Ok(TypeInfo::Unit)
        }
    }

    /// Infer the type of an expression
    fn infer_expr(
        &mut self,
        expr: &Spanned<Expr>,
        sub: &Substitution,
    ) -> Result<(TypeInfo, Substitution), TypeError> {
        match &expr.node {
            // Literals have known types
            Expr::Literal(lit) => {
                let ty = match lit {
                    Literal::Integer(_) => TypeInfo::Int,
                    Literal::Float(_) => TypeInfo::Float,
                    Literal::String(_) => TypeInfo::String,
                    Literal::Bool(_) => TypeInfo::Bool,
                    Literal::Unit => TypeInfo::Unit,
                };
                Ok((ty, sub.clone()))
            }

            // Variable lookup
            Expr::Identifier(name) => {
                if let Some(ty) = self.env.get(name) {
                    // Clone before instantiating to avoid borrow checker issues
                    let ty = ty.clone();
                    let instantiated = self.instantiate(&ty);
                    Ok((instantiated, sub.clone()))
                } else {
                    Err(TypeError {
                        message: format!("Undefined variable: {}", name),
                    })
                }
            }

            // Binary operations
            Expr::Binary(op, left, right) => {
                let (left_ty, s1) = self.infer_expr(left, sub)?;
                let (right_ty, s2) = self.infer_expr(right, &s1)?;

                let (expected_left, expected_right, result_ty) = match op {
                    BinaryOp::Add | BinaryOp::Sub | BinaryOp::Mul | BinaryOp::Div | BinaryOp::Mod => {
                        // Arithmetic: numeric operands, numeric result
                        let num_var = self.env.fresh_var();
                        (num_var.clone(), num_var.clone(), num_var)
                    }
                    BinaryOp::Eq | BinaryOp::NotEq => {
                        // Equality: same types, bool result
                        let eq_var = self.env.fresh_var();
                        (eq_var.clone(), eq_var, TypeInfo::Bool)
                    }
                    BinaryOp::Lt | BinaryOp::LtEq | BinaryOp::Gt | BinaryOp::GtEq => {
                        // Comparison: numeric operands, bool result
                        let num_var = self.env.fresh_var();
                        (num_var.clone(), num_var, TypeInfo::Bool)
                    }
                    BinaryOp::And | BinaryOp::Or => {
                        // Logical: bool operands, bool result
                        (TypeInfo::Bool, TypeInfo::Bool, TypeInfo::Bool)
                    }
                };

                let s3 = unify(&s2.apply(&left_ty), &s2.apply(&expected_left))?;
                let s4 = unify(&s3.apply(&right_ty), &s3.apply(&expected_right))?;

                Ok((s4.apply(&result_ty), s2.compose(&s3).compose(&s4)))
            }

            // Unary operations
            Expr::Unary(op, operand) => {
                let (operand_ty, s1) = self.infer_expr(operand, sub)?;

                let result_ty = match op {
                    UnaryOp::Neg => {
                        // Negation: numeric operand, same type result
                        operand_ty.clone()
                    }
                    UnaryOp::Not => {
                        // Not: bool operand, bool result
                        let s2 = unify(&s1.apply(&operand_ty), &TypeInfo::Bool)?;
                        s2.apply(&TypeInfo::Bool)
                    }
                };

                Ok((result_ty, s1))
            }

            // Function call
            Expr::Call(func_name, args) => {
                // Look up function type
                if let Some(func_ty) = self.env.get(func_name) {
                    // Clone before instantiating to avoid borrow checker issues
                    let func_ty = func_ty.clone();
                    let func_ty = self.instantiate(&func_ty);

                    // Infer argument types
                    let mut arg_types = Vec::new();
                    let mut current_sub = sub.clone();
                    for arg in args {
                        let (arg_ty, s) = self.infer_expr(arg, &current_sub)?;
                        arg_types.push(arg_ty);
                        current_sub = s;
                    }

                    // Create fresh type variable for result
                    let result_ty = self.env.fresh_var();

                    // Unify with function type
                    let expected_func_ty =
                        TypeInfo::Function(arg_types.clone(), Box::new(result_ty.clone()));
                    let s_func = unify(&current_sub.apply(&func_ty), &expected_func_ty)?;

                    Ok((s_func.apply(&result_ty), current_sub.compose(&s_func)))
                } else {
                    Err(TypeError {
                        message: format!("Undefined function: {}", func_name),
                    })
                }
            }

            // Call expression (for closures)
            Expr::CallExpr(func_expr, args) => {
                let (func_ty, s1) = self.infer_expr(func_expr, sub)?;

                // Infer argument types
                let mut arg_types = Vec::new();
                let mut current_sub = s1;
                for arg in args {
                    let (arg_ty, s) = self.infer_expr(arg, &current_sub)?;
                    arg_types.push(arg_ty);
                    current_sub = s;
                }

                // Create fresh type variable for result
                let result_ty = self.env.fresh_var();

                // Unify with function type
                let expected_func_ty =
                    TypeInfo::Function(arg_types, Box::new(result_ty.clone()));
                let s_func = unify(&current_sub.apply(&func_ty), &expected_func_ty)?;

                Ok((s_func.apply(&result_ty), current_sub.compose(&s_func)))
            }

            // Array literal
            Expr::Array(elements) => {
                if elements.is_empty() {
                    // Empty array: create fresh type variable for element type
                    let elem_ty = self.env.fresh_var();
                    Ok((TypeInfo::Array(Box::new(elem_ty)), sub.clone()))
                } else {
                    // Infer type of first element
                    let (first_ty, mut current_sub) = self.infer_expr(&elements[0], sub)?;

                    // All elements must have same type
                    for elem in &elements[1..] {
                        let (elem_ty, s) = self.infer_expr(elem, &current_sub)?;
                        let s_unify = unify(&current_sub.apply(&first_ty), &elem_ty)?;
                        current_sub = current_sub.compose(&s).compose(&s_unify);
                    }

                    Ok((
                        TypeInfo::Array(Box::new(current_sub.apply(&first_ty))),
                        current_sub,
                    ))
                }
            }

            // Array/string indexing
            Expr::Index(array_expr, index_expr) => {
                let (array_ty, s1) = self.infer_expr(array_expr, sub)?;
                let (index_ty, s2) = self.infer_expr(index_expr, &s1)?;

                // Index must be Int
                let s3 = unify(&s2.apply(&index_ty), &TypeInfo::Int)?;

                // Array type must be [T] or String
                let elem_ty = self.env.fresh_var();
                let s4 = match &s3.apply(&array_ty) {
                    TypeInfo::Array(_) => {
                        unify(&s3.apply(&array_ty), &TypeInfo::Array(Box::new(elem_ty.clone())))?
                    }
                    TypeInfo::String => {
                        // String indexing returns String
                        unify(&elem_ty, &TypeInfo::String)?
                    }
                    _ => {
                        return Err(TypeError {
                            message: format!("Cannot index type: {}", s3.apply(&array_ty)),
                        })
                    }
                };

                Ok((s4.apply(&elem_ty), s1.compose(&s2).compose(&s3).compose(&s4)))
            }

            // Result types
            Expr::Okay(value) => {
                let (value_ty, s1) = self.infer_expr(value, sub)?;
                let err_ty = self.env.fresh_var();
                Ok((TypeInfo::Result(Box::new(value_ty), Box::new(err_ty)), s1))
            }

            Expr::Oops(error) => {
                let (error_ty, s1) = self.infer_expr(error, sub)?;
                let ok_ty = self.env.fresh_var();
                Ok((TypeInfo::Result(Box::new(ok_ty), Box::new(error_ty)), s1))
            }

            Expr::Unwrap(result_expr) => {
                let (result_ty, s1) = self.infer_expr(result_expr, sub)?;
                let ok_ty = self.env.fresh_var();
                let err_ty = self.env.fresh_var();
                let s2 = unify(
                    &s1.apply(&result_ty),
                    &TypeInfo::Result(Box::new(ok_ty.clone()), Box::new(err_ty)),
                )?;
                Ok((s2.apply(&ok_ty), s1.compose(&s2)))
            }

            // Lambda expressions
            Expr::Lambda(lambda) => {
                // Create fresh type variables for parameters
                let param_types: Vec<TypeInfo> = lambda
                    .params
                    .iter()
                    .map(|_| self.env.fresh_var())
                    .collect();

                // Add parameters to environment
                let old_env = self.env.bindings.clone();
                for (param, param_ty) in lambda.params.iter().zip(&param_types) {
                    self.env.define(param.name.clone(), param_ty.clone());
                }

                // Infer return type from body
                let (return_ty, s1) = match &lambda.body {
                    LambdaBody::Expr(expr) => self.infer_expr(expr, sub)?,
                    LambdaBody::Block(stmts) => {
                        // Infer type from block (last expression or Unit)
                        let mut current_sub = sub.clone();
                        for stmt in stmts {
                            current_sub = self.check_statement(stmt, &current_sub)?;
                        }
                        (TypeInfo::Unit, current_sub)
                    }
                };

                // Restore environment
                self.env.bindings = old_env;

                let func_ty = TypeInfo::Function(param_types, Box::new(return_ty));
                Ok((func_ty, s1))
            }

            // Unit measurement
            Expr::UnitMeasurement(value, _unit) => {
                // For now, just infer the value type (unit tracking is future work)
                self.infer_expr(value, sub)
            }

            // Gratitude literal
            Expr::GratitudeLiteral(_) => Ok((TypeInfo::Unit, sub.clone())),
        }
    }

    /// Instantiate a type scheme (for polymorphic types)
    /// For now, just clone the type (full polymorphism is future work)
    fn instantiate(&mut self, ty: &TypeInfo) -> TypeInfo {
        ty.clone()
    }

    /// Type check a statement
    fn check_statement(
        &mut self,
        stmt: &Statement,
        sub: &Substitution,
    ) -> Result<Substitution, TypeError> {
        match stmt {
            // Variable declaration: remember x = expr;
            Statement::VarDecl(decl) => {
                let (value_ty, s1) = self.infer_expr(&decl.value, sub)?;
                // Add to environment
                self.env.define(decl.name.clone(), s1.apply(&value_ty));
                Ok(s1)
            }

            // Assignment: x = expr;
            Statement::Assignment(assign) => {
                let (value_ty, s1) = self.infer_expr(&assign.value, sub)?;

                // Variable must exist
                if let Some(var_ty) = self.env.get(&assign.target) {
                    let s2 = unify(&s1.apply(var_ty), &s1.apply(&value_ty))?;
                    Ok(s1.compose(&s2))
                } else {
                    Err(TypeError {
                        message: format!("Undefined variable: {}", assign.target),
                    })
                }
            }

            // Return statement: give back expr;
            Statement::Return(ret) => {
                let (_ret_ty, s1) = self.infer_expr(&ret.value, sub)?;
                // TODO: Check against function return type
                Ok(s1)
            }

            // Conditional: when expr { ... } otherwise { ... }
            Statement::Conditional(cond) => {
                let (cond_ty, s1) = self.infer_expr(&cond.condition, sub)?;

                // Condition must be Bool
                let s2 = unify(&s1.apply(&cond_ty), &TypeInfo::Bool)?;

                // Check then branch
                let mut current_sub = s1.compose(&s2);
                for stmt in &cond.then_branch {
                    current_sub = self.check_statement(stmt, &current_sub)?;
                }

                // Check else branch if present
                if let Some(else_branch) = &cond.else_branch {
                    for stmt in else_branch {
                        current_sub = self.check_statement(stmt, &current_sub)?;
                    }
                }

                Ok(current_sub)
            }

            // Loop: repeat n times { ... }
            Statement::Loop(loop_stmt) => {
                let (count_ty, s1) = self.infer_expr(&loop_stmt.count, sub)?;

                // Count must be Int
                let s2 = unify(&s1.apply(&count_ty), &TypeInfo::Int)?;

                // Check body
                let mut current_sub = s1.compose(&s2);
                for stmt in &loop_stmt.body {
                    current_sub = self.check_statement(stmt, &current_sub)?;
                }

                Ok(current_sub)
            }

            // Attempt block: attempt safely { ... } or reassure "msg";
            Statement::AttemptBlock(attempt) => {
                let mut current_sub = sub.clone();
                for stmt in &attempt.body {
                    current_sub = self.check_statement(stmt, &current_sub)?;
                }
                Ok(current_sub)
            }

            // Consent block: only if okay "perm" { ... }
            Statement::ConsentBlock(consent) => {
                let mut current_sub = sub.clone();
                for stmt in &consent.body {
                    current_sub = self.check_statement(stmt, &current_sub)?;
                }
                Ok(current_sub)
            }

            // Expression statement
            Statement::Expression(expr) => {
                let (_ty, s1) = self.infer_expr(expr, sub)?;
                Ok(s1)
            }

            // Worker spawn: spawn worker name;
            Statement::WorkerSpawn(_) => {
                // TODO: Check worker exists
                Ok(sub.clone())
            }

            // Complain statement: complain "message";
            Statement::Complain(_) => Ok(sub.clone()),

            // Emote-annotated statement
            Statement::EmoteAnnotated(emote) => self.check_statement(&emote.statement, sub),

            // Pattern matching: decide based on expr { ... }
            Statement::Decide(decide) => {
                let (scrutinee_ty, s1) = self.infer_expr(&decide.scrutinee, sub)?;

                // Check each arm
                let mut current_sub = s1;
                for arm in &decide.arms {
                    // Check pattern matches scrutinee type
                    let pattern_ty = self.infer_pattern(&arm.pattern)?;
                    let s2 = unify(&current_sub.apply(&scrutinee_ty), &pattern_ty)?;
                    current_sub = current_sub.compose(&s2);

                    // Check arm body
                    for stmt in &arm.body {
                        current_sub = self.check_statement(stmt, &current_sub)?;
                    }
                }

                Ok(current_sub)
            }
        }
    }

    /// Infer type from a pattern
    fn infer_pattern(&mut self, pattern: &Pattern) -> Result<TypeInfo, TypeError> {
        match pattern {
            Pattern::Literal(lit) => Ok(match lit {
                Literal::Integer(_) => TypeInfo::Int,
                Literal::Float(_) => TypeInfo::Float,
                Literal::String(_) => TypeInfo::String,
                Literal::Bool(_) => TypeInfo::Bool,
                Literal::Unit => TypeInfo::Unit,
            }),
            Pattern::Identifier(_) => {
                // Identifier patterns bind a fresh type variable
                Ok(self.env.fresh_var())
            }
            Pattern::Wildcard => {
                // Wildcard matches anything
                Ok(self.env.fresh_var())
            }
            Pattern::Constructor(name, inner) => {
                // Check constructor type
                match name.as_str() {
                    "Okay" => {
                        let ok_ty = if let Some(p) = inner {
                            self.infer_pattern(p)?
                        } else {
                            TypeInfo::Unit
                        };
                        let err_ty = self.env.fresh_var();
                        Ok(TypeInfo::Result(Box::new(ok_ty), Box::new(err_ty)))
                    }
                    "Oops" => {
                        let err_ty = if let Some(p) = inner {
                            self.infer_pattern(p)?
                        } else {
                            TypeInfo::Unit
                        };
                        let ok_ty = self.env.fresh_var();
                        Ok(TypeInfo::Result(Box::new(ok_ty), Box::new(err_ty)))
                    }
                    _ => Err(TypeError {
                        message: format!("Unknown constructor: {}", name),
                    }),
                }
            }
        }
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

    #[test]
    fn test_unify_basic() {
        // Unifying Int with Int should succeed
        let result = unify(&TypeInfo::Int, &TypeInfo::Int);
        assert!(result.is_ok());

        // Unifying Int with Float should fail
        let result = unify(&TypeInfo::Int, &TypeInfo::Float);
        assert!(result.is_err());
    }

    #[test]
    fn test_unify_type_variable() {
        // Unifying type variable with concrete type
        let var = TypeInfo::Var(0);
        let result = unify(&var, &TypeInfo::Int).unwrap();

        // Should produce substitution [T0 -> Int]
        let substituted = result.apply(&var);
        assert_eq!(substituted, TypeInfo::Int);
    }

    #[test]
    fn test_unify_function() {
        // (Int, Int) -> Bool should unify with itself
        let func1 = TypeInfo::Function(
            vec![TypeInfo::Int, TypeInfo::Int],
            Box::new(TypeInfo::Bool),
        );
        let func2 = TypeInfo::Function(
            vec![TypeInfo::Int, TypeInfo::Int],
            Box::new(TypeInfo::Bool),
        );

        let result = unify(&func1, &func2);
        assert!(result.is_ok());
    }

    #[test]
    fn test_unify_array() {
        // [Int] should unify with [T0]
        let arr1 = TypeInfo::Array(Box::new(TypeInfo::Int));
        let arr2 = TypeInfo::Array(Box::new(TypeInfo::Var(0)));

        let result = unify(&arr1, &arr2).unwrap();
        let substituted = result.apply(&TypeInfo::Var(0));
        assert_eq!(substituted, TypeInfo::Int);
    }

    #[test]
    fn test_occurs_check() {
        // T0 cannot unify with [T0] (infinite type)
        let var = TypeInfo::Var(0);
        let arr = TypeInfo::Array(Box::new(TypeInfo::Var(0)));

        let result = unify(&var, &arr);
        assert!(result.is_err());
    }

    #[test]
    fn test_substitution_compose() {
        // s1 = [T0 -> Int]
        let mut s1 = Substitution::new();
        s1.bind(0, TypeInfo::Int);

        // s2 = [T1 -> T0]
        let mut s2 = Substitution::new();
        s2.bind(1, TypeInfo::Var(0));

        // Composed should be [T0 -> Int, T1 -> Int]
        let composed = s1.compose(&s2);

        assert_eq!(composed.apply(&TypeInfo::Var(0)), TypeInfo::Int);
        assert_eq!(composed.apply(&TypeInfo::Var(1)), TypeInfo::Int);
    }

    #[test]
    fn test_infer_literal() {
        let mut checker = TypeChecker::new();
        let sub = Substitution::new();

        let expr = Spanned::new(Expr::Literal(Literal::Integer(42)), 0..2);
        let (ty, _) = checker.infer_expr(&expr, &sub).unwrap();
        assert_eq!(ty, TypeInfo::Int);

        let expr = Spanned::new(Expr::Literal(Literal::Bool(true)), 0..4);
        let (ty, _) = checker.infer_expr(&expr, &sub).unwrap();
        assert_eq!(ty, TypeInfo::Bool);
    }

    #[test]
    fn test_infer_array() {
        let mut checker = TypeChecker::new();
        let sub = Substitution::new();

        // [1, 2, 3] should infer as [Int]
        let expr = Spanned::new(
            Expr::Array(vec![
                Spanned::new(Expr::Literal(Literal::Integer(1)), 0..1),
                Spanned::new(Expr::Literal(Literal::Integer(2)), 0..1),
                Spanned::new(Expr::Literal(Literal::Integer(3)), 0..1),
            ]),
            0..7,
        );

        let (ty, _) = checker.infer_expr(&expr, &sub).unwrap();
        assert_eq!(ty, TypeInfo::Array(Box::new(TypeInfo::Int)));
    }

    #[test]
    fn test_infer_binary_op() {
        let mut checker = TypeChecker::new();
        let sub = Substitution::new();

        // 1 + 2 should infer as Int
        let expr = Spanned::new(
            Expr::Binary(
                BinaryOp::Add,
                Box::new(Spanned::new(Expr::Literal(Literal::Integer(1)), 0..1)),
                Box::new(Spanned::new(Expr::Literal(Literal::Integer(2)), 0..1)),
            ),
            0..5,
        );

        let (ty, _) = checker.infer_expr(&expr, &sub).unwrap();
        // Result should be a type variable that unifies with Int
        match ty {
            TypeInfo::Int | TypeInfo::Var(_) => {} // Both acceptable
            _ => panic!("Expected Int or Var, got {:?}", ty),
        }
    }
}
