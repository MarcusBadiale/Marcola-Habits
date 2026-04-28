import SwiftUI

struct StatsView: View {
    var body: some View {
        ContentUnavailableView(
            "Statistics",
            systemImage: "chart.bar.fill",
            description: Text("Coming soon")
        )
        .navigationTitle("Stats")
    }
}
