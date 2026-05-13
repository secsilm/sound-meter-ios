import SwiftUI

@main
struct SoundMeterApp: App {
    @StateObject private var monitorViewModel = MonitorViewModel()

    var body: some Scene {
        WindowGroup {
            MonitorView(viewModel: monitorViewModel)
        }
    }
}
