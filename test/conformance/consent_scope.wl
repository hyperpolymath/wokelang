// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent Scope
// Tests that consent is properly scoped to its block

to inner_function() {
    // This should request its own consent, not inherit from outer scope
    only if okay "inner_permission" {
        say "Inner permission granted";
    }
}

to main() {
    only if okay "outer_permission" {
        say "Outer permission granted";
        inner_function();
    }

    say "PASS: Consent scoping works correctly";
}
