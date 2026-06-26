#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# check-grammar-sync.sh — keep spec/grammar.ebnf a byte-faithful copy of the
# canonical grammar/wokelang.ebnf, so the two never silently drift again.
#
# Background: until 2026-06-26 the repo carried THREE EBNF files. Two of them
# (grammar/wokelang.ebnf and spec/grammar.ebnf) each declared themselves "the
# canonical grammar" and disagreed; spec/grammar.ebnf was an older snapshot
# missing while/break/continue, lambdas, record literals, field access and
# function types that the live lexer/parser implement. grammar/wokelang.ebnf is
# the source of truth (verified against src/lexer + src/parser); spec/grammar.ebnf
# is a generated, synchronized copy carrying only its own spec/ SPDX header.
#
# Usage:
#   scripts/check-grammar-sync.sh           # verify the copy is in sync (CI mode)
#   scripts/check-grammar-sync.sh --sync    # regenerate the copy from the source
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/grammar/wokelang.ebnf"
COPY="$ROOT/spec/grammar.ebnf"
MARKER="(* === BEGIN VERBATIM COPY OF grammar/wokelang.ebnf (do not edit below) === *)"

read -r -d '' HEADER <<'EOF' || true
(* SPDX-License-Identifier: MPL-2.0 *)
(* Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> *)
(* @taxonomy: spec/grammar *)
(* ============================================================================ *)
(* WokeLang — Complete EBNF Grammar Specification                               *)
(* ============================================================================ *)
(*                                                                              *)
(* THIS FILE IS A GENERATED, SYNCHRONIZED COPY of the canonical grammar at      *)
(*     grammar/wokelang.ebnf                                                     *)
(* Do NOT edit the grammar here. Edit grammar/wokelang.ebnf, then run           *)
(*     scripts/check-grammar-sync.sh --sync                                      *)
(* CI runs scripts/check-grammar-sync.sh (no args) to fail on drift.            *)
(*                                                                              *)
EOF

generate() { printf '%s\n%s\n' "$HEADER" "$MARKER"; cat "$SRC"; }

case "${1:-}" in
  --sync)
    generate > "$COPY"
    echo "synced: spec/grammar.ebnf regenerated from grammar/wokelang.ebnf"
    ;;
  ""|--check)
    if [ ! -f "$COPY" ]; then echo "MISSING: $COPY" >&2; exit 1; fi
    # Compare everything in the copy AFTER the marker line against the source.
    actual_body="$(awk -v m="$MARKER" 'f{print} $0==m{f=1}' "$COPY")"
    if ! diff <(printf '%s\n' "$actual_body") "$SRC" >/dev/null; then
      echo "DRIFT: spec/grammar.ebnf body differs from grammar/wokelang.ebnf" >&2
      echo "Run: scripts/check-grammar-sync.sh --sync" >&2
      diff <(printf '%s\n' "$actual_body") "$SRC" >&2 || true
      exit 1
    fi
    echo "ok: spec/grammar.ebnf is in sync with grammar/wokelang.ebnf"
    ;;
  *)
    echo "usage: $0 [--check|--sync]" >&2; exit 2 ;;
esac
