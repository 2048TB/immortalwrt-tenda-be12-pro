# Tenda BE12 Pro ImmortalWrt 自动编译

本仓库用于构建 `chasey-dev/immortalwrt-mt798x-rebase` 的 Tenda BE12 Pro 固件（`25.12-dev-wifi7` 分支，Wi-Fi 7 / MT7992）。

## 当前构建方案

- 编译入口：单 `diy.sh`（`pre|feeds|post` 三阶段）
- CI 工作流：单 `.github/workflows/openwrt-builder.yml`
- 目标设备：`CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_tenda_be12-pro`
  - SoC：MediaTek MT7987A (Filogic)
  - Wi-Fi 7 芯片：MT7992（联发科闭源 `mt_wifi7` 驱动栈）
  - 2.5G PHY：Airoha EN8811H（设备定义已含 `kmod-phy-airoha-en8811h` + `airoha-en8811h-firmware`）
- 默认管理地址：`192.168.3.1`
- 默认软件：`luci` + 中文语言包 + `luci-theme-argon`
- 代理：**PassWall2**（`openwrt-passwall2` + `openwrt-passwall-packages` feed，Xray 内核）

## 配置组织方式（重要）

本仓库的 `.config` **不是**完整配置，而是叠加在上游官方 Wi-Fi 7 defconfig 之上的**增量**：

```
上游 defconfig/low-mem-512m/mt7987-mt7992-be7200.config   ← 基底（去掉 Routerich 设备）
                        +
                    本仓库 .config                          ← 增量（LuCI/中文/PassWall2）
                        =
                  最终 openwrt/.config
```

合成由 `diy.sh post` 完成。**为什么必须用这个基底**：上游给 hostapd 打了 MTK 的
MLO 补丁（`975-mtk-mlo-pass-pmksa-link-address.patch` 等），这些补丁引用
`sta_info` 里被 `#ifdef CONFIG_IEEE80211BE` 包住的成员。只有启用完整的
`mt_wifi7` 驱动栈才会 `select DRIVER_11BE_SUPPORT` → 传 `CONFIG_IEEE80211BE=y`
给 hostapd，否则 hostapd 编译必然失败。基底同时带来 MT7992 双频 l1profile、
warp/hwifi、turboacc、eqos 等一整套配置。

## 与 AX6000 参考项目的差异

| 项 | Redmi AX6000 (参考) | 本仓库 (BE12 Pro) |
|---|---|---|
| 上游仓库/分支 | `hanwckf/immortalwrt-mt798x` @ `openwrt-21.02` | `chasey-dev/immortalwrt-mt798x-rebase` @ `25.12-dev-wifi7` |
| SoC / 芯片 | MT7986 | MT7987A |
| Wi-Fi 驱动 | 闭源 `mt_wifi` | 闭源 `mt_wifi7`（MT7992，Wi-Fi 7 / 802.11be） |
| 配置方式 | 完整 `.config` | 上游 defconfig **+ 增量** |
| PassWall2 | 已启用（官方 feed + 自配 golang） | **已启用**（官方 feed，`main` 分支，无需自配 golang） |
| golang | 需 pin `sbwml` 的 26.x feed | 直接用 packages 内置的 **golang 1.26**（xray-core 正好要 go 1.26） |
| factory.bin | 有 | **无**（该设备仅出 `sysupgrade` 与 `initramfs-kernel`） |

## 固件产物

Release 默认上传：

- `*sysupgrade.bin`
- `*initramfs-kernel.bin`

## 使用

1. 用本仓库在 GitHub 上创建新仓库（或直接 clone 后推送）。
2. 进入 Actions → 手动触发 `workflow_dispatch`，或等待每周一的定时构建。
3. 构建产物以 Release 形式自动发布。
