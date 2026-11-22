# SSH Tunnel for OpenWrt

[Русский](README.md) | [English](README.en.md)

Adds the **SSH Tunnel** protocol to LuCI under **Network → Interfaces → Add new
interface**. The connection creates a TUN interface that can be selected in
Podkop. It does not change the default route.

This is the SSH VPN client from
[SshVPN-openwrt](https://github.com/SSHVPN-Connect/SshVPN-openwrt), using the
server component from
[sshvpn-client](https://github.com/SSHVPN-Connect/sshvpn-client).

## Install

1. Open the [releases page](https://github.com/SSHVPN-Connect/SshVPN-openwrt/releases)
   and download the APK matching your device's OpenWrt version, architecture,
   target, and subtarget. The filename contains these values. For example, look
   for `mediatek_filogic` for the Xiaomi Mi Router AX3000T.
2. Copy the file to the router, for example to `/tmp`, and install it:

   ```sh
   apk add --allow-untrusted /tmp/<filename>.apk
   ```

3. In LuCI, add an interface: **Network → Interfaces → Add new interface → SSH Tunnel**.

Check the installed version, architecture, and target/subtarget with
`cat /etc/openwrt_release`. For firmware using `opkg`, build the package with
the matching SDK and install the resulting `.ipk` with `opkg install`.

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

On the first connection, the package configures the SSH VPN server. SSH access
to the server as `root` is required. In the interface form, enter the server
address and port, then provide either a password or the path to a private key
that is already on the router and readable by root.

The network device name is assigned automatically. The package uses
`172.31.255.2/30` on the router and `172.31.255.1` on the server. The server
component allows one active connection at a time.
