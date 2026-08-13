import MCMacros
import MCSettingsAPI
import MCShared
import SwiftUI

@Mockable
struct AppearanceProvider: MCProvider {

    @AppStorage(AppearanceStorageKeys.theme) var themeRawValue: String = AppTheme.system.rawValue
    @AppStorage(AppearanceStorageKeys.accentHex) var accentHex: String = AppearanceDefaults.accentHex

    var theme: AppTheme {
        AppTheme(storedValue: themeRawValue)
    }

    var palette: [String] { AccentPalette.hexes }

    /// Hex de `UserDefaults` pode vir com caixa diferente do literal da paleta.
    func isSelected(_ hex: String) -> Bool {
        accentHex.caseInsensitiveCompare(hex) == .orderedSame
    }

    func selectTheme(_ theme: AppTheme) {
        themeRawValue = theme.rawValue
    }

    func selectAccent(_ hex: String) {
        guard AccentPalette.contains(hex) else { return }
        accentHex = hex
    }
}
