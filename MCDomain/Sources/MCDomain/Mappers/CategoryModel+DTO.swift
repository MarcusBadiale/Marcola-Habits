
public extension CategoryModel {
    func toDTO() -> CategoryDTO {
        CategoryDTO(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
