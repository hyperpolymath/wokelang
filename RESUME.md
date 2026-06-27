<!-- SPDX-License-Identifier: MPL-2.0 -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->

# RESUME — grammar formal-proofs work

Pick-up notes for continuing the `claude/v2-grammar-proofs-audit-1yqgxh` work on
another machine (e.g. the Claude Code desktop app). Everything here is committed
to that branch, so it travels with the code.

## Where the work stands

Goal: machine-check every necessary/sufficient proof for the grammar that exists
in this repo (`grammar/wokelang.ebnf`), install the provers, and report only
proofs that actually run. The grammar was reconciled to one source of truth, and
the proof obligations were mechanized in Lean 4 (mirrored to Coq where sensible).

**Open PR:** #106 — *CFL pumping lemma, machine-checked from scratch in Lean*
(branch `claude/v2-grammar-proofs-audit-1yqgxh`).

**Merged on the way here:** #102 (parser metatheory + grammar reconciliation),
#103 (no-left-recursion + lexer + classification, Lean+Coq), #104 (Coq parser
port + §7.1 not-regular), #105 (§7.3 CFL positive closure).

## Proof inventory — all verified green (last full run in the cloud container)

Single-file, Mathlib-free. `lean <file>` / `coqc <file>` must exit 0 with no errors.

| File | What it proves | Status |
|---|---|---|
| `docs/proofs/verification/WokeLang.lean` / `.v` | core language metatheory (sorry-audit resolved) | ✅ |
| `docs/proofs/verification/WokeGrammar.lean` | Pratt-parser metatheory: prefix/completeness/determinism/injectivity | ✅ |
| `docs/proofs/verification/WokeGrammarStructure.lean` / `.v` | no-left-recursion (+ found a real spec bug in `pattern`), lexer maximal-munch + keyword priority, CFG/¬LL(1)/LL(2) classification | ✅ |
| `docs/proofs/verification/WokeGrammarParser.v` | Coq port of the parser metatheory | ✅ |
| `docs/proofs/verification/WokeGrammarRegular.lean` | §7.1 not-regular: bespoke pigeonhole + `Fin k` DFA + fooling set on `aⁿbⁿ` | ✅ |
| `docs/proofs/verification/WokeGrammarCFL.lean` | §7.3 CFL **positive** closure under ∪, ·, * | ✅ |
| `docs/proofs/verification/WokeGrammarPumping.lean` | **CFL pumping lemma** `cfl_pumping` (the Mathlib-gap result) | ✅ |

Trust base for the proofs: the standard classical kernel constants only
(`propext`, `Classical.choice`, `Quot.sound`) — no holes, no project-specific
assumptions. Confirm with Lean's kernel-dependency printout per file.

The claim-by-claim map lives in
`docs/proofs/verification/GRAMMAR-PROOF-INVENTORY.md`.

## How to re-run the provers locally

The provers are NOT in the repo — they were installed in the (ephemeral) cloud
container. Reinstall the pinned versions locally.

### Lean 4.30.0 (pinned by `docs/proofs/verification/lean-toolchain`)

The exact, Mathlib-free steps are in `.github/workflows/lean-proofs.yml`:

```sh
ver=4.30.0
curl -sSL -o /tmp/lean.tar.zst \
  "https://github.com/leanprover/lean4/releases/download/v${ver}/lean-${ver}-linux.tar.zst"
sudo mkdir -p /opt/lean
sudo tar --use-compress-program=unzstd -xf /tmp/lean.tar.zst -C /opt/lean
export PATH="/opt/lean/lean-${ver}-linux/bin:$PATH"   # use the macOS/win tarball on those OSes
```

Then, from the repo root:

```sh
for f in WokeLang WokeGrammar WokeGrammarStructure WokeGrammarRegular WokeGrammarCFL WokeGrammarPumping; do
  lean docs/proofs/verification/$f.lean && echo "OK $f"
done
```

### Coq 8.18.0

```sh
# install coq 8.18.0 (opam: `opam pin add coq 8.18.0`, or your platform package)
cd docs/proofs/verification
for f in WokeLang WokeGrammarStructure WokeGrammarParser; do coqc $f.v && echo "OK $f"; done
rm -f *.vo *.vok *.vos *.glob .*.aux   # clean build artifacts
```

## Next increment (not yet started)

The only remaining item in the original §7 scope is the **§7.3 ∩ / ¬
non-closure corollary**, now unblocked by `cfl_pumping`:

1. A **finiteness-aware `IsCFL`** predicate. (The relation-based `IsCFL` used for
   the *positive* closure is too permissive for non-closure — an infinite
   nonterminal type could "generate" `aⁿbⁿcⁿ`. Non-closure needs a grammar with
   finitely many nonterminals, matching `cfl_pumping`'s `enum`/`card` interface.)
2. **`aⁿbⁿcⁿ ∉ CFL`** via `cfl_pumping`: any decomposition `uvwxy` with
   `|vwx| ≤ p` touches at most two of the three letter-blocks, so pumping
   unbalances the counts.
3. **Non-closure under ∩** (and hence ¬) by De Morgan against the already-proven
   ∪ closure: `L₁ = {aⁿbⁿcᵐ}` and `L₂ = {aᵐbⁿcⁿ}` are CFLs but `L₁ ∩ L₂ =
   {aⁿbⁿcⁿ}` is not.

Plan: land it as its own follow-up PR (incremental, same as the pumping lemma).

## CI notes

On PR #106, the genuinely-relevant checks are green (Trusted-base reduction
policy; the Lean/Coq compile gates). Three checks are red but are **pre-existing
infrastructure failures unrelated to these proofs**, and every prior merged PR
(#102–#105) carried them too:

- **Licence consistency** — root `LICENSE` SPDX mismatch.
- **Workflow security linter** — a `trufflehog@main` unpinned-action finding.
- **Hypatia Neurosymbolic Analysis** — scanner infrastructure.

## Moving this session to desktop

Per the Claude Code docs, use **teleport** to carry the conversation context +
branch + uncommitted changes from web into the local CLI / desktop app:
`claude --teleport <session-id>` (one-way: web → local). See
<https://code.claude.com/docs/en/claude-code-on-the-web>. Even without it, the
branch and PR #106 hold all the work.
