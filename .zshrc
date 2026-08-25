# Interactive shells only — environment lives in ~/.zshenv,
# PATH construction in ~/.zprofile.

# Prompt
PS1='%~%(!.# .$ )'

# Word navigation with Ctrl + Left/Right
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# General shell aliases
alias ll="ls -lha"
alias ..="cd .."
alias ....="cd ../../"

# Other aliases
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias c="clear; claude"
alias anarlog='$HOME/.local/bin/anarlog' # App-managed CLI, dir deliberately off PATH
