import Foundation
import SwiftData
import MCDomain

public enum ModelContainerFactory {

    public static func makeProduction() throws -> ModelContainer {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
        let config = ModelConfiguration(schema: schema)
        return try ModelContainer(for: schema, configurations: config)
    }

    public static func makeInMemory() throws -> ModelContainer {
        let schema = Schema([CategoryModel.self, HabitModel.self, HabitLogModel.self, HabitTemplateModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @MainActor
    public static func makeSeeded() throws -> ModelContainer {
        let container = try makeInMemory()
        SeedDataProvider.populate(container.mainContext)
        return container
    }
}
