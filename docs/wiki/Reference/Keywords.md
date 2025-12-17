# Keywords Reference

Complete list of reserved keywords in WokeLang.

---

## Control Flow Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `to` | Define a function | `to greet() { }` |
| `give` | Part of return statement | `give back value;` |
| `back` | Part of return statement | `give back value;` |
| `remember` | Declare a variable | `remember x = 5;` |
| `when` | Conditional branch | `when x > 0 { }` |
| `otherwise` | Else branch | `otherwise { }` |
| `repeat` | Loop construct | `repeat 5 times { }` |
| `times` | Part of repeat loop | `repeat n times { }` |

---

## Consent & Safety Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `only` | Part of consent block | `only if okay "..." { }` |
| `if` | Part of consent block | `only if okay "..." { }` |
| `okay` | Part of consent block | `only if okay "..." { }` |
| `attempt` | Try block | `attempt safely { }` |
| `safely` | Part of attempt | `attempt safely { }` |
| `or` | Fallback clause | `or reassure "...";` |
| `reassure` | Recovery message | `or reassure "...";` |
| `complain` | Raise error | `complain "message";` |

---

## Gratitude Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `thanks` | Gratitude block/expression | `thanks to { }` |

---

## Lifecycle Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `hello` | Function entry message | `hello "Starting";` |
| `goodbye` | Function exit message | `goodbye "Done";` |

---

## Concurrency Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `worker` | Define async worker | `worker name { }` |
| `side` | Part of side quest | `side quest name { }` |
| `quest` | Part of side quest | `side quest name { }` |
| `superpower` | Define capability | `superpower name { }` |
| `spawn` | Start worker | `spawn worker name;` |

---

## Pattern Matching Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `decide` | Pattern match | `decide based on x { }` |
| `based` | Part of pattern match | `decide based on x { }` |
| `on` | Part of pattern match | `decide based on x { }` |

---

## Unit Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `measured` | Unit annotation | `100 measured in meters` |
| `in` | Part of unit annotation | `measured in meters` |

---

## Type Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `type` | Type definition | `type Name = String;` |
| `const` | Constant declaration | `const MAX = 100;` |
| `Maybe` | Optional type | `Maybe Int` |

---

## Boolean Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `true` | Boolean true | `remember x = true;` |
| `false` | Boolean false | `remember x = false;` |
| `and` | Logical AND | `a and b` |
| `or` | Logical OR | `a or b` |
| `not` | Logical NOT | `not x` |

---

## Module Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `use` | Import module | `use std.io;` |
| `renamed` | Alias import | `use std.io renamed io;` |
| `share` | Export item | `share myFunction;` |

---

## Primitive Type Names

| Type | Description |
|------|-------------|
| `Int` | 64-bit integer |
| `Float` | 64-bit float |
| `String` | UTF-8 string |
| `Bool` | Boolean |

---

## Reserved for Future Use

These keywords are reserved but not yet implemented:

| Keyword | Planned Purpose |
|---------|-----------------|
| `async` | Async functions |
| `await` | Await async result |
| `match` | Alternative pattern match |
| `case` | Pattern case |
| `class` | Class definition |
| `trait` | Trait definition |
| `impl` | Implementation |
| `pub` | Public visibility |
| `priv` | Private visibility |
| `mut` | Mutable reference |
| `ref` | Reference |
| `yield` | Generator yield |
| `gen` | Generator function |
| `stop` | Break from loop |
| `skip` | Continue loop |

---

## Usage Examples

### Complete Function

```wokelang
to calculateTotal(items: [Float]) → Float {
    hello "Calculating total";

    remember total = 0.0;
    remember i = 0;

    repeat len(items) times {
        total = total + items[i];
        i = i + 1;
    }

    give back total;

    goodbye "Calculation complete";
}
```

### Pattern Matching

```wokelang
decide based on status {
    "active" → {
        print("User is active");
    }
    "inactive" → {
        print("User is inactive");
    }
    _ → {
        print("Unknown status");
    }
}
```

### Error Handling

```wokelang
attempt safely {
    remember data = fetchData();
    when data == none {
        complain "No data found";
    }
    processData(data);
} or reassure "Data fetch failed, using cached version";
```

### Consent Block

```wokelang
only if okay "network_access" {
    remember response = httpGet(url);
    processResponse(response);
}
```

### Gratitude

```wokelang
thanks to {
    "Open Source" → "For making this possible";
    "Contributors" → "For their hard work";
}
```

---

## Operator Keywords

Some keywords function as operators:

| Keyword | Type | Precedence |
|---------|------|------------|
| `and` | Binary | Low |
| `or` | Binary | Lower |
| `not` | Unary | High |

---

## Context-Sensitive Usage

Some words are only keywords in specific contexts:

| Word | Context | Meaning |
|------|---------|---------|
| `in` | After `measured` | Unit specification |
| `in` | Other contexts | Not a keyword |
| `on` | After `based` | Pattern match |
| `on` | Pragma context | Enable pragma |

---

## Identifier Rules

Keywords cannot be used as:
- Variable names
- Function names
- Type names
- Parameter names

```wokelang
// Invalid - 'remember' is a keyword
remember remember = 5;

// Invalid - 'when' is a keyword
to when() { }

// Valid - similar but different
remember rememberMe = 5;
to whenReady() { }
```

---

## Next Steps

- [Operators Reference](Operators.md)
- [Built-in Functions](Builtin-Functions.md)
- [Language Specification](Language-Specification.md)
