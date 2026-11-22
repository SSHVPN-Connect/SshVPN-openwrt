#!/usr/bin/env bash
set -euo pipefail

usage() {
	echo "Usage: $0 <extracted-openwrt-sdk> [output-directory]" >&2
	exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_dir="$(cd -- "$1" && pwd)"
output_dir="${2:-$repo_dir/dist}"
mkdir -p -- "$output_dir"
output_dir="$(cd -- "$output_dir" && pwd)"

if [[ ! -f "$sdk_dir/include/toplevel.mk" || ! -f "$sdk_dir/.config" ]]; then
	echo "Error: '$sdk_dir' does not look like an extracted OpenWrt SDK." >&2
	exit 1
fi

sdk_name="$(basename -- "$sdk_dir")"
if [[ "$sdk_name" =~ ^openwrt-sdk-([0-9]+\.[0-9]+-SNAPSHOT)- ]]; then
	openwrt_version="${BASH_REMATCH[1]}"
elif [[ "$sdk_name" =~ ^openwrt-sdk-([0-9][^-]*)- ]]; then
	openwrt_version="${BASH_REMATCH[1]}"
else
	openwrt_version="sdk"
fi

board="$(sed -n 's/^CONFIG_TARGET_BOARD="\([^"]*\)"/\1/p' "$sdk_dir/.config" | head -n1)"
subtarget="$(sed -n 's/^CONFIG_TARGET_SUBTARGET="\([^"]*\)"/\1/p' "$sdk_dir/.config" | head -n1)"
if [[ -z "$board" || -z "$subtarget" ]]; then
	echo "Error: could not read CONFIG_TARGET_BOARD/SUBTARGET from SDK .config." >&2
	exit 1
fi

package_name="luci-proto-ssh-tunnel"
source_dir="$repo_dir/$package_name"
sdk_package_dir="$sdk_dir/package/$package_name"
mkdir -p -- "$sdk_package_dir"
cp -a -- "$source_dir/." "$sdk_package_dir/"

echo "Building $package_name for OpenWrt $openwrt_version ($board/$subtarget)"
make -C "$sdk_package_dir" TOPDIR="$sdk_dir" compile V=s

artifact="$(find "$sdk_dir/bin/packages" -type f \
	\( -name "$package_name-*.apk" -o -name "$package_name-*.ipk" \) \
	-print -quit)"
if [[ -z "$artifact" ]]; then
	echo "Error: build succeeded but no .apk/.ipk artifact was found under $sdk_dir/bin/packages." >&2
	exit 1
fi

artifact_ext="${artifact##*.}"
output_file="$output_dir/$package_name-$openwrt_version-$board-$subtarget.$artifact_ext"
cp -- "$artifact" "$output_file"
echo "Package: $output_file"
if command -v sha256sum >/dev/null 2>&1; then
	sha256sum "$output_file"
fi
