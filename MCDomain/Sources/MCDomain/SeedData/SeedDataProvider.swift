import Foundation
import SwiftData

public enum SeedDataProvider {

    public static func populate(_ context: ModelContext) {
        let categories = defaultCategories()
        categories.forEach { context.insert($0) }

        let templates = defaultTemplates()
        templates.forEach { context.insert($0) }

        let habits = defaultHabits(categories: categories)
        habits.forEach { context.insert($0) }

        let logs = defaultLogs(for: habits)
        logs.forEach { context.insert($0) }
    }

    // MARK: - Categories

    public static func defaultCategories() -> [CategoryModel] {
        [
            CategoryModel(name: "Saúde", icon: "heart.fill", colorHex: "#EF4444", sortOrder: 0, isDefault: true),
            CategoryModel(name: "Produtividade", icon: "bolt.fill", colorHex: "#3B82F6", sortOrder: 1, isDefault: true),
            CategoryModel(name: "Criatividade", icon: "paintbrush.fill", colorHex: "#A855F7", sortOrder: 2, isDefault: true),
            CategoryModel(name: "Bem-estar", icon: "leaf.fill", colorHex: "#22C55E", sortOrder: 3, isDefault: true),
            CategoryModel(name: "Aprendizado", icon: "book.fill", colorHex: "#F59E0B", sortOrder: 4, isDefault: true),
        ]
    }

    // MARK: - Templates

    private static let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    public static func defaultTemplates() -> [HabitTemplateModel] {
        [
            HabitTemplateModel(name: "Beber água", icon: "drop.fill", categoryName: "Saúde",
                               defaultFrequency: .daily, defaultTargetCount: 8, defaultTargetUnit: "copos"),
            HabitTemplateModel(name: "Meditar", icon: "brain.head.profile", categoryName: "Bem-estar",
                               defaultFrequency: .daily, defaultTargetCount: 1, defaultTargetUnit: "sessão"),
            HabitTemplateModel(name: "Exercício", icon: "figure.run", categoryName: "Saúde",
                               defaultFrequency: .specificDays(weekdays), defaultTargetCount: 1, defaultTargetUnit: "treino"),
            HabitTemplateModel(name: "Ler", icon: "book.fill", categoryName: "Aprendizado",
                               defaultFrequency: .daily, defaultTargetCount: 30, defaultTargetUnit: "minutos"),
            HabitTemplateModel(name: "Journaling", icon: "pencil.line", categoryName: "Bem-estar",
                               defaultFrequency: .daily, defaultTargetCount: 1, defaultTargetUnit: "entrada"),
            HabitTemplateModel(name: "Estudar", icon: "graduationcap.fill", categoryName: "Aprendizado",
                               defaultFrequency: .specificDays(weekdays), defaultTargetCount: 1, defaultTargetUnit: "sessão"),
            HabitTemplateModel(name: "Dormir 8h", icon: "moon.fill", categoryName: "Saúde",
                               defaultFrequency: .daily, defaultTargetCount: 8, defaultTargetUnit: "horas"),
            HabitTemplateModel(name: "Caminhar", icon: "figure.walk", categoryName: "Saúde",
                               defaultFrequency: .daily, defaultTargetCount: 30, defaultTargetUnit: "minutos"),
            HabitTemplateModel(name: "Sem redes sociais", icon: "iphone.slash", categoryName: "Produtividade",
                               defaultFrequency: .daily, defaultTargetCount: 1, defaultTargetUnit: "dia"),
            HabitTemplateModel(name: "Praticar instrumento", icon: "music.note", categoryName: "Criatividade",
                               defaultFrequency: .specificDays(weekdays), defaultTargetCount: 30, defaultTargetUnit: "minutos"),
        ]
    }

    // MARK: - Habits

    public static func defaultHabits(categories: [CategoryModel]) -> [HabitModel] {
        let cat = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        let habits = [
            HabitModel(name: "Beber água", icon: "drop.fill", colorHex: "#EF4444",
                       frequency: .daily, targetCount: 8, targetUnit: "copos",
                       routine: .morning, category: cat["Saúde"]),
            HabitModel(name: "Meditar", icon: "brain.head.profile", colorHex: "#22C55E",
                       frequency: .daily, targetCount: 1, targetUnit: "sessão",
                       routine: .morning, category: cat["Bem-estar"]),
            HabitModel(name: "Exercício", icon: "figure.run", colorHex: "#EF4444",
                       frequency: .specificDays(weekdays), targetCount: 1, targetUnit: "treino",
                       routine: .afternoon, category: cat["Saúde"]),
            HabitModel(name: "Ler", icon: "book.fill", colorHex: "#F59E0B",
                       frequency: .daily, targetCount: 30, targetUnit: "minutos",
                       routine: .evening, category: cat["Aprendizado"]),
            HabitModel(name: "Journaling", icon: "pencil.line", colorHex: "#22C55E",
                       frequency: .daily, targetCount: 1, targetUnit: "entrada",
                       routine: .evening, category: cat["Bem-estar"]),
            HabitModel(name: "Sem redes sociais", icon: "iphone.slash", colorHex: "#3B82F6",
                       frequency: .daily, targetCount: 1, targetUnit: "dia",
                       routine: .anytime, category: cat["Produtividade"]),
        ]

        // Backdate: o seed gera ~90 dias de histórico, então os hábitos precisam ser mais velhos
        // que isso — senão a tela de Stats mostra um hábito "criado hoje" com 3 meses de log.
        if let createdAt = Calendar.current.date(byAdding: .day, value: -120, to: .now) {
            habits.forEach { $0.createdAt = createdAt }
        }

        return habits
    }
}
