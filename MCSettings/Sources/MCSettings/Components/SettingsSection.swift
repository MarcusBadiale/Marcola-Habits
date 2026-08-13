import MCDesignSystem
import SwiftUI

/// Card agrupador das rows, com header em caixa alta.
struct SettingsSection<Content: View>: View {

    /// O handoff §4 pede 18pt pra "cards de stats/settings sections", e `MCSpacing` só tem 14
    /// (`cardCornerRadius`). Constante local em vez de token novo no MCCore: só esta feature usa —
    /// quando a segunda precisar, aí sobe.
    private let cornerRadius: CGFloat = 18

    let header: String
    let identifier: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text(header.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
                .padding(.horizontal, MCSpacing.lg)
                // O identifier fica só no header, nunca no VStack de fora: identifier de
                // container propaga pros descendentes e **sobrescreve** o de cada row — o que
                // faria toda linha responder por "settings-section-data" e apagaria os
                // identifiers individuais.
                .accessibilityIdentifier(identifier)

            VStack(spacing: 0) {
                content
            }
            .background(
                MCColors.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        }
    }
}

#Preview {
    ScrollView {
        SettingsSection(header: "Data", identifier: "preview-section") {
            SettingsRow(
                icon: "arrow.triangle.2.circlepath", tint: .green, label: "Sync now",
                detail: "Never synced", identifier: "preview-sync", action: {}
            )
            SettingsRow(
                icon: "archivebox", tint: .gray, label: "Archived habits",
                detail: "2", isLast: true, identifier: "preview-archived", action: {}
            )
        }
        .padding(.horizontal, MCSpacing.lg)
    }
}
