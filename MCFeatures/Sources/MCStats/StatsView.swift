import SwiftUI

public struct StatsView: View {
    public init() {}

    public var body: some View {
        ContentUnavailableView(
            "Estatísticas",
            systemImage: "chart.bar.fill",
            description: Text("Em breve")
        )
        .navigationTitle("Stats")
    }
}
