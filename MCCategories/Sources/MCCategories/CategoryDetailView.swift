import MCDesignSystem
import MCDomain
import MCShared
import SwiftData
import SwiftUI

struct CategoryDetailView: View {
    @Provider var provider: CategoryDetailProvider

    init(categoryID: UUID) {
        self._provider = Provider(CategoryDetailProvider(categoryID: categoryID))
    }

    var body: some View {
        if let category = provider.category {
            List {
                Section {
                    HStack(spacing: MCSpacing.md) {
                        Image(systemName: category.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: category.colorHex))

                        VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                            Text(category.name)
                                .font(MCTypography.title)

                            Text("\(provider.activeHabits.count) active habit\(provider.activeHabits.count == 1 ? "" : "s")")
                                .font(MCTypography.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, MCSpacing.sm)
                }

                Section("Habits") {
                    if provider.activeHabits.isEmpty {
                        Text("No habits in this category")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(provider.activeHabits.enumerated()), id: \.element.id) { index, habit in
                            HStack(spacing: MCSpacing.md) {
                                Image(systemName: habit.icon)
                                    .foregroundStyle(Color(hex: habit.colorHex))

                                Text(habit.name)
                                    .font(MCTypography.body)

                                Spacer()

                                Image(systemName: provider.isCompleted(habit) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(provider.isCompleted(habit) ? Color(hex: habit.colorHex) : .secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { provider.goToHabitDetail(habit) }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("category-detail-habit-\(index)")
                        }
                    }
                }
            }
            .navigationTitle(category.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { provider.showEditCategory() } label: {
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
