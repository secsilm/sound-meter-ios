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
