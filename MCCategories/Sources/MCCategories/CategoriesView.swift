import MCDesignSystem
import MCDomain
import MCShared
import SwiftData
import SwiftUI

struct CategoriesView: View {
    @Provider var provider = CategoriesProvider()

    var body: some View {
        List {
            ForEach(Array(provider.categories.enumerated()), id: \.element.id) { index, category in
                CategoryRow(
                    category: category,
                    habitCount: provider.habitCount(for: category)
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: MCSpacing.xs,
                    leading: MCSpacing.md,
                    bottom: MCSpacing.xs,
                    trailing: MCSpacing.md
                ))
                .contentShape(Rectangle())
                .onTapGesture { provider.goToDetail(category) }
                // A row não é `Button`, então sem o `.combine` ela vira ícone + nome + contagem +
                // chevron soltos e o identifier não resolve pra nenhum deles (iOS 26).
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("categories-row-\(index)")
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let category = provider.categories[index]
                    if !category.isDefault {
                        provider.deleteCategory(category)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { provider.showAddCategory() } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("categories-add-button")
            }
        }
    }
}

#Preview {
    let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    let container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
    let _ = SeedDataProvider.populate(container.mainContext)
    NavigationStack {
        CategoriesView()
    }
    .modelContainer(container)
}

private struct CategoryRow: View {
    let category: CategoryModel
    let habitCount: Int

    var body: some View {
        HStack(spacing: MCSpacing.md) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(Color(hex: category.colorHex))
                .frame(width: MCSpacing.iconSize, height: MCSpacing.iconSize)

            VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                Text(category.name)
                    .font(MCTypography.headline)

                Text("\(habitCount) habit\(habitCount == 1 ? "" : "s")")
                    .font(MCTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(MCSpacing.cardPadding)
        .background(MCColors.cardBackground, in: RoundedRectangle(cornerRadius: MCSpacing.cardCornerRadius))
    }
}
