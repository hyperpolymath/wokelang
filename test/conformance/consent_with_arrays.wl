// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent with Arrays
// Tests that array operations work correctly within consent blocks

to main() {
    remember items = [];
    remember item_count = 0;

    only if okay "array_permission" {
        items = [1, 2, 3, 4, 5];
        say "Array initialized within consent block";
    }

    item_count = length items;

    when item_count == 5 {
        say "PASS: Array operations within consent block succeeded";
    } otherwise {
        say "FAIL: Array length is incorrect";
    }
}
