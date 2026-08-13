import MCDesignSystem
import SwiftUI

/// Card de perfil no topo das Settings.
///
/// Usa `Color.accentColor` e nunca um hex fixo: o accent é escolhido pelo usuário e aplicado pela
/// `ContentView` via `.tint`.
struct AccountCard: View {

    let name: String
    let detail: String
    let actionTitle: String
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: MCSpacing.lg) {
            avatar

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(name)
                    .font(.system(size: 17, weight: .bold))

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: MCSpacing.sm)

            if isBusy {
                ProgressView().controlSize(.small)
            } else {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityIdentifier("settings-account-action")
            }
        }
        .padding(MCSpacing.lg)
        .background(
            MCColors.cardBackground,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        // Sem identifier no HStack de fora: ele propagaria pros descendentes e sobrescreveria o
        // "settings-account-action" do botão. O UI test se ancora no botão, que é único.
    }

    private var avatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 52, height: 52)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    VStack(spacing: MCSpacing.lg) {
        AccountCard(
            name: "Not signed in",
            detail: "Sync your habits across devices",
            actionTitle: "Sign in with Apple",
            isBusy: false,
            action: {}
        )
        AccountCard(
            name: "Marcus",
            detail: "marcus@marcola.app",
            actionTitle: "Sign out",
            isBusy: false,
            action: {}
        )
    }
    .padding()
}
