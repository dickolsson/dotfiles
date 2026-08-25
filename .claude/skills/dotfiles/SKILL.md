---
name: dotfiles
description: Work with the user's dotfiles. Use when editing, committing, or otherwise managing dotfiles (shell config, ~/.claude settings, ~/.local/bin scripts, or anything tracked by the bare repo at ~/.dotfiles).
---

# Dotfiles

Bare git repo at `~/.dotfiles`, work tree is `$HOME`. Use `dotfiles`
instead of `git` for every operation:

```sh
dotfiles add ~/.config/some-app/config.toml
dotfiles commit -m "feat: add some-app config"
dotfiles push
```

Setup on a new machine:

```sh
curl -sL https://raw.githubusercontent.com/dickolsson/dotfiles/main/scripts/install.sh | sh
```

## Gotchas

- `dotfiles status` hides untracked files (`status.showUntrackedFiles no`),
  so it will NOT show a new file you just created — `dotfiles add` it
  explicitly, and use `dotfiles ls-files` to see what is tracked.
- Executable bits are tracked: `chmod +x` scripts and hooks BEFORE
  `dotfiles add`, or they ship broken.
- `~/.env` is machine-local (banned words for `make check-words`),
  gitignored, and must never be tracked or have its contents quoted in
  tracked files or commit messages.

## The repo is public

Anyone can read it. Never commit secrets, tokens, employer or client
names, or machine identifiers. `make check` enforces this mechanically
(gitleaks, Prettier, banned words from `DOTFILES_CHECK_WORDS` in
`~/.env`), but treat the gates as a backstop, not the reviewer.

## Committing

1. `dotfiles add` the exact paths (see gotchas above).
2. `make check` — must pass before every commit; CI runs the same gates.
3. Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`, ...).
4. `dotfiles push`.

## Machine state: bootstrap hooks

State outside the tracked files (root-owned policy files, launchd jobs,
preference domains) is applied by idempotent hooks in
`scripts/bootstrap.d/`, run in lexical order by `make bootstrap` (and by
the installer). Add a new bootstrap step as an executable `NN-slug` hook
— never as an installer special case. Contract: idempotent, bounded,
exit 0 = applied, 2 = skipped (missing prerequisite), else failed. Full
contract in README.md.

## Related

- `/dotfiles-hardening` adversarially audits the tooling (installer,
  check gates, bootstrap driver, word detection).
- `/homebrew-hardening` audits the Homebrew policy the repo deploys.
