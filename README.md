# mond Pro

<p align="center">
  <img src="https://github.com/nailongooo99/mond-Pro/blob/main/mond.png?raw=true" alt="mond Pro" height="140">
</p>

<p align="center"><strong>面向 iOS 27.0 beta 的 MobileGestalt 汉化、体验优化与系统工具箱。</strong></p>

<p align="center">
  <a href="https://github.com/nailongooo99/mond-Pro/actions"><img src="https://img.shields.io/github/actions/workflow/status/nailongooo99/mond-Pro/ios-release.yml?label=iOS%20build" alt="iOS build"></a>
  <a href="https://github.com/nailongooo99/mond-Pro/releases"><img src="https://img.shields.io/github/v/release/nailongooo99/mond-Pro?display_name=tag" alt="Release"></a>
  <a href="https://github.com/nailongooo99/mond-Pro/blob/main/LICENSE"><img src="https://img.shields.io/badge/platform-iOS%2027-blue" alt="iOS 27"></a>
</p>

> [!WARNING]
> 本工具会修改受保护的 iOS 配置。错误配置可能导致功能异常、启动循环或进入恢复模式。请先备份设备，并确保拥有可用的恢复路径；出现 MobileGestalt 警告时不要重启。

## 项目定位

`mond-Pro` 是 `mond` 的中文化与体验增强版本，保留上游核心能力，同时提供更完整的中文界面、高级字段编辑、备份恢复、画布修复和更清晰的操作提示。

## 主要功能

- MobileGestalt 功能开关与高级字段编辑
- 灵动岛设备外观子类型、设备名称和部分设备能力配置
- 灵动岛状态栏 / 显示画布修复
- MobileGestalt 与画布配置备份、恢复和日志
- 利用方法选择、沙盒授权与 SpringBoard 重载
- PosterBoard 壁纸包导入、在线壁纸库和 Tendies 管理
- Santander 文件管理器：浏览、预览和授权后保存应用容器文件
- 简体中文优先的界面和新增工具说明页

## 新增工具

### 墙纸与 PosterBoard

支持导入 `.tendies` / `.zip` 壁纸包，也可以从在线壁纸库下载。应用壁纸后，根据提示打开 PosterBoard，再从 App 切换器关闭 PosterBoard，使配置重新加载。

建议一次只导入少量壁纸包。PosterBoard 容器路径和权限会随 iOS beta 版本变化，失败时请查看应用日志。

### 文件管理

Santander 用于浏览应用容器中的目录和文件，支持文本、图片、音频和视频预览，并在系统授权成功后保存可编辑文件。文件管理功能依赖利用方法、沙盒权限和设备状态，不保证所有路径都可访问。

## 画布修复

灵动岛外观与显示画布是两套独立配置。仅修改 `ArtworkDeviceSubType` 可能只改变灵动岛位置，不会同步改变屏幕画布和状态栏布局。

当前支持的画布配置：

| 设备子类型 | 画布尺寸 |
| --- | ---: |
| iPhone 14 Pro (`2556`) | `1179 × 2556` |
| iPhone 14 Pro Max (`2796`) | `1290 × 2796` |
| iPhone 16 Pro (`2622`) | `1206 × 2622` |
| iPhone 16 Pro Max (`2868`) | `1320 × 2868` |
| iPhone Air (`2736`) | `1260 × 2736` |

## 构建

需要 macOS、Xcode 和 iOS SDK。Windows 不能直接执行 `xcodebuild`。

```bash
xcodebuild \
  -project mond.xcodeproj \
  -scheme mond \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  build
```

GitHub Actions 会在 macOS runner 上构建未签名 `mond.ipa` 并发布到 [Latest Release](https://github.com/nailongooo99/mond-Pro/releases/latest)。未签名 IPA 不能直接安装，仍需要合适的签名或侧载环境。

## 兼容性

- 目标系统：iOS 27.0 beta 1–4
- 工程最低部署版本：iOS 17.0
- 实际可用性取决于设备型号、系统 beta 版本、利用方法和沙盒路径权限

不保证正式版 iOS、未列出的 beta 版本或 iPadOS 的完整兼容性。

## 安全建议

1. 修改前备份设备和 MobileGestalt 配置。
2. 先运行利用方法，确认日志显示授权成功。
3. 一次只启用少量修改，逐次观察设备状态。
4. 画布修复失败时，先恢复配置并检查日志，不要立即重启。
5. 仅在自己拥有或明确获授权的设备上使用。

## 致谢

感谢 `forcequitOS`、`0xjohnnydev`、`jailbreak.party`、`frs0n` 及 `mond` 上游项目的研究、实现与参考。

## 许可证

请分别查看上游项目、利用代码和依赖组件的许可证与使用条件。
