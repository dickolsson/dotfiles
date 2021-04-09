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

On local systems:
```
sysadm$ gpg2 --card-edit
gpg/card> fetch
gpg/card> quit
```

On remote systems:

```
sysadm$ gpg2 --keyserver keyserver.ubuntu.com --recv 8204A8CD
```

### 4. Install dotfiles

```
wget -qO- https://raw.githubusercontent.com/dickolsson/dotfiles/master/.local/bin/dotfiles-install | sh
```

## Known issues

### QEMU on M1 Mac Mini

With pkgsrc, QEMU (or specifically SPICE Server) doesn't compile out-of-the-box on a M1 Mac Mini.

* Patches: https://stackoverflow.com/a/61444622
* TODO: Submit patches upstream, and to pkgsrc.

## Common issues

### GPG signing issues

Error:
```
sign_and_send_pubkey: signing failed for RSA [...] from agent: agent refused operation

```

Fix: Restart the pinentry program
```
gpg-connect-agent updatestartuptty /bye > /dev/null
```
