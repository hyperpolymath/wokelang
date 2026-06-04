<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# WokeLang for Visual Studio Code

Official VS Code extension for WokeLang - a human-centered programming language with consent-driven capabilities.

## Features

- **Syntax Highlighting** - Full syntax highlighting for `.woke` files
- **Auto-Completion** - Intelligent code completion for:
  - Keywords (to, give, remember, when, attempt, worker, etc.)
  - Standard library modules (std.math, std.string, std.array, etc.)
  - Standard library functions (55+ functions with signatures)
  - Local variables and functions (from type inference)
- **Hover Documentation** - Rich markdown documentation on hover
  - Keyword explanations with syntax examples
  - Type information for variables and functions
  - Function signatures for stdlib functions
- **Go-to-Definition** - Jump to definition with F12 or Cmd+Click
  - Functions, types, constants, variables
  - Nested scope support
- **Real-time Diagnostics** - Instant error detection
  - Lexer errors (syntax errors)
  - Parser errors (structural errors)
  - Linter warnings (code quality)
- **Document Formatting** - Format code with Shift+Alt+F
  - Consistent indentation
  - AST-based formatting

## Installation

### Prerequisites

1. Install WokeLang and build the LSP server:
   ```bash
   cd /path/to/wokelang
   cargo build --bin woke-lsp --release
   ```

2. Make `woke-lsp` available in your PATH, or note the full path to the binary.

### Install Extension

**Option 1: From Source**
```bash
cd /path/to/wokelang/editors/vscode
npm install
npm run compile
code --install-extension .
```

**Option 2: Copy to Extensions Directory**
```bash
cp -r /path/to/wokelang/editors/vscode ~/.vscode/extensions/wokelang-0.1.0/
```

## Configuration

Open VS Code settings (Cmd+,) and configure:

```json
{
  "wokelang.serverPath": "/path/to/woke-lsp",
  "wokelang.trace.server": "off"
}
```

### Settings

- `wokelang.serverPath` - Path to the `woke-lsp` executable (default: `woke-lsp`)
- `wokelang.trace.server` - LSP server logging level:
  - `off` - No logging (default)
  - `messages` - Log messages only
  - `verbose` - Verbose logging

## Usage

1. Open a `.woke` file in VS Code
2. The WokeLang LSP server will start automatically
3. You'll see "WokeLang LSP connected" in the status bar

### Features in Action

**Auto-Completion:**
- Type `std.` → See all stdlib modules
- Type `std.math.` → See all math functions
- Type `rem` → See `remember` keyword suggestion

**Hover:**
- Hover over `to` → See function definition syntax
- Hover over a variable → See its inferred type

**Go-to-Definition:**
- Press F12 on a function call → Jump to function definition
- Cmd+Click on a variable → Jump to declaration

**Formatting:**
- Press Shift+Alt+F → Format entire document

## Example

```wokelang
// Define a function
to calculateArea(width, height) {
    give back width * height;
}

// Use standard library
to main() {
    remember result = calculateArea(5, 10);
    remember rounded = std.math.round(3.7);

    when result > 20 {
        print("Large area");
    } otherwise {
        print("Small area");
    }
}
```

## Troubleshooting

### Extension Not Activating
- Ensure the file has `.woke` extension
- Check that `woke-lsp` is in your PATH or configured in settings

### No Completions/Hover
- Check the Output panel (View → Output → WokeLang Language Server)
- Verify `woke-lsp` is running: `ps aux | grep woke-lsp`

### Server Crashes
- Check LSP server logs for errors
- Try increasing trace level: `"wokelang.trace.server": "verbose"`

## Development

### Build Extension
```bash
cd editors/vscode
npm install
npm run compile
```

### Watch Mode (for development)
```bash
npm run watch
```

### Package Extension
```bash
npm install -g vsce
vsce package
```

This creates `wokelang-0.1.0.vsix` that can be installed with:
```bash
code --install-extension wokelang-0.1.0.vsix
```

## License

MPL-2.0

## Links

- [WokeLang Repository](https://github.com/hyperpolymath/wokelang)
- [Report Issues](https://github.com/hyperpolymath/wokelang/issues)
- [Documentation](https://wokelang.org)

## Credits

**Author:** Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
**Co-Authored-By:** Claude Sonnet 4.5 <noreply@anthropic.com>
