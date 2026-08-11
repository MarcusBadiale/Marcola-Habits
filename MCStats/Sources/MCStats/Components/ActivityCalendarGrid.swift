import MCDesignSystem
import MCDomain
import SwiftUI

/// Grade calendário de um hábito — 7 linhas (dias da semana) × colunas (semanas), estilo GitHub.
///
/// A tela agregada compara hábitos, então usa a tira (`HabitActivityStrip`). Aqui a pergunta é outra
/// — "quando eu falhei?" — e o calendário responde melhor que uma tira de 90 células.
struct ActivityCalendarGrid: View {

    let days: [DayActivityDTO]
    let tint: Color
    let identifierPrefix: String

    private let spacing: CGFloat = 3
    private let labelWidth: CGFloat = 22

    var body: some View {
        if days.isEmpty {
            Text("No activity yet")
                .font(MCTypography.caption)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: MCSpacing.xs) {
                    weekdayLabels
                    grid
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifierPrefix)
        }
    }

    // MARK: - Pedaços

    private var weekdayLabels: some View {
        VStack(alignment: .trailing, spacing: spacing) {
            ForEach(0..<7, id: \.self) { row in
                Text(labelForRow(row))
                    .font(MCTypography.captionSecondary)
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth, height: cellSize, alignment: .trailing)
            }
        }
    }

    private var grid: some View {
        LazyHGrid(rows: rows, spacing: spacing) {
            // Células em branco pra primeira coluna começar no dia da semana certo.
            ForEach(0..<leadingBlanks, id: \.self) { blank in
                Color.clear
                    .frame(width: cellSize, height: cellSize)
                    .accessibilityHidden(true)
                    .id("blank-\(blank)")
            }

            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                ActivityCell(day: day, tint: tint)
                    .frame(width: cellSize, height: cellSize)
                    .accessibilityIdentifier("\(identifierPrefix)-cell-\(index)")
            }
        }
    }

    // MARK: - Layout

    private var rows: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7)
    }

    /// Quantos dias em branco antes do primeiro dia, pra ele cair na linha do seu dia da semana.
    /// Usa `firstWeekday` do calendário — nada aqui pode assumir domingo como primeiro dia.
    private var leadingBlanks: Int {
        guard let first = days.first?.date else { return 0 }
        let calendar = Calendar.current
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }

    private var weekCount: Int {
        Int(ceil(Double(leadingBlanks + days.count) / 7.0))
    }

    /// Tamanho estático por número de semanas — determinístico, sem `GeometryReader`.
    private var cellSize: CGFloat {
        switch weekCount {
        case ..<6: 28
        case ..<10: 22
        default: 16
        }
    }

    /// Só as linhas 1, 3 e 5 recebem label, igual ao heatmap do GitHub — com as 7 fica poluído.
    private func labelForRow(_ row: Int) -> String {
        guard row % 2 == 1 else { return "" }
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let index = (calendar.firstWeekday - 1 + row) % 7
        return String(symbols[index].prefix(1))
    }
}

#Preview("30 / 90 dias") {
    VStack(alignment: .leading, spacing: MCSpacing.xl) {
        ForEach([30, 90], id: \.self) { days in
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                Text("\(days) dias")
                    .font(MCTypography.caption)
                    .foregroundStyle(.secondary)
                ActivityCalendarGrid(
                    days: PreviewActivity.days(count: days),
                    tint: MCColors.accent,
                    identifierPrefix: "preview-calendar-\(days)"
                )
            }
        }
    }
    .padding()
}
