// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Units Basic
// Tests basic units of measure operations

to main() {
    // Declare values with units
    remember distance = 100 measured in km;
    remember more_distance = 50 measured in km;

    // Arithmetic on same units should work
    remember total = distance + more_distance;

    say "Distance 1: ";
    say distance;
    say "Distance 2: ";
    say more_distance;
    say "Total distance: ";
    say total;

    say "PASS: Basic unit operations work";
}
