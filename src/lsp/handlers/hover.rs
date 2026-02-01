// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Hover handler

use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;

use crate::lsp::Backend;

/// Handle hover request
pub async fn hover(backend: &Backend, params: HoverParams) -> Result<Option<Hover>> {
    let uri = params.text_document_position_params.text_document.uri;
    let position = params.text_document_position_params.position;

    // Get document
    let doc = match backend.document_map.get(&uri) {
        Some(d) => d,
        None => return Ok(None),
    };

    // Get word at cursor
    let word = match doc.word_at_position(position.line, position.character) {
        Some(w) => w,
        None => return Ok(None),
    };

    // Check if it's a keyword
    if let Some(keyword_doc) = get_keyword_documentation(&word) {
        return Ok(Some(Hover {
            contents: HoverContents::Markup(MarkupContent {
                kind: MarkupKind::Markdown,
                value: keyword_doc,
            }),
            range: None,
        }));
    }

    // Check type environment for symbol type
    if let Some(type_env) = doc.type_env() {
        if let Some(ty) = type_env.bindings.get(&word) {
            let markdown = format!("**Symbol**: `{}`\n\n**Type**: `{}`", word, ty);

            return Ok(Some(Hover {
                contents: HoverContents::Markup(MarkupContent {
                    kind: MarkupKind::Markdown,
                    value: markdown,
                }),
                range: None,
            }));
        }
    }

    Ok(None)
}

/// Get documentation for WokeLang keywords
fn get_keyword_documentation(keyword: &str) -> Option<String> {
    let doc = match keyword {
        "to" => "## to\n\nDefines a function.\n\n```wokelang\nto add(a, b) {\n    give back a + b;\n}\n```",
        "give" => "## give back\n\nReturns a value from a function.\n\n```wokelang\nto square(x) {\n    give back x * x;\n}\n```",
        "back" => "## give back\n\nReturns a value from a function.",
        "remember" => "## remember\n\nDeclares a variable.\n\n```wokelang\nremember x = 5;\nremember name = \"Alice\";\n```",
        "when" => "## when\n\nConditional expression.\n\n```wokelang\nwhen x > 0 {\n    print(\"positive\");\n} otherwise {\n    print(\"not positive\");\n}\n```",
        "otherwise" => "## otherwise\n\nElse branch of a conditional.",
        "repeat" => "## repeat\n\nLoop construct.\n\n```wokelang\nrepeat 10 times {\n    print(\"hello\");\n}\n```",
        "only" => "## only if okay\n\nConsent/capability block.\n\n```wokelang\nonly if okay \"file.read\" {\n    remember data = readFile(\"data.txt\");\n}\n```",
        "if" => "## only if okay\n\nConsent/capability block.",
        "okay" => "## only if okay / Okay\n\n1. Consent block keyword\n2. Result success constructor\n\n```wokelang\nremember result = Okay(42);\n```",
        "attempt" => "## attempt safely\n\nTry-catch block.\n\n```wokelang\nattempt safely {\n    riskyOperation();\n} handle error {\n    print(\"error occurred\");\n}\n```",
        "worker" => "## worker\n\nDefines a background worker.\n\n```wokelang\nworker DataProcessor {\n    to process(data) {\n        give back data * 2;\n    }\n}\n```",
        "spawn" => "## spawn\n\nSpawns a worker.\n\n```wokelang\nspawn worker { work(); }\n```",
        "measured" => "## measured in\n\nUnit of measure annotation.\n\n```wokelang\nremember distance = 5 measured in km;\n```",
        "type" => "## type\n\nDefines a custom type.\n\n```wokelang\ntype Person = { name: String, age: Int };\n```",
        "use" => "## use\n\nImports a module.\n\n```wokelang\nuse math;\nuse network renamed net;\n```",
        "true" | "false" => "## Boolean Literal\n\nBoolean value: `true` or `false`",
        _ => return None,
    };

    Some(doc.to_string())
}
