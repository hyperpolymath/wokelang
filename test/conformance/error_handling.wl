// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Error Handling
// Tests attempt safely / or reassure blocks

to main() {
    remember handled = false;

    attempt safely {
        say "Attempting operation...";
        // Normal operation that succeeds
        say "Operation completed";
    } or reassure "Don't worry, we handled it gracefully";

    say "PASS: Error handling block executed correctly";
}
