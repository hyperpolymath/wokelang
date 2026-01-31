// SPDX-License-Identifier: PMPL-1.0-or-later
//! WokeLang REPL (Read-Eval-Print Loop)
//!
//! Interactive shell for experimenting with WokeLang.

use crate::{Interpreter, Lexer, Parser};
use miette::Result;
use rustyline::error::ReadlineError;
use rustyline::{DefaultEditor, Result as RustyResult};

pub struct Repl {
    editor: DefaultEditor,
    interpreter: Interpreter,
}

impl Repl {
    pub fn new() -> RustyResult<Self> {
        Ok(Self {
            editor: DefaultEditor::new()?,
            interpreter: Interpreter::new(),
        })
    }

    pub fn run(&mut self) -> Result<()> {
        println!("WokeLang v0.1.0 - Interactive REPL");
        println!("Type 'exit' or press Ctrl+D to quit\n");

        loop {
            match self.editor.readline("woke> ") {
                Ok(line) => {
                    let line = line.trim();

                    if line.is_empty() {
                        continue;
                    }

                    if line == "exit" || line == "quit" {
                        break;
                    }

                    // Add to history
                    let _ = self.editor.add_history_entry(line);

                    // Execute the line
                    if let Err(e) = self.execute(line) {
                        eprintln!("Error: {}", e);
                    }
                }
                Err(ReadlineError::Interrupted) => {
                    println!("^C");
                    continue;
                }
                Err(ReadlineError::Eof) => {
                    println!("^D");
                    break;
                }
                Err(err) => {
                    eprintln!("Error: {:?}", err);
                    break;
                }
            }
        }

        println!("Goodbye!");
        Ok(())
    }

    fn execute(&mut self, source: &str) -> Result<()> {
        // Lex
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize()?;

        // Parse
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse()?;

        // Interpret
        match self.interpreter.run(&program) {
            Ok(_value) => {
                // TODO: Print the result value
                // println!("{}", value);
            }
            Err(e) => {
                eprintln!("Runtime error: {}", e);
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_repl_creation() {
        let repl = Repl::new();
        assert!(repl.is_ok());
    }
}
