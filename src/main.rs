// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//
// WokeLang CLI - main entry point with S-expression and JSON AST dump support
use clap::{Parser, Subcommand};
use miette::Result;
use std::fs;
use std::path::PathBuf;
use wokelang::{
    disassemble as disasm_bytecode, BytecodeCompiler, Interpreter, Lexer, Linter,
    Parser as WokeParser, Repl, TypeChecker,
};

mod sexpr;

#[derive(Parser)]
#[command(name = "woke")]
#[command(version = "0.1.0")]
#[command(about = "WokeLang - A human-centered, consent-driven programming language", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    /// Input file (shorthand for 'woke run <file>')
    #[arg(value_name = "FILE")]
    file: Option<PathBuf>,
}

#[derive(Subcommand)]
enum Commands {
    /// Run a WokeLang program (tree-walking interpreter)
    Run {
        /// Path to .woke file
        file: PathBuf,
    },
    /// Start interactive REPL
    Repl,
    /// Compile to bytecode (.wbc file)
    Compile {
        /// Path to .woke file
        file: PathBuf,
        /// Output bytecode file (default: <input>.wbc)
        #[arg(short, long)]
        output: Option<PathBuf>,
    },
    /// Run bytecode via VM
    RunVm {
        /// Path to .wbc bytecode file
        file: PathBuf,
    },
    /// Disassemble bytecode
    Disasm {
        /// Path to .wbc bytecode file
        file: PathBuf,
    },
    /// Type-check without running
    Typecheck {
        /// Path to .woke file
        file: PathBuf,
    },
    /// Run linter (static analysis)
    Lint {
        /// Path to .woke file
        file: PathBuf,
    },
    /// Show lexer tokens (debug)
    Tokenize {
        /// Path to .woke file
        file: PathBuf,
    },
    /// Show parsed AST (debug)
    Parse {
        /// Path to .woke file
        file: PathBuf,

        /// Output format: pretty (default), sexpr, json
        #[arg(short, long, default_value = "pretty")]
        output: String,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Handle shorthand: `woke file.woke` → `woke run file.woke`
    let command = match (cli.command, cli.file) {
        (Some(cmd), _) => cmd,
        (None, Some(file)) => Commands::Run { file },
        (None, None) => {
            // No args - show help
            println!("WokeLang v0.1.0 - A human-centered, consent-driven programming language");
            println!();
            println!("Usage: woke <COMMAND> [OPTIONS]");
            println!();
            println!("Commands:");
            println!("  run          Run a WokeLang program (tree-walking interpreter)");
            println!("  repl         Start interactive REPL");
            println!("  compile      Compile to bytecode (.wbc file)");
            println!("  run-vm       Run bytecode via VM");
            println!("  disasm       Disassemble bytecode");
            println!("  typecheck    Type-check without running");
            println!("  lint         Run linter (static analysis)");
            println!("  tokenize     Show lexer tokens (debug)");
            println!("  parse        Show parsed AST (debug)");
            println!();
            println!("Run 'woke --help' for more information.");
            return Ok(());
        }
    };

    match command {
        Commands::Repl => {
            let mut repl = Repl::new().expect("Failed to create REPL");
            repl.run().expect("REPL error");
        }

        Commands::Run { file } => {
            run_program(&file)?;
        }

        Commands::Compile { file, output } => {
            compile_program(&file, output)?;
        }

        Commands::RunVm { file } => {
            run_vm(&file)?;
        }

        Commands::Disasm { file } => {
            disassemble(&file)?;
        }

        Commands::Typecheck { file } => {
            typecheck_program(&file)?;
        }

        Commands::Lint { file } => {
            lint_program(&file)?;
        }

        Commands::Tokenize { file } => {
            tokenize_file(&file)?;
        }

        Commands::Parse { file, output } => {
            parse_file(&file, &output)?;
        }
    }

    Ok(())
}

fn run_program(file: &PathBuf) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut parser = WokeParser::new(tokens, &source);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    // Type check first
    let mut typechecker = TypeChecker::new();
    if let Err(e) = typechecker.check_program(&program) {
        eprintln!("Type error: {}", e);
        eprintln!("\nType checking failed. Not running.");
        return Ok(());
    }

    // Run the program
    let mut interpreter = Interpreter::new();
    if let Err(e) = interpreter.run(&program) {
        eprintln!("Runtime error: {}", e);
    }

    Ok(())
}

fn compile_program(file: &PathBuf, _output: Option<PathBuf>) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut parser = WokeParser::new(tokens, &source);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    // Type check
    let mut typechecker = TypeChecker::new();
    if let Err(e) = typechecker.check_program(&program) {
        eprintln!("Type error: {}", e);
        eprintln!("\nType checking failed. Not compiling.");
        return Ok(());
    }

    // Compile to bytecode
    let mut compiler = BytecodeCompiler::new();
    let compiled = match compiler.compile(&program) {
        Ok(bc) => bc,
        Err(e) => {
            eprintln!("Compilation error: {}", e);
            return Ok(());
        }
    };

    // Show compilation success and stats
    println!("✓ Compiled successfully!");
    println!("  {} function(s)", compiled.functions.len());
    if let Some(entry) = compiled.entry {
        println!("  Entry point: {}", compiled.functions[entry].name);
    }

    // Note: bytecode file I/O will be added when serialization is implemented
    println!("\nNote: Bytecode serialization not yet implemented.");
    println!(
        "Use 'woke run-vm {}' to execute via VM (in-memory)",
        file.display()
    );

    Ok(())
}

fn run_vm(file: &PathBuf) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");

    // Use the vm::run_vm helper which compiles and runs
    match wokelang::vm::run_vm(&source) {
        Ok(result) => {
            println!("{:?}", result);
        }
        Err(e) => {
            eprintln!("VM error: {}", e);
        }
    }

    Ok(())
}

fn disassemble(file: &PathBuf) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");

    // Compile to bytecode
    let compiled = match wokelang::vm::compile(&source) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Compilation error: {}", e);
            return Ok(());
        }
    };

    // Use the vm::disassemble helper
    let disasm = disasm_bytecode(&compiled);
    println!("{}", disasm);

    Ok(())
}

fn typecheck_program(file: &PathBuf) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut parser = WokeParser::new(tokens, &source);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut typechecker = TypeChecker::new();
    match typechecker.check_program(&program) {
        Ok(()) => {
            println!("✓ Type check passed!");
        }
        Err(e) => {
            eprintln!("Type error: {}", e);
        }
    }

    Ok(())
}

fn lint_program(file: &PathBuf) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut parser = WokeParser::new(tokens, &source);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut linter = Linter::new();
    let diagnostics = linter.lint(&program);

    if diagnostics.is_empty() {
        println!("✓ No issues found!");
    } else {
        println!("Found {} issue(s):\n", diagnostics.len());
        for diag in &diagnostics {
            let severity_str = match diag.severity {
                wokelang::linter::Severity::Error => "error",
                wokelang::linter::Severity::Warning => "warning",
                wokelang::linter::Severity::Info => "info",
            };
            println!("[{}] {}: {}", severity_str, diag.code, diag.message);
        }
    }

    Ok(())
}

fn tokenize_file(file: &PathBuf) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    for token in &tokens {
        println!("{:?} @ {:?}", token.value, token.span);
    }
    println!("\nTokenized {} tokens successfully.", tokens.len());

    Ok(())
}

/// Parse a .woke file and display the AST in the chosen output format.
///
/// Supports three output modes:
/// - `pretty` (default): Rust Debug formatting
/// - `sexpr` / `sexp`: S-expression representation
/// - `json`: JSON serialization via serde_json
fn parse_file(file: &PathBuf, format: &str) -> Result<()> {
    let source = fs::read_to_string(file).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    let mut parser = WokeParser::new(tokens, &source);
    match parser.parse() {
        Ok(program) => match format {
            "json" => {
                let json = sexpr::program_to_json(&program);
                println!("{}", serde_json::to_string_pretty(&json).unwrap());
            }
            "sexpr" | "sexp" => {
                println!("{}", sexpr::program_to_sexpr(&program));
            }
            // "pretty" is the default for any unrecognised format
            _ => {
                println!("{:#?}", program);
                println!(
                    "\nParsed {} top-level items successfully.",
                    program.items.len()
                );
            }
        },
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
        }
    }

    Ok(())
}
