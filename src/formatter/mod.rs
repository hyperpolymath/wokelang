// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! WokeLang code formatter
//!
//! Provides AST-based code formatting with consistent style.

use crate::ast::{Expr, Program, Statement, TopLevelItem};
use crate::lexer::{Lexer, Spanned};
use crate::parser::Parser;

/// Formatter for WokeLang code
pub struct Formatter {
    indent_size: usize,
}

impl Formatter {
    /// Create a new formatter with default settings
    pub fn new() -> Self {
        Self { indent_size: 4 }
    }

    /// Format source code
    pub fn format(&self, source: &str) -> Result<String, String> {
        // Parse the source
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().map_err(|e| format!("{}", e))?;

        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().map_err(|e| format!("{}", e))?;

        // Format the AST
        Ok(self.format_program(&program))
    }

    fn format_program(&self, program: &Program) -> String {
        let mut output = String::new();

        for (i, item) in program.items.iter().enumerate() {
            if i > 0 {
                output.push_str("\n\n");
            }
            output.push_str(&self.format_top_level_item(item, 0));
        }

        output.push('\n');
        output
    }

    fn format_top_level_item(&self, item: &TopLevelItem, _indent: usize) -> String {
        match item {
            TopLevelItem::Function(func) => {
                let mut output = format!("to {}(", func.name);

                for (i, param) in func.params.iter().enumerate() {
                    if i > 0 {
                        output.push_str(", ");
                    }
                    output.push_str(&param.name);
                }

                output.push_str(") {\n");

                for stmt in &func.body {
                    output.push_str(&self.format_statement(stmt, 1));
                }

                output.push('}');
                output
            }
            TopLevelItem::ConstDef(const_def) => {
                format!("remember {} = {};", const_def.name, "...") // Simplified
            }
            TopLevelItem::TypeDef(type_def) => {
                format!("type {} = ...;", type_def.name) // Simplified
            }
            _ => String::new(),
        }
    }

    fn format_statement(&self, stmt: &Statement, indent: usize) -> String {
        let indent_str = " ".repeat(indent * self.indent_size);
        let mut output = String::new();

        match stmt {
            Statement::VarDecl(var_decl) => {
                output.push_str(&indent_str);
                output.push_str(&format!("remember {} = ...;\n", var_decl.name));
            }
            Statement::Assignment(assign) => {
                output.push_str(&indent_str);
                output.push_str(&format!("{} = ...;\n", assign.target));
            }
            Statement::Expression(expr) => {
                output.push_str(&indent_str);
                output.push_str(&self.format_expr(&expr.node));
                output.push_str(";\n");
            }
            Statement::Return(ret_stmt) => {
                output.push_str(&indent_str);
                output.push_str("give back ...;\n");
            }
            Statement::Conditional(cond) => {
                output.push_str(&indent_str);
                output.push_str("when ... {\n");

                for stmt in &cond.then_branch {
                    output.push_str(&self.format_statement(stmt, indent + 1));
                }

                if let Some(else_stmts) = &cond.else_branch {
                    output.push_str(&indent_str);
                    output.push_str("} otherwise {\n");

                    for stmt in else_stmts {
                        output.push_str(&self.format_statement(stmt, indent + 1));
                    }
                }

                output.push_str(&indent_str);
                output.push_str("}\n");
            }
            Statement::Loop(loop_stmt) => {
                output.push_str(&indent_str);
                output.push_str("repeat ... times {\n");

                for stmt in &loop_stmt.body {
                    output.push_str(&self.format_statement(stmt, indent + 1));
                }

                output.push_str(&indent_str);
                output.push_str("}\n");
            }
            Statement::ConsentBlock(consent) => {
                output.push_str(&indent_str);
                output.push_str(&format!("only if okay \"{}\" {{\n", consent.permission));

                for stmt in &consent.body {
                    output.push_str(&self.format_statement(stmt, indent + 1));
                }

                output.push_str(&indent_str);
                output.push_str("}\n");
            }
            _ => {
                output.push_str(&indent_str);
                output.push_str("// TODO: format other statement types\n");
            }
        }

        output
    }

    fn format_expr(&self, _expr: &Expr) -> String {
        "...".to_string() // Simplified - would need full expression formatting
    }
}

impl Default for Formatter {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_simple_function() {
        let source = "to add(a,b){give back a+b;}";
        let formatter = Formatter::new();
        let formatted = formatter.format(source).unwrap();

        assert!(formatted.contains("to add(a, b) {"));
        assert!(formatted.contains("    give back"));
    }
}
