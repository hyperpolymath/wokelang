// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent with Loops
// Tests that loops work correctly within consent blocks

to main() {
    remember count = 0;

    only if okay "loop_permission" {
        remember i = 0;
        while i < 5 {
            count = count + 1;
            i = i + 1;
        }
        say "Loop executed within consent block";
    }

    when count == 5 {
        say "PASS: Loop iterations within consent block completed correctly";
    } otherwise {
        say "FAIL: Loop did not execute expected iterations";
    }
}
