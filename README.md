# Sound Meter iOS

一个用于 iOS 的持续噪声测量（分贝）应用骨架，支持：

- 实时采样噪声分贝，采样间隔可配。
- 锁屏记录（需在 Xcode 中开启 Background Modes / audio）。
- 导出时序数据为 CSV。
- 可选同时录制音频（默认关闭）。
- 导出 CSV 时可选择是否一并导出原始音频文件。

## 目录结构

- `SoundMeterIOS/App`: App 入口
- `SoundMeterIOS/Core`: 采样、会话模型、CSV 导出
- `SoundMeterIOS/Features/Monitor`: 主界面和状态管理

## 平台与权限

1. `Info.plist` 需要包含：
   - `NSMicrophoneUsageDescription`
2. `Signing & Capabilities` 需要开启：
   - `Background Modes` -> `Audio, AirPlay, and Picture in Picture`

## 下一步建议

- 增加 `ShareLink` / `UIActivityViewController` 用于导出分享。
- 增加历史会话列表和本地持久化。
- 在锁屏/后台场景增加状态提示与恢复逻辑。


## 安装到 iPhone（真机）

可通过 Xcode 直接安装到 iPhone（适合开发与测试）：

1. **准备环境**
   - macOS + 最新 Xcode。
   - 一台 iPhone 与数据线（或已配置无线调试）。
   - Apple ID（免费开发者账号即可进行个人设备调试安装）。

2. **打开工程**
   - 在 Xcode 中打开 `SoundMeterIOS.xcodeproj`（或 `SoundMeterIOS.xcworkspace`，以仓库实际文件为准）。

3. **配置签名（Signing）**
   - 选中 App Target -> `Signing & Capabilities`。
   - 勾选 `Automatically manage signing`。
   - `Team` 选择你的 Apple ID 对应团队。
   - 如提示 `Bundle Identifier` 冲突，修改为你自己的唯一标识（例如 `com.yourname.soundmeter`）。

4. **连接并选择设备**
   - 连接 iPhone，首次连接需要在手机上点击“信任此电脑”。
   - 在 Xcode 顶部运行目标选择你的 iPhone（非模拟器）。

5. **授予开发者信任（首次）**
   - 若安装后无法打开，前往 iPhone：
     `设置 -> 通用 -> VPN与设备管理`（或“设备管理”），
     找到对应开发者证书并点击“信任”。

6. **运行安装**
   - 点击 Xcode 的 `Run`（⌘R）。
   - 首次启动 App 时允许麦克风权限，否则无法进行分贝采样。

7. **后台/锁屏记录验证**
   - 确认工程已开启 `Background Modes -> Audio, AirPlay, and Picture in Picture`。
   - 开始采样后锁屏，观察采样是否持续并可导出 CSV。

> 注意：免费账号签名的应用通常有有效期限制，过期后需要重新通过 Xcode 安装。
