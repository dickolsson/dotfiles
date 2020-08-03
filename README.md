# dotfiles

## Dependencies

- Git

## New system

Checkout the repository:

```
git clone --bare git@github.com:dickolsson/dotfiles.git
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout --force
```

Hide untracked files in the repo:

```
dotfiles config --local status.showUntrackedFiles no
```
