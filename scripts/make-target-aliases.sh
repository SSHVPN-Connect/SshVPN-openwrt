#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
	 echo "Usage: $0 <universal-apk> <output-dir> [target-list]" >&2
	 exit 2
fi

apk=$1
out=$2
targets=${3:-"$(dirname "$0")/../targets/openwrt-25.12.5-targets.txt"}
version=${VERSION:-25.12.5}

[ -f "$apk" ] || { echo "APK not found: $apk" >&2; exit 1; }
[ -f "$targets" ] || { echo "Target list not found: $targets" >&2; exit 1; }
mkdir -p "$out"
sumfile="$out/SHA256SUMS"
: > "$sumfile"

while IFS= read -r target || [ -n "$target" ]; do
	# Ignore blank lines and comments; tolerate a UTF-8 BOM in the list.
	target=$(printf '%s' "$target" | sed '1s/^ï»¿//')
	case "$target" in ''|'#'*) continue ;; esac
	case "$target" in *[!A-Za-z0-9._-]*) echo "Invalid target suffix: $target" >&2; exit 1 ;; esac
	name="luci-proto-ssh-tunnel_v${version}_${target}.apk"
	cp "$apk" "$out/$name"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$out/$name" >> "$sumfile"
	else
		shasum -a 256 "$out/$name" >> "$sumfile"
	fi
done < "$targets"

echo "Created $(wc -l < "$sumfile" | tr -d ' ') target-labelled APKs in $out"
