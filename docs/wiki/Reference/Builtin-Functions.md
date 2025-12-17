# Built-in Functions

WokeLang provides these built-in functions available in all programs.

---

## I/O Functions

### print

Output values to the console.

```wokelang
print(value1, value2, ...)
```

**Parameters:**
- `...values` - Any number of values to print

**Returns:** `Unit`

**Examples:**
```wokelang
print("Hello, World!");
print("The answer is:", 42);
print("Name:", name, "Age:", age);
```

**Output:**
```
Hello, World!
The answer is: 42
Name: Alice Age: 30
```

---

## String Functions

### len

Get the length of a string or array.

```wokelang
len(value) → Int
```

**Parameters:**
- `value: String | Array` - The string or array to measure

**Returns:** `Int` - The length

**Examples:**
```wokelang
len("hello")        // → 5
len("")             // → 0
len([1, 2, 3])      // → 3
len([])             // → 0
```

### toString

Convert any value to a string representation.

```wokelang
toString(value) → String
```

**Parameters:**
- `value: Any` - The value to convert

**Returns:** `String` - String representation

**Examples:**
```wokelang
toString(42)        // → "42"
toString(3.14)      // → "3.14"
toString(true)      // → "true"
toString([1, 2])    // → "[1, 2]"
```

---

## Numeric Functions

### toInt

Convert a value to an integer.

```wokelang
toInt(value) → Int
```

**Parameters:**
- `value: String | Float | Int` - The value to convert

**Returns:** `Int` - The integer value

**Errors:** Throws if string cannot be parsed

**Examples:**
```wokelang
toInt("42")         // → 42
toInt("-17")        // → -17
toInt(3.14)         // → 3
toInt(3.99)         // → 3 (truncates)
toInt(42)           // → 42 (identity)
```

### toFloat

Convert a value to a floating-point number.

```wokelang
toFloat(value) → Float
```

**Parameters:**
- `value: String | Int | Float` - The value to convert

**Returns:** `Float` - The float value

**Errors:** Throws if string cannot be parsed

**Examples:**
```wokelang
toFloat("3.14")     // → 3.14
toFloat("42")       // → 42.0
toFloat(42)         // → 42.0
toFloat(3.14)       // → 3.14 (identity)
```

---

## Type Functions (Planned)

### typeOf

Get the type name of a value.

```wokelang
typeOf(value) → String
```

**Parameters:**
- `value: Any` - The value to inspect

**Returns:** `String` - The type name

**Examples:**
```wokelang
typeOf(42)          // → "Int"
typeOf(3.14)        // → "Float"
typeOf("hello")     // → "String"
typeOf(true)        // → "Bool"
typeOf([1, 2])      // → "Array"
```

### isInt, isFloat, isString, isBool, isArray

Type checking predicates.

```wokelang
isInt(value) → Bool
isFloat(value) → Bool
isString(value) → Bool
isBool(value) → Bool
isArray(value) → Bool
```

**Examples:**
```wokelang
isInt(42)           // → true
isInt("42")         // → false
isString("hello")   // → true
isArray([1, 2])     // → true
```

---

## Array Functions (Planned)

### push

Add an element to the end of an array.

```wokelang
push(array, element) → Array
```

**Examples:**
```wokelang
remember arr = [1, 2, 3];
arr = push(arr, 4);     // → [1, 2, 3, 4]
```

### pop

Remove and return the last element.

```wokelang
pop(array) → { element: T, array: Array }
```

### concat

Concatenate two arrays.

```wokelang
concat(array1, array2) → Array
```

**Examples:**
```wokelang
concat([1, 2], [3, 4])  // → [1, 2, 3, 4]
```

### slice

Extract a portion of an array.

```wokelang
slice(array, start, end) → Array
```

**Examples:**
```wokelang
slice([1, 2, 3, 4, 5], 1, 4)  // → [2, 3, 4]
```

### map

Transform each element.

```wokelang
map(array, function) → Array
```

### filter

Filter elements by predicate.

```wokelang
filter(array, predicate) → Array
```

### reduce

Reduce array to single value.

```wokelang
reduce(array, initial, function) → T
```

---

## Math Functions (Planned)

### abs

Absolute value.

```wokelang
abs(n) → Int | Float
```

### min, max

Minimum and maximum of two values.

```wokelang
min(a, b) → Int | Float
max(a, b) → Int | Float
```

### floor, ceil, round

Rounding functions.

```wokelang
floor(f) → Int
ceil(f) → Int
round(f) → Int
```

### sqrt, pow

Square root and power.

```wokelang
sqrt(n) → Float
pow(base, exponent) → Float
```

---

## Random Functions (Planned)

### random

Generate random number.

```wokelang
random() → Float           // 0.0 to 1.0
random(max) → Int          // 0 to max-1
random(min, max) → Int     // min to max-1
```

---

## Time Functions (Planned)

### now

Get current timestamp.

```wokelang
now() → Int  // Unix timestamp in milliseconds
```

### sleep

Pause execution.

```wokelang
sleep(ms: Int) → Unit
```

---

## Example: Using Built-ins

```wokelang
to main() {
    hello "Built-in functions demo";

    // String operations
    remember greeting = "Hello, WokeLang!";
    print("Length:", len(greeting));

    // Numeric conversions
    remember numStr = "42";
    remember num = toInt(numStr);
    print("Parsed number:", num);

    // Array operations
    remember numbers = [1, 2, 3, 4, 5];
    print("Array length:", len(numbers));

    // Type conversions
    remember pi = 3.14159;
    print("Pi as string:", toString(pi));
    print("Pi as int:", toInt(pi));

    goodbye "Demo complete";
}
```

---

## Adding Custom Built-ins

Built-ins are implemented in `src/interpreter/mod.rs`:

```rust
fn call_builtin(&mut self, name: &str, args: &[Value]) -> Result<Option<Value>> {
    match name {
        "myFunction" => {
            // Implementation
            Ok(Some(Value::Int(42)))
        }
        _ => Ok(None),
    }
}
```

---

## Next Steps

- [Operators Reference](Operators.md)
- [Types Reference](Types.md)
- [Standard Library](Standard-Library.md)
