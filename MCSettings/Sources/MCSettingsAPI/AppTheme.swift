import SwiftUI

/// Preferência de tema do usuário. Vive no target API porque é contrato compartilhado: o
/// MCSettings escreve e a `ContentView` do app target lê pra aplicar `.preferredColorScheme`.
public enum AppTheme: String, CaseIterable, Identifiable, Sendable {

    case system
    case light
    case dark

    public var id: String { rawValue }

    /// `nil` = segue o sistema, que é exatamente o que `.preferredColorScheme` espera.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    public var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// Tolerante a lixo no `UserDefaults` — chave ausente ou valor de uma versão antiga cai no
    /// default em vez de crashar.
    public init(storedValue: String?) {
        self = AppTheme(rawValue: storedValue ?? "") ?? .system
    }
}
