
public extension Habit {
    func toDTO() -> HabitDTO {
        HabitDTO(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            frequency: frequency,
            targetCount: targetCount,
            targetUnit: targetUnit,
            routine: routine,
            isArchived: isArchived,
            categoryID: category?.id,
            templateID: templateID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
