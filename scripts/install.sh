#!/bin/sh
(
set -eu

fail() {
	printf 'SSH Tunnel: %s\n' "$*" >&2
	exit 1
}

[ "$(id -u)" = 0 ] || fail "Run this script as root."
[ -r /etc/openwrt_release ] || fail "OpenWrt release information is missing."
. /etc/openwrt_release

version=${DISTRIB_RELEASE:-unknown}
case "$version" in
	25.12.5) tag=v0.1.0; manager=apk; ext=apk ;;
	25.12.6) tag=openwrt-25.12.6; manager=apk; ext=apk ;;
	24.10.4) tag=openwrt-24.10.4; manager=opkg; ext=ipk ;;
	*) fail "OpenWrt $version is unsupported. Available builds: 24.10.4, 25.12.5, 25.12.6." ;;
esac
command -v "$manager" >/dev/null || fail "$manager is missing."

work=$(mktemp -d /tmp/ssh-tunnel-install.XXXXXX)
trap 'rm -rf "$work"' EXIT
trap 'exit 1' HUP INT TERM
cd "$work"

repo="SSHVPN-Connect/SshVPN-openwrt"
release_url="https://github.com/$repo/releases/download/$tag"
api="https://api.github.com/repos/$repo/releases"
use_api=0

download() {
	local asset="$1" id

	if [ "$use_api" = 0 ] && wget -T 12 -O "$asset" "$release_url/$asset"; then
		return 0
	fi

	use_api=1
	command -v jsonfilter >/dev/null || fail "GitHub API fallback requires jsonfilter."
	if [ ! -s release.json ]; then
		printf 'Trying the GitHub API for OpenWrt %s.\n' "$version"
		wget -T 12 -O release.json "$api/tags/$tag" || return 1
	fi
	id=$(jsonfilter -i release.json -e "@.assets[@.name=\"$asset\"].id") || return 1
	case "$id" in ''|*[!0-9]*) return 1 ;; esac
	wget -T 12 --header='Accept: application/octet-stream' -O "$asset" \
		"$api/assets/$id?download=1"
}

download SHA256SUMS || fail "Could not download checksums. Check HTTPS access to github.com, api.github.com and release-assets.githubusercontent.com from the router."
platform=${DISTRIB_TARGET:-}
target="luci-proto-ssh-tunnel_v${version}_${DISTRIB_ARCH:-}_${platform%/*}_${platform#*/}.$ext"
entry=$(awk -v target="$target" -v ext="$ext" '
	length($1) != 64 || $1 ~ /[^0-9a-fA-F]/ { next }
	$2 == target { specific = $0; exact++ }
	(ext == "apk" && $2 ~ /^luci-proto-ssh-tunnel-[0-9.]+-r[0-9]+[.]apk$/) ||
	(ext == "ipk" && $2 ~ /^luci-proto-ssh-tunnel_[0-9.]+-r[0-9]+_all[.]ipk$/) {
		universal = $0; generic++
	}
	END {
		if (exact == 1) print specific
		else if (exact == 0 && generic == 1) print universal
		else exit 1
	}
' SHA256SUMS) || fail "No unique package found for OpenWrt $version ($platform)."
package=$(printf '%s\n' "$entry" | awk '{ print $2 }')
download "$package" || fail "Could not download $package."
printf '%s\n' "$entry" | sha256sum -c - || fail "Package checksum mismatch."

"$manager" update
case "$manager" in
	apk) apk add --allow-untrusted "$work/$package" ;;
	opkg) opkg install "$work/$package" ;;
esac
printf 'SSH Tunnel installed. In LuCI, open Network > Interfaces > Add new interface.\n'
)
