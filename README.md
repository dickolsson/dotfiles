# Dotfiles

[![Check](https://github.com/dickolsson/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/dickolsson/dotfiles/actions/workflows/check.yml)

This home directory is managed by a bare Git repo at `~/.dotfiles`.

## Setup

```sh
curl -sL https://raw.githubusercontent.com/dickolsson/dotfiles/main/scripts/install.sh | sh
```

The installer materializes the tracked files into `$HOME` and applies the
[bootstrap hooks](#bootstrap).

## Usage

Use `dotfiles` instead of `git` for all operations:

```sh
dotfiles add ~/.config/some-app/config.toml
dotfiles commit -m "feat: add some-app config"
dotfiles push
```

## Bootstrap

Machine state that lives outside the tracked files (root-owned policy
files, launchd jobs, preference domains) is applied by hooks:

```sh
make bootstrap
```

The installer runs the same hooks; rerunning is always safe. A hook is an
executable `NN-slug` file in `scripts/bootstrap.d/`, run in lexical order
by `scripts/bootstrap.pl` with cwd `$HOME`. The contract: be idempotent
(detect "already applied" and exit 0), finish inside the per-hook timeout
(5 minutes by default — the driver kills overruns; a hook doing
legitimately long work, like a first package install, may raise its own
limit with a `# bootstrap-timeout: <seconds>` header line), and exit 0
for applied, 2 for skipped (missing prerequisite), anything else for
failed. The driver runs every hook even after a failure and exits
non-zero if any failed. To add a bootstrap step, drop in a new hook — the
installer and Makefile need no changes.

## Checks

Run `make check` before committing. It verifies formatting (Prettier),
scans for leaked secrets (gitleaks), and fails if any banned word appears
in tracked files. The banned-word list lives in `DOTFILES_CHECK_WORDS`:
locally as `DOTFILES_CHECK_WORDS=word1 word2` in the Git-ignored `~/.env`,
in CI as a repository secret of the same name. The gate skips cleanly
when the list is unset (e.g. pull requests from forks), and its failure
message names the word's position rather than the word, so public CI
logs cannot leak the list.

The `10-check-words` bootstrap hook seeds `~/.env` from machine-local
signals (keychain PKI, DNS search domains, the TLS interception chain,
the local account name, and the machine's host name); it only appends
words that are missing.

## Security

Homebrew keeps everything current automatically while enforcing package
integrity: security fixes only ship as new versions (Homebrew has no
backport channel), so update cadence is patch latency.

### Automated updates

The official `homebrew/autoupdate` launchd job runs `brew update`,
`brew upgrade`, and `brew cleanup` daily (installed by the
`40-brew-autoupdate` bootstrap hook).

Casks marked `auto_updates` are skipped by the job (it does not run
`--greedy`) and update through their own in-app updaters, which stay
enabled: Ghostty via `auto-update` in its tracked config, VSCodium via
`update.mode` in its tracked settings, Bitwarden built-in (no toggle),
and Rancher Desktop via a locked deployment profile imported from
`~/scripts/rancher-profile.plist` by the `30-rancher-profile` hook.

Homebrew itself follows stable release tags only.

### Integrity

Enforced via env vars declared in `~/.zshenv`, with the authoritative copy
in the root-owned `/etc/homebrew/brew.env` — it takes priority over shell
env for every brew run, including the launchd job. The `20-brew-env`
bootstrap hook deploys it from the tracked `~/scripts/brew.env` (sudo,
only when the deployed copy has drifted).

- Bottle build provenance is verified via sigstore attestations.
- Taps are restricted to an explicit allowlist; installs from arbitrary URLs or paths are forbidden.
- Casks must ship a real checksum (`--require-sha`); source builds, postinstalls, and tests run with network access denied.
- Installed packages are declared in `~/Brewfile` for drift detection (`brew bundle check` / `brew bundle cleanup`).
- The Homebrew prefix is writable only by the owning user (no group write).
- Analytics are disabled.
- `PATH` has no empty entries and no user-writable directories ahead of the Homebrew prefix; `~/.local/bin` is off `PATH`.
- All programs must be managed by Homebrew: custom compiler toolchains and per-user package managers should not be present.

Audit with the `homebrew-hardening` Claude Code skill.
