import MCDesignSystem
import MCShared
import SwiftUI

struct SettingsView: View {

    @Provider var provider = SettingsProvider()

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                account
                dataSection
                habitsSection
                appearanceSection
                aboutSection
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Settings")
    }

    // MARK: - Conta

    private var account: some View {
        AccountCard(
            name: provider.accountName,
            detail: provider.accountDetail,
            actionTitle: provider.accountActionTitle,
            isBusy: provider.isAuthenticating,
            action: { provider.toggleAccount() }
        )
    }

    // MARK: - Seções

    private var dataSection: some View {
        SettingsSection(header: "Data", identifier: "settings-section-data") {
            SettingsRow(
                icon: "arrow.triangle.2.circlepath",
                tint: Color(hex: "#34C759"),
                label: "Sync now",
                detail: provider.syncDetail,
                isBusy: provider.isSyncing,
                showsChevron: false,
                // Sem `isEnabled: !isSyncing`: a dedução de chamada dupla mora no serviço, e
                // atenuar a row no meio do sync faria ela piscar.
                identifier: "settings-sync-row",
                action: { provider.syncNow() }
            )
            SettingsRow(
                icon: "square.and.arrow.up",
                tint: Color(hex: "#007AFF"),
                label: "Export data",
                identifier: "settings-export-row",
                action: { provider.goToExport() }
            )
            SettingsRow(
                icon: "archivebox",
                tint: Color(hex: "#8E8E93"),
                label: "Archived habits",
                detail: provider.archivedDetail,
                isLast: true,
                identifier: "settings-archived-row",
                action: { provider.goToArchived() }
            )
        }
    }

    private var habitsSection: some View {
        SettingsSection(header: "Habits", identifier: "settings-section-habits") {
            SettingsRow(
                icon: "bell.badge",
                tint: Color(hex: "#FF3B30"),
                label: "Notifications",
                detail: "Coming soon",
                isEnabled: false,
                isLast: true,
                identifier: "settings-notifications-row"
            )
        }
    }

    private var appearanceSection: some View {
        SettingsSection(header: "Appearance", identifier: "settings-section-appearance") {
            SettingsRow(
                icon: "circle.lefthalf.filled",
                tint: Color(hex: "#3A3A3C"),
                label: "Theme",
                detail: provider.themeDetail,
                identifier: "settings-theme-row",
                action: { provider.goToAppearance() }
            )
            SettingsRow(
                icon: "paintpalette",
                tint: Color.accentColor,
                label: "App color",
                isLast: true,
                identifier: "settings-accent-row",
                action: { provider.goToAppearance() }
            )
        }
    }

    private var aboutSection: some View {
        SettingsSection(header: "About", identifier: "settings-section-about") {
            SettingsRow(
                icon: "info.circle",
                tint: Color(hex: "#5856D6"),
                label: "Version",
                detail: provider.appVersionDetail,
                showsChevron: false,
                identifier: "settings-version-row"
            )
            SettingsRow(
                icon: "star",
                tint: Color(hex: "#FF9500"),
                label: "Rate on the App Store",
                detail: "Coming soon",
                isEnabled: false,
                isLast: true,
                identifier: "settings-rate-row"
            )
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewContainer.make())
}
