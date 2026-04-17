import Foundation

public struct CategoryDTO: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int
    public var isDefault: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 0,
        isDefault: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
