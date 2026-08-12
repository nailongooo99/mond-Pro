# mond Pro

<p align="center">
  <img src="https://github.com/nailongooo99/mond-Pro/blob/main/mond.png?raw=true" alt="mond Pro" height="140">
</p>

<p align="center"><strong>MobileGestalt customization and Dynamic Island canvas tools for iOS 27.0 beta 1–4.</strong></p>

<p align="center">
  <a href="https://github.com/nailongooo99/mond-Pro/actions"><img src="https://img.shields.io/github/actions/workflow/status/nailongooo99/mond-Pro/ios-release.yml?label=iOS%20build" alt="iOS build"></a>
  <a href="https://github.com/nailongooo99/mond-Pro/releases"><img src="https://img.shields.io/github/v/release/nailongooo99/mond-Pro?display_name=tag" alt="Release"></a>
</p>

> [!WARNING]
> **Use at your own risk.** These tweaks modify protected iOS configuration. Incorrect values or unsupported firmware may cause instability, feature loss, boot loops, or require a recovery/restore. Back up your device first and never reboot while MobileGestalt warnings are present.

## 中文说明

mond Pro 是一个面向 iOS 27.0 beta 1–4 的 MobileGestalt 修改工具，并提供可选的灵动岛显示画布 / 状态栏修复。

### 主要功能

- 修改灵动岛、全天候显示、充电上限、开机提示音等 MobileGestalt 项。
- 支持设备外观子类型选择、设备名称自定义和部分设备能力伪装。
- 为兼容设备提供可选的 `IOMobileGraphicsFamily.plist` 画布修复。
- 支持画布配置备份与恢复。
- 内置利用方法选择、沙盒令牌管理、运行日志和 SpringBoard 重载。
- 已完成简体中文界面适配。

### 灵动岛画布修复

灵动岛外观与显示画布是两套独立配置。仅修改 `ArtworkDeviceSubType` 可能只会改变灵动岛位置，不会同步改变屏幕画布和状态栏布局。

启用“灵动岛状态栏 / 画布修复”后，工具会根据所选子类型写入 `canvas_width` 和 `canvas_height`。当前配置包括：

| 设备子类型 | 画布尺寸 |
| --- | ---: |
| iPhone 14 Pro (`2556`) | `1179 × 2556` |
| iPhone 14 Pro Max (`2796`) | `1290 × 2796` |
| iPhone 16 Pro (`2622`) | `1206 × 2622` |
| iPhone 16 Pro Max (`2868`) | `1320 × 2868` |
| iPhone Air (`2736`) | `1260 × 2736` |

`2436` 保留给“关闭灵动岛”和“iPhone X 手势”，不作为 iPhone 14 Pro 的画布值。修改画布前会尝试保存 `SavedCanvas.plist` 备份；关闭选项或执行恢复操作时，会尝试恢复备份。更改后可能需要重启设备。

### 已知问题

- 部分修改可能在重启后消失。
- Apple Intelligence 目前可能无法正常启用。
- “解除地区限制”在部分系统版本或设备上可能无效。
- iPadOS 界面及相关修改可能无效，并可能导致启动循环或恢复模式。
- 画布 plist 的路径、权限和系统行为会随 iOS beta 版本变化；如果画布修复失败，工具会记录日志，并尽量不阻断其他 MobileGestalt 修改。
- 本项目不保证兼容正式版 iOS 或未列出的 beta 版本。

### 使用建议

1. 先备份设备，并确保设备可以通过电脑或恢复模式修复。
2. 先运行利用方法并确认日志显示访问成功。
3. 一次只启用少量修改，应用后先观察设备状态。
4. 选用灵动岛子类型时，如需同步状态栏和画布，请同时开启画布修复。
5. 如果出现 MobileGestalt 警告，不要重启；先使用“恢复修改”并查看日志。

### 从源码构建

本项目需要 macOS、Xcode 和 iOS SDK。Windows 环境不能直接运行 `xcodebuild`。

```bash
xcodebuild \
  -project mond.xcodeproj \
  -scheme mond \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

仓库中的 GitHub Actions 工作流会在 macOS runner 上构建未签名 `.app`，并将其打包为 `mond.ipa`，同时尝试更新 `latest` Release。未签名 IPA 不能直接作为已签名 App 安装；实际安装仍需要合适的签名、侧载或设备环境。

### 兼容性

- 目标系统：iOS 27.0 beta 1–4。
- 最低工程部署版本：iOS 17.0。
- 实际可用性取决于设备型号、系统 beta 版本、利用方法和系统路径权限。

## English

mond Pro is a MobileGestalt customization tool for iOS 27.0 beta 1–4 with an optional Dynamic Island display-canvas and status-bar correction.

### Features

- Toggle Dynamic Island, Always-On Display, charge limit, boot chime and other MobileGestalt features.
- Select an artwork subtype, set a custom device name, and spoof selected device capabilities.
- Optionally update `IOMobileGraphicsFamily.plist` with the canvas size matching the selected Dynamic Island profile.
- Back up and restore the canvas plist when the system permits access.
- Includes exploit-method selection, sandbox-token management, runtime logs and SpringBoard respring.
- Includes Simplified Chinese localization.

### Dynamic Island canvas fix

Dynamic Island artwork and display geometry are separate settings. Changing only `ArtworkDeviceSubType` may move or enable the island without changing the native display canvas or status-bar layout.

When “Dynamic Island Status Bar / Canvas Fix” is enabled, mond Pro writes `canvas_width` and `canvas_height` for the selected subtype:

| Profile | Canvas |
| --- | ---: |
| iPhone 14 Pro (`2556`) | `1179 × 2556` |
| iPhone 14 Pro Max (`2796`) | `1290 × 2796` |
| iPhone 16 Pro (`2622`) | `1206 × 2622` |
| iPhone 16 Pro Max (`2868`) | `1320 × 2868` |
| iPhone Air (`2736`) | `1260 × 2736` |

`2436` remains reserved for “Disable Dynamic Island” and “iPhone X Gestures”; it is not used for the iPhone 14 Pro profile. The app attempts to create `SavedCanvas.plist` before the first canvas change and restore it when requested. A reboot may be required.

### Known issues

- Some tweaks may disappear after reboot.
- Apple Intelligence activation may not work.
- Disable Region Restrictions may be ineffective on some versions or devices.
- The iPadOS UI and related tweaks may fail, cause a boot loop, or enter recovery mode.
- The canvas plist path, permissions and behavior can change between iOS beta builds. If the canvas fix fails, mond Pro logs the error and attempts not to block the other MobileGestalt changes.
- Compatibility with public releases or beta versions outside the listed range is not guaranteed.

### Safety recommendations

1. Back up your device and make sure you have a recovery path before applying tweaks.
2. Run the exploit method and confirm successful access in the log.
3. Apply only a few changes at a time and observe the device after each respring.
4. Enable the canvas fix together with the Dynamic Island subtype when matching geometry is required.
5. If MobileGestalt warnings appear, do not reboot. Revert the changes first and inspect the logs.

### Build from source

Building requires macOS, Xcode and the iOS SDK. `xcodebuild` cannot run natively on Windows.

```bash
xcodebuild \
  -project mond.xcodeproj \
  -scheme mond \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

The repository workflow builds an unsigned `.app` on a macOS runner, packages it as `mond.ipa`, and attempts to update the `latest` Release. An unsigned IPA is not an install-ready signed app; installation still requires an appropriate signing, sideloading or device environment.

### Compatibility

- Target OS: iOS 27.0 beta 1–4.
- Project deployment target: iOS 17.0.
- Actual behavior depends on the device model, beta build, exploit method and system path permissions.

## Credits / 致谢

- [forcequit](https://github.com/forcequitOS) — `bad_query` exploit / bad_query 利用程序
- [johnny](https://github.com/0xjohnnydev) — MCM bug class research / MCM 错误类别相关工作
- [jailbreak.party](https://github.com/jailbreakdotparty) — PartyUI, GestaltView and respring implementation / PartyUI、GestaltView 及重载 SpringBoard 实现
- [nailongooo99](https://github.com/nailongooo99) — Simplified Chinese localization support / 提供简体中文汉化支持

## License / 许可证

Please review the upstream project and included source files for their applicable licenses. Components and exploit code may have separate copyright and usage conditions. Use this project only on devices you own or are authorized to modify.
