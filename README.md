# Dotfiles

IMPORTANT: The dotfiles in this home directory are managed by a Git repo.

See `.local/bin/dotfiles-install` for the details of how the Git repo and
this home directory was installed.

## Dependencies

- curl
- git
- rsync

## New system setup

### 1. Install base packages

#### Debian

```
sudo apt install vim rsync gnupg2 gnupg-agent scdaemon pcscd
```

#### BSD and Darwin

- `/usr/pkgsrc/editors/vim`
- `/usr/pkgsrc/net/rsync`
- `/usr/pkgsrc/security/gnupg2`
- `/usr/pkgsrc/security/pcsc-tools`
- `/usr/pkgsrc/security/pinentry-mac`

```
$ make
$ sudo make install
```

### 3. Install dotfiles

```
curl -Ls https://raw.githubusercontent.com/dickolsson/dotfiles/master/.local/bin/dotfiles-install | sh
```
