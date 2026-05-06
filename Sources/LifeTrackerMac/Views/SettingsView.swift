import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ActivityStore

    var body: some View {
        Form {
            Section("Privacy") {
                LabeledContent("Foreground tracking", value: "App names only")
                LabeledContent("File tracking", value: "Metadata only")
                LabeledContent("Screenshots", value: "Never")
                LabeledContent("File contents", value: "Never")
            }

            Section("Watch Roots") {
                ForEach(store.watchRoots, id: \.path) { root in
                    Text(root.path)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
