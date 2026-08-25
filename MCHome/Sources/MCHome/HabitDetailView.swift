import MCDesignSystem
import MCDomain
import MCShared
import SwiftData
import SwiftUI

struct HabitDetailView: View {
    @Provider var provider: HabitDetailProvider

    init(habitID: UUID) {
        self._provider = Provider(HabitDetailProvider(habitID: habitID))
    }

    var body: some View {
        if let habit = provider.habit {
            List {
                Section {
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: habit.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: habit.colorHex))

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text(habit.name)
                                .font(MCTypography.title)

                            Text(provider.frequencyDescription)
                                .font(MCTypography.callout)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        StreakBadge(count: provider.currentStreak)
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
                    if provider.recentLogs.isEmpty {
                        Text("No records yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(provider.recentLogs) { log in
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
                        provider.archiveHabit()
                    } label: {
                        Label("Archive habit", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("habit-detail-archive-button")
                }
            }
            .accessibilityIdentifier("habit-detail-list")
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

#Preview {
    HabitDetailPreviewWrapper()
}

private struct HabitDetailPreviewWrapper: View {
    let container: ModelContainer
    let habitID: UUID

    @MainActor init() {
        container = PreviewContainer.make()
        let habits = try! container.mainContext.fetch(FetchDescriptor<HabitModel>())
        habitID = habits.first!.id
    }

    var body: some View {
        NavigationStack {
            HabitDetailView(habitID: habitID)
        }
        .modelContainer(container)
    }
}
