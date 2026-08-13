import MCDesignSystem
import SwiftUI

/// Linha de Settings: bolha de ícone colorida, label, detail opcional e chevron.
///
/// View dumb com params primitivos, no mesmo espírito dos componentes do MCDesignSystem — mas
/// mora aqui porque só o MCSettings usa (design-system.md: só sobe quando 2+ features usarem).
struct SettingsRow: View {

    let icon: String
    let tint: Color
    let label: String
    var detail: String? = nil
    /// Trocado pelo chevron quando a linha está ocupada (ex: sync em voo).
    var isBusy: Bool = false
    var showsChevron: Bool = true
    /// Row de "Coming soon": visível, atenuada e sem navegação — mas com identifier, pro UI test
    /// conseguir assertar que ela existe e não leva a lugar nenhum.
    var isEnabled: Bool = true
    var isLast: Bool = false
    let identifier: String
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if isEnabled, let action {
                Button(action: action) { content }
                    .buttonStyle(.plain)
            } else {
                // Sem ação (ex: "Version") a row fica normal, só não é tocável. Atenuada é só
                // quando está de fato desabilitada — "Coming soon".
                // `.combine` porque sem isso a row vira 4 elementos soltos (bolha, label, detail,
                // chevron) e o identifier não resolve pra nada no XCUITest — a versão com Button
                // já é um elemento único de graça.
                content
                    .opacity(isEnabled ? 1 : 0.45)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
            }
        }
        .accessibilityIdentifier(identifier)
    }

    private var content: some View {
        HStack(spacing: MCSpacing.md) {
            iconBubble

            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.primary)

            Spacer(minLength: MCSpacing.sm)

            if let detail {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            accessory
        }
        .padding(.vertical, MCSpacing.md)
        .padding(.horizontal, MCSpacing.lg)
        .contentShape(.rect)
        .overlay(alignment: .bottomLeading) {
            if !isLast {
                Divider().padding(.leading, 58)
            }
        }
    }

    private var iconBubble: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(tint)
            .frame(width: 30, height: 30)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder
    private var accessory: some View {
        if isBusy {
            ProgressView().controlSize(.small)
        } else if showsChevron {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingsRow(
            icon: "arrow.triangle.2.circlepath", tint: .green, label: "Sync now",
            detail: "2 hours ago", showsChevron: false, identifier: "p1", action: {}
        )
        SettingsRow(
            icon: "square.and.arrow.up", tint: .blue, label: "Export data",
            identifier: "p2", action: {}
        )
        SettingsRow(
            icon: "bell.badge", tint: .red, label: "Notifications",
            detail: "Coming soon", isEnabled: false, isLast: true, identifier: "p3"
        )
    }
    .background(MCColors.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .padding()
}
