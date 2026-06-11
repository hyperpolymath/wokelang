// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! AST Visitor framework for WokeLang.

use super::*;

/// Trait for visiting WokeLang AST nodes.
pub trait Visitor: Sized {
    fn visit_program(&mut self, program: &Program) {
        for item in &program.items { self.visit_top_level_item(item); }
    }
    fn visit_top_level_item(&mut self, item: &TopLevelItem) {
        walk_top_level_item(self, item);
    }
    fn visit_statement(&mut self, stmt: &Statement) { walk_statement(self, stmt); }
    fn visit_expr(&mut self, expr: &Expr) { walk_expr(self, expr); }
    fn visit_pattern(&mut self, _pattern: &Pattern) {}
    fn visit_function_def(&mut self, func: &FunctionDef) {
        walk_function_def(self, func);
    }
}

pub fn walk_top_level_item<V: Visitor>(v: &mut V, item: &TopLevelItem) {
    match item {
        TopLevelItem::Function(f) => v.visit_function_def(f),
        TopLevelItem::ConsentBlock(c) => {
            for stmt in &c.body { v.visit_statement(stmt); }
        }
        TopLevelItem::GratitudeDecl(_) => {}
        TopLevelItem::WorkerDef(w) => {
            for stmt in &w.body { v.visit_statement(stmt); }
        }
        TopLevelItem::SideQuestDef(s) => {
            for stmt in &s.body { v.visit_statement(stmt); }
        }
        TopLevelItem::SuperpowerDecl(s) => {
            for stmt in &s.body { v.visit_statement(stmt); }
        }
        TopLevelItem::ModuleImport(_) | TopLevelItem::Pragma(_)
        | TopLevelItem::TypeDef(_) => {}
        TopLevelItem::ConstDef(c) => v.visit_expr(&c.value.node),
    }
}

pub fn walk_function_def<V: Visitor>(v: &mut V, func: &FunctionDef) {
    for stmt in &func.body { v.visit_statement(stmt); }
}

pub fn walk_statement<V: Visitor>(v: &mut V, stmt: &Statement) {
    match stmt {
        Statement::VarDecl(d) => v.visit_expr(&d.value.node),
        Statement::Assignment(a) => v.visit_expr(&a.value.node),
        Statement::Return(r) => v.visit_expr(&r.value.node),
        Statement::Conditional(c) => {
            v.visit_expr(&c.condition.node);
            for s in &c.then_branch { v.visit_statement(s); }
            if let Some(eb) = &c.else_branch {
                for s in eb { v.visit_statement(s); }
            }
        }
        Statement::Loop(l) => {
            v.visit_expr(&l.count.node);
            for s in &l.body { v.visit_statement(s); }
        }
        Statement::While(w) => {
            v.visit_expr(&w.condition.node);
            for s in &w.body { v.visit_statement(s); }
        }
        Statement::AttemptBlock(a) => {
            for s in &a.body { v.visit_statement(s); }
        }
        Statement::ConsentBlock(c) => {
            for s in &c.body { v.visit_statement(s); }
        }
        Statement::Expression(e) => v.visit_expr(&e.node),
        Statement::SendMessage(s) => v.visit_expr(&s.message.node),
        Statement::WorkerSpawn(_) | Statement::ReceiveMessage(_)
        | Statement::AwaitWorker(_) | Statement::CancelWorker(_)
        | Statement::Complain(_)
        | Statement::Break(_) | Statement::Continue(_) => {}
        Statement::EmoteAnnotated(e) => v.visit_statement(&e.statement),
        Statement::Decide(d) => {
            v.visit_expr(&d.scrutinee.node);
            for arm in &d.arms {
                v.visit_pattern(&arm.pattern);
                for s in &arm.body { v.visit_statement(s); }
            }
        }
    }
}

pub fn walk_expr<V: Visitor>(v: &mut V, expr: &Expr) {
    match expr {
        Expr::Literal(_) | Expr::Identifier(_) | Expr::GratitudeLiteral(_) => {}
        Expr::Binary(_, lhs, rhs) => {
            v.visit_expr(&lhs.node);
            v.visit_expr(&rhs.node);
        }
        Expr::Unary(_, operand) => v.visit_expr(&operand.node),
        Expr::Call(_, args) => {
            for arg in args { v.visit_expr(&arg.node); }
        }
        Expr::CallExpr(callee, args) => {
            v.visit_expr(&callee.node);
            for arg in args { v.visit_expr(&arg.node); }
        }
        Expr::UnitMeasurement(inner, _) => v.visit_expr(&inner.node),
        Expr::Array(elems) => {
            for e in elems { v.visit_expr(&e.node); }
        }
        Expr::Index(arr, idx) => {
            v.visit_expr(&arr.node);
            v.visit_expr(&idx.node);
        }
        Expr::Okay(inner) | Expr::Oops(inner) | Expr::Unwrap(inner) => {
            v.visit_expr(&inner.node);
        }
        Expr::Lambda(lam) => {
            match &lam.body {
                LambdaBody::Expr(e) => v.visit_expr(&e.node),
                LambdaBody::Block(stmts) => {
                    for s in stmts { v.visit_statement(s); }
                }
            }
        }
        Expr::FieldAccess(obj, _) => v.visit_expr(&obj.node),
        Expr::RecordLiteral(_, fields) => {
            for (_, val) in fields { v.visit_expr(&val.node); }
        }
    }
}
