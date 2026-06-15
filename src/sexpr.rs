// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// sexpr.rs — S-expression and JSON AST dump for WokeLang
//
// Converts the full WokeLang AST into either S-expression text or a
// serde_json::Value tree.  Every AST node type defined in ast/mod.rs
// is covered:
//   - TopLevelItem (Function, ConsentBlock, GratitudeDecl, WorkerDef,
//     SideQuestDef, SuperpowerDecl, ModuleImport, Pragma, TypeDef, ConstDef)
//   - Statement (VarDecl, Assignment, Return, Conditional, Loop,
//     AttemptBlock, ConsentBlock, Expression, WorkerSpawn, Complain,
//     EmoteAnnotated, Decide, Break, Continue, While)
//   - Expr (Literal, Identifier, Binary, Unary, Call, CallExpr,
//     UnitMeasurement, GratitudeLiteral, Array, Index, Okay, Oops,
//     Unwrap, Lambda, FieldAccess, RecordLiteral)
//   - Pattern (Literal, Identifier, Wildcard, Constructor)
//   - Type (Basic, Array, Optional, Reference, Function, Generic, TypeVar)

use wokelang::ast::*;

// ============================================================================
// S-expression output
// ============================================================================

/// Convert a complete WokeLang program to an S-expression string.
pub fn program_to_sexpr(program: &Program) -> String {
    let mut out = String::new();
    out.push_str("(program");
    for item in &program.items {
        out.push('\n');
        out.push_str("  ");
        top_level_item_to_sexpr(item, &mut out, 2);
    }
    out.push(')');
    out
}

/// Indent helper — pushes `indent` spaces onto `out`.
fn pad(out: &mut String, indent: usize) {
    for _ in 0..indent {
        out.push(' ');
    }
}

/// Emit a newline followed by indentation.
fn nl(out: &mut String, indent: usize) {
    out.push('\n');
    pad(out, indent);
}

// ---------------------------------------------------------------------------
// Top-level items
// ---------------------------------------------------------------------------

/// Serialize a single top-level item to S-expression form.
fn top_level_item_to_sexpr(item: &TopLevelItem, out: &mut String, indent: usize) {
    match item {
        TopLevelItem::Function(f) => function_def_to_sexpr(f, out, indent),
        TopLevelItem::ConsentBlock(c) => {
            out.push_str(&format!("(consent-block \"{}\"", c.permission));
            for s in &c.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        TopLevelItem::GratitudeDecl(g) => {
            out.push_str("(gratitude");
            for entry in &g.entries {
                nl(out, indent + 2);
                out.push_str(&format!(
                    "(entry \"{}\" \"{}\")",
                    entry.recipient, entry.reason
                ));
            }
            out.push(')');
        }
        TopLevelItem::WorkerDef(w) => {
            out.push_str(&format!("(worker \"{}\"", w.name));
            for s in &w.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        TopLevelItem::SideQuestDef(sq) => {
            out.push_str(&format!("(side-quest \"{}\"", sq.name));
            for s in &sq.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        TopLevelItem::SuperpowerDecl(sp) => {
            out.push_str(&format!("(superpower \"{}\"", sp.name));
            for s in &sp.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        TopLevelItem::ModuleImport(mi) => {
            out.push_str(&format!("(import \"{}\"", mi.path.parts.join(".")));
            if let Some(rename) = &mi.rename {
                out.push_str(&format!(" :as \"{}\"", rename));
            }
            out.push(')');
        }
        TopLevelItem::Pragma(p) => {
            let dir = match p.directive {
                PragmaDirective::Care => "care",
                PragmaDirective::Strict => "strict",
                PragmaDirective::Verbose => "verbose",
            };
            out.push_str(&format!(
                "(pragma {} {})",
                dir,
                if p.enabled { "on" } else { "off" }
            ));
        }
        TopLevelItem::TypeDef(td) => {
            out.push_str(&format!("(type-def \"{}\"", td.name));
            nl(out, indent + 2);
            type_variant_to_sexpr(&td.definition, out, indent + 2);
            out.push(')');
        }
        TopLevelItem::ConstDef(cd) => {
            out.push_str(&format!("(const \"{}\" ", cd.name));
            type_to_sexpr(&cd.ty, out);
            out.push(' ');
            expr_to_sexpr(&cd.value.node, out, indent + 2);
            out.push(')');
        }
    }
}

/// Serialize a function definition to S-expression form.
fn function_def_to_sexpr(f: &FunctionDef, out: &mut String, indent: usize) {
    out.push_str(&format!("(fn \"{}\"", f.name));
    if let Some(ref emote) = f.emote {
        out.push_str(&format!(" :emote \"{}\"", emote.name));
    }
    // Type parameters
    if !f.type_params.is_empty() {
        out.push_str(" (type-params");
        for tp in &f.type_params {
            out.push_str(&format!(" \"{}\"", tp.name));
        }
        out.push(')');
    }
    // Parameters
    nl(out, indent + 2);
    out.push_str("(params");
    for p in &f.params {
        out.push_str(&format!(" \"{}\"", p.name));
        if let Some(ref ty) = p.ty {
            out.push(':');
            type_to_sexpr(ty, out);
        }
    }
    out.push(')');
    // Return type
    if let Some(ref ret) = f.return_type {
        out.push_str(" :returns ");
        type_to_sexpr(ret, out);
    }
    // Body
    for stmt in &f.body {
        nl(out, indent + 2);
        stmt_to_sexpr(stmt, out, indent + 2);
    }
    out.push(')');
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Serialize a type annotation to S-expression form.
fn type_to_sexpr(ty: &Type, out: &mut String) {
    match ty {
        Type::Basic(name) => out.push_str(&format!("(type \"{}\")", name)),
        Type::Array(inner) => {
            out.push_str("(array ");
            type_to_sexpr(inner, out);
            out.push(')');
        }
        Type::Optional(inner) => {
            out.push_str("(maybe ");
            type_to_sexpr(inner, out);
            out.push(')');
        }
        Type::Reference(inner) => {
            out.push_str("(ref ");
            type_to_sexpr(inner, out);
            out.push(')');
        }
        Type::Function(params, ret) => {
            out.push_str("(fn-type (");
            for (i, p) in params.iter().enumerate() {
                if i > 0 {
                    out.push(' ');
                }
                type_to_sexpr(p, out);
            }
            out.push_str(") -> ");
            type_to_sexpr(ret, out);
            out.push(')');
        }
        Type::Generic(name, args) => {
            out.push_str(&format!("(generic \"{}\"", name));
            for a in args {
                out.push(' ');
                type_to_sexpr(a, out);
            }
            out.push(')');
        }
        Type::TypeVar(name) => out.push_str(&format!("(typevar \"{}\")", name)),
    }
}

/// Serialize a type variant (from type definitions) to S-expression form.
fn type_variant_to_sexpr(tv: &TypeVariant, out: &mut String, indent: usize) {
    match tv {
        TypeVariant::Struct(fields) => {
            out.push_str("(struct");
            for f in fields {
                nl(out, indent + 2);
                out.push_str(&format!("(field \"{}\" ", f.name));
                type_to_sexpr(&f.ty, out);
                out.push(')');
            }
            out.push(')');
        }
        TypeVariant::Enum(variants) => {
            out.push_str("(enum");
            for v in variants {
                nl(out, indent + 2);
                out.push_str(&format!("(variant \"{}\"", v.name));
                for f in &v.fields {
                    out.push(' ');
                    type_to_sexpr(f, out);
                }
                out.push(')');
            }
            out.push(')');
        }
        TypeVariant::Alias(ty) => {
            out.push_str("(alias ");
            type_to_sexpr(ty, out);
            out.push(')');
        }
    }
}

// ---------------------------------------------------------------------------
// Statements
// ---------------------------------------------------------------------------

/// Serialize a statement to S-expression form.
fn stmt_to_sexpr(stmt: &Statement, out: &mut String, indent: usize) {
    match stmt {
        Statement::VarDecl(v) => {
            out.push_str(&format!("(remember \"{}\" ", v.name));
            expr_to_sexpr(&v.value.node, out, indent + 2);
            if let Some(ref unit) = v.unit {
                out.push_str(&format!(" :unit \"{}\"", unit));
            }
            out.push(')');
        }
        Statement::Assignment(a) => {
            out.push_str(&format!("(assign \"{}\" ", a.target));
            expr_to_sexpr(&a.value.node, out, indent + 2);
            out.push(')');
        }
        Statement::Return(r) => {
            out.push_str("(give-back ");
            expr_to_sexpr(&r.value.node, out, indent + 2);
            out.push(')');
        }
        Statement::Conditional(c) => {
            out.push_str("(when ");
            expr_to_sexpr(&c.condition.node, out, indent + 2);
            nl(out, indent + 2);
            out.push_str("(then");
            for s in &c.then_branch {
                out.push(' ');
                stmt_to_sexpr(s, out, indent + 4);
            }
            out.push(')');
            if let Some(ref els) = c.else_branch {
                nl(out, indent + 2);
                out.push_str("(otherwise");
                for s in els {
                    out.push(' ');
                    stmt_to_sexpr(s, out, indent + 4);
                }
                out.push(')');
            }
            out.push(')');
        }
        Statement::Loop(l) => {
            out.push_str("(repeat ");
            expr_to_sexpr(&l.count.node, out, indent + 2);
            for s in &l.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        Statement::AttemptBlock(a) => {
            out.push_str(&format!("(attempt-safely :reassure \"{}\"", a.reassurance));
            for s in &a.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        Statement::ConsentBlock(c) => {
            out.push_str(&format!("(consent \"{}\"", c.permission));
            for s in &c.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
        Statement::Expression(e) => {
            expr_to_sexpr(&e.node, out, indent);
        }
        Statement::WorkerSpawn(w) => {
            out.push_str(&format!("(spawn-worker \"{}\")", w.worker_name));
        }
        Statement::SendMessage(s) => {
            out.push_str(&format!("(send :to \"{}\" ", s.target));
            expr_to_sexpr(&s.message.node, out, indent + 2);
            out.push(')');
        }
        Statement::ReceiveMessage(r) => {
            out.push_str(&format!("(receive :from \"{}\")", r.source));
        }
        Statement::AwaitWorker(a) => {
            out.push_str(&format!("(await-worker \"{}\")", a.worker_name));
        }
        Statement::CancelWorker(c) => {
            out.push_str(&format!("(cancel-worker \"{}\")", c.worker_name));
        }
        Statement::Complain(c) => {
            out.push_str(&format!("(complain \"{}\")", c.message));
        }
        Statement::EmoteAnnotated(ea) => {
            out.push_str(&format!("(emote-annotated \"{}\" ", ea.emote.name));
            stmt_to_sexpr(&ea.statement, out, indent + 2);
            out.push(')');
        }
        Statement::Decide(d) => {
            out.push_str("(decide ");
            expr_to_sexpr(&d.scrutinee.node, out, indent + 2);
            for arm in &d.arms {
                nl(out, indent + 2);
                out.push_str("(arm ");
                pattern_to_sexpr(&arm.pattern, out);
                out.push(' ');
                out.push_str("(body");
                for s in &arm.body {
                    out.push(' ');
                    stmt_to_sexpr(s, out, indent + 4);
                }
                out.push_str("))");
            }
            out.push(')');
        }
        Statement::Break(_) => out.push_str("(break)"),
        Statement::Continue(_) => out.push_str("(continue)"),
        Statement::While(w) => {
            out.push_str("(while ");
            expr_to_sexpr(&w.condition.node, out, indent + 2);
            for s in &w.body {
                nl(out, indent + 2);
                stmt_to_sexpr(s, out, indent + 2);
            }
            out.push(')');
        }
    }
}

// ---------------------------------------------------------------------------
// Patterns
// ---------------------------------------------------------------------------

/// Serialize a pattern to S-expression form.
fn pattern_to_sexpr(pat: &Pattern, out: &mut String) {
    match pat {
        Pattern::Literal(lit) => literal_to_sexpr(lit, out),
        Pattern::Identifier(name) => out.push_str(&format!("(pat-id \"{}\")", name)),
        Pattern::Wildcard => out.push('_'),
        Pattern::Constructor(name, inner) => {
            out.push_str(&format!("(pat-ctor \"{}\"", name));
            if let Some(ref p) = inner {
                out.push(' ');
                pattern_to_sexpr(p, out);
            }
            out.push(')');
        }
    }
}

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

/// Serialize an expression to S-expression form.
fn expr_to_sexpr(expr: &Expr, out: &mut String, indent: usize) {
    match expr {
        Expr::Literal(lit) => literal_to_sexpr(lit, out),
        Expr::Identifier(name) => out.push_str(&format!("(id \"{}\")", name)),
        Expr::Binary(op, lhs, rhs) => {
            let op_str = match op {
                BinaryOp::Add => "+",
                BinaryOp::Sub => "-",
                BinaryOp::Mul => "*",
                BinaryOp::Div => "/",
                BinaryOp::Mod => "%",
                BinaryOp::Eq => "==",
                BinaryOp::NotEq => "!=",
                BinaryOp::Lt => "<",
                BinaryOp::Gt => ">",
                BinaryOp::LtEq => "<=",
                BinaryOp::GtEq => ">=",
                BinaryOp::And => "and",
                BinaryOp::Or => "or",
            };
            out.push_str(&format!("({} ", op_str));
            expr_to_sexpr(&lhs.node, out, indent + 2);
            out.push(' ');
            expr_to_sexpr(&rhs.node, out, indent + 2);
            out.push(')');
        }
        Expr::Unary(op, operand) => {
            let op_str = match op {
                UnaryOp::Neg => "neg",
                UnaryOp::Not => "not",
            };
            out.push_str(&format!("({} ", op_str));
            expr_to_sexpr(&operand.node, out, indent + 2);
            out.push(')');
        }
        Expr::Call(name, args) => {
            out.push_str(&format!("(call \"{}\"", name));
            for a in args {
                out.push(' ');
                expr_to_sexpr(&a.node, out, indent + 2);
            }
            out.push(')');
        }
        Expr::CallExpr(callee, args) => {
            out.push_str("(call-expr ");
            expr_to_sexpr(&callee.node, out, indent + 2);
            for a in args {
                out.push(' ');
                expr_to_sexpr(&a.node, out, indent + 2);
            }
            out.push(')');
        }
        Expr::UnitMeasurement(expr, unit) => {
            out.push_str("(measured ");
            expr_to_sexpr(&expr.node, out, indent + 2);
            out.push_str(&format!(" :in \"{}\")", unit));
        }
        Expr::GratitudeLiteral(name) => {
            out.push_str(&format!("(thanks \"{}\")", name));
        }
        Expr::Array(elems) => {
            out.push_str("(array");
            for e in elems {
                out.push(' ');
                expr_to_sexpr(&e.node, out, indent + 2);
            }
            out.push(')');
        }
        Expr::Index(arr, idx) => {
            out.push_str("(index ");
            expr_to_sexpr(&arr.node, out, indent + 2);
            out.push(' ');
            expr_to_sexpr(&idx.node, out, indent + 2);
            out.push(')');
        }
        Expr::Okay(inner) => {
            out.push_str("(okay ");
            expr_to_sexpr(&inner.node, out, indent + 2);
            out.push(')');
        }
        Expr::Oops(inner) => {
            out.push_str("(oops ");
            expr_to_sexpr(&inner.node, out, indent + 2);
            out.push(')');
        }
        Expr::Unwrap(inner) => {
            out.push_str("(unwrap ");
            expr_to_sexpr(&inner.node, out, indent + 2);
            out.push(')');
        }
        Expr::Lambda(lam) => {
            out.push_str("(lambda (params");
            for p in &lam.params {
                out.push_str(&format!(" \"{}\"", p.name));
            }
            out.push_str(") ");
            match &lam.body {
                LambdaBody::Expr(e) => expr_to_sexpr(&e.node, out, indent + 2),
                LambdaBody::Block(stmts) => {
                    out.push_str("(block");
                    for s in stmts {
                        nl(out, indent + 4);
                        stmt_to_sexpr(s, out, indent + 4);
                    }
                    out.push(')');
                }
            }
            out.push(')');
        }
        Expr::FieldAccess(obj, field) => {
            out.push_str("(field-access ");
            expr_to_sexpr(&obj.node, out, indent + 2);
            out.push_str(&format!(" \"{}\")", field));
        }
        Expr::RecordLiteral(name, fields) => {
            out.push_str(&format!("(record \"{}\"", name));
            for (fname, fval) in fields {
                nl(out, indent + 2);
                out.push_str(&format!("(field \"{}\" ", fname));
                expr_to_sexpr(&fval.node, out, indent + 4);
                out.push(')');
            }
            out.push(')');
        }
    }
}

/// Serialize a literal value to S-expression form.
fn literal_to_sexpr(lit: &Literal, out: &mut String) {
    match lit {
        Literal::Integer(n) => out.push_str(&format!("{}", n)),
        Literal::Float(f) => out.push_str(&format!("{}", f)),
        Literal::String(s) => out.push_str(&format!("\"{}\"", s)),
        Literal::Bool(b) => out.push_str(if *b { "#t" } else { "#f" }),
        Literal::Unit => out.push_str("()"),
    }
}

// ============================================================================
// JSON output
// ============================================================================

/// Convert a complete WokeLang program to a JSON value.
pub fn program_to_json(program: &Program) -> serde_json::Value {
    serde_json::json!({
        "type": "program",
        "items": program.items.iter().map(top_level_item_to_json).collect::<Vec<_>>()
    })
}

/// Convert a top-level item to JSON.
fn top_level_item_to_json(item: &TopLevelItem) -> serde_json::Value {
    match item {
        TopLevelItem::Function(f) => function_def_to_json(f),
        TopLevelItem::ConsentBlock(c) => serde_json::json!({
            "type": "consent_block",
            "permission": c.permission,
            "body": c.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        TopLevelItem::GratitudeDecl(g) => serde_json::json!({
            "type": "gratitude",
            "entries": g.entries.iter().map(|e| serde_json::json!({
                "recipient": e.recipient,
                "reason": e.reason
            })).collect::<Vec<_>>()
        }),
        TopLevelItem::WorkerDef(w) => serde_json::json!({
            "type": "worker",
            "name": w.name,
            "body": w.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        TopLevelItem::SideQuestDef(sq) => serde_json::json!({
            "type": "side_quest",
            "name": sq.name,
            "body": sq.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        TopLevelItem::SuperpowerDecl(sp) => serde_json::json!({
            "type": "superpower",
            "name": sp.name,
            "body": sp.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        TopLevelItem::ModuleImport(mi) => serde_json::json!({
            "type": "import",
            "path": mi.path.parts.join("."),
            "rename": mi.rename
        }),
        TopLevelItem::Pragma(p) => serde_json::json!({
            "type": "pragma",
            "directive": format!("{:?}", p.directive),
            "enabled": p.enabled
        }),
        TopLevelItem::TypeDef(td) => serde_json::json!({
            "type": "type_def",
            "name": td.name,
            "definition": type_variant_to_json(&td.definition)
        }),
        TopLevelItem::ConstDef(cd) => serde_json::json!({
            "type": "const",
            "name": cd.name,
            "ty": type_to_json(&cd.ty),
            "value": expr_to_json(&cd.value.node)
        }),
    }
}

/// Convert a function definition to JSON.
fn function_def_to_json(f: &FunctionDef) -> serde_json::Value {
    serde_json::json!({
        "type": "function",
        "name": f.name,
        "emote": f.emote.as_ref().map(|e| &e.name),
        "type_params": f.type_params.iter().map(|tp| &tp.name).collect::<Vec<_>>(),
        "params": f.params.iter().map(|p| serde_json::json!({
            "name": p.name,
            "ty": p.ty.as_ref().map(type_to_json)
        })).collect::<Vec<_>>(),
        "return_type": f.return_type.as_ref().map(type_to_json),
        "body": f.body.iter().map(stmt_to_json).collect::<Vec<_>>()
    })
}

/// Convert a type to JSON.
fn type_to_json(ty: &Type) -> serde_json::Value {
    match ty {
        Type::Basic(name) => serde_json::json!({"type": "basic", "name": name}),
        Type::Array(inner) => serde_json::json!({"type": "array", "element": type_to_json(inner)}),
        Type::Optional(inner) => {
            serde_json::json!({"type": "optional", "inner": type_to_json(inner)})
        }
        Type::Reference(inner) => {
            serde_json::json!({"type": "reference", "inner": type_to_json(inner)})
        }
        Type::Function(params, ret) => serde_json::json!({
            "type": "function",
            "params": params.iter().map(type_to_json).collect::<Vec<_>>(),
            "return": type_to_json(ret)
        }),
        Type::Generic(name, args) => serde_json::json!({
            "type": "generic",
            "name": name,
            "args": args.iter().map(type_to_json).collect::<Vec<_>>()
        }),
        Type::TypeVar(name) => serde_json::json!({"type": "typevar", "name": name}),
    }
}

/// Convert a type variant definition to JSON.
fn type_variant_to_json(tv: &TypeVariant) -> serde_json::Value {
    match tv {
        TypeVariant::Struct(fields) => serde_json::json!({
            "kind": "struct",
            "fields": fields.iter().map(|f| serde_json::json!({
                "name": f.name,
                "ty": type_to_json(&f.ty)
            })).collect::<Vec<_>>()
        }),
        TypeVariant::Enum(variants) => serde_json::json!({
            "kind": "enum",
            "variants": variants.iter().map(|v| serde_json::json!({
                "name": v.name,
                "fields": v.fields.iter().map(type_to_json).collect::<Vec<_>>()
            })).collect::<Vec<_>>()
        }),
        TypeVariant::Alias(ty) => serde_json::json!({"kind": "alias", "ty": type_to_json(ty)}),
    }
}

/// Convert a statement to JSON.
fn stmt_to_json(stmt: &Statement) -> serde_json::Value {
    match stmt {
        Statement::VarDecl(v) => serde_json::json!({
            "type": "var_decl",
            "name": v.name,
            "value": expr_to_json(&v.value.node),
            "unit": v.unit
        }),
        Statement::Assignment(a) => serde_json::json!({
            "type": "assignment",
            "target": a.target,
            "value": expr_to_json(&a.value.node)
        }),
        Statement::Return(r) => serde_json::json!({
            "type": "return",
            "value": expr_to_json(&r.value.node)
        }),
        Statement::Conditional(c) => serde_json::json!({
            "type": "conditional",
            "condition": expr_to_json(&c.condition.node),
            "then": c.then_branch.iter().map(stmt_to_json).collect::<Vec<_>>(),
            "else": c.else_branch.as_ref().map(|b| b.iter().map(stmt_to_json).collect::<Vec<_>>())
        }),
        Statement::Loop(l) => serde_json::json!({
            "type": "loop",
            "count": expr_to_json(&l.count.node),
            "body": l.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        Statement::AttemptBlock(a) => serde_json::json!({
            "type": "attempt",
            "reassurance": a.reassurance,
            "body": a.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        Statement::ConsentBlock(c) => serde_json::json!({
            "type": "consent_block",
            "permission": c.permission,
            "body": c.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
        Statement::Expression(e) => serde_json::json!({
            "type": "expression",
            "expr": expr_to_json(&e.node)
        }),
        Statement::WorkerSpawn(w) => serde_json::json!({
            "type": "spawn_worker",
            "name": w.worker_name
        }),
        Statement::SendMessage(s) => serde_json::json!({
            "type": "send_message",
            "target": s.target,
            "message": expr_to_json(&s.message.node)
        }),
        Statement::ReceiveMessage(r) => serde_json::json!({
            "type": "receive_message",
            "source": r.source
        }),
        Statement::AwaitWorker(a) => serde_json::json!({
            "type": "await_worker",
            "name": a.worker_name
        }),
        Statement::CancelWorker(c) => serde_json::json!({
            "type": "cancel_worker",
            "name": c.worker_name
        }),
        Statement::Complain(c) => serde_json::json!({
            "type": "complain",
            "message": c.message
        }),
        Statement::EmoteAnnotated(ea) => serde_json::json!({
            "type": "emote_annotated",
            "emote": ea.emote.name,
            "statement": stmt_to_json(&ea.statement)
        }),
        Statement::Decide(d) => serde_json::json!({
            "type": "decide",
            "scrutinee": expr_to_json(&d.scrutinee.node),
            "arms": d.arms.iter().map(|arm| serde_json::json!({
                "pattern": pattern_to_json(&arm.pattern),
                "body": arm.body.iter().map(stmt_to_json).collect::<Vec<_>>()
            })).collect::<Vec<_>>()
        }),
        Statement::Break(_) => serde_json::json!({"type": "break"}),
        Statement::Continue(_) => serde_json::json!({"type": "continue"}),
        Statement::While(w) => serde_json::json!({
            "type": "while",
            "condition": expr_to_json(&w.condition.node),
            "body": w.body.iter().map(stmt_to_json).collect::<Vec<_>>()
        }),
    }
}

/// Convert a pattern to JSON.
fn pattern_to_json(pat: &Pattern) -> serde_json::Value {
    match pat {
        Pattern::Literal(lit) => serde_json::json!({
            "type": "literal",
            "value": literal_to_json(lit)
        }),
        Pattern::Identifier(name) => serde_json::json!({
            "type": "identifier",
            "name": name
        }),
        Pattern::Wildcard => serde_json::json!({"type": "wildcard"}),
        Pattern::Constructor(name, inner) => serde_json::json!({
            "type": "constructor",
            "name": name,
            "inner": inner.as_ref().map(|p| pattern_to_json(p))
        }),
    }
}

/// Convert an expression to JSON.
fn expr_to_json(expr: &Expr) -> serde_json::Value {
    match expr {
        Expr::Literal(lit) => literal_to_json(lit),
        Expr::Identifier(name) => serde_json::json!({"type": "identifier", "name": name}),
        Expr::Binary(op, lhs, rhs) => serde_json::json!({
            "type": "binary",
            "op": format!("{:?}", op),
            "lhs": expr_to_json(&lhs.node),
            "rhs": expr_to_json(&rhs.node)
        }),
        Expr::Unary(op, operand) => serde_json::json!({
            "type": "unary",
            "op": format!("{:?}", op),
            "operand": expr_to_json(&operand.node)
        }),
        Expr::Call(name, args) => serde_json::json!({
            "type": "call",
            "name": name,
            "args": args.iter().map(|a| expr_to_json(&a.node)).collect::<Vec<_>>()
        }),
        Expr::CallExpr(callee, args) => serde_json::json!({
            "type": "call_expr",
            "callee": expr_to_json(&callee.node),
            "args": args.iter().map(|a| expr_to_json(&a.node)).collect::<Vec<_>>()
        }),
        Expr::UnitMeasurement(expr, unit) => serde_json::json!({
            "type": "unit_measurement",
            "expr": expr_to_json(&expr.node),
            "unit": unit
        }),
        Expr::GratitudeLiteral(name) => serde_json::json!({
            "type": "gratitude_literal",
            "name": name
        }),
        Expr::Array(elems) => serde_json::json!({
            "type": "array",
            "elements": elems.iter().map(|e| expr_to_json(&e.node)).collect::<Vec<_>>()
        }),
        Expr::Index(arr, idx) => serde_json::json!({
            "type": "index",
            "array": expr_to_json(&arr.node),
            "index": expr_to_json(&idx.node)
        }),
        Expr::Okay(inner) => serde_json::json!({
            "type": "okay",
            "value": expr_to_json(&inner.node)
        }),
        Expr::Oops(inner) => serde_json::json!({
            "type": "oops",
            "value": expr_to_json(&inner.node)
        }),
        Expr::Unwrap(inner) => serde_json::json!({
            "type": "unwrap",
            "value": expr_to_json(&inner.node)
        }),
        Expr::Lambda(lam) => serde_json::json!({
            "type": "lambda",
            "params": lam.params.iter().map(|p| serde_json::json!({
                "name": p.name,
                "ty": p.ty.as_ref().map(type_to_json)
            })).collect::<Vec<_>>(),
            "return_type": lam.return_type.as_ref().map(type_to_json),
            "body": match &lam.body {
                LambdaBody::Expr(e) => serde_json::json!({"kind": "expr", "value": expr_to_json(&e.node)}),
                LambdaBody::Block(stmts) => serde_json::json!({
                    "kind": "block",
                    "statements": stmts.iter().map(stmt_to_json).collect::<Vec<_>>()
                }),
            }
        }),
        Expr::FieldAccess(obj, field) => serde_json::json!({
            "type": "field_access",
            "object": expr_to_json(&obj.node),
            "field": field
        }),
        Expr::RecordLiteral(name, fields) => serde_json::json!({
            "type": "record_literal",
            "name": name,
            "fields": fields.iter().map(|(fname, fval)| serde_json::json!({
                "name": fname,
                "value": expr_to_json(&fval.node)
            })).collect::<Vec<_>>()
        }),
    }
}

/// Convert a literal to JSON.
fn literal_to_json(lit: &Literal) -> serde_json::Value {
    match lit {
        Literal::Integer(n) => serde_json::json!({"type": "integer", "value": n}),
        Literal::Float(f) => serde_json::json!({"type": "float", "value": f}),
        Literal::String(s) => serde_json::json!({"type": "string", "value": s}),
        Literal::Bool(b) => serde_json::json!({"type": "bool", "value": b}),
        Literal::Unit => serde_json::json!({"type": "unit"}),
    }
}
