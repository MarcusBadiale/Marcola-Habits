import MCDesignSystem
import MCSettingsAPI
import MCShared
import SwiftUI

struct AppearanceView: View {

    @Provider var provider = AppearanceProvider()

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                theme
                accent
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Appearance")
    }

    private var theme: some View {
        SettingsSection(header: "Theme", identifier: "settings-appearance-theme") {
            // Bind direto no `$themeRawValue` (Binding<String>) com `.tag(rawValue)`, em vez de
            // construir um Binding<AppTheme> na View — mesma mecânica do `provider.$name` do
            // EditCategorySheet.
            Picker("Theme", selection: provider.$themeRawValue) {
                ForEach(AppTheme.allCases) { option in
                    Text(option.label).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(MCSpacing.lg)
            .accessibilityIdentifier("settings-appearance-theme-picker")
        }
    }

    private var accent: some View {
        SettingsSection(header: "App color", identifier: "settings-appearance-accent") {
            AccentColorGrid(
                hexes: provider.palette,
                isSelected: { provider.isSelected($0) },
                onSelect: { provider.selectAccent($0) }
            )
            .padding(MCSpacing.lg)
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
