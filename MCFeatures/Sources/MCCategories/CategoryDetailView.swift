import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftUI

@MCView(CategoryDetailViewModel.self)
struct CategoryDetailView: View {
    init(categoryID: UUID) {
        self._data = .init(categoryID: categoryID)
    }

    var body: some View {
        if let category = data.category {
            List {
                Section {
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: category.colorHex))

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text(category.name)
                                .font(MCTypography.title)

                            Text("\(data.activeHabits.count) hábito\(data.activeHabits.count == 1 ? "" : "s") ativo\(data.activeHabits.count == 1 ? "" : "s")")
                                .font(MCTypography.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, MCSpacing.sm)
                }

                Section("Hábitos") {
                    if data.activeHabits.isEmpty {
                        Text("Nenhum hábito nesta categoria")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(data.activeHabits.enumerated()), id: \.element.id) { index, habit in
                            HStack(spacing: MCSpacing.md) {
                                Image(systemName: habit.icon)
                                    .foregroundStyle(Color(hex: habit.colorHex))

                                Text(habit.name)
                                    .font(MCTypography.body)

                                Spacer()

                                Image(systemName: data.isCompleted(habit) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(data.isCompleted(habit) ? Color(hex: habit.colorHex) : .secondary)
                            }
                            .onTapGesture { data.goToHabitDetail(habit) }
                            .accessibilityIdentifier("category-detail-habit-\(index)")
                        }
                    }
                }
            }
            .navigationTitle(category.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { data.showEditCategory() } label: {
                        Text("Editar")
                    }
                    .accessibilityIdentifier("category-detail-edit-button")
                }
            }
        } else {
            ContentUnavailableView(
                "Categoria não encontrada",
                systemImage: "questionmark.circle"
            )
        }
    }
}
