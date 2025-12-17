# WokeLang Library

The WokeLang library is organized into two distinct parts:

```
lib/
├── common/                    # Shared across all 7 languages (aggregate-library)
│   ├── core.woke             # 20 core operations from aggregate-library spec
│   ├── prelude.woke          # Extended core utilities
│   ├── collections.woke      # Extended collection operations
│   ├── async.woke            # Concurrent programming patterns
│   └── README.md
│
└── wokelang/                  # WokeLang-specific features (NOT shared)
    ├── consent.woke          # Consent and permission management
    ├── emotes.woke           # Emotional annotations
    ├── gratitude.woke        # Attribution utilities
    └── README.md
```

## Common Library (`lib/common/`)

Implements the **aggregate-library** specification - 20 core operations that work across all seven languages in the ecosystem:

| Category | Operations | Count |
|----------|------------|-------|
| Arithmetic | `add`, `subtract`, `multiply`, `divide`, `modulo` | 5 |
| Comparison | `less_than`, `greater_than`, `equal`, `not_equal`, `less_equal`, `greater_equal` | 6 |
| Logical | `logical_and`, `logical_or`, `logical_not` | 3 |
| String | `concat`, `string_length`, `substring` | 3 |
| Collection | `map`, `filter`, `fold`, `contains` | 4 |
| Conditional | `if_then_else` | 1 |

**Total: 20 core operations**

Plus extended utilities (`prelude.woke`, `collections.woke`, `async.woke`) that are language-agnostic.

📖 See: [aggregate-library](https://github.com/hyperpolymath/aggregate-library)

## WokeLang-Specific Library (`lib/wokelang/`)

Features that make WokeLang unique:

| Module | Purpose |
|--------|---------|
| `consent.woke` | Permission management, safe I/O, privacy utilities |
| `emotes.woke` | Emotional annotations, sentiment-aware code, code health |
| `gratitude.woke` | Attribution management, contributor recognition |

These features are **NOT** in the aggregate-library because they're specific to WokeLang's philosophy of human-centered, consent-driven programming.

## The Seven Languages

WokeLang is one of seven languages that share the common library:

1. **WokeLang** - Consent-driven, emotional computing ← *You are here*
2. **Duet/Ensemble** - AI-first, session types, effect systems
3. **Eclexia** - Sustainability-focused, energy budgets
4. **Oblíbený** - Security-first, provable termination
5. **RT-Lang** - Real-time systems, dependent types
6. **Phronesis** - Ethical reasoning, values-based programming
7. **Julia the Viper** - Reversible computing, totality

## Quick Start

```woke
(* Import libraries *)
use lib.common.core;
use lib.common.collections;
use lib.wokelang.consent;
use lib.wokelang.emotes;

@mindful(importance=5)
to main() {
    hello "Starting WokeLang application";

    (* Use common library operations *)
    remember numbers = [1, 2, 3, 4, 5];
    remember doubled = map(numbers, to (x: Int) -> Int {
        give back multiply(x, 2);
    });
    remember sum = fold(doubled, 0, add);

    (* Use WokeLang-specific features *)
    @happy(intensity=7)
    logWithEmote(Proud(8), "Computed sum: " + toString(sum));

    (* Consent-protected file operation *)
    remember result = safeWriteFile("output.txt", toString(sum));

    give back sum;

    goodbye "Application complete";
}

thanks to {
    "aggregate-library" → "Shared foundations across languages";
    "WokeLang Community" → "Human-centered programming";
}
```

## Design Philosophy

### Common Library
- **Minimal**: Only operations that exist across ALL 7 languages
- **Universal**: Works across radically different paradigms
- **Testable**: Concrete, executable test cases
- **Language-agnostic**: No WokeLang-specific features

### WokeLang-Specific Library
- **Human-Centered**: Code written for humans first
- **Consent-First**: Respecting user autonomy
- **Emotionally Aware**: Acknowledging the human side of programming
- **Grateful**: Celebrating contributions and collaboration

## License

- Common library: MIT / GPL-3.0-or-later / Palimpsest-0.8 (per aggregate-library)
- WokeLang-specific: Same as WokeLang project (MIT)
