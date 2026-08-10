#!/usr/bin/env bash
set -euo pipefail

ak3_source=${1:?AnyKernel3 source directory is required}
kernel_image=${2:?kernel image is required}
ak3_template=${3:?AnyKernel3 template is required}
output_zip=$(realpath -m "${4:?output zip is required}")
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

test -f "$ak3_source/LICENSE"
test -d "$ak3_source/META-INF"
test -d "$ak3_source/tools"
test -f "$kernel_image"

mkdir -p "$stage/ramdisk" "$stage/patch" "$stage/modules"
cp -a "$ak3_source/META-INF" "$ak3_source/tools" "$stage/"
cp "$ak3_source/LICENSE" "$stage/LICENSE"
cp "$ak3_template" "$stage/anykernel.sh"
cp "$kernel_image" "$stage/Image.gz-dtb"
chmod 0755 "$stage/anykernel.sh"

mkdir -p "$(dirname "$output_zip")"
(cd "$stage" && zip -qr9 "$output_zip" .)
unzip -tq "$output_zip"
sha256sum "$output_zip"
