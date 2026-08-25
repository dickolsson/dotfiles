# ~/Makefile
# Manage dotfiles: run `make check` before committing, `make bootstrap`
# to (re)apply the machine bootstrap hooks in scripts/bootstrap.d/.
# Add new checks as check-* targets and chain them to `check`.

# Use the bare repo when it exists (this machine), plain git otherwise (CI).
DOTFILES := $(shell [ -d "$(HOME)/.dotfiles" ] && echo 'git --git-dir=$(HOME)/.dotfiles --work-tree=$(HOME)' || echo git)

# Machine-local settings (e.g. DOTFILES_CHECK_WORDS); absent on CI and
# fresh clones.
-include .env

.PHONY: bootstrap check check-secrets check-format check-words

check: check-secrets check-format check-words

# Apply the bootstrap hooks (idempotent; safe to rerun anytime).
bootstrap:
	@perl scripts/bootstrap.pl

# Scan for leaked secrets and credentials.
check-secrets:
	@$(DOTFILES) ls-files -z | xargs -0 -I {} gitleaks dir --verbose {}

# Check formatting with Prettier.
check-format:
	@$(DOTFILES) ls-files -z | xargs -0 bunx prettier --check --ignore-unknown

# Fail if a word from DOTFILES_CHECK_WORDS (space-separated; set in the
# ignored .env locally, provided as a repository secret in CI) appears in
# tracked file contents or names. Skips when unset. The failure names the
# word's position, never the word, so public CI logs cannot leak it.
check-words:
	@i=0; for w in $(DOTFILES_CHECK_WORDS); do \
		i=$$((i+1)); \
		if $(DOTFILES) grep -I -i -q -e "$$w" -- . || $(DOTFILES) ls-files | grep -i -q -e "$$w"; then \
			echo "check-words: banned word #$$i found (see DOTFILES_CHECK_WORDS)" >&2; \
			exit 1; \
		fi; \
	done
