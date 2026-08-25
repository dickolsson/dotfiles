#!/bin/sh
# curl -sL https://raw.githubusercontent.com/dickolsson/dotfiles/main/scripts/install.sh | sh
#
# All actions live in main(), called on the last line, so a truncated
# download defines some functions and executes nothing.

set -eu

REPO="https://github.com/dickolsson/dotfiles.git"
DOTFILES="${HOME:?HOME is not set}/.dotfiles"

# Helper for running git against the bare repo with $HOME as work tree.
dotfiles() {
	git --git-dir="$DOTFILES" --work-tree="$HOME" "$@"
}

main() {
	if ! command -v git >/dev/null 2>&1; then
		echo "error: git is required" >&2
		exit 1
	fi

	if [ -e "$DOTFILES" ]; then
		echo "error: $DOTFILES already exists; remove it to reinstall" >&2
		exit 1
	fi

	git clone --bare "$REPO" "$DOTFILES"

	# From here until success, a failure or interrupt removes the clone so
	# a rerun starts clean instead of hitting "already exists".
	trap 'rm -rf "$DOTFILES"' EXIT INT TERM

	# Materialize the tracked files into $HOME (overwriting local copies)
	# and keep `dotfiles status` quiet about everything else in $HOME.
	cd "$HOME"
	dotfiles checkout -f main
	dotfiles config status.showUntrackedFiles no

	# A bare clone has no fetch refspec; add one so pull/push track origin.
	dotfiles config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
	dotfiles fetch -q origin
	dotfiles branch -q --set-upstream-to=origin/main main

	trap - EXIT INT TERM

	# Apply the bootstrap hooks (best effort; each hook is idempotent and
	# can be re-applied anytime with `make bootstrap`).
	if ! perl "$HOME/scripts/bootstrap.pl"; then
		echo "dotfiles: warning: some bootstrap hooks did not complete; rerun with 'make bootstrap'" >&2
	fi

	# Add the dotfiles alias to .zshrc if not already present.
	if ! grep -q "alias dotfiles" "$HOME/.zshrc" 2>/dev/null; then
		cat >>"$HOME/.zshrc" <<'EOF'

alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
EOF
		echo "dotfiles: added alias to ~/.zshrc"
	fi

	echo "dotfiles: installed to $DOTFILES with the work tree at $HOME"
}

main "$@"
