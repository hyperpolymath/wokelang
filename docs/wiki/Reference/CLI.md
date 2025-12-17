# CLI Reference

The `woke` command-line interface for WokeLang.

---

## Installation

```bash
cargo install --path .
# or
cargo build --release
# Binary at: target/release/woke
```

---

## Basic Usage

```bash
# Run a WokeLang file
woke program.woke

# Start the REPL
woke repl

# Show version
woke --version

# Show help
woke --help
```

---

## Commands

### Run (Default)

Execute a WokeLang source file:

```bash
woke <file.woke>
woke run <file.woke>
```

**Options:**
| Flag | Description |
|------|-------------|
| `-v, --verbose` | Show execution details |
| `--no-hello` | Suppress hello/goodbye messages |

**Example:**
```bash
woke examples/demo.woke
woke run --verbose examples/demo.woke
```

### REPL

Start the interactive Read-Eval-Print Loop:

```bash
woke repl
```

**REPL Commands:**
| Command | Description |
|---------|-------------|
| `:help` | Show help |
| `:quit` | Exit REPL |
| `:reset` | Clear state |
| `:load <file>` | Load a file |
| `:ast <expr>` | Show AST |

### Compile

Compile WokeLang to WebAssembly:

```bash
woke compile [OPTIONS] <file.woke>
```

**Options:**
| Flag | Description |
|------|-------------|
| `--wasm` | Output WASM binary |
| `-o, --output <file>` | Output file path |
| `--opt-level <level>` | Optimization level (0, 1, s, z) |
| `--wat` | Output WAT (text format) |

**Example:**
```bash
woke compile --wasm -o add.wasm math.woke
woke compile --wat -o debug.wat math.woke
```

### Check

Parse and type-check without executing:

```bash
woke check <file.woke>
```

**Options:**
| Flag | Description |
|------|-------------|
| `--strict` | Enable strict mode |
| `--ast` | Print AST |
| `--tokens` | Print token stream |

**Example:**
```bash
woke check --strict program.woke
woke check --ast program.woke
```

### Format (Planned)

Format WokeLang source code:

```bash
woke fmt <file.woke>
woke fmt --check <file.woke>  # Check without modifying
```

---

## Global Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help message |
| `-V, --version` | Show version |
| `-q, --quiet` | Suppress output |
| `--color <when>` | Color output (auto, always, never) |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Parse error |
| 3 | Runtime error |
| 4 | File not found |

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WOKE_PATH` | Module search paths | `.` |
| `WOKE_COLOR` | Color output | `auto` |
| `WOKE_VERBOSE` | Verbose output | `false` |

---

## Configuration Files

### Project Configuration (woke.toml)

```toml
[package]
name = "my-project"
version = "0.1.0"
edition = "2024"

[dependencies]
# Future: package dependencies

[build]
opt-level = "s"
target = "wasm"
```

---

## Examples

### Running Programs

```bash
# Simple run
woke hello.woke

# With verbose output
woke -v program.woke

# Multiple files (planned)
woke main.woke lib.woke
```

### REPL Session

```bash
$ woke repl
WokeLang REPL v0.1.0
Type :help for commands, :quit to exit

woke> remember x = 42
woke> print(x * 2)
84
woke> :quit
```

### Compilation

```bash
# Compile to WASM
woke compile --wasm -o output.wasm input.woke

# View as WAT
woke compile --wat -o output.wat input.woke

# Optimized build
woke compile --wasm --opt-level=s -o optimized.wasm input.woke
```

### Checking Code

```bash
# Basic check
woke check program.woke

# Strict mode
woke check --strict program.woke

# View parsed AST
woke check --ast program.woke
```

---

## Shell Completion

### Bash

```bash
# Add to ~/.bashrc
eval "$(woke completions bash)"
```

### Zsh

```bash
# Add to ~/.zshrc
eval "$(woke completions zsh)"
```

### Fish

```bash
woke completions fish > ~/.config/fish/completions/woke.fish
```

---

## Debugging

### Verbose Output

```bash
woke -v program.woke
# Shows: parsing, execution phases, timing
```

### Token Stream

```bash
woke check --tokens program.woke
# Output:
# [0..2] Remember
# [3..4] Identifier("x")
# [5..6] Equal
# ...
```

### AST Dump

```bash
woke check --ast program.woke
# Output:
# Program {
#   items: [
#     Function {
#       name: "main",
#       ...
#     }
#   ]
# }
```

---

## Integration

### With Make

```makefile
WOKE = woke
WASM_FLAGS = --wasm --opt-level=s

%.wasm: %.woke
	$(WOKE) compile $(WASM_FLAGS) -o $@ $<

all: main.wasm

clean:
	rm -f *.wasm
```

### With npm/package.json

```json
{
  "scripts": {
    "build": "woke compile --wasm -o dist/main.wasm src/main.woke",
    "check": "woke check src/*.woke",
    "test": "woke test"
  }
}
```

### With CI (GitHub Actions)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Rust
        uses: dtolnay/rust-action@stable
      - name: Build WokeLang
        run: cargo build --release
      - name: Check code
        run: ./target/release/woke check src/*.woke
      - name: Compile to WASM
        run: ./target/release/woke compile --wasm -o output.wasm src/main.woke
```

---

## Next Steps

- [REPL Guide](../Getting-Started/REPL.md)
- [Installation](../Getting-Started/Installation.md)
- [WASM Compilation](../Internals/WASM-Compilation.md)
