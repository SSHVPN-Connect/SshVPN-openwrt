# SSH Tunnel for OpenWrt

<img src="assets/ssh-tunnel-logo.png" width="72" height="72" alt="SSH Tunnel logo">

[Русский](README.md) | [English](README.en.md)

Adds the **SSH Tunnel** protocol to LuCI under **Network → Interfaces → Add new
interface**. The connection creates a TUN interface that can be selected in
Podkop. It does not change the default route.

This is the SSH VPN client from
[SshVPN-openwrt](https://github.com/SSHVPN-Connect/SshVPN-openwrt), using the
server component from
[sshvpn-client](https://github.com/SSHVPN-Connect/sshvpn-client).

## Install

Run this in the router's SSH session as `root`.

```sh
installer=$(mktemp /tmp/ssh-tunnel-install.XXXXXX) &&
  wget -T 15 -O "$installer" https://raw.githubusercontent.com/SSHVPN-Connect/SshVPN-openwrt/main/scripts/install.sh &&
  sh "$installer"
```

The script detects the OpenWrt version and platform, downloads the matching
package, verifies its SHA-256 checksum, and installs it with its dependencies.
If the release URL is unreachable, it tries the GitHub API.

If the router cannot download the script from the URL above, copy
[install.sh](scripts/install.sh) to `/tmp` and run `sh /tmp/install.sh`.

For manual installation, download the package for
[24.10.4](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases/tag/openwrt-24.10.4),
[25.12.5](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases/tag/v0.1.0), or
[25.12.6](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases/tag/openwrt-25.12.6).
For other firmware versions, use the matching SDK.

After installation, open **Network → Interfaces → Add new interface → SSH Tunnel**.

## Build

Use the OpenWrt SDK matching the firmware version, target, and subtarget. SDKs
are available from the [OpenWrt downloads directory](https://downloads.openwrt.org/).

Install build dependencies on Linux (Debian/Ubuntu):

```sh
sudo apt update
sudo apt install build-essential gawk gettext git libncurses-dev libssl-dev python3 rsync unzip zstd
```

Extract the SDK, clone this repository, and run this command from the repository root:

```sh
./scripts/build-sdk.sh /path/to/openwrt-sdk
```

The resulting APK or IPK will be placed in `dist/`. To choose a different output directory:

```sh
./scripts/build-sdk.sh /path/to/openwrt-sdk ./build-output
```

## Configure

### Share invitation code

Under **Connection method**, choose **Use an invitation code** and paste the
complete line from the Windows client's Share menu into **Share invitation code**.
The server must have invitation support enabled by the owner's client. An
invitation can be redeemed once and expires after 30 minutes. When the
interface starts, the router redeems it, creates a permanent key, and saves the
profile. The code field clears after activation. The default SSH port is `22`.
Enter another port in **SSH port** if the server uses one.

### Direct connection

Under **Connection method**, choose **Enter SSH credentials manually**.
Automatic server setup requires SSH access as `root`. Enter the server address
and port, then provide either a password or the path to a private key that is
already on the router and readable by root.

The network device name is assigned automatically. The package uses
`172.31.255.2/30` on the router and `172.31.255.1` on the server. The server
component allows one active connection at a time.
