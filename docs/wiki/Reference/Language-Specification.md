# WokeLang Language Specification

**Version**: 0.1.0
**Status**: Draft

---

## 1. Lexical Structure

### 1.1 Character Set

WokeLang source files are encoded in UTF-8. The language supports:
- ASCII letters (a-z, A-Z)
- Digits (0-9)
- Unicode letters in strings and comments
- Special characters: `→`, `@`, `#`

### 1.2 Whitespace and Comments

```ebnf
whitespace = " " | "\t" | "\n" | "\r" ;
line_comment = "//" , { any_char } , newline ;
block_comment = "/*" , { any_char } , "*/" ;
```

### 1.3 Identifiers

```ebnf
identifier = letter , { letter | digit | "_" } ;
letter = "a".."z" | "A".."Z" ;
digit = "0".."9" ;
```

Reserved identifiers cannot be used as variable or function names.

### 1.4 Keywords

**Control Flow**
```
to, give, back, remember, when, otherwise, repeat, times
```

**Consent & Safety**
```
only, if, okay, attempt, safely, or, reassure, complain
```

**Gratitude**
```
thanks, to
```

**Lifecycle**
```
hello, goodbye
```

**Concurrency**
```
worker, side, quest, superpower, spawn
```

**Pattern Matching**
```
decide, based, on
```

**Units**
```
measured, in
```

**Types**
```
type, const, String, Int, Float, Bool, Maybe
```

**Boolean**
```
true, false, and, or, not
```

### 1.5 Literals

#### Integer Literals
```ebnf
integer = [ "-" ] , digit , { digit } ;
```

Examples: `42`, `-17`, `0`, `1000000`

#### Float Literals
```ebnf
float = [ "-" ] , digit , { digit } , "." , digit , { digit } ;
```

Examples: `3.14`, `-0.5`, `100.0`

#### String Literals
```ebnf
string = '"' , { string_char } , '"' ;
string_char = any_char_except_quote | escape_sequence ;
escape_sequence = "\\" , ( "n" | "t" | "r" | '"' | "'" | "\\" ) ;
```

Examples: `"Hello"`, `"Line1\nLine2"`, `"Tab\there"`

#### Boolean Literals
```ebnf
bool = "true" | "false" ;
```

#### Array Literals
```ebnf
array = "[" , [ expression , { "," , expression } ] , "]" ;
```

Examples: `[1, 2, 3]`, `["a", "b"]`, `[]`

---

## 2. Types

### 2.1 Primitive Types

| Type | Description | Example |
|------|-------------|---------|
| `Int` | 64-bit signed integer | `42` |
| `Float` | 64-bit floating point | `3.14` |
| `String` | UTF-8 string | `"hello"` |
| `Bool` | Boolean value | `true` |

### 2.2 Composite Types

#### Arrays
```wokelang
remember numbers: [Int] = [1, 2, 3];
remember names: [String] = ["Alice", "Bob"];
```

#### Optional Types
```wokelang
remember maybeValue: Maybe Int = findValue();
```

#### Reference Types
```wokelang
to modify(data: &[Int]) {
    // Can modify the referenced array
}
```

### 2.3 Custom Types

#### Type Aliases
```wokelang
type UserId = String;
type Temperature = Float;
```

#### Struct Types
```wokelang
type Person = {
    name: String,
    age: Int,
    email: Maybe String
};
```

#### Enum Types
```wokelang
type Result = Success(String) | Failure(String);
type Option = Some(Int) | None;
```

### 2.4 Unit Types

```wokelang
remember distance = 100 measured in meters;
remember temp = 98.6 measured in fahrenheit;
```

---

## 3. Expressions

### 3.1 Operator Precedence (lowest to highest)

| Precedence | Operators | Associativity |
|------------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=` | Left |
| 4 | `<`, `>`, `<=`, `>=` | Left |
| 5 | `+`, `-` | Left |
| 6 | `*`, `/`, `%` | Left |
| 7 | `not`, `-` (unary) | Right |
| 8 | function call, array index | Left |

### 3.2 Arithmetic Expressions

```wokelang
remember sum = a + b;
remember product = x * y;
remember quotient = total / count;
remember remainder = value % 2;
remember negative = -number;
```

### 3.3 Comparison Expressions

```wokelang
remember isEqual = a == b;
remember isNotEqual = a != b;
remember isLess = a < b;
remember isGreater = a > b;
remember isLessOrEqual = a <= b;
remember isGreaterOrEqual = a >= b;
```

### 3.4 Logical Expressions

```wokelang
remember bothTrue = a and b;
remember eitherTrue = a or b;
remember opposite = not condition;
```

### 3.5 Function Calls

```wokelang
remember result = add(1, 2);
remember greeting = greet("World");
print("Hello");
```

### 3.6 Gratitude Expressions

```wokelang
remember credit = thanks("Open Source Community");
```

---

## 4. Statements

### 4.1 Variable Declaration

```ebnf
variable_decl = "remember" , identifier , "=" , expression ,
                [ "measured" , "in" , unit ] , ";" ;
```

```wokelang
remember x = 42;
remember name = "Alice";
remember speed = 60 measured in mph;
```

### 4.2 Assignment

```ebnf
assignment = identifier , "=" , expression , ";" ;
```

```wokelang
x = x + 1;
name = "Bob";
```

### 4.3 Return Statement

```ebnf
return_stmt = "give" , "back" , expression , ";" ;
```

```wokelang
give back result;
give back x + y;
```

### 4.4 Conditional Statement

```ebnf
conditional = "when" , expression , "{" , { statement } , "}" ,
              [ "otherwise" , "{" , { statement } , "}" ] ;
```

```wokelang
when x > 0 {
    print("Positive");
} otherwise {
    print("Non-positive");
}
```

### 4.5 Loop Statement

```ebnf
loop = "repeat" , expression , "times" , "{" , { statement } , "}" ;
```

```wokelang
repeat 5 times {
    print("Hello!");
}

repeat count times {
    process(item);
}
```

### 4.6 Attempt Block

```ebnf
attempt_block = "attempt" , "safely" , "{" , { statement } , "}" ,
                "or" , "reassure" , string , ";" ;
```

```wokelang
attempt safely {
    remember data = fetchData();
    processData(data);
} or reassure "Operation failed, but that's okay";
```

### 4.7 Consent Block

```ebnf
consent_block = "only" , "if" , "okay" , string , "{" , { statement } , "}" ;
```

```wokelang
only if okay "camera_access" {
    remember photo = takePhoto();
    save(photo);
}
```

### 4.8 Complain Statement

```ebnf
complain_stmt = "complain" , string , ";" ;
```

```wokelang
complain "Something unexpected happened";
```

### 4.9 Pattern Matching

```ebnf
decide_stmt = "decide" , "based" , "on" , expression , "{" , { match_arm } , "}" ;
match_arm = pattern , "→" , "{" , { statement } , "}" ;
pattern = literal | identifier | "_" ;
```

```wokelang
decide based on status {
    "success" → {
        print("It worked!");
    }
    "error" → {
        complain "Something went wrong";
    }
    _ → {
        print("Unknown status");
    }
}
```

---

## 5. Declarations

### 5.1 Function Declaration

```ebnf
function_def = [ emote_tag ] , "to" , identifier ,
               "(" , [ param_list ] , ")" , [ "→" , type ] ,
               "{" ,
               [ "hello" , string , ";" ] ,
               { statement } ,
               [ "goodbye" , string , ";" ] ,
               "}" ;
```

```wokelang
@important
to calculateTotal(items: [Item]) → Float {
    hello "Starting calculation";

    remember total = 0.0;
    repeat len(items) times {
        total = total + items[i].price;
    }

    give back total;

    goodbye "Calculation complete";
}
```

### 5.2 Worker Declaration

```ebnf
worker_def = "worker" , identifier , "{" , { statement } , "}" ;
```

```wokelang
worker dataProcessor {
    remember data = fetchData();
    remember result = processData(data);
    saveResult(result);
}
```

### 5.3 Side Quest Declaration

```ebnf
side_quest_def = "side" , "quest" , identifier , "{" , { statement } , "}" ;
```

```wokelang
side quest backgroundSync {
    attempt safely {
        syncWithServer();
    } or reassure "Sync will retry later";
}
```

### 5.4 Gratitude Declaration

```ebnf
gratitude_decl = "thanks" , "to" , "{" , { gratitude_entry } , "}" ;
gratitude_entry = string , "→" , string , ";" ;
```

```wokelang
thanks to {
    "Rust Community" → "For the amazing tooling";
    "Contributors" → "For their valuable input";
}
```

### 5.5 Pragma Declaration

```ebnf
pragma = "#" , pragma_directive , ( "on" | "off" ) , ";" ;
pragma_directive = "care" | "strict" | "verbose" ;
```

```wokelang
#care on;      // Enable caring mode (extra safety checks)
#verbose on;   // Enable verbose output
#strict on;    // Enable strict type checking
```

---

## 6. Emote Tags

Emote tags provide emotional context to code.

```ebnf
emote_tag = "@" , identifier , [ "(" , emote_params , ")" ] ;
emote_params = emote_param , { "," , emote_param } ;
emote_param = identifier , "=" , ( number | string | identifier ) ;
```

### Standard Emote Tags

| Tag | Meaning | Use Case |
|-----|---------|----------|
| `@important` | Critical code | Security-sensitive operations |
| `@cautious` | Proceed carefully | Data deletion, modifications |
| `@experimental` | Not stable | New features, testing |
| `@deprecated` | Will be removed | Legacy code |
| `@happy` | Positive outcome | Success handlers |
| `@sad` | Negative outcome | Error handlers |
| `@curious` | Exploratory | Debug code, logging |

```wokelang
@cautious
to deleteAllData() {
    only if okay "delete_data" {
        clearDatabase();
    }
}

@experimental(stability="alpha")
to newFeature() {
    // This might change
}
```

---

## 7. Module System

### 7.1 Imports

```ebnf
module_import = "use" , qualified_name , [ "renamed" , identifier ] , ";" ;
qualified_name = identifier , { "." , identifier } ;
```

```wokelang
use std.io;
use std.json renamed json;
use myapp.utils.helpers;
```

### 7.2 Exports (Planned)

```wokelang
share calculateTotal;
share {
    Person,
    createPerson,
    updatePerson
};
```

---

## 8. Built-in Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `print` | `(...) → Unit` | Output to console |
| `len` | `(String\|Array) → Int` | Get length |
| `toString` | `(Any) → String` | Convert to string |
| `toInt` | `(String\|Float) → Int` | Convert to integer |
| `toFloat` | `(String\|Int) → Float` | Convert to float |

---

## 9. Memory Model

WokeLang uses automatic memory management:
- Values are immutable by default
- References allow controlled mutation
- No manual memory management required
- Garbage collection in interpreter mode
- Linear memory in WASM mode

---

## 10. Concurrency Model

### Workers
Workers execute code asynchronously:
```wokelang
worker myWorker {
    // Runs in background
}

spawn worker myWorker;
```

### Side Quests
Lower-priority background tasks:
```wokelang
side quest cleanup {
    // Runs when system is idle
}
```

### Superpowers
Special capabilities requiring permission:
```wokelang
superpower fileAccess {
    // Has elevated permissions
}
```

---

## Appendix A: EBNF Grammar

See [grammar/wokelang.ebnf](../../../grammar/wokelang.ebnf) for the complete EBNF specification.

## Appendix B: Reserved for Future Use

The following are reserved for future language features:
- `async`, `await`
- `match`, `case`
- `class`, `trait`, `impl`
- `pub`, `priv`
- `mut`, `ref`
- `yield`, `gen`
