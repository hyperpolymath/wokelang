# WokeLang Standard Library

A human-centered library collection for WokeLang, organized into common utilities
and language-specific features.

## Structure

```
lib/
├── common/           # Language-agnostic utilities
│   ├── prelude.woke  # Core utilities (identity, boolean, numeric, string, array)
│   ├── collections.woke  # Higher-order functions (map, filter, reduce)
│   └── async.woke    # Concurrent programming patterns
│
└── wokelang/         # WokeLang-specific features
    ├── consent.woke  # Consent and permission management
    ├── emotes.woke   # Emotional annotations and sentiment-aware code
    └── gratitude.woke # Attribution and acknowledgment utilities
```

## Common Library

### prelude.woke
Core utilities that every program needs:
- **Identity functions**: `identity`, `constant`, `flip`
- **Boolean operations**: `negate`, `allTrue`, `anyTrue`
- **Numeric utilities**: `clamp`, `inRange`, `sign`, `isEven`, `isOdd`, `gcd`, `lcm`
- **String utilities**: `isEmpty`, `repeat`, `startsWith`, `endsWith`
- **Array utilities**: `head`, `tail`, `last`, `reverse`, `contains`, `indexOf`
- **Result utilities**: `isOkay`, `isOops`, `getOrDefault`, `mapResult`
- **Debugging**: `debug`, `assert`

### collections.woke
Higher-order functions for data transformation:
- **Core transformations**: `map`, `filter`, `reduce`, `reduceRight`
- **Searching**: `find`, `findIndex`, `all`, `any`, `none`
- **Advanced transformations**: `flatten`, `flatMap`, `zip`, `unzip`, `partition`, `groupBy`
- **Slicing**: `take`, `drop`, `takeWhile`, `dropWhile`, `slice`
- **Statistics**: `count`, `sum`, `product`, `average`
- **Sorting**: `sortInts`
- **Deduplication**: `unique`, `distinctBy`

### async.woke
Concurrent programming utilities:
- **Worker patterns**: `TaskRunner`, parallel execution
- **Promise-like patterns**: `runAsync`, `parallel`, `race`
- **Retry patterns**: `retry`, `retryWithBackoff`
- **Timeout patterns**: `withTimeout`
- **Debounce/throttle**: `debounce`
- **Channel utilities**: `createChannel`, `channelSend`, `channelReceive`

## WokeLang-Specific Library

### consent.woke
Human-centered consent management:
- **Safe execution**: `withConsent`, `requireAllConsents`, `withAnyConsent`
- **Permission constants**: `PERM_READ_FILE`, `PERM_NETWORK_HTTP`, etc.
- **Safe operations**: `safeReadFile`, `safeWriteFile`, `safeHttpGet`
- **Audit logging**: `logConsentRequest`, `createAuditTrail`
- **Privacy patterns**: `withPrivacy`, `redact`, `anonymize`

### emotes.woke
Emotional annotations for code:
- **Emote types**: `Happy`, `Sad`, `Curious`, `Careful`, `Mindful`, etc.
- **Emote logging**: `logWithEmote`
- **Sentiment-aware execution**: `withCaution`, `withInvestigation`
- **Emotional state tracking**: `EmotionalState`, `updateEmotionalState`
- **Code health indicators**: `assessCodeHealth`, `reportCodeHealth`

### gratitude.woke
Attribution and acknowledgment:
- **Gratitude registry**: `createGratitudeRegistry`, `acknowledge`
- **Credit generation**: `generateCredits`, `generateThankYouNote`
- **Dependency attribution**: `acknowledgeDependency`, `generateLicenseNotices`
- **Contributor recognition**: `recognizeContributor`
- **Gratitude expressions**: `expressGratitude`, `randomGratitudeQuote`

## Usage

```woke
use lib.common.prelude;
use lib.common.collections;
use lib.wokelang.consent;
use lib.wokelang.emotes;

to main() {
    hello "Starting application";

    (* Use common utilities *)
    remember numbers = [1, 2, 3, 4, 5];
    remember doubled = map(numbers, to (x: Int) -> Int { give back x * 2; });

    (* Use consent-aware file reading *)
    remember content = safeReadFile("config.json")?;

    (* Log with emotional context *)
    @happy(intensity=8)
    logWithEmote(Proud(8), "Application started successfully!");

    give back 0;
    goodbye "Application complete";
}
```

## Philosophy

The WokeLang standard library embodies the language's core principles:

1. **Human-Centered**: Every function is designed with human developers in mind
2. **Consent-First**: Sensitive operations require explicit permission
3. **Emotionally Aware**: Code can express and track emotional context
4. **Grateful**: Attribution and acknowledgment are first-class concepts

## Contributing

When contributing to the library:
1. Include appropriate emote annotations
2. Add gratitude blocks acknowledging inspirations
3. Ensure consent is requested for sensitive operations
4. Write clear hello/goodbye lifecycle messages

## Gratitude

This library was built with gratitude to:
- Functional programming communities for inspiring composable patterns
- Rust for Result types and error handling patterns
- Go for channel-based concurrency
- All contributors who help make WokeLang more human-centered
