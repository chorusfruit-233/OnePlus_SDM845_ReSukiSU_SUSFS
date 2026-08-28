#!/usr/bin/env bash
set -euo pipefail

kernel_root=${1:?kernel source directory is required}
resukisu_repo=${2:?ReSukiSU repository is required}
resukisu_ref=${3:?ReSukiSU ref is required}
patch_root=${4:?patch directory is required}
cake_repo=${5:?CAKE repository is required}
cake_ref=${6:?CAKE ref is required}
cake_checkout=${7:?CAKE checkout directory is required}
bbg_repo=${8:?Baseband Guard repository is required}
bbg_ref=${9:?Baseband Guard ref is required}
patches_repo=${10:?kernel patches repository is required}
patches_ref=${11:?kernel patches ref is required}
patches_checkout=${12:?kernel patches checkout directory is required}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

# SUSFS v2.2.0 is vendored as a self-contained 4.9 patch (based on
# JackA1ltman/NonGKI_Kernel_Build_2nd), so no upstream git fetch is needed.
git -C "$kernel_root" apply --whitespace=nowarn \
    "$patch_root/susfs-4.9.patch"

# Replace KernelSU's kprobe hooks with SUSFS inline hooks (no-kprobe mode).
bash "$script_dir/susfs-inline-hook.sh" "$kernel_root"

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
test -f "$kernel_root/include/linux/susfs.h"
test -f "$kernel_root/include/linux/susfs_def.h"
test -f "$kernel_root/net/sched/sch_cake.c"
test -f "$kernel_root/net/ipv4/tcp_bbr3.c"
test -L "$kernel_root/security/baseband-guard"
grep -q 'KSTAT_SPOOF_CTIME_TV_SEC (1 << 8)' "$kernel_root/include/linux/susfs.h"
grep -q 'SUSFS_VERSION "v2.2.0"' "$kernel_root/include/linux/susfs.h"
grep -q 'ksu_handle_execveat_sucompat' "$kernel_root/fs/exec.c"
grep -q 'ksu_handle_faccessat' "$kernel_root/fs/open.c"
grep -q 'ksu_handle_stat' "$kernel_root/fs/stat.c"
grep -q 'ksu_handle_sys_reboot' "$kernel_root/kernel/reboot.c"
grep -q '^int filename_lookup(' "$kernel_root/fs/namei.c"
grep -q 'atomic_t filter_count' "$kernel_root/include/linux/seccomp.h"

echo "ReSukiSU commit: $(git -C "$kernel_root/KernelSU" rev-parse HEAD)"
echo "SUSFS patch: $patch_root/susfs-4.9.patch ($(sha256sum "$patch_root/susfs-4.9.patch" | cut -c1-12))"
echo "CAKE commit: $(git -C "$cake_checkout" rev-parse HEAD)"
echo "Baseband Guard commit: $(git -C "$kernel_root/Baseband-guard" rev-parse HEAD)"
echo "Kernel patches commit: $(git -C "$patches_checkout" rev-parse HEAD)"
