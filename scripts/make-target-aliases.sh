#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
	echo "Usage: $0 <universal-apk-or-ipk> <output-dir> [target-list]" >&2
	exit 2
fi

package=$1
out=$2
version=${VERSION:-25.12.5}
targets=${3:-"$(dirname "$0")/../targets/openwrt-$version-targets.txt"}

[ -f "$package" ] || { echo "Package not found: $package" >&2; exit 1; }
extension=${package##*.}
case "$extension" in
	apk|ipk) ;;
	*) echo "Expected an APK or IPK file: $package" >&2; exit 1 ;;
esac
[ -f "$targets" ] || { echo "Target list not found: $targets" >&2; exit 1; }
mkdir -p "$out"
sumfile="$out/SHA256SUMS"
: > "$sumfile"

while IFS= read -r target || [ -n "$target" ]; do
	# Ignore blank lines and comments; tolerate a UTF-8 BOM in the list.
	target=$(printf '%s' "$target" | sed '1s/^ï»¿//')
	case "$target" in ''|'#'*) continue ;; esac
	case "$target" in *[!A-Za-z0-9._-]*) echo "Invalid target suffix: $target" >&2; exit 1 ;; esac
	name="luci-proto-ssh-tunnel_v${version}_${target}.$extension"
	cp "$package" "$out/$name"
	if command -v sha256sum >/dev/null 2>&1; then
		(cd "$out" && sha256sum "$name") >> "$sumfile"
	else
		(cd "$out" && shasum -a 256 "$name") >> "$sumfile"
	fi
done < "$targets"

echo "Created $(wc -l < "$sumfile" | tr -d ' ') packages in $out"
