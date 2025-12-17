# Operators Reference

Complete reference of operators in WokeLang.

---

## Operator Precedence

From lowest to highest:

| Precedence | Operators | Associativity | Description |
|------------|-----------|---------------|-------------|
| 1 | `or` | Left | Logical OR |
| 2 | `and` | Left | Logical AND |
| 3 | `==`, `!=` | Left | Equality |
| 4 | `<`, `>`, `<=`, `>=` | Left | Comparison |
| 5 | `+`, `-` | Left | Addition, Subtraction |
| 6 | `*`, `/`, `%` | Left | Multiplication, Division, Modulo |
| 7 | `not`, `-` (unary) | Right | Logical NOT, Negation |
| 8 | `()`, `[]` | Left | Call, Index |

---

## Arithmetic Operators

### Addition (`+`)

```wokelang
remember sum = 5 + 3;           // 8
remember decimal = 1.5 + 2.5;   // 4.0
remember text = "Hello" + " " + "World";  // "Hello World"
```

| Left | Right | Result |
|------|-------|--------|
| Int | Int | Int |
| Float | Float | Float |
| Int | Float | Float |
| Float | Int | Float |
| String | String | String |

### Subtraction (`-`)

```wokelang
remember diff = 10 - 4;         // 6
remember neg = 5 - 10;          // -5
remember decimal = 5.0 - 2.5;   // 2.5
```

| Left | Right | Result |
|------|-------|--------|
| Int | Int | Int |
| Float | Float | Float |
| Int | Float | Float |
| Float | Int | Float |

### Multiplication (`*`)

```wokelang
remember product = 6 * 7;       // 42
remember scaled = 2.5 * 4;      // 10.0
```

| Left | Right | Result |
|------|-------|--------|
| Int | Int | Int |
| Float | Float | Float |
| Int | Float | Float |
| Float | Int | Float |

### Division (`/`)

```wokelang
remember quotient = 20 / 4;     // 5
remember decimal = 7.0 / 2.0;   // 3.5
remember intDiv = 7 / 2;        // 3 (integer division)
```

| Left | Right | Result | Notes |
|------|-------|--------|-------|
| Int | Int | Int | Truncates |
| Float | Float | Float | |
| Int | Float | Float | |
| Float | Int | Float | |

**Division by zero:**
```wokelang
remember x = 10 / 0;  // Runtime error
```

### Modulo (`%`)

```wokelang
remember remainder = 17 % 5;    // 2
remember even = 10 % 2;         // 0
remember odd = 11 % 2;          // 1
```

| Left | Right | Result |
|------|-------|--------|
| Int | Int | Int |

### Unary Negation (`-`)

```wokelang
remember negative = -42;
remember pos = -(-5);           // 5
remember x = 10;
remember neg_x = -x;            // -10
```

---

## Comparison Operators

### Equality (`==`)

```wokelang
remember same = 5 == 5;         // true
remember diff = 5 == 6;         // false
remember strEq = "a" == "a";    // true
remember boolEq = true == true; // true
```

### Inequality (`!=`)

```wokelang
remember diff = 5 != 6;         // true
remember same = 5 != 5;         // false
```

### Less Than (`<`)

```wokelang
remember less = 3 < 5;          // true
remember notLess = 5 < 3;       // false
remember equal = 5 < 5;         // false
remember strLess = "a" < "b";   // true (lexicographic)
```

### Greater Than (`>`)

```wokelang
remember greater = 5 > 3;       // true
remember notGreater = 3 > 5;    // false
remember equal = 5 > 5;         // false
```

### Less Than or Equal (`<=`)

```wokelang
remember leq = 5 <= 5;          // true
remember less = 3 <= 5;         // true
remember greater = 6 <= 5;      // false
```

### Greater Than or Equal (`>=`)

```wokelang
remember geq = 5 >= 5;          // true
remember greater = 5 >= 3;      // true
remember less = 3 >= 5;         // false
```

---

## Logical Operators

### Logical AND (`and`)

```wokelang
remember both = true and true;   // true
remember one = true and false;   // false
remember none = false and false; // false
```

**Short-circuit evaluation:**
```wokelang
// If first is false, second is not evaluated
remember safe = false and riskyOperation();  // riskyOperation not called
```

### Logical OR (`or`)

```wokelang
remember either = true or false;  // true
remember both = true or true;     // true
remember none = false or false;   // false
```

**Short-circuit evaluation:**
```wokelang
// If first is true, second is not evaluated
remember quick = true or slowOperation();  // slowOperation not called
```

### Logical NOT (`not`)

```wokelang
remember opposite = not true;     // false
remember double = not not true;   // true
remember negFalse = not false;    // true
```

---

## Special Operators

### Arrow (`→` or `->`)

Used for:
- Return type declaration
- Pattern match arms

```wokelang
// Return type
to add(a: Int, b: Int) → Int {
    give back a + b;
}

// Pattern match arm
decide based on x {
    1 → { print("one"); }
    2 → { print("two"); }
}
```

Both Unicode (`→`) and ASCII (`->`) versions are valid.

### Array Index (`[]`)

```wokelang
remember arr = [10, 20, 30];
remember first = arr[0];          // 10
remember last = arr[2];           // 30
```

### Function Call (`()`)

```wokelang
remember result = add(1, 2);
print("Hello");
remember length = len("test");
```

### Member Access (`.`) (Planned)

```wokelang
remember name = person.name;
remember x = point.x;
```

### Reference (`&`) (Planned)

```wokelang
to modify(data: &[Int]) {
    // Can modify original
}
```

---

## Operator Combinations

### Chained Comparisons

```wokelang
// Each comparison is separate
remember valid = x > 0 and x < 100;
remember inRange = min <= value and value <= max;
```

### Complex Expressions

```wokelang
// Follows precedence rules
remember result = 2 + 3 * 4;      // 14 (not 20)
remember explicit = (2 + 3) * 4;  // 20

// Logical with comparison
remember check = x > 0 and y < 10 or z == 0;
// Equivalent to: ((x > 0) and (y < 10)) or (z == 0)
```

### Parentheses for Clarity

```wokelang
// Recommended: Use parentheses for complex expressions
remember clear = (a + b) * (c + d);
remember explicit = (x > 0) and (y < 10);
```

---

## Type Coercion

### Automatic Coercion

```wokelang
// Int + Float → Float
remember mixed = 5 + 3.5;         // 8.5 (Float)

// Comparisons preserve types
remember eq = 5 == 5.0;           // false (different types)
```

### Manual Conversion

```wokelang
remember intVal = 5;
remember floatVal = toFloat(intVal);
remember eq = floatVal == 5.0;    // true
```

---

## Common Patterns

### Conditional Expression (Workaround)

```wokelang
// WokeLang doesn't have ternary operator
// Use when/otherwise instead
remember result = 0;
when condition {
    result = valueIfTrue;
} otherwise {
    result = valueIfFalse;
}
```

### Safe Division

```wokelang
to safeDivide(a: Int, b: Int) → Int {
    when b == 0 {
        complain "Division by zero";
    }
    give back a / b;
}
```

### Bounds Checking

```wokelang
to isInBounds(value: Int, min: Int, max: Int) → Bool {
    give back value >= min and value <= max;
}
```

---

## Planned Operators

| Operator | Purpose | Example |
|----------|---------|---------|
| `**` | Exponentiation | `2 ** 10` |
| `?` | Error propagation | `value?` |
| `??` | Null coalescing | `value ?? default` |
| `..` | Range | `1..10` |
| `...` | Spread | `[...arr, 4]` |

---

## Next Steps

- [Keywords Reference](Keywords.md)
- [Built-in Functions](Builtin-Functions.md)
- [Types Reference](Types.md)
