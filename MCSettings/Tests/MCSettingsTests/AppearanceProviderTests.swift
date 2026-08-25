import Foundation
import MCSettingsAPI
import Testing
@testable import MCSettings

@Suite("AppearanceProvider")
struct AppearanceProviderTests {

    @Test
    func defaultsSaoSystemEOAccentPadrao() {
        let sut = AppearanceProvider.Mock()

        #expect(sut.theme == .system)
        #expect(sut.accentHex == AppearanceDefaults.accentHex)
    }

    @Test
    func selecionarTemaGravaORawValue() {
        var sut = AppearanceProvider.Mock()

        sut.selectTheme(.dark)

        #expect(sut.themeRawValue == "dark")
        #expect(sut.theme == .dark)
    }

    @Test
    func selecionarAccentGravaOHex() {
        var sut = AppearanceProvider.Mock()

        sut.selectAccent("#EF4444")

        #expect(sut.accentHex == "#EF4444")
    }

    /// Hex fora da paleta é ignorado — senão um valor gravado por engano deixaria a tela sem
    /// nenhuma opção marcada, e sem como voltar.
    @Test
    func accentForaDaPaletaEhIgnorado() {
        var sut = AppearanceProvider.Mock(accentHex: "#3B82F6")

        sut.selectAccent("#123456")

        #expect(sut.accentHex == "#3B82F6")
    }

    @Test
    func isSelectedEhCaseInsensitive() {
        let sut = AppearanceProvider.Mock(accentHex: "#3b82f6")

        #expect(sut.isSelected("#3B82F6"))
        #expect(sut.isSelected("#EF4444") == false)
    }

    @Test
    func temaInvalidoNoStorageCaiEmSystem() {
        let sut = AppearanceProvider.Mock(themeRawValue: "sepia")

        #expect(sut.theme == .system)
    }

    @Test
    func paletaVemDoAccentPalette() {
        #expect(AppearanceProvider.Mock().palette == AccentPalette.hexes)
    }
}
