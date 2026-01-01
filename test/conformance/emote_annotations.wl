// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Emote Annotations
// Tests that emote tags are processed correctly

@enthusiastic
to greet() {
    say "Hello with enthusiasm!";
}

@careful
to process_data() {
    say "Processing data carefully...";
}

@grateful(to="User")
to thank_user() {
    say "Thank you for using WokeLang!";
}

to main() {
    greet();
    process_data();
    thank_user();
    say "PASS: Emote annotations work correctly";
}
