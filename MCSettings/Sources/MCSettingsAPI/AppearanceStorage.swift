import Foundation

/// Chaves de `UserDefaults` da aparência.
///
/// Sem ponto de propósito: `@AppStorage` observa o `UserDefaults` via KVO usando a chave como
/// key path, e `.` é interpretado como travessia de KVC — a leitura funcionaria, mas a View
/// pararia de re-renderizar quando o valor mudasse.
public enum AppearanceStorageKeys {
    public static let theme = "mcSettingsTheme"
    public static let accentHex = "mcSettingsAccentHex"
}

public enum AppearanceDefaults {
    /// Espelha o `MCColors.accentHex` do MCDesignSystem. Duplicado como literal porque o target
    /// API não depende do MCCore — se um dia divergirem, este é o que manda na preferência
    /// do usuário.
    public static let accentHex = "#3B82F6"
}

/// Opções de accent oferecidas na tela de Aparência.
public enum AccentPalette {

    public static let hexes: [String] = [
        "#3B82F6",  // blue
        "#007AFF",  // iOS blue
        "#EF4444",  // red
        "#F59E0B",  // amber
        "#22C55E",  // green
        "#14B8A6",  // teal
        "#A855F7",  // purple
        "#EC4899",  // pink
    ]

    public static func contains(_ hex: String) -> Bool {
        hexes.contains { $0.caseInsensitiveCompare(hex) == .orderedSame }
    }
}
