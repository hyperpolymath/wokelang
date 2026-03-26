# Basic Syntax

This guide covers WokeLang's fundamental syntax elements.

---

## Comments

```wokelang
// Single-line comment

/* Multi-line
   comment */
```

---

## Variables

### Declaration with `remember`

```wokelang
remember name = "Alice";
remember age = 30;
remember pi = 3.14159;
remember isActive = true;
```

### Type Annotations (Optional)

```wokelang
remember count: Int = 0;
remember message: String = "Hello";
remember ratio: Float = 0.75;
remember flag: Bool = false;
```

### Assignment

```wokelang
remember x = 10;
x = x + 5;  // x is now 15
```

---

## Data Types

### Primitive Types

| Type | Description | Examples |
|------|-------------|----------|
| `Int` | 64-bit integer | `42`, `-17`, `0` |
| `Float` | 64-bit float | `3.14`, `-0.5`, `1.0` |
| `String` | UTF-8 text | `"hello"`, `"line\n"` |
| `Bool` | Boolean | `true`, `false` |

### Arrays

```wokelang
remember numbers = [1, 2, 3, 4, 5];
remember names = ["Alice", "Bob", "Charlie"];
remember empty: [Int] = [];
```

### Unit Values (with measurements)

```wokelang
remember distance = 100 measured in meters;
remember temp = 72 measured in fahrenheit;
remember speed = 60 measured in mph;
```

---

## Operators

### Arithmetic

```wokelang
remember sum = 5 + 3;      // 8
remember diff = 10 - 4;    // 6
remember product = 6 * 7;  // 42
remember quotient = 20 / 4; // 5
remember remainder = 17 % 5; // 2
remember negative = -42;
```

### Comparison

```wokelang
remember eq = 5 == 5;    // true
remember ne = 5 != 3;    // true
remember lt = 3 < 5;     // true
remember gt = 7 > 4;     // true
remember le = 5 <= 5;    // true
remember ge = 6 >= 6;    // true
```

### Logical

```wokelang
remember both = true and false;  // false
remember either = true or false; // true
remember opposite = not true;    // false
```

### String Concatenation

```wokelang
remember greeting = "Hello, " + "World!";  // "Hello, World!"
```

---

## Control Flow

### Conditionals with `when`/`otherwise`

```wokelang
when score >= 90 {
    print("Excellent!");
} otherwise {
    print("Keep trying!");
}
```

### Loops with `repeat`

```wokelang
repeat 5 times {
    print("Hello!");
}

remember count = 3;
repeat count times {
    print("Counting...");
}
```

---

## Functions

### Basic Definition

```wokelang
to greet() {
    print("Hello!");
}
```

### With Parameters

```wokelang
to greet(name: String) {
    print("Hello, " + name + "!");
}
```

### With Return Type

```wokelang
to add(a: Int, b: Int) → Int {
    give back a + b;
}
```

### Calling Functions

```wokelang
greet();
greet("Alice");
remember result = add(3, 5);
```

---

## Error Handling

### Attempt Blocks

```wokelang
attempt safely {
    remember data = riskyOperation();
    processData(data);
} or reassure "Operation failed, but we're okay";
```

### Complain Statement

```wokelang
when value < 0 {
    complain "Value must be non-negative";
}
```

---

## Consent Blocks

```wokelang
only if okay "camera_access" {
    remember photo = takePhoto();
    save(photo);
}
```

---

## Pattern Matching

```wokelang
decide based on status {
    "success" → {
        print("It worked!");
    }
    "pending" → {
        print("Still waiting...");
    }
    _ → {
        print("Unknown status");
    }
}
```

---

## Emote Tags

```wokelang
@important
to deleteAllData() {
    only if okay "delete_all" {
        clearDatabase();
    }
}

@experimental(stability="alpha")
to newFeature() {
    // Experimental code
}
```

---

## Gratitude

```wokelang
thanks to {
    "Open Source Community" → "For amazing tools";
    "Contributors" → "For valuable feedback";
}
```

---

## Pragmas

```wokelang
#care on;      // Enable extra safety checks
#verbose on;   // Enable verbose output
#strict on;    // Enable strict type checking
```

---

## Complete Example

```wokelang
// Calculator example
#care on;

thanks to {
    "Math" → "For making sense of numbers";
}

@important
to main() {
    hello "Calculator starting up";

    remember a = 10;
    remember b = 5;

    print("Addition: " + toString(add(a, b)));
    print("Subtraction: " + toString(subtract(a, b)));
    print("Multiplication: " + toString(multiply(a, b)));

    attempt safely {
        print("Division: " + toString(divide(a, b)));
    } or reassure "Division failed";

    goodbye "Calculations complete";
}

to add(x: Int, y: Int) → Int {
    give back x + y;
}

to subtract(x: Int, y: Int) → Int {
    give back x - y;
}

to multiply(x: Int, y: Int) → Int {
    give back x * y;
}

to divide(x: Int, y: Int) → Int {
    when y == 0 {
        complain "Division by zero";
    }
    give back x / y;
}
```

---

## Next Steps

- [Functions](../Language-Guide/Functions.md) - Advanced function features
- [Control Flow](../Language-Guide/Control-Flow.md) - Detailed control structures
- [Error Handling](../Language-Guide/Error-Handling.md) - Robust error management
