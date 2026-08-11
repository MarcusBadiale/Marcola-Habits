import MCDesignSystem
import MCDomain
import MCShared
import SwiftData
import SwiftUI

struct EditCategorySheet: View {
    @Provider var provider: EditCategoryProvider

    init(editingCategoryID: UUID?) {
        self._provider = Provider(EditCategoryProvider(editingCategoryID: editingCategoryID))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Category name", text: provider.$name)
                        .accessibilityIdentifier("edit-category-name-field")

                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: provider.icon)
                            .foregroundStyle(Color(hex: provider.colorHex))
                            .font(.title2)
                    }

                    IconPicker(selectedIcon: provider.$icon)
                }

                Section("Color") {
                    ColorGridPicker(selectedHex: provider.$colorHex)
                }
            }
            .navigationTitle(provider.isEditing ? "Edit category" : "New category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { provider.cancel() }
                        .accessibilityIdentifier("edit-category-cancel-button")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { provider.save() }
                        .disabled(!provider.canSave)
                        .accessibilityIdentifier("edit-category-save-button")
                }
            }
            .onAppear { provider.loadExisting() }
        }
    }
}

private struct IconPicker: View {
    @Binding var selectedIcon: String

    private let icons = [
        "folder.fill", "heart.fill", "bolt.fill", "paintbrush.fill",
        "leaf.fill", "book.fill", "star.fill", "flame.fill",
        "drop.fill", "figure.run", "brain.head.profile", "moon.fill",
        "sun.max.fill", "music.note", "graduationcap.fill", "dumbbell.fill",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: MCSpacing.sm) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(
                        selectedIcon == icon ? MCColors.accent.opacity(0.2) : Color.clear,
                        in: Circle()
                    )
                    .onTapGesture { selectedIcon = icon }
            }
        }
    }
}

#Preview("New Category") {
    let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    let container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
    EditCategorySheet(editingCategoryID: nil)
        .modelContainer(container)
}

#Preview("Edit Category") {
    let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
    let container = try! ModelContainer(for: schema, configurations: .init(schema: schema, isStoredInMemoryOnly: true))
    let _ = SeedDataProvider.populate(container.mainContext)
    let categoryID = try! container.mainContext.fetch(FetchDescriptor<CategoryModel>(sortBy: [SortDescriptor(\CategoryModel.sortOrder)])).first!.id
    EditCategorySheet(editingCategoryID: categoryID)
        .modelContainer(container)
}

private struct ColorGridPicker: View {
    @Binding var selectedHex: String

    private let colors = [
        "#EF4444", "#F59E0B", "#22C55E", "#3B82F6",
        "#A855F7", "#EC4899", "#14B8A6", "#F97316",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: MCSpacing.sm) {
            ForEach(colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(.white, lineWidth: selectedHex == hex ? 3 : 0)
                    )
                    .shadow(color: selectedHex == hex ? Color(hex: hex).opacity(0.4) : .clear, radius: 4)
                    .onTapGesture { selectedHex = hex }
            }
        }
    }
}
