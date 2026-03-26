# WokeLang Common Library

This directory contains WokeLang's implementation of the **aggregate-library** common operations, plus additional utilities that are language-agnostic.

## Relationship to aggregate-library

The [aggregate-library](https://github.com/hyperpolymath/aggregate-library) defines 20 core operations that work across all seven languages in the ecosystem. WokeLang implements all of these operations.

### Core Operations (from aggregate-library)

| Category | Operations |
|----------|------------|
| Arithmetic (5) | `add`, `subtract`, `multiply`, `divide`, `modulo` |
| Comparison (6) | `less_than`, `greater_than`, `equal`, `not_equal`, `less_equal`, `greater_equal` |
| Logical (3) | `logical_and`, `logical_or`, `logical_not` |
| String (3) | `concat`, `string_length`, `substring` |
| Collection (4) | `map`, `filter`, `fold`, `contains` |
| Conditional (1) | `if_then_else` |

### Extended Utilities (WokeLang common extensions)

Beyond the 20 core operations, this directory includes additional language-agnostic utilities:

- **prelude.woke** - Identity functions, numeric utilities, array helpers, Result utilities
- **collections.woke** - Extended collection operations (zip, partition, groupBy, etc.)
- **async.woke** - Concurrent programming patterns (workers, retry, timeout)

## Usage

```woke
(* Import common library *)
use lib.common.prelude;
use lib.common.collections;

to main() {
    (* Use core operations *)
    remember sum = add(10, 20);
    remember doubled = map([1, 2, 3], to (x: Int) -> Int { give back multiply(x, 2); });

    (* Use extended utilities *)
    remember evens = filter(doubled, isEven);

    give back sum;
}
```

## Files

| File | Description |
|------|-------------|
| `core.woke` | The 20 aggregate-library operations |
| `prelude.woke` | Extended core utilities |
| `collections.woke` | Extended collection operations |
| `async.woke` | Concurrent programming utilities |

## Specification Compliance

All implementations in `core.woke` comply with the aggregate-library specifications and pass the defined test cases.

## See Also

- [aggregate-library specifications](https://github.com/hyperpolymath/aggregate-library)
- [WokeLang-specific library](../wokelang/README.md)
