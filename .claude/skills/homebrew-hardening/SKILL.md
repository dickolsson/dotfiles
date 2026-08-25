---
name: homebrew-hardening
description: Audit the Homebrew installation against the hardening baseline (automated daily updates via launchd, integrity verification, tap allowlist, system env file, prefix permissions, Brewfile drift). Use when asked to audit, check, or verify Homebrew security or hardening.
---

# Homebrew hardening audit

Verify every item below with read-only commands. Report a PASS/FAIL checklist
with a one-line remediation for each failure. Do not change anything unless
asked.

## 1. Hardening environment variables

All of these must be set in the environment and declared in `~/.zshenv` (so
they bind in every zsh, not just interactive shells):

- `HOMEBREW_UPDATE_TO_TAG=1`
- `HOMEBREW_VERIFY_ATTESTATIONS=1` (also verify `gh` is on PATH — required for attestation checks)
- `HOMEBREW_NO_INSECURE_REDIRECT=1`
- `HOMEBREW_FORBID_PACKAGES_FROM_PATHS=1`
- `HOMEBREW_NO_ANALYTICS=1`
- `HOMEBREW_FORMULA_BUILD_NETWORK=deny`
- `HOMEBREW_FORMULA_POSTINSTALL_NETWORK=deny`
- `HOMEBREW_FORMULA_TEST_NETWORK=deny`
- `HOMEBREW_ALLOWED_TAPS` (non-empty; must include `homebrew/autoupdate`)

Also: `HOMEBREW_CASK_OPTS` must contain `--require-sha` and must NOT contain
`--no-quarantine`.

Update suppressors must NOT be set anywhere (environment, `~/.zshenv`, or
the system env file): `HOMEBREW_NO_AUTO_UPDATE`,
`HOMEBREW_NO_INSTALL_UPGRADE`, `HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK`.
Updates are automated (section 5) and nothing may disable or throttle them.

## 2. System env file (enforcement layer)

The shell variables above are convention — any same-uid process can unset
them. The enforcement copy lives in Homebrew's system-wide env file:

- `/etc/homebrew/brew.env` exists, owned `root:wheel`, mode 644 (dir
  `/etc/homebrew` root-owned, mode 755, not group/world-writable).
- It sets `HOMEBREW_SYSTEM_ENV_TAKES_PRIORITY=1` (this makes it load last,
  overriding shell env and the other env files for brew runs — including
  runs by the autoupdate launchd job).
- It is identical to the tracked source of truth at `~/scripts/brew.env`
  (`diff` must be empty; remediation: `make bootstrap`) and mirrors every
  variable in section 1 (values unquoted — quotes become part of the
  value).
- The user-writable override files must NOT exist:
  `$(brew --prefix)/etc/homebrew/brew.env` and `~/.homebrew/brew.env`
  (also `$XDG_CONFIG_HOME/homebrew/brew.env` if `XDG_CONFIG_HOME` is set).
- Spot-check enforcement: `env -u HOMEBREW_ALLOWED_TAPS brew config` must
  still show the allowed taps (proves the system file re-injects policy).

## 3. Taps and tap trust

- Every tap in `brew tap` output must be listed in `HOMEBREW_ALLOWED_TAPS`.
  Flag any tap that is not.
- Every entry in `brew trust` output (taps, formulae, casks, commands) must
  correspond to `HOMEBREW_ALLOWED_TAPS` or a `trusted:` stanza in
  `~/Brewfile`. Flag dormant grants — trust for taps that are not tapped or
  allowlisted means their Ruby would evaluate without prompting if ever
  tapped. Remediation: `brew untrust --tap <name>`.

## 4. Homebrew itself on a stable release

`brew --version` must be a plain tag (e.g. `6.0.19`). A suffix like
`-9-g<hash>` means brew is on untagged commits — remediation: the
autoupdate job corrects this on its next run (with
`HOMEBREW_UPDATE_TO_TAG=1` set), or run `brew update` manually.

## 5. Automated updates (launchd)

Updates run unattended via the official `homebrew/autoupdate` tap,
installed by the `40-brew-autoupdate` bootstrap hook (remediation for any
failure below: `make bootstrap`):

- The `homebrew/autoupdate` tap is tapped.
- `brew autoupdate status` reports the job installed and running.
- The launchd agent
  `~/Library/LaunchAgents/com.github.domt4.homebrew-autoupdate.plist`
  exists and is loaded (`launchctl list | grep homebrew-autoupdate`).
- The job upgrades formulae and casks and runs cleanup, but not greedily
  (self-updating casks are handled in-app; section 6): the status output
  must report `Upgrade: formulae and casks` and `Cleanup: yes`, and the
  wrapper script the plist's ProgramArguments points to (under
  `~/Library/Application Support/com.github.domt4.homebrew-autoupdate/`)
  must not pass `--greedy`.
- The interval is 86400 seconds (daily) or shorter.
- Logs under `~/Library/Logs/com.github.domt4.homebrew-autoupdate/` show a
  successful run within the last two days (allow slack for sleep/reboots).
- No OTHER Homebrew-related launchd jobs exist in `~/Library/LaunchAgents`
  or `/Library/LaunchDaemons` — flag anything beyond the autoupdate agent.
- `brew services list` — flag any running service the user does not
  recognize.
- `brew analytics` must report disabled.

## 6. Casks

From `brew info --cask --json=v2` for all installed casks:

- Flag any cask with no checksum (`sha256 :no_check`). These are also blocked
  at install time by `--require-sha` (section 1).
- Casks with `auto_updates: true` are skipped by the autoupdate job, so each
  such app's own in-app updater must be enabled. Verify where a setting is
  inspectable: Ghostty's `auto-update` in `~/.config/ghostty/config.ghostty`
  (`download`), Rancher Desktop's locked deployment profile
  (`defaults read io.rancherdesktop.profile.locked application` must show
  `updater = { enabled = 1 }`, matching the tracked
  `~/scripts/rancher-profile.plist`), VSCodium's `update.mode` in its user
  settings (must be `default` or unset). Flag any that is off.
- Casks with `auto_updates: false` receive updates only from the autoupdate
  job, so confirm section 5 passes.

## 7. Prefix permissions

`$(brew --prefix)` must be owned by the expected user, and nothing under it
may be group- or world-writable:

```sh
find "$(brew --prefix)" \( -perm -g+w -o -perm -o+w \) ! -type l
```

Expect no output. Note: Homebrew operations can recreate group-writable
directories; remediation is `chmod g-w,o-w` on the reported paths.

## 8. PATH hygiene

Build a fresh login-shell PATH (`env -i HOME="$HOME" TERM=dumb zsh -lic 'echo "$PATH"'`)
and also inspect the live PATH:

- No empty entries (`::`, leading or trailing `:`) — an empty entry makes the
  shell search the current directory.
- No user-writable directories ahead of the Homebrew prefix, except
  directories actively managed by an application the user has accepted.
- Per-user tool directories (e.g. `~/.local/bin`, `~/.cargo/bin`) are not on
  PATH; tools there are addressed by alias or absolute path instead.

## 9. No custom toolchains

Everything must be managed by Homebrew. Flag compiler toolchains and per-user
package managers installed outside it — e.g. `~/.rustup`/`~/.cargo`, `~/.nvm`,
`~/.pyenv`, standalone binaries or installer layouts under `~/.local` —
except tools the user has explicitly excepted.

## 10. Brewfile drift

- `~/Brewfile` must exist.
- `brew bundle check --file=~/Brewfile` — everything declared is installed
  (remediation: `make bootstrap`; the `25-brew-bundle` hook installs it).
- `brew bundle cleanup --file=~/Brewfile` (dry-run by default) — flag anything
  installed that is not declared; undeclared packages may indicate unsolicited
  additions.

## Report

End with a summary table: item, PASS/FAIL, remediation. Call out explicitly
whether any finding suggests tampering versus configuration drift.
