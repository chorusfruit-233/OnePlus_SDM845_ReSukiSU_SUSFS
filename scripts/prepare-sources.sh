#!/usr/bin/env bash
set -euo pipefail

kernel_root=${1:?kernel source directory is required}
resukisu_repo=${2:?ReSukiSU repository is required}
resukisu_ref=${3:?ReSukiSU ref is required}
susfs_repo=${4:?SUSFS repository is required}
susfs_ref=${5:?SUSFS ref is required}
patch_root=${6:?patch directory is required}
susfs_checkout=${7:?SUSFS checkout directory is required}
cake_repo=${8:?CAKE repository is required}
cake_ref=${9:?CAKE ref is required}
cake_checkout=${10:?CAKE checkout directory is required}
bbg_repo=${11:?Baseband Guard repository is required}
bbg_ref=${12:?Baseband Guard ref is required}
patches_repo=${13:?kernel patches repository is required}
patches_ref=${14:?kernel patches ref is required}
patches_checkout=${15:?kernel patches checkout directory is required}

clone_ref() {
    local repo=$1 ref=$2 destination=$3
    rm -rf "$destination"
    git clone --filter=blob:none --no-checkout "$repo" "$destination"
    git -C "$destination" fetch --depth=1 origin "$ref"
    git -C "$destination" checkout --detach FETCH_HEAD
}

clone_sparse_ref() {
    local repo=$1 ref=$2 destination=$3 path=$4
    rm -rf "$destination"
    git clone --filter=blob:none --no-checkout "$repo" "$destination"
    git -C "$destination" sparse-checkout init --cone
    git -C "$destination" sparse-checkout set "$path"
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

clone_ref "$cake_repo" "$cake_ref" "$cake_checkout"
install -D -m 0644 "$cake_checkout/sch_cake.c" \
    "$kernel_root/net/sched/sch_cake.c"
install -D -m 0644 "$cake_checkout/cobalt.h" \
    "$kernel_root/include/net/cobalt.h"
git -C "$kernel_root" apply --whitespace=nowarn \
    "$patch_root/cake-4.9-adaptation.patch"

clone_ref "$bbg_repo" "$bbg_ref" "$kernel_root/Baseband-guard"
ln -sfn ../Baseband-guard "$kernel_root/security/baseband-guard"
ln -sfn ../../../Baseband-guard/tracing/tracing.h \
    "$kernel_root/security/selinux/include/bbg_tracing.h"

clone_sparse_ref "$patches_repo" "$patches_ref" "$patches_checkout" \
    common/bbrv3
git -C "$kernel_root" apply --whitespace=nowarn \
    --include=net/ipv4/tcp_bbr3.c \
    "$patches_checkout/common/bbrv3/0001-net-tcp-backport-BBRv3-to-android12-5.10.patch"
git -C "$kernel_root" apply --whitespace=nowarn \
    "$patch_root/bbrv3-4.9-adaptation.patch"

test -L "$kernel_root/drivers/kernelsu"
test -f "$kernel_root/fs/susfs.c"
test -f "$kernel_root/net/sched/sch_cake.c"
test -f "$kernel_root/net/ipv4/tcp_bbr3.c"
test -L "$kernel_root/security/baseband-guard"
grep -q 'KSTAT_SPOOF_CTIME_TV_SEC (1 << 8)' "$kernel_root/include/linux/susfs.h"
grep -q 'LINUX_VERSION_CODE < KERNEL_VERSION(5, 0, 0)' "$kernel_root/fs/susfs.c"

echo "ReSukiSU commit: $(git -C "$kernel_root/KernelSU" rev-parse HEAD)"
echo "SUSFS commit: $(git -C "$susfs_checkout" rev-parse HEAD)"
echo "CAKE commit: $(git -C "$cake_checkout" rev-parse HEAD)"
echo "Baseband Guard commit: $(git -C "$kernel_root/Baseband-guard" rev-parse HEAD)"
echo "Kernel patches commit: $(git -C "$patches_checkout" rev-parse HEAD)"
