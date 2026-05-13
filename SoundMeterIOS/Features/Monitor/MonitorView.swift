import SwiftUI

struct MonitorView: View {
    @ObservedObject var viewModel: MonitorViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("实时监测") {
                    HStack {
                        Text("当前分贝")
                        Spacer()
                        Text(String(format: "%.1f dB", viewModel.currentDecibel))
                            .font(.title2.monospacedDigit())
                    }

                    Slider(value: $viewModel.sampleInterval, in: 0.1...5.0, step: 0.1)
                    Text("采样间隔：\(String(format: "%.1f", viewModel.sampleInterval)) 秒")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("录制选项") {
                    Toggle("同时录制音频", isOn: $viewModel.shouldRecordAudio)
                    Toggle("导出时包含音频", isOn: $viewModel.includeAudioInExport)
                        .disabled(!viewModel.shouldRecordAudio)
                }

                Section {
                    Button(viewModel.isRecording ? "停止记录" : "开始记录") {
                        viewModel.toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("导出 CSV") {
                        viewModel.exportCSV()
                    }
                    .disabled(viewModel.session.samples.isEmpty)
                }

                if let url = viewModel.exportedCSVURL {
                    Section("导出结果") {
                        Text("CSV: \(url.lastPathComponent)")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("噪声计")
        }
    }
}
