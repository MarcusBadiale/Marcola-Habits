import MCDesignSystem
import MCDomain
import MCShared
import SwiftData
import SwiftUI

struct HomeView: View {
    @Provider var provider = HomeProvider()

    var body: some View {
        VStack(spacing: 0) {
            DateCarousel(selectedDate: provider.$selectedDate)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.sm) {
                    CategoryChip(
                        name: "All",
                        icon: "square.grid.2x2",
                        colorHex: MCColors.accentHex,
                        isSelected: provider.selectedCategoryID == nil
                    )
                    .onTapGesture { provider.selectedCategoryID = nil }
                    .accessibilityIdentifier("home-category-all")

                    ForEach(Array(provider.categories.enumerated()), id: \.element.id) { index, category in
                        CategoryChip(
                            name: category.name,
                            icon: category.icon,
                            colorHex: category.colorHex,
                            isSelected: provider.selectedCategoryID == category.id
                        )
                        .onTapGesture { provider.selectedCategoryID = category.id }
                        .accessibilityIdentifier("home-category-chip-\(index)")
                    }
                }
                .padding(.horizontal, MCSpacing.md)
            }
            .padding(.vertical, MCSpacing.xs)

            List {
                ForEach(Array(provider.filteredHabits.enumerated()), id: \.element.id) { index, habit in
                    HabitCard(
                        name: habit.name,
                        icon: habit.icon,
                        colorHex: habit.colorHex,
                        isCompleted: provider.isCompleted(habit),
                        streak: provider.streak(habit),
                        progress: provider.progress(habit),
                        onToggle: { provider.toggleCompletion(habit) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: MCSpacing.xs,
                        leading: MCSpacing.md,
                        bottom: MCSpacing.xs,
                        trailing: MCSpacing.md
                    ))
                    .onTapGesture { provider.goToDetail(habit) }
                    .accessibilityIdentifier("home-habit-card-\(index)")
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { provider.showAddHabit() } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("home-add-button")
            }
        }
    }
}

#Preview {
    HomePreview()
}

private struct HomePreview: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
        .modelContainer(PreviewContainer.make())
    }
}
