// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//! Standard library metadata for completion

use tower_lsp::lsp_types::{CompletionItem, CompletionItemKind, Documentation};

/// Get completion items for a stdlib module
pub fn get_stdlib_completions(module: &str) -> Vec<CompletionItem> {
    match module {
        "math" => math_completions(),
        "string" => string_completions(),
        "array" => array_completions(),
        "io" => io_completions(),
        "json" => json_completions(),
        "time" => time_completions(),
        "net" => net_completions(),
        "chan" => chan_completions(),
        _ => Vec::new(),
    }
}

fn math_completions() -> Vec<CompletionItem> {
    vec![
        completion_item(
            "abs",
            "Absolute value",
            "abs(x: Int | Float) -> Int | Float",
        ),
        completion_item("sqrt", "Square root", "sqrt(x: Float) -> Float"),
        completion_item("pow", "Power", "pow(base: Float, exp: Float) -> Float"),
        completion_item("sin", "Sine", "sin(x: Float) -> Float"),
        completion_item("cos", "Cosine", "cos(x: Float) -> Float"),
        completion_item("tan", "Tangent", "tan(x: Float) -> Float"),
        completion_item("floor", "Floor", "floor(x: Float) -> Int"),
        completion_item("ceil", "Ceiling", "ceil(x: Float) -> Int"),
        completion_item("round", "Round", "round(x: Float) -> Int"),
        completion_item("min", "Minimum", "min(a, b) -> a | b"),
        completion_item("max", "Maximum", "max(a, b) -> a | b"),
    ]
}

fn string_completions() -> Vec<CompletionItem> {
    vec![
        completion_item(
            "upper",
            "Convert to uppercase",
            "upper(s: String) -> String",
        ),
        completion_item(
            "lower",
            "Convert to lowercase",
            "lower(s: String) -> String",
        ),
        completion_item("trim", "Trim whitespace", "trim(s: String) -> String"),
        completion_item(
            "concat",
            "Concatenate strings",
            "concat(a: String, b: String) -> String",
        ),
        completion_item("length", "String length", "length(s: String) -> Int"),
        completion_item(
            "split",
            "Split string",
            "split(s: String, sep: String) -> [String]",
        ),
        completion_item(
            "join",
            "Join strings",
            "join(arr: [String], sep: String) -> String",
        ),
        completion_item(
            "substring",
            "Get substring",
            "substring(s: String, start: Int, end: Int) -> String",
        ),
        completion_item(
            "contains",
            "Check if contains",
            "contains(s: String, sub: String) -> Bool",
        ),
        completion_item(
            "replace",
            "Replace substring",
            "replace(s: String, from: String, to: String) -> String",
        ),
    ]
}

fn array_completions() -> Vec<CompletionItem> {
    vec![
        completion_item("map", "Map over array", "map(arr: [a], f: a -> b) -> [b]"),
        completion_item(
            "filter",
            "Filter array",
            "filter(arr: [a], f: a -> Bool) -> [a]",
        ),
        completion_item(
            "fold",
            "Fold array",
            "fold(arr: [a], init: b, f: (b, a) -> b) -> b",
        ),
        completion_item("length", "Array length", "length(arr: [a]) -> Int"),
        completion_item("push", "Add to end", "push(arr: [a], item: a) -> [a]"),
        completion_item(
            "pop",
            "Remove from end",
            "pop(arr: [a]) -> Result<(a, [a]), String>",
        ),
        completion_item(
            "head",
            "First element",
            "head(arr: [a]) -> Result<a, String>",
        ),
        completion_item("tail", "All but first", "tail(arr: [a]) -> [a]"),
        completion_item("reverse", "Reverse array", "reverse(arr: [a]) -> [a]"),
        completion_item("sort", "Sort array", "sort(arr: [a]) -> [a]"),
    ]
}

fn io_completions() -> Vec<CompletionItem> {
    vec![
        completion_item(
            "readFile",
            "Read file (requires file.read)",
            "readFile(path: String) -> Result<String, String>",
        ),
        completion_item(
            "writeFile",
            "Write file (requires file.write)",
            "writeFile(path: String, content: String) -> Result<Unit, String>",
        ),
        completion_item(
            "appendFile",
            "Append to file (requires file.write)",
            "appendFile(path: String, content: String) -> Result<Unit, String>",
        ),
        completion_item(
            "fileExists",
            "Check if file exists",
            "fileExists(path: String) -> Bool",
        ),
        completion_item(
            "deleteFile",
            "Delete file (requires file.delete)",
            "deleteFile(path: String) -> Result<Unit, String>",
        ),
    ]
}

fn json_completions() -> Vec<CompletionItem> {
    vec![
        completion_item(
            "parse",
            "Parse JSON string",
            "parse(s: String) -> Result<Json, String>",
        ),
        completion_item("stringify", "Convert to JSON", "stringify(value) -> String"),
    ]
}

fn time_completions() -> Vec<CompletionItem> {
    vec![
        completion_item("now", "Current timestamp", "now() -> Int"),
        completion_item("sleep", "Sleep for milliseconds", "sleep(ms: Int) -> Unit"),
        completion_item(
            "format",
            "Format timestamp",
            "format(timestamp: Int, format: String) -> String",
        ),
    ]
}

fn net_completions() -> Vec<CompletionItem> {
    vec![
        completion_item(
            "httpGet",
            "HTTP GET (requires net.http)",
            "httpGet(url: String) -> Result<String, String>",
        ),
        completion_item(
            "httpPost",
            "HTTP POST (requires net.http)",
            "httpPost(url: String, body: String) -> Result<String, String>",
        ),
    ]
}

fn chan_completions() -> Vec<CompletionItem> {
    vec![
        completion_item("make", "Create channel", "make() -> Channel<a>"),
        completion_item(
            "send",
            "Send to channel",
            "send(ch: Channel<a>, value: a) -> Unit",
        ),
        completion_item("recv", "Receive from channel", "recv(ch: Channel<a>) -> a"),
        completion_item(
            "tryRecv",
            "Try receive",
            "tryRecv(ch: Channel<a>) -> Result<a, String>",
        ),
        completion_item("close", "Close channel", "close(ch: Channel<a>) -> Unit"),
    ]
}

/// Helper to create a completion item
fn completion_item(label: &str, doc: &str, signature: &str) -> CompletionItem {
    CompletionItem {
        label: label.to_string(),
        kind: Some(CompletionItemKind::FUNCTION),
        detail: Some(signature.to_string()),
        documentation: Some(Documentation::String(doc.to_string())),
        sort_text: Some(format!("0_{}", label)),
        ..Default::default()
    }
}
