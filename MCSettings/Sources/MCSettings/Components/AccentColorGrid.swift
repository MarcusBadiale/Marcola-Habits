import MCDesignSystem
import SwiftUI

/// Grade de bolinhas pra escolher o accent do app.
///
/// Recebe `selectedHex: String` em vez de uma closure `isSelected` — componente dumb de verdade,
/// e evita chamar função do provider (que o `@Mockable` marca como `mutating`) de dentro de uma
/// avaliação de `body`.
struct AccentColorGrid: View {

    let hexes: [String]
    let selectedHex: String
    let onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: MCSpacing.md), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: MCSpacing.lg) {
            ForEach(Array(hexes.enumerated()), id: \.element) { index, hex in
                Button { onSelect(hex) } label: {
                    swatch(hex: hex, isSelected: isSelected(hex))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hex)
                .accessibilityIdentifier("settings-appearance-accent-\(index)")
            }
        }
    }

    private func isSelected(_ hex: String) -> Bool {
        selectedHex.caseInsensitiveCompare(hex) == .orderedSame
    }

    private func swatch(hex: String, isSelected: Bool) -> some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 36, height: 36)
            .overlay {
                Circle()
                    .strokeBorder(Color.primary.opacity(isSelected ? 0.85 : 0), lineWidth: 3)
                    .padding(-4)
            }
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(4)
    }
}

#Preview {
    AccentColorGrid(
        hexes: ["#3B82F6", "#007AFF", "#EF4444", "#F59E0B", "#22C55E", "#14B8A6", "#A855F7", "#EC4899"],
        selectedHex: "#22C55E",
        onSelect: { _ in }
    )
    .padding()
}
