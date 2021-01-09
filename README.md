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

### 2. Fetch GPG key

```
$ gpg2 --card-edit
gpg/card> fetch
gpg/card> quit
```

### 3. Install dotfiles

```
curl -Ls https://raw.githubusercontent.com/dickolsson/dotfiles/master/.local/bin/dotfiles-install | sh
```

## Common issues

Problem: GPG signing issues
```
sign_and_send_pubkey: signing failed for RSA [...] from agent: agent refused operation

```

Fix: Restart the pinentry program
```
gpg-connect-agent updatestartuptty /bye > /dev/null
```
