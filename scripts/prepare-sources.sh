#!/usr/bin/env bash
set -euo pipefail

kernel_root=${1:?kernel source directory is required}
resukisu_repo=${2:?ReSukiSU repository is required}
resukisu_ref=${3:?ReSukiSU ref is required}
susfs_repo=${4:?SUSFS repository is required}
susfs_ref=${5:?SUSFS ref is required}
patch_root=${6:?patch directory is required}
susfs_checkout=${7:?SUSFS checkout directory is required}

clone_ref() {
    local repo=$1 ref=$2 destination=$3
    rm -rf "$destination"
    git clone --filter=blob:none --no-checkout "$repo" "$destination"
    git -C "$destination" fetch --depth=1 origin "$ref"
    git -C "$destination" checkout --detach FETCH_HEAD
}

clone_ref "$resukisu_repo" "$resukisu_ref" "$kernel_root/KernelSU"
ln -sfn ../KernelSU/kernel "$kernel_root/drivers/kernelsu"

clone_ref "$susfs_repo" "$susfs_ref" "$susfs_checkout"
install -D -m 0644 "$susfs_checkout/kernel_patches/fs/susfs.c" \
    "$kernel_root/fs/susfs.c"
install -D -m 0644 "$susfs_checkout/kernel_patches/include/linux/susfs.h" \
    "$kernel_root/include/linux/susfs.h"
install -D -m 0644 "$susfs_checkout/kernel_patches/include/linux/susfs_def.h" \
    "$kernel_root/include/linux/susfs_def.h"

git -C "$kernel_root" apply --whitespace=nowarn \
    "$patch_root/susfs-4.9-adaptation.patch"

test -L "$kernel_root/drivers/kernelsu"
test -f "$kernel_root/fs/susfs.c"
grep -q 'KSTAT_SPOOF_CTIME_TV_SEC (1 << 8)' "$kernel_root/include/linux/susfs.h"
grep -q 'LINUX_VERSION_CODE < KERNEL_VERSION(5, 0, 0)' "$kernel_root/fs/susfs.c"

echo "ReSukiSU commit: $(git -C "$kernel_root/KernelSU" rev-parse HEAD)"
echo "SUSFS commit: $(git -C "$susfs_checkout" rev-parse HEAD)"
