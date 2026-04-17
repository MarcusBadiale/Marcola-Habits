import SwiftUI

public enum MCColors {

    // MARK: - Category colors

    public static let health = Color(hex: "#EF4444")
    public static let productivity = Color(hex: "#3B82F6")
    public static let creativity = Color(hex: "#A855F7")
    public static let wellbeing = Color(hex: "#22C55E")
    public static let learning = Color(hex: "#F59E0B")

    // MARK: - UI accents

    public static let accentHex = "#3B82F6"
    public static let accent = Color(hex: accentHex)
    public static let success = Color(hex: "#22C55E")
    public static let warning = Color(hex: "#F59E0B")
    public static let danger = Color(hex: "#EF4444")

    // MARK: - Surfaces

    #if os(iOS)
    public static let cardBackground = Color(uiColor: .secondarySystemBackground)
    public static let chipBackground = Color(uiColor: .tertiarySystemBackground)
    #else
    public static let cardBackground = Color(nsColor: .controlBackgroundColor)
    public static let chipBackground = Color(nsColor: .windowBackgroundColor)
    #endif
}
