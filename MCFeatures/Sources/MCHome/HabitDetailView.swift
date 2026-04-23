import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftData
import SwiftUI

@MCView(HabitDetailProvider.self)
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
                    Section("Goal") {
                        HStack {
                            Text("Target")
                            Spacer()
                            Text("\(habit.targetCount) \(habit.targetUnit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Routine") {
                    HStack {
                        Text("Period")
                        Spacer()
                        Text(routineLabel(habit.routine))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Recent logs") {
                    if data.recentLogs.isEmpty {
                        Text("No records yet")
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
                        Label("Archive habit", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("habit-detail-archive-button")
                }
            }
            .navigationTitle(habit.name)
        } else {
            ContentUnavailableView(
                "Habit not found",
                systemImage: "questionmark.circle"
            )
        }
    }

    private func routineLabel(_ routine: Routine) -> String {
        switch routine {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .anytime: "Any time"
        }
    }
}
