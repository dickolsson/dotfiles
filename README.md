# Dotfiles

IMPORTANT: The dotfiles in this home directory are managed by a Git repo.

See `.local/bin/dotfiles-install` for the details of how the Git repo and
this home directory was installed.

## New system setup

### 0. Base system setup

Install the system with a `sysadm` user. Then:

```
root# usermod -aG staff sysadm
root# mkdir /usr/local/pkg
root# chown sysadm:staff /usr/local/pkg
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

Download and bootstrap pkgsrc (replace `wget -qO-` with `curl -sL URL` or `ftp -o - URL` as appropriate):
```
sysadm$ screen
sysadm$ wget -qO- https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.bz2 | tar -xjf - -C ~
sysadm$ cd ~/pkgsrc/
sysadm$ SH=/bin/bash ./bootstrap/bootstrap --prefix /usr/local/pkg --unprivileged
```

For macOS, you might need to work-around platform quirks in pkgsrc before bootstrapping:
```
sysadm$ export OSX_SDK_PATH=$(xcrun --show-sdk-path)
```

And, until we have our dotfiles installed:
```
sysadm$ export PATH=/usr/local/pkg/bin:/usr/local/pkg/sbin:$PATH
```

### 2. Install base packages

- `editors/vim`
- `devel/git`
- `net/wget`
- `net/rsync`
- `security/gnupg2`

For each package:
```
sysadm$ bmake
sysadm$ bmake install
```

### 3. Fetch GPG key

```
sysadm$ gpg2 --card-edit
gpg/card> fetch
gpg/card> quit
```

### 4. Install dotfiles

```
wget -qO- https://raw.githubusercontent.com/dickolsson/dotfiles/master/.local/bin/dotfiles-install | sh
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
