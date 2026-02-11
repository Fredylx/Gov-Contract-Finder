import SwiftUI

struct DebugPanelView: View {
    @Bindable var settings: DebugSettings

    var body: some View {
        NavigationStack {
            Form(content: {
                Section("Logging", content: {
                    Toggle("Enable Debug Logging", isOn: $settings.isEnabled)
                    Text("Logs appear in Xcode Console under subsystem 'Gov-Contract-Finder'.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                })
                Section("API Key", content: {
                    Text((APIKeyProvider.samKey() != nil) ? "SAM API Key: Found" : "SAM API Key: Not found")
                        .foregroundStyle((APIKeyProvider.samKey() != nil) ? .green : .red)
                })
            })
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    DebugPanelView(settings: DebugSettings.shared)
}
