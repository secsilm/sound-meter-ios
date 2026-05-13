import SwiftUI

struct MonitorView: View {
    @ObservedObject var viewModel: MonitorViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    meterCard
                    settingsCard
                    if !viewModel.exportItems.isEmpty {
                        exportsCard
                    }
                    if let status = viewModel.statusMessage {
                        statusCard(status)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(backgroundGradient)
            .navigationTitle("噪声计")
            .toolbar { bottomBar }
        }
    }

    // MARK: - Cards

    private var meterCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", viewModel.currentDecibel))
                    .font(.system(size: 76, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: viewModel.currentDecibel))
                    .animation(.snappy(duration: 0.25), value: viewModel.currentDecibel)
                Text("dB")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Gauge(value: min(max(viewModel.currentDecibel, 0), 120), in: 0...120) {
                Text("Level")
            } currentValueLabel: {
                Text("\(Int(viewModel.currentDecibel))")
            } minimumValueLabel: {
                Text("0").font(.caption2)
            } maximumValueLabel: {
                Text("120").font(.caption2)
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(meterTint)
            HStack {
                Label("\(viewModel.session.samples.count) 样本", systemImage: "waveform")
                Spacer()
                if viewModel.isRecording {
                    Label("录制中", systemImage: "record.circle.fill")
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse, options: .repeating)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard(shape: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("采样间隔", systemImage: "timer")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.1f s", viewModel.sampleInterval))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.sampleInterval, in: 0.1...5.0, step: 0.1) {
                    Text("采样间隔")
                } minimumValueLabel: {
                    Text("0.1s").font(.caption2)
                } maximumValueLabel: {
                    Text("5s").font(.caption2)
                }
                .disabled(viewModel.isRecording)
            }

            Divider()

            Toggle(isOn: $viewModel.shouldRecordAudio) {
                Label("同时录制原始音频", systemImage: "mic.fill")
            }
            .disabled(viewModel.isRecording)

            Toggle(isOn: $viewModel.includeAudioInExport) {
                Label("导出时附带音频文件", systemImage: "square.and.arrow.up.on.square")
            }
            .disabled(!viewModel.shouldRecordAudio)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var exportsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("导出文件已就绪", systemImage: "doc.on.doc")
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    viewModel.clearExports()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            ForEach(viewModel.exportItems, id: \.self) { url in
                HStack(spacing: 10) {
                    Image(systemName: url.pathExtension == "csv" ? "tablecells" : "waveform")
                        .foregroundStyle(.accent)
                    Text(url.lastPathComponent)
                        .font(.footnote.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
            }
            ShareLink(items: viewModel.exportItems) {
                Label("分享 / 保存", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .glassCard(shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func statusCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.bubble.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
            Spacer()
        }
        .padding(14)
        .glassCard(shape: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var bottomBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                viewModel.toggleRecording()
            } label: {
                Label(viewModel.isRecording ? "停止" : "开始",
                      systemImage: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                    .labelStyle(.titleAndIcon)
            }
            .tint(viewModel.isRecording ? .red : .accentColor)

            Spacer()

            Button {
                viewModel.prepareExport()
            } label: {
                Label("生成导出", systemImage: "doc.badge.plus")
            }
            .disabled(!viewModel.canExport)
        }
    }

    // MARK: - Helpers

    private var meterTint: Color {
        switch viewModel.currentDecibel {
        case ..<60: return .green
        case ..<85: return .yellow
        default: return .red
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Glass card modifier

private struct GlassCardModifier<S: InsettableShape>: ViewModifier {
    let shape: S

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(in: shape)
        } else {
            content
                .background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                .clipShape(shape)
        }
    }
}

private extension View {
    func glassCard<S: InsettableShape>(shape: S) -> some View {
        modifier(GlassCardModifier(shape: shape))
    }
}
