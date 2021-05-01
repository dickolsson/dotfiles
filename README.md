# Dotfiles

IMPORTANT: The dotfiles in this home directory are managed by a Git repo.

See `.local/bin/dotfiles-install` for the details of how the Git repo and
this home directory was installed.

## Basic guidelines for new systems

* Build machines: Debain Bullseye
* Service machines: Alpine
* Network appliances: OpenWRT (with musl)
* Linux 5.9 or above
* Create a `sysadm` user
* Separate `/home` partition
* Always use a Wireguard connection

## 1. Wireguard setup

Before we do anything, we need a reliable and private connection.

On Debian:

```
root# apt install wireguard resolvconf
```

Install, enable and start a Wireguard configuration:

```
root# cp example.conf /etc/wireguard/
root# systemctl enable wg-quick@example
root# systemctl start wg-quick@example
```

## Build machine setup

### OpenWRT dependencies:

```
root# apt install asciidoc binutils flex gcc intltool make libncurses-dev libssl-dev patch python3-dev unzip gettext libxslt1-dev zlib1g-dev libboost-dev libxml-parser-perl libusb-dev bin86 bcc sharutils libpam0g-dev libcap-dev xsltproc
```

### Buildroot dependencies

```
root# apt install binutils gcc make libncurses-dev unzip patch python3-nose2 python3-pexpect
```

## General machine setup

### 0. Base system setup

Install the system with a `sysadm` user. Then:

```
root# usermod -aG staff sysadm
root# mkdir -p /usr/local/pkg/etc
root# chown -R sysadm:staff /usr/local/pkg
```

### 1. Bootstrap pkgsrc

In order to reliably bootstrap pkgsrc we need a few essentials:

On Debian:

```
root# apt install build-essential screen
```

On BSD:

```
root# pkg add screen
```

Download and bootstrap pkgsrc (replace `wget -qO-` with `curl -sL URL` or `ftp -o - URL` as appropriate):

```
sysadm$ screen
sysadm# cat > /usr/local/pkg/etc/mk.conf <<EOF
DISTDIR= /usr/local/pkg/distfiles
PACKAGES= /usr/local/pkg/packages
EOF
sysadm$ wget -qO- https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.bz2 | tar -xjf - -C ~
sysadm$ cd ~/pkgsrc/
sysadm$ SH=/bin/bash ./bootstrap/bootstrap --prefix /usr/local/pkg --unprivileged
sysadm$ cat work/mk.conf.example >> /usr/local/pkg/etc/mk.conf
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

On remote systems, configure the SSH server:

```
root# echo "StreamLocalBindUnlink yes" > /etc/ssh/sshd_config
root# systemctl restart sshd
```

And import the GPG key:

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
sign and send pubkey: signing failed for RSA [...] from agent: agent refused operation

```

Fix: Restart the pinentry program

```
gpg-connect-agent updatestartuptty /bye > /dev/null
```
