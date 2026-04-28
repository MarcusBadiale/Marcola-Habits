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
        return [
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
    }

    // MARK: - Logs

    public static func defaultLogs(for habits: [HabitModel]) -> [HabitLogModel] {
        // Pattern por hábito: index 0 = hoje, 1 = ontem... (1=feito, 0=não)
        let completions = [
            "011111111111011011101", // Beber água: streak 11, hoje pendente
            "111110111111101110110", // Meditar: streak 4 + hoje
            "111111111111111111111", // Exercício: sempre (pula fins de semana)
            "001010110100101011010", // Ler: esporádico
            "111111111111100111011", // Journaling: streak 12 + hoje
            "010110100101011011010", // Sem redes sociais: ~50%
        ]
        let countRanges: [(min: Int, max: Int)] = [
            (5, 8), (1, 1), (1, 1), (15, 30), (1, 1), (1, 1),
        ]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var logs: [HabitLogModel] = []

        for (index, habit) in habits.enumerated() {
            let pattern = completions[index]
            let range = countRanges[index]

            for dayOffset in 0..<pattern.count {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                guard habit.isScheduled(for: date) else { continue }

                let char = pattern[pattern.index(pattern.startIndex, offsetBy: dayOffset)]
                let completed = char == "1"
                let count = completed ? range.min + (dayOffset % (range.max - range.min + 1)) : 0

                logs.append(HabitLogModel(date: date, completed: completed, count: count, habit: habit))
            }
        }

        return logs
    }
}
