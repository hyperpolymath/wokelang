// SPDX-License-Identifier: PMPL-1.0-or-later
//! WokeLang Linter
//!
//! Static analysis tool for WokeLang code quality and style checking.

use crate::ast::*;
use std::collections::HashSet;

/// Lint severity level
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Severity {
    Error,
    Warning,
    Info,
}

/// Lint diagnostic
#[derive(Debug, Clone)]
pub struct Diagnostic {
    pub severity: Severity,
    pub message: String,
    pub span: Span,
    pub code: String,
}

/// Linter for WokeLang code
pub struct Linter {
    diagnostics: Vec<Diagnostic>,
    defined_vars: HashSet<String>,
    used_vars: HashSet<String>,
}

impl Linter {
    pub fn new() -> Self {
        Self {
            diagnostics: Vec::new(),
            defined_vars: HashSet::new(),
            used_vars: HashSet::new(),
        }
    }

    /// Lint a program and return diagnostics
    pub fn lint(&mut self, program: &Program) -> Vec<Diagnostic> {
        self.diagnostics.clear();
        self.defined_vars.clear();
        self.used_vars.clear();

        // Lint all top-level items
        for item in &program.items {
            self.lint_top_level_item(item);
        }

        // Check for unused variables
        for var in &self.defined_vars {
            if !self.used_vars.contains(var) {
                self.diagnostics.push(Diagnostic {
                    severity: Severity::Warning,
                    message: format!("Unused variable: {}", var),
                    span: Span::default(),
                    code: "W001".to_string(),
                });
            }
        }

        self.diagnostics.clone()
    }

    fn lint_top_level_item(&mut self, item: &TopLevelItem) {
        match item {
            TopLevelItem::Function(func) => self.lint_function(func),
            TopLevelItem::ConsentBlock(_) => {},
            TopLevelItem::GratitudeDecl(_) => {},
            TopLevelItem::WorkerDef(_) => {},
            TopLevelItem::SideQuestDef(_) => {},
            TopLevelItem::SuperpowerDecl(_) => {},
            TopLevelItem::ModuleImport(_) => {},
            TopLevelItem::Pragma(_) => {},
            TopLevelItem::TypeDef(_) => {},
            TopLevelItem::ConstDef(_) => {},
        }
    }

    fn lint_function(&mut self, func: &FunctionDef) {
        // Check function name style
        if !func.name.chars().next().map_or(false, |c| c.is_lowercase()) {
            self.diagnostics.push(Diagnostic {
                severity: Severity::Warning,
                message: format!("Function '{}' should start with lowercase", func.name),
                span: func.span.clone(),
                code: "W002".to_string(),
            });
        }

        // Track parameters as defined variables
        for param in &func.params {
            self.defined_vars.insert(param.name.clone());
        }

        // Lint function body
        for stmt in &func.body {
            self.lint_statement(stmt);
        }
    }

    fn lint_statement(&mut self, stmt: &Statement) {
        match stmt {
            Statement::VarDecl(var_decl) => {
                self.defined_vars.insert(var_decl.name.clone());
                self.lint_expr(&var_decl.value);
            }
            Statement::Assignment(assignment) => {
                if !self.defined_vars.contains(&assignment.target) {
                    self.diagnostics.push(Diagnostic {
                        severity: Severity::Error,
                        message: format!("Assignment to undefined variable: {}", assignment.target),
                        span: assignment.span.clone(),
                        code: "E001".to_string(),
                    });
                }
                self.used_vars.insert(assignment.target.clone());
                self.lint_expr(&assignment.value);
            }
            Statement::Return(ret) => {
                self.lint_expr(&ret.value);
            }
            Statement::Conditional(cond) => {
                self.lint_expr(&cond.condition);
                for stmt in &cond.then_branch {
                    self.lint_statement(stmt);
                }
                if let Some(else_branch) = &cond.else_branch {
                    for stmt in else_branch {
                        self.lint_statement(stmt);
                    }
                }
            }
            Statement::Loop(loop_stmt) => {
                self.lint_expr(&loop_stmt.count);
                for stmt in &loop_stmt.body {
                    self.lint_statement(stmt);
                }
            }
            Statement::AttemptBlock(attempt) => {
                for stmt in &attempt.body {
                    self.lint_statement(stmt);
                }
            }
            Statement::ConsentBlock(consent) => {
                for stmt in &consent.body {
                    self.lint_statement(stmt);
                }
            }
            Statement::Expression(expr) => {
                self.lint_expr(expr);
            }
            Statement::WorkerSpawn(_) => {}
            Statement::Complain(_) => {}
            Statement::EmoteAnnotated(emote) => {
                self.lint_statement(&emote.statement);
            }
            Statement::Decide(decide) => {
                self.lint_expr(&decide.scrutinee);
                for arm in &decide.arms {
                    for stmt in &arm.body {
                        self.lint_statement(stmt);
                    }
                }
            }
        }
    }

    fn lint_expr(&mut self, expr: &Spanned<Expr>) {
        match &expr.node {
            Expr::Literal(_) => {}
            Expr::Identifier(name) => {
                self.used_vars.insert(name.clone());
                if !self.defined_vars.contains(name) {
                    self.diagnostics.push(Diagnostic {
                        severity: Severity::Warning,
                        message: format!("Use of possibly undefined variable: {}", name),
                        span: expr.span.clone(),
                        code: "W003".to_string(),
                    });
                }
            }
            Expr::Binary(_, left, right) => {
                self.lint_expr(left);
                self.lint_expr(right);
            }
            Expr::Unary(_, operand) => {
                self.lint_expr(operand);
            }
            Expr::Call(_, args) => {
                for arg in args {
                    self.lint_expr(arg);
                }
            }
            Expr::CallExpr(callee, args) => {
                self.lint_expr(callee);
                for arg in args {
                    self.lint_expr(arg);
                }
            }
            Expr::Array(elements) => {
                for elem in elements {
                    self.lint_expr(elem);
                }
            }
            Expr::Index(array, index) => {
                self.lint_expr(array);
                self.lint_expr(index);
            }
            Expr::Okay(val) => self.lint_expr(val),
            Expr::Oops(val) => self.lint_expr(val),
            Expr::Unwrap(val) => self.lint_expr(val),
            Expr::Lambda(lambda) => {
                // Track lambda params
                for param in &lambda.params {
                    self.defined_vars.insert(param.name.clone());
                }

                match &lambda.body {
                    LambdaBody::Expr(expr) => self.lint_expr(expr),
                    LambdaBody::Block(stmts) => {
                        for stmt in stmts {
                            self.lint_statement(stmt);
                        }
                    }
                }
            }
            Expr::UnitMeasurement(value, _unit) => {
                self.lint_expr(value);
            }
            Expr::GratitudeLiteral(_) => {}
        }
    }
}

impl Default for Linter {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_linter_unused_variable() {
        let mut linter = Linter::new();

        let program = Program {
            items: vec![TopLevelItem::Function(FunctionDef {
                name: "test".to_string(),
                params: vec![],
                body: vec![Statement::VarDecl(VarDecl {
                    name: "unused".to_string(),
                    value: Spanned {
                        node: Expr::Literal(Literal::Integer(42)),
                        span: Span::default(),
                    },
                    unit: None,
                    span: Span::default(),
                })],
                return_type: None,
                type_params: vec![],
                emote: None,
                hello: None,
                goodbye: None,
                span: Span::default(),
            })],
        };

        let diagnostics = linter.lint(&program);
        assert!(diagnostics.iter().any(|d| d.code == "W001"));
    }

    #[test]
    fn test_linter_uppercase_function() {
        let mut linter = Linter::new();

        let program = Program {
            items: vec![TopLevelItem::Function(FunctionDef {
                name: "Test".to_string(), // Should be lowercase
                params: vec![],
                body: vec![],
                return_type: None,
                type_params: vec![],
                emote: None,
                hello: None,
                goodbye: None,
                span: Span::default(),
            })],
        };

        let diagnostics = linter.lint(&program);
        assert!(diagnostics.iter().any(|d| d.code == "W002"));
    }

    #[test]
    fn test_linter_undefined_assignment() {
        let mut linter = Linter::new();

        let program = Program {
            items: vec![TopLevelItem::Function(FunctionDef {
                name: "test".to_string(),
                params: vec![],
                body: vec![Statement::Assignment(Assignment {
                    target: "undefined".to_string(),
                    value: Spanned {
                        node: Expr::Literal(Literal::Integer(42)),
                        span: Span::default(),
                    },
                    span: Span::default(),
                })],
                return_type: None,
                type_params: vec![],
                emote: None,
                hello: None,
                goodbye: None,
                span: Span::default(),
            })],
        };

        let diagnostics = linter.lint(&program);
        assert!(diagnostics.iter().any(|d| d.code == "E001"));
    }
}
