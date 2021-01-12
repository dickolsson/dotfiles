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
root# usermod -aG staff sysadm
root# mkdir /usr/local/{bin,etc,libexec,man,pkgdb,sbin,share,var}
root# find /usr/local/* -type d -exec chown root:staff {} \; -exec chmod 775 {} \;
```

### 1. Bootstrap pkgsrc

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
sysadm$ tar xf pkgsrc.tar.bz2
sysadm$ SH=/usr/bin/bash ./pkgsrc/bootstrap/bootstrap --prefix /usr/local --unprivileged
```

### 2. Install base packages

- `/usr/pkgsrc/editors/vim`
- `/usr/pkgsrc/net/rsync`
- `/usr/pkgsrc/security/gnupg2`
- `/usr/pkgsrc/security/pcsc-tools`
- `/usr/pkgsrc/security/pinentry-mac`

```
sysadm$ make
sysadm$ make install
```

### 3. Fetch GPG key

```
$ gpg2 --card-edit
gpg/card> fetch
gpg/card> quit
```

### 4. Install dotfiles

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
