# Sound Meter iOS

一个 iOS 噪声等级（分贝）持续测量应用，原生面向 iOS 26：

- 实时分贝采样，采样间隔可在 0.1 – 5.0 秒之间配置。
- 锁屏 / 后台持续记录（开启了 `UIBackgroundModes -> audio`）。
- 时序数据可导出为 CSV，通过 `ShareLink` 分享给"文件"、邮件等。
- 可选同时录制原始音频（默认关闭），导出时可勾选一并附带 m4a。
- 自动处理 `AVAudioSession` 中断（通话）与音频路由变更（耳机插拔）。
- UI 全面使用 iOS 26 Liquid Glass（`glassEffect`）；在更早系统上自动降级为半透明 Material。

## 目录结构

```
SoundMeterIOS.xcodeproj/             # Xcode 工程
SoundMeterIOS/
├─ App/SoundMeterApp.swift           # @main 入口
├─ Core/
│  ├─ AudioMonitorService.swift      # AVAudioSession + AVAudioRecorder 采样，含中断处理
│  ├─ CSVExporter.swift              # 时序数据写 CSV
│  ├─ NoiseSample.swift              # 单次采样模型
│  └─ RecordingSession.swift         # 会话模型
├─ Features/Monitor/
│  ├─ MonitorView.swift              # iOS 26 Liquid Glass 界面
│  └─ MonitorViewModel.swift         # 状态 + 导出流程
└─ Resources/
   ├─ Info.plist                     # 含 NSMicrophoneUsageDescription / UIBackgroundModes
   └─ Assets.xcassets                # AppIcon / AccentColor
```

## 平台

- 部署目标：**iOS 26.0**
- Xcode：需要支持 iOS 26 SDK 的版本（Xcode 17+）
- Swift：5.0 编译器即可

## 安装到 iPhone

1. macOS + Xcode 17（含 iOS 26 SDK）。
2. 打开 `SoundMeterIOS.xcodeproj`。
3. 选中 App Target → `Signing & Capabilities`：
   - 勾选 `Automatically manage signing`，选自己的 Team。
   - 若 `Bundle Identifier` 冲突，改成你自己的（如 `com.yourname.soundmeter`）。
4. 连接 iPhone，运行目标选你的设备（非模拟器；模拟器无麦克风）。
5. 首次安装后：`设置 → 通用 → VPN 与设备管理`，信任开发者证书。
6. 首次启动时同意麦克风权限。

> 工程已预置 `Background Modes → Audio`，锁屏后采样会继续。

## 使用

1. 在主界面调整"采样间隔"。
2. 如果需要保留原始音频，打开"同时录制原始音频"；如果还需要在导出 CSV 时一并附带 m4a，再打开"导出时附带音频文件"。
3. 点击底部"开始"开始记录；锁屏 / 切到后台都不影响。
4. 点击"停止"后，点击"生成导出"，下方会出现"分享 / 保存"按钮，弹出系统分享面板。

## 关于 dB 数值

`AVAudioRecorder.averagePower(forChannel:)` 返回的是 dBFS（峰值满刻度的相对值），范围约 `-160…0`。这里以 `clamp(-80, 0) + 100` 做粗略映射，得到一个 `20–100` 区间的"主观分贝"。**不是经过校准的 SPL 值**，仅作相对比较；如需 SPL 精度，请用外置校准声压计配合校准曲线。

## 已知限制 / 下一步

- 会话不会本地持久化，App 重启即清空（CSV/音频文件仍在沙盒 Documents 中）。
- 没有历史会话列表 UI。
- 没有 A/C 计权（A-weighting）或时间常数（Fast/Slow）切换。
- AppIcon 是空占位，需要时自行替换。
