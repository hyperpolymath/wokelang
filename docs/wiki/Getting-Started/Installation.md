# Installation

This guide covers how to install WokeLang on your system.

---

## Requirements

- **Rust** 1.70 or later (for building from source)
- **Cargo** (comes with Rust)
- A terminal/command-line interface

---

## Installation Methods

### From Source (Recommended)

1. **Clone the repository:**
```bash
git clone https://github.com/hyperpolymath/wokelang.git
cd wokelang
```

2. **Build the project:**
```bash
cargo build --release
```

3. **Install the binary:**
```bash
cargo install --path .
```

This installs the `woke` command to `~/.cargo/bin/`.

### Verify Installation

```bash
woke --version
# Output: woke 0.1.0
```

---

## Build Targets

### Standard Binary

```bash
cargo build --release
# Binary at: target/release/woke
```

### Shared Library (for FFI)

```bash
cargo build --release
# Produces:
#   target/release/libwokelang.so (Linux)
#   target/release/libwokelang.dylib (macOS)
#   target/release/wokelang.dll (Windows)
```

### Static Library

```bash
cargo build --release
# Produces: target/release/libwokelang.a
```

### WASM Build

For WebAssembly compilation target:

```bash
cargo build --release --target wasm32-unknown-unknown
```

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux (x86_64) | Fully supported | Primary development platform |
| macOS (x86_64) | Fully supported | |
| macOS (ARM64) | Fully supported | Apple Silicon |
| Windows (x86_64) | Supported | May require Visual Studio Build Tools |
| WebAssembly | Experimental | Via `woke compile --wasm` |

---

## Directory Structure

After installation, the WokeLang project has this structure:

```
wokelang/
├── src/
│   ├── lexer/      # Tokenizer
│   ├── parser/     # Recursive descent parser
│   ├── ast/        # Abstract syntax tree types
│   ├── interpreter/# Tree-walking interpreter
│   ├── codegen/    # WASM compiler
│   ├── ffi/        # C/Zig FFI bindings
│   └── main.rs     # CLI entry point
├── grammar/        # EBNF specification
├── examples/       # Example programs
├── include/        # C header files
├── zig/            # Zig bindings
└── docs/           # Documentation
```

---

## Troubleshooting

### "command not found: woke"

Ensure `~/.cargo/bin` is in your PATH:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

Add this to your shell configuration file (`.bashrc`, `.zshrc`, etc.).

### Build Errors

1. **Update Rust:**
```bash
rustup update
```

2. **Clean and rebuild:**
```bash
cargo clean
cargo build --release
```

### Missing Dependencies

The project requires these crates (automatically downloaded by Cargo):
- `logos` - Lexer generator
- `thiserror` - Error handling
- `miette` - Diagnostic formatting
- `rustyline` - REPL line editing
- `wasm-encoder` - WASM code generation

---

## Next Steps

- [Hello, World!](Hello-World.md) - Write your first WokeLang program
- [Basic Syntax](Basic-Syntax.md) - Learn the fundamentals
- [REPL Guide](REPL.md) - Interactive development
