import MCDesignSystem
import MCDomain
import MCShared
import SwiftData
import SwiftUI

struct HabitStatsView: View {

    @Provider var provider: HabitStatsProvider

    init(habitID: UUID) {
        self._provider = Provider(HabitStatsProvider(habitID: habitID))
    }

    var body: some View {
        Group {
            if let habit = provider.habit {
                content(for: habit)
            } else {
                ContentUnavailableView("Habit not found", systemImage: "questionmark.circle")
                    .accessibilityIdentifier("habit-stats-not-found")
            }
        }
        .navigationTitle(provider.habit?.name ?? "Stats")
    }

    private func content(for habit: HabitModel) -> some View {
        let summary = provider.summary

        return ScrollView {
            VStack(alignment: .leading, spacing: MCSpacing.lg) {
                StatsPeriodPicker(period: provider.$period, identifierPrefix: "habit-stats-period")

                StatsSummaryCard(
                    rate: summary.rate,
                    bestStreak: summary.bestStreak,
                    periodTitle: provider.period.sectionTitle,
                    identifierPrefix: "habit-stats",
                    currentStreak: summary.currentStreak
                )

                VStack(alignment: .leading, spacing: MCSpacing.md) {
                    Text(provider.period.sectionTitle)
                        .font(MCTypography.caption)
                        .foregroundStyle(.secondary)

                    ActivityCalendarGrid(
                        days: summary.days,
                        tint: Color(hex: habit.colorHex),
                        identifierPrefix: "habit-stats-calendar"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MCSpacing.cardPadding)
                .background(
                    MCColors.cardBackground,
                    in: RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius, style: .continuous)
                )
            }
            .padding(MCSpacing.lg)
        }
    }
}

#Preview {
    HabitStatsPreviewWrapper()
}

/// Busca um `habitID` real do container antes de montar a view — o provider precisa do id no init.
private struct HabitStatsPreviewWrapper: View {
    let container: ModelContainer
    let habitID: UUID

    @MainActor init() {
        container = PreviewContainer.make()
        let habits = try! container.mainContext.fetch(FetchDescriptor<HabitModel>())
        habitID = habits.first!.id
    }

    var body: some View {
        NavigationStack {
            HabitStatsView(habitID: habitID)
        }
        .modelContainer(container)
    }
}
