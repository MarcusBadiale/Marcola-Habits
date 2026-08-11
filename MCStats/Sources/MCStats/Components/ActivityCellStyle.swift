import MCDesignSystem
import MCDomain
import SwiftUI

/// Aparência de uma célula da matriz de atividade. Compartilhado pela tira (tela agregada) e pela
/// grade calendário (tela de detalhe), pra as duas lerem igual.
enum ActivityCellStyle {

    static let cornerRadius: CGFloat = 2

    /// Preenchimento da célula. `.clear` no `notScheduled` — ela é desenhada só com borda.
    static func fill(for state: ActivityState, tint: Color) -> Color {
        switch state {
        case .completed:
            return tint
        case .missed:
            return tint.opacity(0.12)
        case .notScheduled:
            return .clear
        }
    }

    /// Borda vazada só nos dias sem obrigação — é o que os distingue de "tinha e não fez".
    static func stroke(for state: ActivityState) -> Color {
        state == .notScheduled ? Color.secondary.opacity(0.25) : .clear
    }

    static func accessibilityLabel(for day: DayActivityDTO) -> String {
        let date = day.date.formatted(.dateTime.day().month(.abbreviated))
        switch day.state {
        case .completed:
            return "\(date): done"
        case .missed:
            return "\(date): missed"
        case .notScheduled:
            return "\(date): not scheduled"
        }
    }
}

/// Uma célula. Não define tamanho — quem posiciona (tira ou grade) é que dá o frame.
struct ActivityCell: View {
    let day: DayActivityDTO
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: ActivityCellStyle.cornerRadius, style: .continuous)
            .fill(ActivityCellStyle.fill(for: day.state, tint: tint))
            .overlay {
                RoundedRectangle(cornerRadius: ActivityCellStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActivityCellStyle.stroke(for: day.state), lineWidth: 0.5)
            }
            .accessibilityLabel(ActivityCellStyle.accessibilityLabel(for: day))
    }
}

#Preview {
    HStack(spacing: MCSpacing.sm) {
        ForEach([ActivityState.completed, .missed, .notScheduled], id: \.self) { state in
            VStack(spacing: MCSpacing.xs) {
                ActivityCell(day: DayActivityDTO(date: .now, state: state), tint: MCColors.success)
                    .frame(width: 28, height: 28)
                Text(state.rawValue)
                    .font(MCTypography.captionSecondary)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}
