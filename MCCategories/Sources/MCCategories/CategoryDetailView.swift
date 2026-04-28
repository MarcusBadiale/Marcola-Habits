import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftData
import SwiftUI

@MCView(CategoryDetailProvider.self)
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

                            Text("\(data.activeHabits.count) active habit\(data.activeHabits.count == 1 ? "" : "s")")
                                .font(MCTypography.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, MCSpacing.sm)
                }

                Section("Habits") {
                    if data.activeHabits.isEmpty {
                        Text("No habits in this category")
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
                        Text("Edit")
                    }
                    .accessibilityIdentifier("category-detail-edit-button")
                }
            }
        } else {
            ContentUnavailableView(
                "Category not found",
                systemImage: "questionmark.circle"
            )
        }
    }
}

#Preview("With Habits") {
    let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    let container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
    let _ = SeedDataProvider.populate(container.mainContext)
    let categoryID = try! container.mainContext.fetch(FetchDescriptor<CategoryModel>(sortBy: [SortDescriptor(\CategoryModel.sortOrder)])).first!.id
    NavigationStack {
        CategoryDetailView(categoryID: categoryID)
    }
    .modelContainer(container)
}

#Preview("Empty Category") {
    let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    let container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
    let empty = CategoryModel(name: "Vazia", icon: "folder.fill", colorHex: "#3B82F6")
    let _ = container.mainContext.insert(empty)
    NavigationStack {
        CategoryDetailView(categoryID: empty.id)
    }
    .modelContainer(container)
}

#Preview("Not Found") {
    let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    let container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
    NavigationStack {
        CategoryDetailView(categoryID: UUID())
    }
    .modelContainer(container)
}
