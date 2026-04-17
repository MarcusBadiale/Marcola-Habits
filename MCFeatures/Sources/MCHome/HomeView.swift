import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftUI

@MCView(HomeViewModel.self)
public struct HomeView: View {
    public init() {
        self._data = .init()
    }
    public var body: some View {
        VStack(spacing: 0) {
            DateCarousel(selectedDate: data.$selectedDate)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MCSpacing.sm) {
                    CategoryChip(
                        name: "Todos",
                        icon: "square.grid.2x2",
                        colorHex: MCColors.accentHex,
                        isSelected: data.selectedCategoryID == nil
                    )
                    .onTapGesture { data.$selectedCategoryID.wrappedValue = nil }
                    .accessibilityIdentifier("home-category-all")

                    ForEach(Array(data.categories.enumerated()), id: \.element.id) { index, category in
                        CategoryChip(
                            name: category.name,
                            icon: category.icon,
                            colorHex: category.colorHex,
                            isSelected: data.selectedCategoryID == category.id
                        )
                        .onTapGesture { data.$selectedCategoryID.wrappedValue = category.id }
                        .accessibilityIdentifier("home-category-chip-\(index)")
                    }
                }
                .padding(.horizontal, MCSpacing.md)
            }
            .padding(.vertical, MCSpacing.xs)

            List {
                ForEach(Array(data.filteredHabits.enumerated()), id: \.element.id) { index, habit in
                    HabitCard(
                        name: habit.name,
                        icon: habit.icon,
                        colorHex: habit.colorHex,
                        isCompleted: data.isCompleted(habit),
                        streak: data.streak(habit),
                        progress: data.progress(habit),
                        onToggle: { data.toggleCompletion(habit) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: MCSpacing.xs,
                        leading: MCSpacing.md,
                        bottom: MCSpacing.xs,
                        trailing: MCSpacing.md
                    ))
                    .onTapGesture { data.goToDetail(habit) }
                    .accessibilityIdentifier("home-habit-card-\(index)")
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Hoje")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { data.showAddHabit() } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("home-add-button")
            }
        }
    }
}
