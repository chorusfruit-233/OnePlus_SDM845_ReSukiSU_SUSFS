# OnePlus SDM845 ReSukiSU/SUSFS Builder

这是独立于 kernel 源码的构建仓库。每次 GitHub Actions 运行都会：

1. 拉取固定的 LineageOS 4.9.337 kernel 基线并应用 `patches/lineage-4.9/`；
2. 按 workflow 输入拉取 ReSukiSU、SUSFS 和 AnyKernel3 的最新提交；
3. 构建 `Image.gz-dtb` 并生成可刷入的 AnyKernel3 ZIP；
4. 上传内核、AK3 包、SHA256 校验和及实际提交记录。

当前配置面向 OnePlus 6/6T：`enchilada` / `fajita`，defconfig 为
`enchilada_defconfig`。

第一优先级还包含 Droidspaces/LXC 基础支持。workflow 会检查 namespaces、cgroups、
seccomp、veth/bridge、netfilter、overlayfs 和 tmpfs ACL/XATTR 等选项；目标 4.9 树
使用 `CONFIG_NF_CT_NETLINK` 作为新版文档中的 conntrack-netlink 对应项。

## 使用

把本仓库推送到自己的 GitHub 仓库，打开 **Actions -> Build OnePlus 6/6T Lineage 4.9 AK3**。
默认使用 `main`、`gki-android13-5.10` 和 `master`，也可以手动填写分支、tag 或 commit。

`kernel_base` 必须与补丁生成时的 kernel 基线一致。升级 kernel 基线时，应重新生成
`kernel-4.9-adaptation.patch` 并同步更新配置中的提交号。

不要把本仓库的 workflow 或补丁复制回 kernel 源码仓库。
