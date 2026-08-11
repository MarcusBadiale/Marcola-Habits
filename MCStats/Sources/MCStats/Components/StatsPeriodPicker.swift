import MCDesignSystem
import SwiftUI

/// Seletor de período. Recebe o identifier por init porque as duas telas de Stats usam o mesmo
/// componente — sem isso os ids colidiriam nos UI tests.
struct StatsPeriodPicker: View {

    @Binding var period: StatsPeriod
    let identifierPrefix: String

    var body: some View {
        Picker("Period", selection: $period) {
            ForEach(StatsPeriod.allCases) { option in
                Text(option.shortLabel)
                    .accessibilityIdentifier("\(identifierPrefix)-option-\(option.days)")
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("\(identifierPrefix)-picker")
    }
}

#Preview {
    @Previewable @State var period: StatsPeriod = .month

    return VStack {
        StatsPeriodPicker(period: $period, identifierPrefix: "preview")
        Text(period.sectionTitle)
            .font(MCTypography.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
