#!/usr/bin/python3
"""Bridge the router TUN device to the SSH Tunnel server's framed stream."""
import fcntl
import os
import re
import select
import struct
import subprocess
import sys

MTU = 1420
TUNSETIFF = 0x400454CA
TUNSETPERSIST = 0x400454CB
IFF_TUN = 0x0001
IFF_NO_PI = 0x1000


def write_all(fd, data):
    view = memoryview(data)
    while view:
        count = os.write(fd, view)
        view = view[count:]


def tun_ioctl(fd, device):
    if not re.fullmatch(r"[a-zA-Z0-9_.-]{1,15}", device):
        raise RuntimeError("Invalid TUN device name")
    fcntl.ioctl(fd, TUNSETIFF, struct.pack("16sH22x", device.encode(), IFF_TUN | IFF_NO_PI))


def create_tun(device):
    tun = os.open("/dev/net/tun", os.O_RDWR | os.O_CLOEXEC)
    try:
        tun_ioctl(tun, device)
        fcntl.ioctl(tun, TUNSETPERSIST, 1)
    finally:
        os.close(tun)
    subprocess.run(["/sbin/ip", "link", "set", "dev", device, "mtu", str(MTU), "up"], check=True)


def delete_tun(device):
    try:
        tun = os.open("/dev/net/tun", os.O_RDWR | os.O_CLOEXEC)
    except FileNotFoundError:
        return
    try:
        tun_ioctl(tun, device)
        fcntl.ioctl(tun, TUNSETPERSIST, 0)
    finally:
        os.close(tun)


def main():
    if len(sys.argv) == 3 and sys.argv[1] in ("--create", "--delete"):
        (create_tun if sys.argv[1] == "--create" else delete_tun)(sys.argv[2])
        return
    if len(sys.argv) != 7:
        raise RuntimeError("usage: ssh-tunnel-client HOST PORT USER DEVICE KEY AUTH")
    host, port, username, device, key, auth = sys.argv[1:]
    tun = os.open("/dev/net/tun", os.O_RDWR | os.O_CLOEXEC)
    tun_ioctl(tun, device)
    # The protocol handler created a persistent device so netifd could
    # register it before starting this process. From here on, keep it alive
    # only while this file descriptor remains open.
    fcntl.ioctl(tun, TUNSETPERSIST, 0)
    subprocess.run(["/sbin/ip", "link", "set", "dev", device, "mtu", str(MTU), "up"], check=True)

    ssh = ["/usr/bin/ssh", "-T", "-p", port, "-o", "ConnectTimeout=15", "-o", "StrictHostKeyChecking=accept-new"]
    # Passwords use sshpass's environment interface so the secret is not in argv.
    if auth == "key":
        ssh += ["-o", "BatchMode=yes", "-i", key]
    else:
        ssh += ["-o", "PreferredAuthentications=password,keyboard-interactive"]
    target = username + "@" + host
    ssh += ["--", target]
    if auth == "password":
        ssh = ["/usr/bin/sshpass", "-e"] + ssh

    # First connection provisions the same handler used by the Windows client.
    installer = "/usr/share/ssh-tunnel/install-server.sh"
    with open(installer, "rb") as source:
        result = subprocess.run(ssh + ["sh", "-s"], stdin=source, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        sys.stderr.buffer.write(result.stderr)
        raise RuntimeError("Server setup failed. The configured SSH account must be root.")
    ssh += ["ssh-tunnel-vpn"]

    proc = subprocess.Popen(ssh, stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)
    greeting = proc.stdout.readline()
    if greeting != b"SSHVPN1\n":
        raise RuntimeError("Server did not start the VPN handler (SSHVPN1). Check server setup and root SSH access.")
    input_fd = proc.stdout.fileno()
    output_fd = proc.stdin.fileno()
    pending = bytearray()
    try:
        while True:
            ready, _, _ = select.select([tun, input_fd], [], [])
            if input_fd in ready:
                data = os.read(input_fd, 16384)
                if not data:
                    break
                pending.extend(data)
                while len(pending) >= 2:
                    size = int.from_bytes(pending[:2], "big")
                    if not 20 <= size <= MTU:
                        raise RuntimeError("Invalid IPv4 frame from SSH server")
                    if len(pending) < size + 2:
                        break
                    packet = bytes(pending[2:size + 2])
                    del pending[:size + 2]
                    if packet[0] >> 4 == 4:
                        write_all(tun, packet)
            if tun in ready:
                packet = os.read(tun, MTU)
                if len(packet) >= 20 and packet[0] >> 4 == 4:
                    write_all(output_fd, len(packet).to_bytes(2, "big") + packet)
    finally:
        proc.terminate()
        proc.wait()
        os.close(tun)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError) as exc:
        print("SSH Tunnel: " + str(exc), file=sys.stderr)
        sys.exit(1)
