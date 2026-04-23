import SwiftUI

struct SettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Settings",
            systemImage: "gearshape.fill",
            description: Text("Coming soon")
        )
        .navigationTitle("Settings")
    }
}
