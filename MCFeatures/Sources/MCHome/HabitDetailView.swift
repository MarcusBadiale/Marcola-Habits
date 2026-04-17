import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftUI

@MCView(HabitDetailViewModel.self)
struct HabitDetailView: View {
    init(habitID: UUID) {
        self._data = .init(habitID: habitID)
    }

    var body: some View {
        if let habit = data.habit {
            List {
                Section {
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: habit.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: habit.colorHex))

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text(habit.name)
                                .font(MCTypography.title)

                            Text(data.frequencyDescription)
                                .font(MCTypography.callout)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        StreakBadge(count: data.currentStreak)
                    }
                    .padding(.vertical, MCSpacing.sm)
                }

                if habit.targetCount > 1 {
                    Section("Meta") {
                        HStack {
                            Text("Objetivo")
                            Spacer()
                            Text("\(habit.targetCount) \(habit.targetUnit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Rotina") {
                    HStack {
                        Text("Período")
                        Spacer()
                        Text(routineLabel(habit.routine))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Últimos registros") {
                    if data.recentLogs.isEmpty {
                        Text("Nenhum registro ainda")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(data.recentLogs) { log in
                            HStack {
                                Text(log.date.shortMonthDay)
                                Spacer()
                                if habit.targetCount > 1 {
                                    Text("\(log.count)/\(habit.targetCount)")
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: log.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(log.completed ? Color(hex: habit.colorHex) : .secondary)
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        data.archiveHabit()
                    } label: {
                        Label("Arquivar hábito", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("habit-detail-archive-button")
                }
            }
            .navigationTitle(habit.name)
        } else {
            ContentUnavailableView(
                "Hábito não encontrado",
                systemImage: "questionmark.circle"
            )
        }
    }

    private func routineLabel(_ routine: Routine) -> String {
        switch routine {
        case .morning: "Manhã"
        case .afternoon: "Tarde"
        case .evening: "Noite"
        case .anytime: "Qualquer hora"
        }
    }
}
