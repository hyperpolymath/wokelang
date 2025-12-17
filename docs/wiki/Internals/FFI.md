# FFI (Foreign Function Interface)

WokeLang provides a C-compatible FFI for embedding in other languages.

---

## Overview

The FFI allows:

- **Embedding**: Use WokeLang in C, C++, Zig, Go, Python, etc.
- **Extension**: Call native code from WokeLang
- **Integration**: Build hybrid applications

---

## C API

### Header File

Located in `include/wokelang.h`:

```c
#ifndef WOKELANG_H
#define WOKELANG_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque types */
typedef struct WokeInterpreter WokeInterpreter;
typedef struct WokeValue WokeValue;

/* Result codes */
typedef enum WokeResult {
    WOKE_OK = 0,
    WOKE_ERROR = 1,
    WOKE_PARSE_ERROR = 2,
    WOKE_RUNTIME_ERROR = 3,
    WOKE_NULL_POINTER = 4
} WokeResult;

/* Value type tags */
typedef enum WokeValueType {
    WOKE_TYPE_INT = 0,
    WOKE_TYPE_FLOAT = 1,
    WOKE_TYPE_STRING = 2,
    WOKE_TYPE_BOOL = 3,
    WOKE_TYPE_ARRAY = 4,
    WOKE_TYPE_UNIT = 5
} WokeValueType;

/* Interpreter lifecycle */
WokeInterpreter* woke_interpreter_new(void);
void woke_interpreter_free(WokeInterpreter* interp);

/* Execution */
WokeResult woke_exec(WokeInterpreter* interp, const char* source);
WokeResult woke_eval(WokeInterpreter* interp, const char* source, WokeValue** out);

/* Value operations */
void woke_value_free(WokeValue* value);
WokeValueType woke_value_type(const WokeValue* value);
WokeResult woke_value_as_int(const WokeValue* value, int64_t* out);
WokeResult woke_value_as_float(const WokeValue* value, double* out);
WokeResult woke_value_as_bool(const WokeValue* value, int* out);
char* woke_value_as_string(const WokeValue* value);
void woke_string_free(char* s);

/* Value creation */
WokeValue* woke_value_from_int(int64_t n);
WokeValue* woke_value_from_float(double f);
WokeValue* woke_value_from_bool(int b);
WokeValue* woke_value_from_string(const char* s);

/* Utility */
const char* woke_version(void);
const char* woke_last_error(void);

#ifdef __cplusplus
}
#endif

#endif /* WOKELANG_H */
```

---

## Rust Implementation

Located in `src/ffi/c_api.rs`:

```rust
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_double, c_int, c_longlong};
use std::ptr;

/// Opaque handle to interpreter
pub struct WokeInterpreter {
    inner: Interpreter,
}

/// Opaque handle to value
pub struct WokeValue {
    inner: Value,
}

#[repr(C)]
pub enum WokeResult {
    Ok = 0,
    Error = 1,
    ParseError = 2,
    RuntimeError = 3,
    NullPointer = 4,
}

#[no_mangle]
pub extern "C" fn woke_interpreter_new() -> *mut WokeInterpreter {
    Box::into_raw(Box::new(WokeInterpreter {
        inner: Interpreter::new(),
    }))
}

#[no_mangle]
pub unsafe extern "C" fn woke_interpreter_free(interp: *mut WokeInterpreter) {
    if !interp.is_null() {
        drop(Box::from_raw(interp));
    }
}

#[no_mangle]
pub unsafe extern "C" fn woke_exec(
    interp: *mut WokeInterpreter,
    source: *const c_char,
) -> WokeResult {
    if interp.is_null() || source.is_null() {
        return WokeResult::NullPointer;
    }

    let interp = &mut *interp;
    let source = match CStr::from_ptr(source).to_str() {
        Ok(s) => s,
        Err(_) => return WokeResult::Error,
    };

    let lexer = Lexer::new(source);
    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(_) => return WokeResult::ParseError,
    };

    let mut parser = Parser::new(tokens, source);
    let program = match parser.parse() {
        Ok(p) => p,
        Err(_) => return WokeResult::ParseError,
    };

    match interp.inner.run(&program) {
        Ok(_) => WokeResult::Ok,
        Err(_) => WokeResult::RuntimeError,
    }
}
```

---

## Build Configuration

### Cargo.toml

```toml
[lib]
name = "wokelang"
path = "src/lib.rs"
crate-type = ["lib", "cdylib", "staticlib"]
```

### Build Outputs

```bash
cargo build --release

# Produces:
# target/release/libwokelang.so   (Linux shared)
# target/release/libwokelang.a    (Linux static)
# target/release/libwokelang.dylib (macOS shared)
# target/release/wokelang.dll     (Windows shared)
```

---

## Language Bindings

### C Example

```c
#include <stdio.h>
#include "wokelang.h"

int main() {
    WokeInterpreter* interp = woke_interpreter_new();
    if (!interp) {
        fprintf(stderr, "Failed to create interpreter\n");
        return 1;
    }

    const char* code =
        "to greet(name: String) → String {\n"
        "    give back \"Hello, \" + name + \"!\";\n"
        "}\n"
        "to main() {\n"
        "    print(greet(\"World\"));\n"
        "}\n";

    WokeResult result = woke_exec(interp, code);
    if (result != WOKE_OK) {
        fprintf(stderr, "Execution error: %d\n", result);
    }

    woke_interpreter_free(interp);
    return 0;
}
```

Compile:
```bash
gcc -o example example.c -L./target/release -lwokelang -lpthread -ldl -lm
```

### Zig Bindings

Located in `zig/wokelang.zig`:

```zig
const std = @import("std");

pub const WokeResult = enum(c_int) {
    ok = 0,
    @"error" = 1,
    parse_error = 2,
    runtime_error = 3,
    null_pointer = 4,
};

pub const WokeValueType = enum(c_int) {
    int = 0,
    float = 1,
    string = 2,
    bool = 3,
    array = 4,
    unit = 5,
};

pub const WokeInterpreter = opaque {};
pub const WokeValue = opaque {};

// External C functions
extern fn woke_interpreter_new() ?*WokeInterpreter;
extern fn woke_interpreter_free(interp: ?*WokeInterpreter) void;
extern fn woke_exec(interp: ?*WokeInterpreter, source: [*:0]const u8) WokeResult;
extern fn woke_value_type(value: ?*const WokeValue) WokeValueType;
extern fn woke_value_as_int(value: ?*const WokeValue, out: *i64) WokeResult;
extern fn woke_value_as_string(value: ?*const WokeValue) ?[*:0]u8;
extern fn woke_string_free(s: ?[*:0]u8) void;
extern fn woke_value_free(value: ?*WokeValue) void;
extern fn woke_version() [*:0]const u8;

/// High-level Zig wrapper
pub const Interpreter = struct {
    ptr: *WokeInterpreter,

    pub fn init() !Interpreter {
        const ptr = woke_interpreter_new() orelse return error.FailedToCreateInterpreter;
        return Interpreter{ .ptr = ptr };
    }

    pub fn deinit(self: *Interpreter) void {
        woke_interpreter_free(self.ptr);
    }

    pub fn exec(self: *Interpreter, source: [:0]const u8) !void {
        const result = woke_exec(self.ptr, source.ptr);
        return switch (result) {
            .ok => {},
            .parse_error => error.ParseError,
            .runtime_error => error.RuntimeError,
            else => error.Unknown,
        };
    }
};

pub fn version() []const u8 {
    return std.mem.span(woke_version());
}
```

### Zig Example

```zig
const std = @import("std");
const woke = @import("wokelang");

pub fn main() !void {
    var interp = try woke.Interpreter.init();
    defer interp.deinit();

    try interp.exec(
        \\to main() {
        \\    print("Hello from Zig!");
        \\}
    );

    std.debug.print("WokeLang version: {s}\n", .{woke.version()});
}
```

Build with Zig:
```bash
zig build-exe example.zig -lwokelang -L./target/release
```

### Python (via ctypes)

```python
import ctypes
from ctypes import c_char_p, c_void_p, c_int, c_int64, POINTER

# Load library
lib = ctypes.CDLL("./target/release/libwokelang.so")

# Define types
lib.woke_interpreter_new.restype = c_void_p
lib.woke_interpreter_free.argtypes = [c_void_p]
lib.woke_exec.argtypes = [c_void_p, c_char_p]
lib.woke_exec.restype = c_int
lib.woke_version.restype = c_char_p

class WokeInterpreter:
    def __init__(self):
        self.ptr = lib.woke_interpreter_new()
        if not self.ptr:
            raise RuntimeError("Failed to create interpreter")

    def __del__(self):
        if self.ptr:
            lib.woke_interpreter_free(self.ptr)

    def exec(self, source):
        result = lib.woke_exec(self.ptr, source.encode('utf-8'))
        if result != 0:
            raise RuntimeError(f"Execution error: {result}")

# Usage
interp = WokeInterpreter()
interp.exec("""
to main() {
    print("Hello from Python!");
}
""")

print(f"Version: {lib.woke_version().decode()}")
```

---

## Memory Management

### Rules

1. **Interpreter**: Created with `woke_interpreter_new`, freed with `woke_interpreter_free`
2. **Values**: Created by `woke_value_from_*`, freed with `woke_value_free`
3. **Strings**: Returned by `woke_value_as_string`, freed with `woke_string_free`

### Example

```c
// Create
WokeInterpreter* interp = woke_interpreter_new();
WokeValue* value = woke_value_from_int(42);

// Use
int64_t n;
woke_value_as_int(value, &n);

// Free (in reverse order)
woke_value_free(value);
woke_interpreter_free(interp);
```

---

## Error Handling

### Result Codes

| Code | Meaning |
|------|---------|
| `WOKE_OK` (0) | Success |
| `WOKE_ERROR` (1) | General error |
| `WOKE_PARSE_ERROR` (2) | Syntax error |
| `WOKE_RUNTIME_ERROR` (3) | Runtime error |
| `WOKE_NULL_POINTER` (4) | NULL argument |

### Error Messages

```c
WokeResult result = woke_exec(interp, code);
if (result != WOKE_OK) {
    const char* error = woke_last_error();
    if (error) {
        fprintf(stderr, "Error: %s\n", error);
    }
}
```

---

## Thread Safety

- Each `WokeInterpreter` instance is **not thread-safe**
- Create separate interpreters for each thread
- Values can be passed between threads once extracted

---

## Performance Considerations

1. **String conversion**: Allocates new memory; cache when possible
2. **Repeated execution**: Reuse interpreter instance
3. **Batch operations**: Prefer single exec with multiple statements

---

## Platform Support

| Platform | Shared Library | Static Library |
|----------|---------------|----------------|
| Linux x86_64 | libwokelang.so | libwokelang.a |
| macOS x86_64 | libwokelang.dylib | libwokelang.a |
| macOS ARM64 | libwokelang.dylib | libwokelang.a |
| Windows | wokelang.dll | wokelang.lib |

---

## Next Steps

- [WASM Compilation](WASM-Compilation.md)
- [Interpreter Internals](Interpreter.md)
- [CLI Reference](../Reference/CLI.md)
