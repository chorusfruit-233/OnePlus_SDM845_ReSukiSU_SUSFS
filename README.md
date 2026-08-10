# OnePlus SDM845 ReSukiSU/SUSFS Builder

这是独立于 kernel 源码的构建仓库。每次 GitHub Actions 运行都会：

1. 拉取固定的 LineageOS 4.9.337 kernel 基线并应用 `patches/lineage-4.9/`；
2. 按 workflow 输入解析并固定 ReSukiSU、SUSFS、BBG、WildKernels patches
   和 AnyKernel3 的最新提交；
3. 从 4.9 兼容 CAKE 基线安装 qdisc，并应用 CAKE/BBRv3 的 4.9 API 适配；
4. 构建 `Image.gz-dtb` 并生成可刷入的 AnyKernel3 ZIP；
5. 上传内核、AK3 包、SHA256 校验和及所有实际提交记录。

当前配置面向 OnePlus 6/6T：`enchilada` / `fajita`，defconfig 为
`enchilada_defconfig`。

第一优先级还包含 Droidspaces/LXC 基础支持。workflow 会检查 namespaces、cgroups、
seccomp、veth/bridge、netfilter、overlayfs 和 tmpfs ACL/XATTR 等选项；目标 4.9 树
使用 `CONFIG_NF_CT_NETLINK` 作为新版文档中的 conntrack-netlink 对应项。

第二优先级包含 CAKE、BBRv3、Baseband Guard，以及保守的 CPUfreq、内存、F2FS
和唤醒优化。BBRv1 保留为运行时回退；BBG 默认不保护 boot/recovery，避免妨碍刷写。
CAKE 固定使用最后一版旧 qdisc API 基线 `15f1f6c`，因为当前 `master` 已依赖新版
`tcf_block`/extack API，不适合直接安装到 Linux 4.9。

## 使用

把本仓库推送到自己的 GitHub 仓库，打开 **Actions -> Build OnePlus 6/6T Lineage 4.9 AK3**。
默认使用 `main`、`gki-android13-5.10` 和 `master`，也可以手动填写分支、tag 或 commit。

构建使用最大 2 GiB 的 `ccache`。首次运行会建立缓存，后续只重新编译源码或参数发生
变化的对象。定时运行还会比较 kernel 基线、builder、补丁、ReSukiSU、SUSFS、BBG、
WildKernels patches、CAKE 和 AnyKernel3 的实际 commit；全部未变化时直接跳过。手动运行时选择 `force_rebuild`
可以忽略该标记并强制重编译。

Clang LTO 未默认启用。本 4.9 树的实现要求目标架构 GNU gold + LLVMgold；Ubuntu
默认的 x86 gold 无法链接 AArch64 对象。保持 GCC 构建可复现，待提供经过验证的
AArch64 gold/Android clang 工具链后再单独启用。

每次实际构建还会上传 `device-tests/` artifact，其中包含静态 AArch64 的
`susfs_syscall_test`、设备执行脚本和说明。它覆盖 SUS_PATH 的 syscall regression
以及 SUS_MOUNT 的 mountinfo/fdinfo 检查，可在设备上以对应的 SUSFS 身份运行。

`kernel_base` 必须与补丁生成时的 kernel 基线一致。升级 kernel 基线时，应重新生成
`kernel-4.9-adaptation.patch` 并同步更新配置中的提交号。

不要把本仓库的 workflow 或补丁复制回 kernel 源码仓库。
