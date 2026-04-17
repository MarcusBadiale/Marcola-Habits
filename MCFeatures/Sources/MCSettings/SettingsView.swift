import SwiftUI

public struct SettingsView: View {
    public init() {}

    public var body: some View {
        ContentUnavailableView(
            "Configurações",
            systemImage: "gearshape.fill",
            description: Text("Em breve")
        )
        .navigationTitle("Settings")
    }
}
