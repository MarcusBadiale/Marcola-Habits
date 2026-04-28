import MarcolasPattern
import MCDomain
import MCNavigationAPI
import MCShared
import SwiftData
import SwiftUI

@MCProvider
struct EditCategoryProvider {
    let editingCategoryID: UUID?

    @Query var allCategories: [CategoryModel]

    @State var name: String = ""
    @State var icon: String = "folder.fill"
    @State var colorHex: String = "#3B82F6"
    @State var didLoadExisting: Bool = false

    @Environment(\.modelContext) var modelContext: ModelContext
    @Environment(\.navigator) var navigator: NavigatorAPI

    var isEditing: Bool { editingCategoryID != nil }

    var existingCategory: CategoryModel? {
        guard let id = editingCategoryID else { return nil }
        return allCategories.first { $0.id == id }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func loadExisting() {
        guard !didLoadExisting, let category = existingCategory else { return }
        name = category.name
        icon = category.icon
        colorHex = category.colorHex
        didLoadExisting = true
    }

    func save() {
        if let category = existingCategory {
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.icon = icon
            category.colorHex = colorHex
            category.updatedAt = Date.now
        } else {
            let maxOrder = allCategories.map(\.sortOrder).max() ?? -1
            let category = CategoryModel(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                colorHex: colorHex,
                sortOrder: maxOrder + 1
            )
            modelContext.insert(category)
        }
        navigator.dismiss()
    }

    func cancel() {
        navigator.dismiss()
    }
}
