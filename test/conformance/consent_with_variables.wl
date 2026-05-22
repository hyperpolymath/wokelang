// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent with Variables
// Tests that variables can be modified within consent blocks and used after

to main() {
    remember counter = 0;
    remember final_value = 0;

    only if okay "increment_permission" {
        counter = counter + 1;
        counter = counter + 1;
        counter = counter + 1;
        say "Counter incremented within consent block";
    }

    final_value = counter;

    when final_value == 3 {
        say "PASS: Variable modifications within consent block persisted";
    } otherwise {
        say "FAIL: Variable modifications did not persist correctly";
    }
}
