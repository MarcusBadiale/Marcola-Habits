import MarcolasPattern
import MCDesignSystem
import MCDomain
import SwiftData
import SwiftUI

@MCView(EditCategoryProvider.self)
struct EditCategorySheet: View {
    init(editingCategoryID: UUID?) {
        self._data = .init(editingCategoryID: editingCategoryID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Category name", text: data.$name)
                        .accessibilityIdentifier("edit-category-name-field")

                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: data.icon)
                            .foregroundStyle(Color(hex: data.colorHex))
                            .font(.title2)
                    }

                    IconPicker(selectedIcon: data.$icon)
                }

                Section("Color") {
                    ColorGridPicker(selectedHex: data.$colorHex)
                }
            }
            .navigationTitle(data.isEditing ? "Edit category" : "New category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { data.cancel() }
                        .accessibilityIdentifier("edit-category-cancel-button")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { data.save() }
                        .disabled(!data.canSave)
                        .accessibilityIdentifier("edit-category-save-button")
                }
            }
            .onAppear { data.loadExisting() }
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
