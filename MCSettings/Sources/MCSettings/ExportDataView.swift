import MCDesignSystem
import MCShared
import SwiftUI

struct ExportDataView: View {

    @Provider var provider = ExportProvider()

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                contents
                shareButton
                disclaimer

                if let errorMessage = provider.errorMessage {
                    Text(errorMessage)
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.danger)
                        .accessibilityIdentifier("settings-export-error")
                }
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Export data")
        // No `.task` e não no `body`: com 91 dias de histórico o encode é centenas de KB, e
        // refazer isso a cada invalidação seria desperdício visível.
        .task { provider.build() }
    }

    private var contents: some View {
        SettingsSection(header: "Contents", identifier: "settings-export-summary") {
            SettingsRow(
                icon: "square.grid.2x2",
                tint: Color(hex: "#A855F7"),
                label: "Categories",
                detail: "\(provider.categoryCount)",
                showsChevron: false,
                identifier: "settings-export-categories"
            )
            SettingsRow(
                icon: "checklist",
                tint: Color(hex: "#3B82F6"),
                label: "Habits",
                detail: "\(provider.habitCount)",
                showsChevron: false,
                identifier: "settings-export-habits"
            )
            SettingsRow(
                icon: "calendar",
                tint: Color(hex: "#22C55E"),
                label: "Check-ins",
                detail: "\(provider.logCount)",
                showsChevron: false,
                identifier: "settings-export-logs"
            )
            SettingsRow(
                icon: "doc.text",
                tint: Color(hex: "#8E8E93"),
                label: "File size",
                detail: provider.sizeDetail,
                showsChevron: false,
                isLast: true,
                identifier: "settings-export-size"
            )
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let document = provider.document {
            ShareLink(
                item: document,
                preview: SharePreview(
                    HabitExportDocument.fileName,
                    image: Image(systemName: "doc.text")
                )
            ) {
                Label("Export JSON", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("settings-export-share-button")
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, MCSpacing.sm)
        }
    }

    private var disclaimer: some View {
        Text("Backup only — Marcola can't import this file back yet. Until sync arrives, this is the only copy of your data that lives outside the app.")
            .font(MCTypography.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("settings-export-disclaimer")
    }
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
    .modelContainer(PreviewContainer.make())
}
