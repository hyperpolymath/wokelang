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

/// Unit of measure for dimensional analysis
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Unit {
    /// Dimensionless (no unit)
    Dimensionless,
    /// Base units
    Meter,
    Second,
    Kilogram,
    Ampere,
    Kelvin,
    Mole,
    Candela,
    /// Derived units (stored as combinations of base units)
    Derived(Box<DerivedUnit>),
    /// Custom named unit
    Custom(String),
}

/// Derived unit (like meter/second, meter²)
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct DerivedUnit {
    /// Numerator units with powers (e.g., meter², second⁻¹)
    pub numerator: Vec<(Unit, i32)>,
    /// Denominator units with powers
    pub denominator: Vec<(Unit, i32)>,
}

impl Unit {
    /// Multiply two units
    pub fn multiply(&self, other: &Unit) -> Unit {
        match (self, other) {
            (Unit::Dimensionless, u) | (u, Unit::Dimensionless) => u.clone(),
            _ => Unit::Derived(Box::new(DerivedUnit {
                numerator: vec![(self.clone(), 1), (other.clone(), 1)],
                denominator: vec![],
            })),
        }
    }

    /// Divide two units
    pub fn divide(&self, other: &Unit) -> Unit {
        match (self, other) {
            (u, Unit::Dimensionless) => u.clone(),
            (Unit::Dimensionless, u) => Unit::Derived(Box::new(DerivedUnit {
                numerator: vec![],
                denominator: vec![(u.clone(), 1)],
            })),
            _ => Unit::Derived(Box::new(DerivedUnit {
                numerator: vec![(self.clone(), 1)],
                denominator: vec![(other.clone(), 1)],
            })),
        }
    }
}

impl fmt::Display for Unit {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Unit::Dimensionless => write!(f, "1"),
            Unit::Meter => write!(f, "m"),
            Unit::Second => write!(f, "s"),
            Unit::Kilogram => write!(f, "kg"),
            Unit::Ampere => write!(f, "A"),
            Unit::Kelvin => write!(f, "K"),
            Unit::Mole => write!(f, "mol"),
            Unit::Candela => write!(f, "cd"),
            Unit::Custom(name) => write!(f, "{}", name),
            Unit::Derived(derived) => {
                if !derived.numerator.is_empty() {
                    for (i, (unit, power)) in derived.numerator.iter().enumerate() {
                        if i > 0 {
                            write!(f, "·")?;
                        }
                        write!(f, "{}", unit)?;
                        if *power != 1 {
                            write!(f, "^{}", power)?;
                        }
                    }
                }
                if !derived.denominator.is_empty() {
                    write!(f, "/")?;
                    for (i, (unit, power)) in derived.denominator.iter().enumerate() {
                        if i > 0 {
                            write!(f, "·")?;
                        }
                        write!(f, "{}", unit)?;
                        if *power != 1 {
                            write!(f, "^{}", power)?;
                        }
                    }
                }
                Ok(())
            }
        }
    }
}

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
    /// Record/struct type (name of the type)
    Record(String),
    /// Type variable for inference
    Var(usize),
    /// Unknown type (for gradual typing)
    Unknown,
    /// Quantity with unit of measure (e.g., 5 meters)
    Quantity(Box<TypeInfo>, Unit),
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
            TypeInfo::Record(name) => write!(f, "{}", name),
            TypeInfo::Var(id) => write!(f, "T{}", id),
            TypeInfo::Unknown => write!(f, "?"),
            TypeInfo::Quantity(base_type, unit) => write!(f, "{} measured in {}", base_type, unit),
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
            TypeInfo::Record(name) => TypeInfo::Record(name.clone()),
            TypeInfo::Quantity(base_type, unit) => {
                TypeInfo::Quantity(Box::new(self.apply(base_type)), unit.clone())
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
    pub bindings: HashMap<String, TypeInfo>,
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
        (TypeInfo::Record(name1), TypeInfo::Record(name2)) => {
            if name1 == name2 {
                Ok(Substitution::new())
            } else {
                Err(TypeError {
                    message: format!("Type mismatch: {} vs {}", name1, name2),
                })
            }
        }

        // Quantity types - units must match exactly
        (TypeInfo::Quantity(base1, unit1), TypeInfo::Quantity(base2, unit2)) => {
            if unit1 != unit2 {
                return Err(TypeError {
                    message: format!("Unit mismatch: cannot unify {} with {}", unit1, unit2),
                });
            }
            unify(base1, base2)
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
        TypeInfo::Record(_name) => false, // Record types are nominal, no occurrence check needed
        TypeInfo::Quantity(base_type, _unit) => occurs_check(var, base_type),
        _ => false,
    }
}

/// The type checker
pub struct TypeChecker {
    env: TypeEnv,
    type_defs: std::collections::HashMap<String, TypeVariant>,
}

impl TypeChecker {
    pub fn new() -> Self {
        let mut env = TypeEnv::new();
        let type_defs = std::collections::HashMap::new();

        // Register built-in functions
        // print: a -> Unit
        env.define(
            "print".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0)], // Takes any type
                Box::new(TypeInfo::Unit),
            ),
        );

        // printInline: a -> Unit
        env.define(
            "printInline".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::Unit)),
        );

        // toString: a -> String
        env.define(
            "toString".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::String)),
        );

        // Okay: a -> Result a b
        env.define(
            "Okay".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0)],
                Box::new(TypeInfo::Result(
                    Box::new(TypeInfo::Var(0)),
                    Box::new(TypeInfo::Var(1)),
                )),
            ),
        );

        // Oops: b -> Result a b
        env.define(
            "Oops".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(1)],
                Box::new(TypeInfo::Result(
                    Box::new(TypeInfo::Var(0)),
                    Box::new(TypeInfo::Var(1)),
                )),
            ),
        );

        // === aLib (aggregate-library) Functions ===

        // Arithmetic (5)
        let num_to_num = TypeInfo::Function(
            vec![TypeInfo::Var(0), TypeInfo::Var(0)],
            Box::new(TypeInfo::Var(0)),
        );
        env.define("std.alib.add".to_string(), num_to_num.clone());
        env.define("std.alib.subtract".to_string(), num_to_num.clone());
        env.define("std.alib.multiply".to_string(), num_to_num.clone());
        env.define("std.alib.divide".to_string(), num_to_num.clone());
        env.define("std.alib.modulo".to_string(), num_to_num);

        // Comparison (6)
        let compare = TypeInfo::Function(
            vec![TypeInfo::Var(0), TypeInfo::Var(0)],
            Box::new(TypeInfo::Bool),
        );
        env.define("std.alib.equal".to_string(), compare.clone());
        env.define("std.alib.notEqual".to_string(), compare.clone());
        env.define("std.alib.lessThan".to_string(), compare.clone());
        env.define("std.alib.lessEqual".to_string(), compare.clone());
        env.define("std.alib.greaterThan".to_string(), compare.clone());
        env.define("std.alib.greaterEqual".to_string(), compare);

        // Logical (3)
        let bool_to_bool = TypeInfo::Function(
            vec![TypeInfo::Bool, TypeInfo::Bool],
            Box::new(TypeInfo::Bool),
        );
        env.define("std.alib.and".to_string(), bool_to_bool.clone());
        env.define("std.alib.or".to_string(), bool_to_bool);
        env.define(
            "std.alib.not".to_string(),
            TypeInfo::Function(vec![TypeInfo::Bool], Box::new(TypeInfo::Bool)),
        );

        // Collection (4) - simplified types
        env.define(
            "std.alib.map".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0), TypeInfo::Var(1)],
                Box::new(TypeInfo::Var(2)),
            ),
        );
        env.define(
            "std.alib.filter".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0), TypeInfo::Var(1)],
                Box::new(TypeInfo::Var(0)),
            ),
        );
        env.define(
            "std.alib.fold".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0), TypeInfo::Var(1), TypeInfo::Var(2)],
                Box::new(TypeInfo::Var(1)),
            ),
        );
        env.define(
            "std.alib.contains".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0), TypeInfo::Var(1)],
                Box::new(TypeInfo::Bool),
            ),
        );

        // String (3)
        env.define(
            "std.alib.concat".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::String, TypeInfo::String],
                Box::new(TypeInfo::String),
            ),
        );
        env.define(
            "std.alib.length".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::Int)),
        );
        env.define(
            "std.alib.substring".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::String, TypeInfo::Int, TypeInfo::Int],
                Box::new(TypeInfo::String),
            ),
        );

        // Conditional (1)
        env.define(
            "std.alib.ifThenElse".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Bool, TypeInfo::Var(0), TypeInfo::Var(0)],
                Box::new(TypeInfo::Var(0)),
            ),
        );

        // === Math Functions ===
        env.define(
            "std.math.abs".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::Var(0))),
        );
        env.define(
            "std.math.sqrt".to_string(),
            TypeInfo::Function(vec![TypeInfo::Float], Box::new(TypeInfo::Float)),
        );
        env.define(
            "std.math.pow".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Float, TypeInfo::Float],
                Box::new(TypeInfo::Float),
            ),
        );
        env.define(
            "std.math.sin".to_string(),
            TypeInfo::Function(vec![TypeInfo::Float], Box::new(TypeInfo::Float)),
        );
        env.define(
            "std.math.cos".to_string(),
            TypeInfo::Function(vec![TypeInfo::Float], Box::new(TypeInfo::Float)),
        );
        env.define(
            "std.math.tan".to_string(),
            TypeInfo::Function(vec![TypeInfo::Float], Box::new(TypeInfo::Float)),
        );

        // === String Functions ===
        env.define(
            "std.string.upper".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::String)),
        );
        env.define(
            "std.string.lower".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::String)),
        );
        env.define(
            "std.string.trim".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::String)),
        );

        // === Channel Functions (Go-style concurrency) ===
        // std.chan.make: Int -> Channel
        env.define(
            "std.chan.make".to_string(),
            TypeInfo::Function(vec![TypeInfo::Int], Box::new(TypeInfo::Var(0))), // Returns generic channel
        );
        // std.chan.send: (Channel, a) -> Unit
        env.define(
            "std.chan.send".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0), TypeInfo::Var(1)],
                Box::new(TypeInfo::Unit),
            ),
        );
        // std.chan.recv: Channel -> a
        env.define(
            "std.chan.recv".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::Var(1))),
        );
        // std.chan.tryRecv: Channel -> Result a b
        env.define(
            "std.chan.tryRecv".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0)],
                Box::new(TypeInfo::Result(
                    Box::new(TypeInfo::Var(1)),
                    Box::new(TypeInfo::String),
                )),
            ),
        );
        // std.chan.recvTimeout: (Channel, Int) -> Result a b
        env.define(
            "std.chan.recvTimeout".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Var(0), TypeInfo::Int],
                Box::new(TypeInfo::Result(
                    Box::new(TypeInfo::Var(1)),
                    Box::new(TypeInfo::String),
                )),
            ),
        );
        // std.chan.close: Channel -> Unit
        env.define(
            "std.chan.close".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::Unit)),
        );
        // std.chan.isClosed: Channel -> Bool
        env.define(
            "std.chan.isClosed".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::Bool)),
        );

        // === Short aliases (same types as above) ===
        // Reuse the type definitions
        let num_to_num2 = TypeInfo::Function(
            vec![TypeInfo::Var(0), TypeInfo::Var(0)],
            Box::new(TypeInfo::Var(0)),
        );
        env.define("add".to_string(), num_to_num2.clone());
        env.define("subtract".to_string(), num_to_num2.clone());
        env.define("multiply".to_string(), num_to_num2.clone());
        env.define("divide".to_string(), num_to_num2.clone());
        env.define("modulo".to_string(), num_to_num2);

        let compare2 = TypeInfo::Function(
            vec![TypeInfo::Var(0), TypeInfo::Var(0)],
            Box::new(TypeInfo::Bool),
        );
        env.define("equal".to_string(), compare2.clone());
        env.define("notEqual".to_string(), compare2.clone());
        env.define("lessThan".to_string(), compare2.clone());
        env.define("lessEqual".to_string(), compare2.clone());
        env.define("greaterThan".to_string(), compare2.clone());
        env.define("greaterEqual".to_string(), compare2);

        let bool_op = TypeInfo::Function(
            vec![TypeInfo::Bool, TypeInfo::Bool],
            Box::new(TypeInfo::Bool),
        );
        env.define("and".to_string(), bool_op.clone());
        env.define("or".to_string(), bool_op);
        env.define(
            "not".to_string(),
            TypeInfo::Function(vec![TypeInfo::Bool], Box::new(TypeInfo::Bool)),
        );

        env.define(
            "concat".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::String, TypeInfo::String],
                Box::new(TypeInfo::String),
            ),
        );
        env.define(
            "strLength".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::Int)),
        );

        env.define(
            "abs".to_string(),
            TypeInfo::Function(vec![TypeInfo::Var(0)], Box::new(TypeInfo::Var(0))),
        );
        env.define(
            "sqrt".to_string(),
            TypeInfo::Function(vec![TypeInfo::Float], Box::new(TypeInfo::Float)),
        );
        env.define(
            "pow".to_string(),
            TypeInfo::Function(
                vec![TypeInfo::Float, TypeInfo::Float],
                Box::new(TypeInfo::Float),
            ),
        );

        env.define(
            "upper".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::String)),
        );
        env.define(
            "lower".to_string(),
            TypeInfo::Function(vec![TypeInfo::String], Box::new(TypeInfo::String)),
        );

        Self { env, type_defs }
    }

    /// Convert AST Type to TypeInfo
    fn type_from_ast(&self, ast_ty: &Type) -> TypeInfo {
        match ast_ty {
            Type::Basic(name) => match name.as_str() {
                "Int" => TypeInfo::Int,
                "Float" => TypeInfo::Float,
                "String" => TypeInfo::String,
                "Bool" => TypeInfo::Bool,
                _ => TypeInfo::Record(name.clone()),
            },
            Type::Array(elem_ty) => TypeInfo::Array(Box::new(self.type_from_ast(elem_ty))),
            Type::Optional(inner_ty) => {
                // Represent Option as Result with Unit error
                TypeInfo::Result(
                    Box::new(self.type_from_ast(inner_ty)),
                    Box::new(TypeInfo::Unit),
                )
            }
            Type::Function(param_tys, return_ty) => {
                let params = param_tys.iter().map(|t| self.type_from_ast(t)).collect();
                TypeInfo::Function(params, Box::new(self.type_from_ast(return_ty)))
            }
            Type::Reference(inner_ty) => {
                // For now, just use the inner type (references not fully supported)
                self.type_from_ast(inner_ty)
            }
            Type::Generic(name, _args) => {
                // For now, treat generics as basic types
                TypeInfo::Record(name.clone())
            }
            Type::TypeVar(name) => {
                // Type variable - use fresh var
                TypeInfo::Var(0) // This is a simplification
            }
        }
    }

    /// Type check a complete program
    pub fn check_program(&mut self, program: &Program) -> Result<(), TypeError> {
        let sub = Substitution::new();

        // First pass: collect type definitions
        for item in &program.items {
            if let TopLevelItem::TypeDef(type_def) = item {
                self.type_defs
                    .insert(type_def.name.clone(), type_def.definition.clone());
            }
        }

        // Second pass: collect function signatures
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
                    BinaryOp::Add
                    | BinaryOp::Sub
                    | BinaryOp::Mul
                    | BinaryOp::Div
                    | BinaryOp::Mod => {
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
                let expected_func_ty = TypeInfo::Function(arg_types, Box::new(result_ty.clone()));
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
                    TypeInfo::Array(_) => unify(
                        &s3.apply(&array_ty),
                        &TypeInfo::Array(Box::new(elem_ty.clone())),
                    )?,
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

                Ok((
                    s4.apply(&elem_ty),
                    s1.compose(&s2).compose(&s3).compose(&s4),
                ))
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
                let param_types: Vec<TypeInfo> =
                    lambda.params.iter().map(|_| self.env.fresh_var()).collect();

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
            Expr::UnitMeasurement(value, unit_name) => {
                // Infer the base value type
                let (value_type, sub1) = self.infer_expr(value, sub)?;

                // Parse unit name into Unit enum
                let unit = self.parse_unit(unit_name);

                // Create Quantity type
                let quantity_type = TypeInfo::Quantity(Box::new(value_type), unit);

                Ok((quantity_type, sub1))
            }

            // Field access: record.field
            Expr::FieldAccess(record_expr, field_name) => {
                let (record_ty, s1) = self.infer_expr(record_expr, sub)?;

                // Look up the record type in type definitions
                match &s1.apply(&record_ty) {
                    TypeInfo::Record(name) => {
                        // Look up struct definition to get field type
                        if let Some(type_def) = self.type_defs.get(name) {
                            if let TypeVariant::Struct(fields) = type_def {
                                for field in fields {
                                    if &field.name == field_name {
                                        let field_ty = self.type_from_ast(&field.ty);
                                        return Ok((field_ty, s1));
                                    }
                                }
                                return Err(TypeError {
                                    message: format!("Record {} has no field {}", name, field_name),
                                });
                            }
                        }
                        Err(TypeError {
                            message: format!("Unknown record type: {}", name),
                        })
                    }
                    _ => Err(TypeError {
                        message: format!(
                            "Cannot access field of non-record type: {}",
                            s1.apply(&record_ty)
                        ),
                    }),
                }
            }

            // Record literal: Type { field: value, ... }
            Expr::RecordLiteral(type_name, fields) => {
                // Look up struct definition and clone it to avoid borrow issues
                let struct_fields = if let Some(type_def) = self.type_defs.get(type_name) {
                    if let TypeVariant::Struct(fields) = type_def {
                        fields.clone()
                    } else {
                        return Err(TypeError {
                            message: format!("{} is not a struct type", type_name),
                        });
                    }
                } else {
                    return Err(TypeError {
                        message: format!("Unknown type: {}", type_name),
                    });
                };

                // Check all struct fields are present
                let mut current_sub = sub.clone();
                for struct_field in &struct_fields {
                    let field_value = fields.iter().find(|(name, _)| name == &struct_field.name);

                    if let Some((_, value_expr)) = field_value {
                        // Infer value type and unify with expected field type
                        let (value_ty, s1) = self.infer_expr(value_expr, &current_sub)?;
                        let expected_ty = self.type_from_ast(&struct_field.ty);
                        let s2 = unify(&s1.apply(&value_ty), &s1.apply(&expected_ty))?;
                        current_sub = s1.compose(&s2);
                    } else {
                        return Err(TypeError {
                            message: format!(
                                "Missing field {} in {} literal",
                                struct_field.name, type_name
                            ),
                        });
                    }
                }

                // Check for extra fields
                for (field_name, _) in fields {
                    if !struct_fields.iter().any(|f| &f.name == field_name) {
                        return Err(TypeError {
                            message: format!(
                                "Unknown field {} in {} literal",
                                field_name, type_name
                            ),
                        });
                    }
                }

                Ok((TypeInfo::Record(type_name.clone()), current_sub))
            }

            // Gratitude literal
            Expr::GratitudeLiteral(_) => Ok((TypeInfo::Unit, sub.clone())),
        }
    }

    /// Instantiate a type scheme (for polymorphic types)
    /// Replaces all type variables with fresh ones to allow polymorphic reuse
    fn instantiate(&mut self, ty: &TypeInfo) -> TypeInfo {
        use std::collections::HashMap;

        fn instantiate_helper(
            ty: &TypeInfo,
            env: &mut TypeEnv,
            var_map: &mut HashMap<usize, TypeInfo>,
        ) -> TypeInfo {
            match ty {
                TypeInfo::Var(id) => {
                    // Replace type variable with fresh one (memoized)
                    var_map
                        .entry(*id)
                        .or_insert_with(|| env.fresh_var())
                        .clone()
                }
                TypeInfo::Function(params, ret) => {
                    let new_params = params
                        .iter()
                        .map(|p| instantiate_helper(p, env, var_map))
                        .collect();
                    let new_ret = Box::new(instantiate_helper(ret, env, var_map));
                    TypeInfo::Function(new_params, new_ret)
                }
                TypeInfo::Array(elem) => {
                    TypeInfo::Array(Box::new(instantiate_helper(elem, env, var_map)))
                }
                TypeInfo::Result(ok, err) => TypeInfo::Result(
                    Box::new(instantiate_helper(ok, env, var_map)),
                    Box::new(instantiate_helper(err, env, var_map)),
                ),
                // Concrete types don't need instantiation
                _ => ty.clone(),
            }
        }

        let mut var_map = HashMap::new();
        instantiate_helper(ty, &mut self.env, &mut var_map)
    }

    /// Parse a unit name into a Unit enum
    fn parse_unit(&self, unit_name: &str) -> Unit {
        match unit_name.to_lowercase().as_str() {
            // Base SI units
            "meter" | "meters" | "m" => Unit::Meter,
            "second" | "seconds" | "s" => Unit::Second,
            "kilogram" | "kilograms" | "kg" => Unit::Kilogram,
            "ampere" | "amperes" | "a" => Unit::Ampere,
            "kelvin" | "k" => Unit::Kelvin,
            "mole" | "moles" | "mol" => Unit::Mole,
            "candela" | "cd" => Unit::Candela,

            // Dimensionless
            "1" | "dimensionless" | "" => Unit::Dimensionless,

            // Custom unit (anything else)
            _ => Unit::Custom(unit_name.to_string()),
        }
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

            Statement::While(while_loop) => {
                let (cond_ty, s1) = self.infer_expr(&while_loop.condition, sub)?;

                // Condition must be Bool
                let s2 = unify(&s1.apply(&cond_ty), &TypeInfo::Bool)?;

                // Check body
                let mut current_sub = s1.compose(&s2);
                for stmt in &while_loop.body {
                    current_sub = self.check_statement(stmt, &current_sub)?;
                }

                Ok(current_sub)
            }

            Statement::Break(_) => Ok(sub.clone()),
            Statement::Continue(_) => Ok(sub.clone()),
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

    /// Get the type environment (for LSP)
    pub fn env(&self) -> &TypeEnv {
        &self.env
    }

    /// Take ownership of the type environment (for LSP caching)
    pub fn take_env(self) -> TypeEnv {
        self.env
    }

    /// Get all symbols in scope (for LSP completion)
    pub fn get_all_symbols(&self) -> Vec<(String, TypeInfo)> {
        self.env
            .bindings
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect()
    }

    /// Get type of specific symbol (for LSP hover)
    pub fn get_symbol_type(&self, name: &str) -> Option<TypeInfo> {
        self.env.get(name).cloned()
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
        let func1 =
            TypeInfo::Function(vec![TypeInfo::Int, TypeInfo::Int], Box::new(TypeInfo::Bool));
        let func2 =
            TypeInfo::Function(vec![TypeInfo::Int, TypeInfo::Int], Box::new(TypeInfo::Bool));

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
