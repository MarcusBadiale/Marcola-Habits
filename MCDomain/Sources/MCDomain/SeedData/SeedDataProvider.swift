import SwiftData

public enum SeedDataProvider {

    public static func populate(_ context: ModelContext) {
        let categories = defaultCategories()
        categories.forEach { context.insert($0) }

        let templates = defaultTemplates()
        templates.forEach { context.insert($0) }
    }

    public static func defaultCategories() -> [Category] {
        [
            Category(name: "Saúde", icon: "heart.fill", colorHex: "#EF4444", sortOrder: 0, isDefault: true),
            Category(name: "Produtividade", icon: "bolt.fill", colorHex: "#3B82F6", sortOrder: 1, isDefault: true),
            Category(name: "Criatividade", icon: "paintbrush.fill", colorHex: "#A855F7", sortOrder: 2, isDefault: true),
            Category(name: "Bem-estar", icon: "leaf.fill", colorHex: "#22C55E", sortOrder: 3, isDefault: true),
            Category(name: "Aprendizado", icon: "book.fill", colorHex: "#F59E0B", sortOrder: 4, isDefault: true),
        ]
    }

    private static let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    public static func defaultTemplates() -> [HabitTemplate] {
        [
            HabitTemplate(name: "Beber água", icon: "drop.fill", categoryName: "Saúde",
                          defaultFrequency: .daily, defaultTargetCount: 8, defaultTargetUnit: "copos"),
            HabitTemplate(name: "Meditar", icon: "brain.head.profile", categoryName: "Bem-estar",
                          defaultFrequency: .daily, defaultTargetCount: 1, defaultTargetUnit: "sessão"),
            HabitTemplate(name: "Exercício", icon: "figure.run", categoryName: "Saúde",
                          defaultFrequency: .specificDays(weekdays), defaultTargetCount: 1, defaultTargetUnit: "treino"),
            HabitTemplate(name: "Ler", icon: "book.fill", categoryName: "Aprendizado",
                          defaultFrequency: .daily, defaultTargetCount: 30, defaultTargetUnit: "minutos"),
            HabitTemplate(name: "Journaling", icon: "pencil.line", categoryName: "Bem-estar",
                          defaultFrequency: .daily, defaultTargetCount: 1, defaultTargetUnit: "entrada"),
            HabitTemplate(name: "Estudar", icon: "graduationcap.fill", categoryName: "Aprendizado",
                          defaultFrequency: .specificDays(weekdays), defaultTargetCount: 1, defaultTargetUnit: "sessão"),
            HabitTemplate(name: "Dormir 8h", icon: "moon.fill", categoryName: "Saúde",
                          defaultFrequency: .daily, defaultTargetCount: 8, defaultTargetUnit: "horas"),
            HabitTemplate(name: "Caminhar", icon: "figure.walk", categoryName: "Saúde",
                          defaultFrequency: .daily, defaultTargetCount: 30, defaultTargetUnit: "minutos"),
            HabitTemplate(name: "Sem redes sociais", icon: "iphone.slash", categoryName: "Produtividade",
                          defaultFrequency: .daily, defaultTargetCount: 1, defaultTargetUnit: "dia"),
            HabitTemplate(name: "Praticar instrumento", icon: "music.note", categoryName: "Criatividade",
                          defaultFrequency: .specificDays(weekdays), defaultTargetCount: 30, defaultTargetUnit: "minutos"),
        ]
    }
}
