import SwiftUI

public struct CategoryChip: View {
    public let name: String
    public let icon: String
    public let colorHex: String
    public let isSelected: Bool

    public init(name: String, icon: String, colorHex: String, isSelected: Bool = false) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isSelected = isSelected
    }

    private var chipColor: Color { Color(hex: colorHex) }

    public var body: some View {
        HStack(spacing: MCSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)

            Text(name)
                .font(MCTypography.callout)
        }
        .padding(.horizontal, MCSpacing.md)
        .padding(.vertical, MCSpacing.sm)
        .foregroundStyle(isSelected ? .white : chipColor)
        .background(
            isSelected ? chipColor : chipColor.opacity(0.12),
            in: Capsule()
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    HStack {
        CategoryChip(name: "Saúde", icon: "heart.fill", colorHex: "#EF4444", isSelected: true)
        CategoryChip(name: "Produtividade", icon: "bolt.fill", colorHex: "#3B82F6")
        CategoryChip(name: "Bem-estar", icon: "leaf.fill", colorHex: "#22C55E")
    }
    .padding()
}
