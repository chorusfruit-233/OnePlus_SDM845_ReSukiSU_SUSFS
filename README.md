<div align="center">

# OnePlus 6/6T ReSukiSU + SUSFS

基于 LineageOS Linux 4.9.337 的可复现 AnyKernel3 自动构建项目

[![Build AK3](https://github.com/chorusfruit-233/OnePlus_SDM845_ReSukiSU_SUSFS/actions/workflows/build-ak3.yml/badge.svg)](https://github.com/chorusfruit-233/OnePlus_SDM845_ReSukiSU_SUSFS/actions/workflows/build-ak3.yml)
[![Kernel](https://img.shields.io/badge/kernel-4.9.337-informational)](https://github.com/LineageOS/android_kernel_oneplus_sdm845)
[![ReSukiSU](https://img.shields.io/badge/ReSukiSU-integrated-success)](https://github.com/ReSukiSU/ReSukiSU)
[![SUSFS](https://img.shields.io/badge/SUSFS-4.9_backport-orange)](https://gitlab.com/simonpunk/susfs4ksu)
[![Devices](https://img.shields.io/badge/devices-OnePlus_6%20%7C%206T-blue)](#兼容性)

</div>

本仓库不是 kernel 源码仓库，而是一套独立的拉取、移植、编译、验证和打包流程。
每次有效构建都会从固定的 LineageOS 4.9 最新基线开始，动态解析各上游项目的实际提交，
应用本仓库维护的 4.9 适配补丁，最终输出可刷入的 AnyKernel3 ZIP。

> [!WARNING]
> 刷写自定义内核存在无法开机、数据损坏或需要恢复原厂 `boot` 的风险。请先备份当前
> `boot.img`，确认 bootloader 已解锁并准备好可用的恢复手段。你需要自行承担刷写风险。

## 兼容性

| 项目 | 支持情况 |
| --- | --- |
| 设备 | OnePlus 6 / 6T |
| Codename | `enchilada` / `fajita` |
| AK3 设备名 | `enchilada`、`fajita`、`OnePlus6`、`OnePlus6T` |
| Android | Android 15 |
| Kernel | LineageOS 4.9.337，`lineage-22.2` |
| 架构 | ARM64 |
| 分区 | A/B `boot` 分区 |

构建固定在配置文件记录的 kernel commit（当前为 `228c16bfcd25`）。其他 ROM 即使使用相同设备，也可能因
ramdisk、内核模块或 vendor 接口差异而不兼容。不要在未备份原始 `boot.img` 的情况下
跨 ROM 盲刷。

## 已集成功能

### ReSukiSU 与 SUSFS

- 动态拉取 ReSukiSU `main` 的最新提交；
- 将 SUSFS `gki-android13-5.10` backport 到 Linux 4.9；
- 启用 SUS_PATH、SUS_MOUNT、SUS_KSTAT、SPOOF_UNAME、SUS_MAP、cmdline spoof
  和符号隐藏；
- 将 SUS_PATH 的 namei 状态语义映射到 4.9，并覆盖 open、stat、access、readlink、
  getdents64、unlink、rename、`O_PATH` 与 `O_TRUNC`；
- `CONFIG_KSU_SUSFS_OPEN_REDIRECT` 当前保持关闭，未把尚未完成真机回归的功能伪装成可用。

### 网络与容器

- BBRv1 与 BBRv3，可在运行时保留 BBRv1 作为回退；
- CAKE、FQ、FQ_CODEL 与 PIE qdisc；
- TTL/HL target、IPSet、IPv6 NAT；
- Droidspaces/LXC 所需的 namespaces、cgroups、seccomp、veth、bridge、netfilter、
  overlayfs、TMPFS XATTR/POSIX ACL 等基础配置；
- Actions 会在编译前逐项检查关键 Droidspaces 配置，缺失时直接终止构建。

### 安全与通用优化

- Baseband Guard 通过 Linux 4.9 旧式 LSM/SELinux 路径接入；
- 默认不阻止 boot/recovery 写入，避免干扰正常刷写和救砖流程；
- 可选的 CPUfreq `scaling_min_freq_limit`；
- arm64 copy prefetch、页面与 `struct file` 对齐、VFS cache pressure 调整；
- F2FS urgent GC 间隔和 alarmtimer 精确唤醒窗口优化。

## 获取构建产物

1. 打开 [Actions 页面](https://github.com/chorusfruit-233/OnePlus_SDM845_ReSukiSU_SUSFS/actions/workflows/build-ak3.yml)。
2. 选择最近一次成功且实际执行了 `build` job 的运行。
3. 在页面底部下载 `OnePlus6-6T-lineage-4.9-ak3` artifact。
4. 解压 artifact，核对 `SHA256SUMS` 后再使用其中的 AK3 ZIP。

artifact 包含：

| 文件 | 用途 |
| --- | --- |
| `OnePlus6-6T-ReSukiSU-*-SUSFS-*-AK3.zip` | 可刷入的 AnyKernel3 包 |
| `Image.gz-dtb` | 编译得到的内核镜像 |
| `SHA256SUMS` | AK3 ZIP 的 SHA256 校验值 |
| `build-info.txt` | 本次构建使用的全部上游 commit |
| `device-tests/` | AArch64 SUSFS syscall 真机回归测试 |

> [!NOTE]
> Actions artifact 是一个下载容器。刷入前需要先解压 artifact，再刷其中名称以
> `-AK3.zip` 结尾的文件，不要直接刷 artifact 外层压缩包。

## 刷入

推荐使用支持 AnyKernel3 的内核刷写工具或自定义 recovery：

1. 备份当前可正常启动的 `boot.img`；
2. 确认下载的包与设备、Android 版本和当前 ROM 匹配；
3. 用 `SHA256SUMS` 校验 AK3 ZIP；
4. 刷入 `*-AK3.zip`；
5. 重启后检查内核版本、ReSukiSU 管理器状态和基本网络功能。

出现 bootloop 时，刷回备份的原始 `boot.img`。本项目不会修改 system/vendor 分区，
但这并不能替代可靠的 boot 备份。

## 手动构建

在 Actions 页面选择 **Run workflow**。可用输入如下：

| 输入 | 默认值 | 说明 |
| --- | --- | --- |
| `resukisu_ref` | `main` | ReSukiSU branch、tag 或完整 commit |
| `susfs_ref` | `gki-android13-5.10` | SUSFS branch、tag 或完整 commit |
| `bbg_ref` | `main` | Baseband Guard branch、tag 或完整 commit |
| `kernel_patches_ref` | `main` | WildKernels patches branch、tag 或完整 commit |
| `anykernel_ref` | `master` | AnyKernel3 branch、tag 或完整 commit |
| `force_rebuild` | `false` | 忽略无变化标记并强制完整构建 |

定时任务每天在 `18:17 UTC`（北京时间次日 `02:17`）检查一次上游。workflow 会先将
branch/tag 解析成不可变 commit，再把 kernel 基线、builder、补丁和所有上游 commit
共同组成 build key：

- build key 未变化时，只运行约数秒的解析 job，跳过内核编译；
- 输入变化时恢复最多 2 GiB 的 `ccache`，只重编译受影响对象；
- `force_rebuild=true` 可绕过无变化跳过，但仍会使用编译缓存。

## 构建来源

| 组件 | 上游 | 策略 |
| --- | --- | --- |
| Kernel | [LineageOS/android_kernel_oneplus_sdm845](https://github.com/LineageOS/android_kernel_oneplus_sdm845) | 固定基线 commit |
| ReSukiSU | [ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) | 默认跟踪 `main` |
| SUSFS | [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) | 默认跟踪 `gki-android13-5.10` |
| CAKE | [dtaht/sch_cake](https://github.com/dtaht/sch_cake) | 固定最后一版兼容旧 qdisc API 的基线 |
| BBRv3 patches | [WildKernels/kernel_patches](https://github.com/WildKernels/kernel_patches) | 稀疏拉取 `common/bbrv3` |
| Baseband Guard | [vc-teahouse/Baseband-guard](https://github.com/vc-teahouse/Baseband-guard) | 默认跟踪 `main` |
| AnyKernel3 | [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) | 默认跟踪 `master` |

每次构建的确切版本以 artifact 内的 `build-info.txt` 为准，不应只根据 branch 名推断。

## 真机回归测试

`device-tests/` 中包含静态链接的 ARM64 测试程序和执行脚本。推送到已 root 的设备：

```sh
adb push device-tests/susfs_syscall_test /data/local/tmp/
adb push device-tests/run-susfs-regression.sh /data/local/tmp/
adb shell su -c 'chmod 0755 /data/local/tmp/susfs_syscall_test /data/local/tmp/run-susfs-regression.sh'
adb shell su -c '/data/local/tmp/run-susfs-regression.sh'
```

需要验证已标记的 SUS_PATH 时，在对应 SUSFS 隐藏身份/namespace 中运行：

```sh
adb shell su -c '/data/local/tmp/run-susfs-regression.sh \
  /data/local/tmp/susfs_syscall_test --hidden /path/to/marked-entry'
```

测试覆盖 `stat/open/access/readlink/getdents64/unlink/rename/O_PATH/O_TRUNC`，以及
SUS_MOUNT 的 `/proc/self/mountinfo` 和 fdinfo。完整参数见
[`tests/device/README.md`](tests/device/README.md)。

## 已知限制

- LTO 未启用。该 4.9 树需要可用的 AArch64 GNU gold/LLVMgold 组合；GitHub runner
  默认的主机 gold 不能链接 AArch64 kernel；
- BBRv3 的 ECN-low、PLB 和逐丢包回调依赖较新的 TCP/route ABI，本 backport 不提供；
- CAKE 固定在 `15f1f6c` 兼容基线，当前 upstream `master` 依赖新版 `tcf_block` 和
  extack API，不能直接放入 4.9；
- 编译成功不等于所有 ROM 上均已完成启动、基带、网络和容器稳定性验证；
- `kernel_base` 变化后必须重新生成并验证 `kernel-4.9-adaptation.patch`，不能只修改
  配置中的 commit 绕过基线检查。

## 仓库结构

```text
.github/workflows/   GitHub Actions 构建流程
ak3/                 OnePlus 6/6T AnyKernel3 模板
configs/             设备、kernel 和上游配置
patches/lineage-4.9/ Linux 4.9 主补丁及 SUSFS/CAKE/BBRv3 适配
scripts/             动态拉取上游与 AK3 打包脚本
tests/device/        SUSFS 设备端 syscall 回归测试
```

这个边界是有意保留的：kernel 源码负责内核实现，本仓库负责可复现构建、动态上游追踪
和产物发布。不要把 workflow、构建缓存或外部源码 checkout 复制回 kernel 仓库。

## 问题反馈

提交 issue 时请至少附上：

- 设备型号与 codename；
- ROM 名称、Android 版本和构建日期；
- Actions run 链接及 artifact 中的 `build-info.txt`；
- 刷写方式、是否能进入 fastboot/recovery；
- `dmesg`、`logcat` 或明确的复现步骤。

只有“无法启动”而没有 ROM、构建 commit 和日志的信息，通常不足以定位 4.9 backport
或 ramdisk 兼容问题。

## 致谢

- [ReSukiSU Team](https://github.com/ReSukiSU/ReSukiSU)
- [simonpunk / SUSFS](https://gitlab.com/simonpunk/susfs4ksu)
- [LineageOS](https://github.com/LineageOS)
- [WildKernels](https://github.com/WildKernels)
- [vc-teahouse / Baseband Guard](https://github.com/vc-teahouse/Baseband-guard)
- [dtaht / sch_cake](https://github.com/dtaht/sch_cake)
- [osm0sis / AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [ravindu644 / Droidspaces](https://github.com/ravindu644/Droidspaces-OSS)
- [huangdihd / OnePlus_ReSukiSU_SUSFS](https://github.com/huangdihd/OnePlus_ReSukiSU_SUSFS)
