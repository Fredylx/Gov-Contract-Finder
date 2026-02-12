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
                Section("Feature Flags", content: {
                    Toggle("Enable NAICS Presets", isOn: Binding<Bool>(
                        get: { settings.featureFlags.naicsPresetsEnabled },
                        set: { settings.featureFlags.naicsPresetsEnabled = $0 }
                    ))
                    Toggle("Enable Sort Control", isOn: Binding<Bool>(
                        get: { settings.featureFlags.sortControlEnabled },
                        set: { settings.featureFlags.sortControlEnabled = $0 }
                    ))
                    Toggle("Enable Dark Mode Toggle", isOn: Binding<Bool>(
                        get: { settings.featureFlags.darkModeToggleEnabled },
                        set: { settings.featureFlags.darkModeToggleEnabled = $0 }
                    ))
                })
            })
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    DebugPanelView(settings: DebugSettings.shared)
}
