import SwiftUI



struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $settings.isDarkMode)
                }
                
                Section("Units") {
                    Toggle("Use Metric System (kg/cm)", isOn: $settings.useMetricSystem)
                    if !settings.useMetricSystem {
                        Text("Using Imperial System (lb/in)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                }
                
                Section("Data Management") {
                    Button {
                        // In a real app, this would trigger a share sheet with all data
                        // For now, we can show an alert or just a placeholder action
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        // Placeholder for delete all action
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
