import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftUI

@MCView(CategoriesViewModel.self)
public struct CategoriesView: View {
    public init() {
        self._data = .init()
    }
    public var body: some View {
        List {
            ForEach(Array(data.categories.enumerated()), id: \.element.id) { index, category in
                CategoryRow(
                    category: category,
                    habitCount: data.habitCount(category)
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: MCSpacing.xs,
                    leading: MCSpacing.md,
                    bottom: MCSpacing.xs,
                    trailing: MCSpacing.md
                ))
                .onTapGesture { data.goToDetail(category) }
                .accessibilityIdentifier("categories-row-\(index)")
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let category = data.categories[index]
                    if !category.isDefault {
                        data.deleteCategory(category)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Categorias")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { data.showAddCategory() } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("categories-add-button")
            }
        }
    }
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

                Text("\(habitCount) hábito\(habitCount == 1 ? "" : "s")")
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
