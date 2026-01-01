// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Units Same Type Operations
// Tests that operations between same units work correctly

to main() {
    // Time measurements
    remember duration1 = 30 measured in minutes;
    remember duration2 = 15 measured in minutes;
    remember total_time = duration1 + duration2;

    say "Time total: ";
    say total_time;

    // Mass measurements
    remember mass1 = 5 measured in kg;
    remember mass2 = 3 measured in kg;
    remember total_mass = mass1 + mass2;

    say "Mass total: ";
    say total_mass;

    // Comparisons with units
    when mass1 > mass2 {
        say "Mass1 is greater";
    }

    say "PASS: Same-unit operations work correctly";
}
