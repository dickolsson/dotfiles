# Dotfiles

IMPORTANT: The dotfiles in this home directory are managed by a Git repo.

See `.local/bin/dotfiles-install` for the details of how the Git repo and
this home directory was installed.

## Dependencies

- curl
- git
- rsync

## New system setup

### 0. Base system setup

Install the system with a `sysadm` user. Then:

```
root# usermod -aG adm,staff sysadm
root# chmod 775 /usr/local /usr/local/etc /usr/local/share
root# chown root:staff /usr/local /usr/local/etc /usr/local/share
```

### 0. Bootstrap pkgsrc

In order to reliably bootstrap pkgsrc we need a few essentials:

On Debian:
```
root# apt install build-essential screen
```

On BSD:
```
root# pkg_add screen
```

```
sysadm$ screen
sysadm$ cd ~
sysadm$ wget http://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.bz2
sysadm$ SH=/usr/bin/bash ./pkgsrc/bootstrap/bootstrap --prefix /usr/local --unprivileged
```

### 1. Install base packages

- `/usr/pkgsrc/editors/vim`
- `/usr/pkgsrc/net/rsync`
- `/usr/pkgsrc/security/gnupg2`
- `/usr/pkgsrc/security/pcsc-tools`
- `/usr/pkgsrc/security/pinentry-mac`

```
sysadm$ make
sysadm$ make install
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
