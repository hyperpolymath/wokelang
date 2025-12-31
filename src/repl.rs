//! WokeLang REPL - Interactive Read-Eval-Print Loop
//!
//! Features:
//! - Multiline input with automatic detection of incomplete expressions
//! - Persistent history saved to ~/.woke_history
//! - Tab completion for keywords and defined identifiers
//! - Linting/type checking before evaluation
//! - Environment inspection

use crate::ast::TopLevelItem;
use crate::interpreter::Interpreter;
use crate::lexer::Lexer;
use crate::parser::Parser;
use crate::typechecker::TypeChecker;
use rustyline::completion::{Completer, Pair};
use rustyline::error::ReadlineError;
use rustyline::highlight::Highlighter;
use rustyline::hint::Hinter;
use rustyline::history::DefaultHistory;
use rustyline::validate::{ValidationContext, ValidationResult, Validator};
use rustyline::{Editor, Helper};
use std::borrow::Cow;
use std::collections::HashSet;

const BANNER: &str = r#"
 __        __    _        _
 \ \      / /__ | | _____| |    __ _ _ __   __ _
  \ \ /\ / / _ \| |/ / _ \ |   / _` | '_ \ / _` |
   \ V  V / (_) |   <  __/ |__| (_| | | | | (_| |
    \_/\_/ \___/|_|\_\___|_____\__,_|_| |_|\__, |
                                          |___/
"#;

const HELP: &str = r#"
WokeLang REPL Commands:
  :help, :h        Show this help message
  :quit, :q        Exit the REPL
  :clear, :c       Clear the screen
  :reset, :r       Reset interpreter state
  :load <file>     Load and run a file
  :ast <expr>      Show AST for an expression
  :type <expr>     Show inferred type for an expression
  :env             Show current environment variables
  :lint            Toggle linting (type checking) before execution
  :history         Show command history

Multiline Input:
  - Incomplete expressions automatically continue on the next line
  - End multi-line input with a complete statement/expression
  - Press Ctrl+C to cancel multi-line input

Examples:
  remember x = 42;
  print(x + 8);
  to double(n) { give back n * 2; }
  double(21)
"#;

/// Keywords for tab completion
const KEYWORDS: &[&str] = &[
    "to", "remember", "give", "back", "when", "otherwise", "repeat", "times",
    "while", "decide", "based", "on", "attempt", "safely", "or", "reassure",
    "only", "if", "okay", "thanks", "worker", "spawn", "hello", "goodbye",
    "complain", "Int", "Float", "String", "Bool", "Unit", "Maybe", "Result",
    "Okay", "Oops", "unwrap", "true", "false", "print", "len", "toString",
    "toInt", "isOkay", "isOops", "unwrapOr", "getError",
];

/// REPL helper for rustyline (completion, validation, hints)
#[derive(Helper)]
struct WokeHelper {
    identifiers: HashSet<String>,
}

impl WokeHelper {
    fn new() -> Self {
        Self {
            identifiers: HashSet::new(),
        }
    }

    fn add_identifier(&mut self, name: &str) {
        self.identifiers.insert(name.to_string());
    }
}

impl Completer for WokeHelper {
    type Candidate = Pair;

    fn complete(
        &self,
        line: &str,
        pos: usize,
        _ctx: &rustyline::Context<'_>,
    ) -> rustyline::Result<(usize, Vec<Pair>)> {
        // Find the start of the current word
        let start = line[..pos]
            .rfind(|c: char| !c.is_alphanumeric() && c != '_')
            .map(|i| i + 1)
            .unwrap_or(0);

        let prefix = &line[start..pos];
        if prefix.is_empty() {
            return Ok((pos, Vec::new()));
        }

        let mut completions: Vec<Pair> = Vec::new();

        // Add keyword completions
        for kw in KEYWORDS {
            if kw.starts_with(prefix) {
                completions.push(Pair {
                    display: kw.to_string(),
                    replacement: kw.to_string(),
                });
            }
        }

        // Add identifier completions
        for ident in &self.identifiers {
            if ident.starts_with(prefix) && !KEYWORDS.contains(&ident.as_str()) {
                completions.push(Pair {
                    display: ident.clone(),
                    replacement: ident.clone(),
                });
            }
        }

        completions.sort_by(|a, b| a.display.cmp(&b.display));
        completions.dedup_by(|a, b| a.display == b.display);

        Ok((start, completions))
    }
}

impl Hinter for WokeHelper {
    type Hint = String;

    fn hint(&self, _line: &str, _pos: usize, _ctx: &rustyline::Context<'_>) -> Option<String> {
        None // No hints for now
    }
}

impl Highlighter for WokeHelper {
    fn highlight<'l>(&self, line: &'l str, _pos: usize) -> Cow<'l, str> {
        Cow::Borrowed(line) // No highlighting for now
    }

    fn highlight_char(&self, _line: &str, _pos: usize, _forced: bool) -> bool {
        false
    }
}

impl Validator for WokeHelper {
    fn validate(&self, ctx: &mut ValidationContext<'_>) -> rustyline::Result<ValidationResult> {
        let input = ctx.input();

        // Check for balanced braces/brackets/parens
        let mut brace_count = 0i32;
        let mut bracket_count = 0i32;
        let mut paren_count = 0i32;
        let mut in_string = false;
        let mut prev_char = ' ';

        for c in input.chars() {
            if c == '"' && prev_char != '\\' {
                in_string = !in_string;
            }
            if !in_string {
                match c {
                    '{' => brace_count += 1,
                    '}' => brace_count -= 1,
                    '[' => bracket_count += 1,
                    ']' => bracket_count -= 1,
                    '(' => paren_count += 1,
                    ')' => paren_count -= 1,
                    _ => {}
                }
            }
            prev_char = c;
        }

        // If any count is positive, input is incomplete
        if brace_count > 0 || bracket_count > 0 || paren_count > 0 || in_string {
            return Ok(ValidationResult::Incomplete);
        }

        // If any count is negative, there's an error
        if brace_count < 0 || bracket_count < 0 || paren_count < 0 {
            return Ok(ValidationResult::Invalid(Some(
                "Unmatched closing bracket/brace/paren".to_string(),
            )));
        }

        Ok(ValidationResult::Valid(None))
    }
}

/// The WokeLang REPL
pub struct Repl {
    interpreter: Interpreter,
    typechecker: TypeChecker,
    editor: Editor<WokeHelper, DefaultHistory>,
    lint_enabled: bool,
    history_path: Option<std::path::PathBuf>,
}

impl Repl {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let config = rustyline::Config::builder()
            .history_ignore_space(true)
            .completion_type(rustyline::CompletionType::List)
            .edit_mode(rustyline::EditMode::Emacs)
            .build();

        let helper = WokeHelper::new();
        let mut editor = Editor::with_config(config)?;
        editor.set_helper(Some(helper));

        // Try to load history
        let history_path = dirs::home_dir().map(|p| p.join(".woke_history"));
        if let Some(ref path) = history_path {
            let _ = editor.load_history(path);
        }

        Ok(Self {
            interpreter: Interpreter::new(),
            typechecker: TypeChecker::new(),
            editor,
            lint_enabled: true,
            history_path,
        })
    }

    pub fn run(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("{}", BANNER);
        println!("WokeLang v0.1.0 - Interactive REPL");
        println!("Type :help for commands, :quit to exit");
        if self.lint_enabled {
            println!("Linting is ON (type checking before execution)");
        }
        println!();

        let mut multiline_buffer = String::new();
        let mut in_multiline = false;

        loop {
            let prompt = if in_multiline { "...> " } else { "woke> " };
            let readline = self.editor.readline(prompt);

            match readline {
                Ok(line) => {
                    if in_multiline {
                        multiline_buffer.push('\n');
                        multiline_buffer.push_str(&line);

                        // Check if input is now complete
                        if self.is_complete(&multiline_buffer) {
                            let input = std::mem::take(&mut multiline_buffer);
                            let _ = self.editor.add_history_entry(&input);
                            self.process_input(&input);
                            in_multiline = false;
                        }
                    } else {
                        let line = line.trim();
                        if line.is_empty() {
                            continue;
                        }

                        if line.starts_with(':') {
                            let _ = self.editor.add_history_entry(line);
                            if self.handle_command(line)? {
                                break;
                            }
                        } else if !self.is_complete(line) {
                            // Start multiline input
                            multiline_buffer = line.to_string();
                            in_multiline = true;
                        } else {
                            let _ = self.editor.add_history_entry(line);
                            self.process_input(line);
                        }
                    }
                }
                Err(ReadlineError::Interrupted) => {
                    if in_multiline {
                        println!("^C (multiline input cancelled)");
                        multiline_buffer.clear();
                        in_multiline = false;
                    } else {
                        println!("^C");
                    }
                    continue;
                }
                Err(ReadlineError::Eof) => {
                    println!("\nGoodbye!");
                    break;
                }
                Err(err) => {
                    eprintln!("Error: {:?}", err);
                    break;
                }
            }
        }

        // Save history
        if let Some(ref path) = self.history_path {
            let _ = self.editor.save_history(path);
        }

        Ok(())
    }

    fn is_complete(&self, input: &str) -> bool {
        let mut brace_count = 0i32;
        let mut bracket_count = 0i32;
        let mut paren_count = 0i32;
        let mut in_string = false;
        let mut prev_char = ' ';

        for c in input.chars() {
            if c == '"' && prev_char != '\\' {
                in_string = !in_string;
            }
            if !in_string {
                match c {
                    '{' => brace_count += 1,
                    '}' => brace_count -= 1,
                    '[' => bracket_count += 1,
                    ']' => bracket_count -= 1,
                    '(' => paren_count += 1,
                    ')' => paren_count -= 1,
                    _ => {}
                }
            }
            prev_char = c;
        }

        brace_count == 0 && bracket_count == 0 && paren_count == 0 && !in_string
    }

    fn handle_command(&mut self, line: &str) -> Result<bool, Box<dyn std::error::Error>> {
        let parts: Vec<&str> = line.splitn(2, ' ').collect();
        let cmd = parts[0];
        let arg = parts.get(1).map(|s| s.trim());

        match cmd {
            ":quit" | ":q" => {
                println!("Goodbye!");
                return Ok(true);
            }
            ":help" | ":h" => {
                println!("{}", HELP);
            }
            ":clear" | ":c" => {
                print!("\x1B[2J\x1B[1;1H");
            }
            ":reset" | ":r" => {
                self.interpreter = Interpreter::new();
                self.typechecker = TypeChecker::new();
                if let Some(helper) = self.editor.helper_mut() {
                    helper.identifiers.clear();
                }
                println!("Interpreter and type checker state reset.");
            }
            ":load" | ":l" => {
                if let Some(path) = arg {
                    self.load_file(path);
                } else {
                    println!("Usage: :load <filename>");
                }
            }
            ":ast" => {
                if let Some(code) = arg {
                    self.show_ast(code);
                } else {
                    println!("Usage: :ast <expression>");
                }
            }
            ":type" | ":t" => {
                if let Some(code) = arg {
                    self.show_type(code);
                } else {
                    println!("Usage: :type <expression>");
                }
            }
            ":env" => {
                self.show_env();
            }
            ":lint" => {
                self.lint_enabled = !self.lint_enabled;
                println!(
                    "Linting is now {}",
                    if self.lint_enabled { "ON" } else { "OFF" }
                );
            }
            ":history" => {
                for (i, entry) in self.editor.history().iter().enumerate() {
                    println!("{}: {}", i + 1, entry);
                }
            }
            _ => {
                println!(
                    "Unknown command: {}. Type :help for available commands.",
                    cmd
                );
            }
        }

        Ok(false)
    }

    fn process_input(&mut self, input: &str) {
        // Try to parse as a program (statements/definitions)
        let lexer = Lexer::new(input);
        let tokens = match lexer.tokenize() {
            Ok(t) => t,
            Err(e) => {
                eprintln!("Lexer error: {:?}", e);
                return;
            }
        };

        let mut parser = Parser::new(tokens.clone(), input);

        // First, try parsing as a full program
        match parser.parse() {
            Ok(program) => {
                // Collect identifiers for completion
                for item in &program.items {
                    if let TopLevelItem::Function(f) = item {
                        if let Some(helper) = self.editor.helper_mut() {
                            helper.add_identifier(&f.name);
                        }
                    }
                }

                // Type check if linting is enabled
                if self.lint_enabled {
                    if let Err(e) = self.typechecker.check_program(&program) {
                        eprintln!("Type error: {}", e);
                        return;
                    }
                }

                if let Err(e) = self.interpreter.run(&program) {
                    eprintln!("Runtime error: {}", e);
                }
            }
            Err(_) => {
                // Try wrapping as an expression in a function and evaluating
                let wrapped = format!(
                    "to __repl_expr__() {{ remember __result__ = {}; print(__result__); }}
                     to main() {{ __repl_expr__(); }}",
                    input.trim_end_matches(';')
                );

                let lexer = Lexer::new(&wrapped);
                if let Ok(tokens) = lexer.tokenize() {
                    let mut parser = Parser::new(tokens, &wrapped);
                    if let Ok(program) = parser.parse() {
                        // Type check if linting is enabled
                        if self.lint_enabled {
                            if let Err(e) = self.typechecker.check_program(&program) {
                                eprintln!("Type error: {}", e);
                                return;
                            }
                        }

                        if let Err(e) = self.interpreter.run(&program) {
                            eprintln!("Error: {}", e);
                        }
                    } else {
                        eprintln!("Parse error in input");
                    }
                }
            }
        }
    }

    fn load_file(&mut self, path: &str) {
        match std::fs::read_to_string(path) {
            Ok(source) => {
                println!("Loading {}...", path);
                let lexer = Lexer::new(&source);
                match lexer.tokenize() {
                    Ok(tokens) => {
                        let mut parser = Parser::new(tokens, &source);
                        match parser.parse() {
                            Ok(program) => {
                                // Type check
                                if self.lint_enabled {
                                    if let Err(e) = self.typechecker.check_program(&program) {
                                        eprintln!("Type error: {}", e);
                                        return;
                                    }
                                }

                                // Collect identifiers for completion
                                for item in &program.items {
                                    if let TopLevelItem::Function(f) = item {
                                        if let Some(helper) = self.editor.helper_mut() {
                                            helper.add_identifier(&f.name);
                                        }
                                    }
                                }

                                if let Err(e) = self.interpreter.run(&program) {
                                    eprintln!("Runtime error: {}", e);
                                } else {
                                    println!("Loaded successfully.");
                                }
                            }
                            Err(e) => eprintln!("Parse error: {:?}", e),
                        }
                    }
                    Err(e) => eprintln!("Lexer error: {:?}", e),
                }
            }
            Err(e) => eprintln!("Could not read file: {}", e),
        }
    }

    fn show_ast(&self, code: &str) {
        let lexer = Lexer::new(code);
        match lexer.tokenize() {
            Ok(tokens) => {
                let mut parser = Parser::new(tokens, code);
                match parser.parse() {
                    Ok(program) => {
                        println!("{:#?}", program);
                    }
                    Err(e) => eprintln!("Parse error: {:?}", e),
                }
            }
            Err(e) => eprintln!("Lexer error: {:?}", e),
        }
    }

    fn show_type(&self, code: &str) {
        // Wrap as an expression to infer type
        let wrapped = format!(
            "to __type_check__() {{ remember __result__ = {}; give back __result__; }}",
            code.trim_end_matches(';')
        );

        let lexer = Lexer::new(&wrapped);
        if let Ok(tokens) = lexer.tokenize() {
            let mut parser = Parser::new(tokens, &wrapped);
            if let Ok(program) = parser.parse() {
                let mut tc = TypeChecker::new();
                match tc.check_program(&program) {
                    Ok(()) => {
                        // TODO: Actually return the inferred type from type checker
                        println!("Expression type checks successfully");
                    }
                    Err(e) => eprintln!("Type error: {}", e),
                }
            } else {
                eprintln!("Parse error");
            }
        }
    }

    fn show_env(&self) {
        println!("(Environment inspection not yet implemented)");
        println!("Available identifiers for completion:");
        if let Some(helper) = self.editor.helper() {
            for ident in &helper.identifiers {
                println!("  {}", ident);
            }
        }
    }
}

impl Default for Repl {
    fn default() -> Self {
        Self::new().expect("Failed to create REPL")
    }
}
