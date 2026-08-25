---
name: dotfiles-hardening
description: Adversarially test the dotfiles mechanics (bare-repo install, make check gates, banned-word detection) against faulty input, interrupts, and hostile environments. Use when asked to audit, stress-test, or verify the dotfiles tooling.
---

# Dotfiles hardening audit

Adversarially verify the invariants below and report a PASS/FAIL checklist
with a one-line remediation per failure. The invariants are the contract;
devise whatever tests attack them best — anything listed is a floor, not a
ceiling. Run installs and mutation tests only in a throwaway HOME under a
scratch directory, cloning from the local bare repo; leave the real
`~/.dotfiles`, `~/.env`, and working tree untouched. Stay read-only
against the real environment and change nothing unless asked.

## 1. Publishability

The repo is public only as long as it never names the employer.

- Every banned word in `DOTFILES_CHECK_WORDS` (defined in `~/.env`) must
  be absent from tracked file contents, file names, and every commit
  message on every local and remote ref.
- `make check-words` must demonstrably fail when a banned word is present
  — prove it with a word that actually occurs in the tree, not by
  trusting a passing exit code.
- The check-words failure message must never print the banned word
  itself (CI logs on a public repo would leak it) — only its position.
- `~/.env` must be ignored and untracked.

## 2. Check gates

- `make check` runs all gates (secrets, formatting, banned words) and
  each gate fails loudly — verify at least one negative case per gate.
- The gates must work both against the bare repo (this machine) and in a
  plain checkout (how CI runs them).
- The CI workflow must run the same `make check` — no drift between local
  and CI gating — and must feed `DOTFILES_CHECK_WORDS` from the
  repository secret of the same name so the banned-word gate runs in CI
  too (skipping cleanly when the secret is absent, as on fork PRs).

## 3. Installer (`scripts/install.sh`)

Attack in a throwaway HOME:

- A truncated download executes nothing (all actions live behind a
  function called on the last line).
- Any failure after the clone leaves no `.dotfiles` behind, so a rerun
  starts clean; rerunning over an existing install fails with a clear
  error and damages nothing.
- Works regardless of the caller's cwd.
- Preserves pre-existing user files it does not own (e.g. `.env`
  content), and ends with working upstream tracking and a clean, quiet
  `status`.
- Applies the bootstrap hooks (section 5) as its last step, best effort:
  a failing hook produces a warning but never aborts the install or
  removes the clone.

## 4. Word detection (`scripts/bootstrap.d/10-check-words`)

Attack in a throwaway HOME:

- Bans the machine identity too: the local account name and the short
  host name land in the word list from offline sources alone.
- Append-only: never rewrites or reorders existing `.env` content, and
  never glues onto a final line that lacks a trailing newline.
- Idempotent: a rerun changes nothing.
- Bounded: a black-holed network probe (e.g. an unroutable TEST-NET
  address) cannot hang it past its timeout, and detection still succeeds
  from offline sources.
- Interrupt-safe: killed mid-run, it leaves `.env` exactly as found and
  cleans up after itself.
- Fails cleanly (non-zero exit, clear message) on unexpected arguments,
  unset HOME, an unwritable `.env`, and when nothing is detected.
- Works in a bare environment (`env -i`, system PATH, system perl).

## 5. Bootstrap driver (`scripts/bootstrap.pl` + `scripts/bootstrap.d/`)

Attack in a throwaway HOME with fake hooks (use `BOOTSTRAP_TIMEOUT` to
keep timeout tests fast); never run destructive fakes against the real
environment:

- Runs hooks in lexical order, keeps going after a failing hook, and
  exits non-zero iff at least one hook failed.
- Classifies exit 0 as ok, exit 2 as skip, anything else as fail, and
  says which hook failed and why (exit status, timeout, not executable).
- A hook that hangs — including one that ignores TERM — is killed at the
  timeout and reported as failed; the driver itself never hangs.
- A `# bootstrap-timeout: <seconds>` declaration in a hook's header is
  honored (the hook is still killed at that limit), a malformed
  declaration falls back to the default, and the `BOOTSTRAP_TIMEOUT`
  environment override beats both.
- A hook file that is not executable is a loud failure, not a silent
  no-op; a file not matching `NN-slug` is ignored with a warning
  (dotfiles like `.DS_Store` silently).
- A rerun after a successful pass reports every hook ok/skip and changes
  nothing (this is the hooks' idempotency contract — verify it for the
  real hooks read-only, e.g. the brew-env hook must not invoke sudo when
  the deployed file already matches).
- Fails cleanly (non-zero exit, clear message) on unexpected arguments,
  unset HOME, a missing `bootstrap.d`, and a non-numeric
  `BOOTSTRAP_TIMEOUT`.
- Works in a bare environment (`env -i`, system PATH, system perl) and
  regardless of the caller's cwd (hooks are found next to the driver;
  hooks run with cwd `$HOME`).

## 6. Bare-repo mechanics

- `~/.dotfiles` exists; `status` is clean and quiet about untracked HOME
  files; upstream tracking and push/pull work over a protocol that
  functions on this network.
- The `dotfiles` alias resolves to the documented git invocation.
- Ignore rules cover machine-local files (`.env`, backups).

## Report

End with a summary table: item, PASS/FAIL, remediation. Distinguish
regressions in the tooling from environmental problems, and note any
attacks you devised beyond this list and what they found.
