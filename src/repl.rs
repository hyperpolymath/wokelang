use crate::ast::TopLevelItem;
use crate::interpreter::Interpreter;
use crate::lexer::Lexer;
use crate::parser::Parser;
use rustyline::error::ReadlineError;
use rustyline::DefaultEditor;

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
  :help, :h     Show this help message
  :quit, :q     Exit the REPL
  :clear, :c    Clear the screen
  :reset, :r    Reset interpreter state
  :load <file>  Load and run a file
  :ast <expr>   Show AST for an expression
  :env          Show current environment variables

Examples:
  remember x = 42;
  print(x + 8);
  to double(n) { give back n * 2; }
  double(21)
"#;

pub struct Repl {
    interpreter: Interpreter,
    editor: DefaultEditor,
}

impl Repl {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let editor = DefaultEditor::new()?;
        Ok(Self {
            interpreter: Interpreter::new(),
            editor,
        })
    }

    pub fn run(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        println!("{}", BANNER);
        println!("WokeLang v0.1.0 - Interactive REPL");
        println!("Type :help for commands, :quit to exit\n");

        loop {
            let readline = self.editor.readline("woke> ");

            match readline {
                Ok(line) => {
                    let line = line.trim();
                    if line.is_empty() {
                        continue;
                    }

                    let _ = self.editor.add_history_entry(line);

                    if line.starts_with(':') {
                        if self.handle_command(line)? {
                            break;
                        }
                    } else {
                        self.eval_input(line);
                    }
                }
                Err(ReadlineError::Interrupted) => {
                    println!("^C");
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

        Ok(())
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
                println!("Interpreter state reset.");
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
            ":env" => {
                println!("(Environment inspection not yet implemented)");
            }
            _ => {
                println!("Unknown command: {}. Type :help for available commands.", cmd);
            }
        }

        Ok(false)
    }

    fn eval_input(&mut self, input: &str) {
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
                if let Err(e) = self.interpreter.run(&program) {
                    eprintln!("Runtime error: {}", e);
                } else {
                    // Check if the last item was a simple expression, print its value
                    if let Some(TopLevelItem::Function(f)) = program.items.last() {
                        if f.name == "__repl_expr__" {
                            // This was a wrapped expression, value already printed
                        }
                    }
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
                        if let Err(e) = self.interpreter.run(&program) {
                            // If that also fails, show original parse error
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
}

impl Default for Repl {
    fn default() -> Self {
        Self::new().expect("Failed to create REPL")
    }
}
