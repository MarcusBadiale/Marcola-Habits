import MCDesignSystem
import MCDomain
import SwiftUI

/// A tira de dias de um hábito, usada na lista da tela agregada.
///
/// As células dividem a largura disponível (`maxWidth: 28` como teto), então 7 dias dão quadrados
/// gordos e 90 dias dão uma textura fina. Como todas as tiras da lista têm a mesma contagem de dias
/// e o mesmo inset, as colunas alinham entre hábitos sem `GeometryReader` e sem scroll horizontal.
struct HabitActivityStrip: View {

    let days: [DayActivityDTO]
    let tint: Color
    let identifierPrefix: String

    private let cellHeight: CGFloat = 14
    private let maxCellWidth: CGFloat = 28

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                ActivityCell(day: day, tint: tint)
                    .frame(maxWidth: maxCellWidth)
                    .frame(height: cellHeight)
                    .accessibilityIdentifier("\(identifierPrefix)-cell-\(index)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifierPrefix)
    }
}

#Preview("7 / 30 / 90 dias") {
    VStack(alignment: .leading, spacing: MCSpacing.lg) {
        ForEach([7, 30, 90], id: \.self) { days in
            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text("\(days) dias")
                    .font(MCTypography.caption)
                    .foregroundStyle(.secondary)
                HabitActivityStrip(
                    days: PreviewActivity.days(count: days),
                    tint: MCColors.success,
                    identifierPrefix: "preview-strip-\(days)"
                )
            }
        }
    }
    .padding()
}
