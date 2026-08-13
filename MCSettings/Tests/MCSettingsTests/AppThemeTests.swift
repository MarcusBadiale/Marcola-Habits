import SwiftUI
import Testing
@testable import MCSettingsAPI

@Suite("AppTheme")
struct AppThemeTests {

    @Test("system não força colorScheme nenhum")
    func systemSegueOSistema() {
        #expect(AppTheme.system.colorScheme == nil)
    }

    @Test("light e dark forçam o colorScheme correspondente")
    func lightEDarkForcam() {
        #expect(AppTheme.light.colorScheme == .light)
        #expect(AppTheme.dark.colorScheme == .dark)
    }

    @Test("os três casos têm label")
    func labels() {
        #expect(AppTheme.system.label == "System")
        #expect(AppTheme.light.label == "Light")
        #expect(AppTheme.dark.label == "Dark")
        #expect(AppTheme.allCases.count == 3)
    }

    @Test("round-trip pelo rawValue", arguments: AppTheme.allCases)
    func roundTrip(theme: AppTheme) {
        #expect(AppTheme(storedValue: theme.rawValue) == theme)
        #expect(theme.id == theme.rawValue)
    }

    @Test("valor inválido ou ausente cai em system")
    func toleranteALixo() {
        #expect(AppTheme(storedValue: nil) == .system)
        #expect(AppTheme(storedValue: "") == .system)
        #expect(AppTheme(storedValue: "sepia") == .system)
    }

    @Test("o accent default está na paleta oferecida")
    func defaultEstaNaPaleta() {
        #expect(AccentPalette.contains(AppearanceDefaults.accentHex))
    }

    @Test("contains da paleta é case-insensitive")
    func paletaCaseInsensitive() {
        #expect(AccentPalette.contains("#3b82f6"))
        #expect(AccentPalette.contains("#000000") == false)
    }
}
