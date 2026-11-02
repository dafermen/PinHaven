import Foundation
import SwiftData

@MainActor
enum LocalStore {
    static func makeContainer() throws -> ModelContainer {
        let base = try FileManager.default.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask, appropriateFor: nil, create: true)
        var directory = base.appendingPathComponent("PinHaven", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        // This private application-support directory is deliberately local-only.
        // Reapply before opening; covers the store and SQLite sidecar files.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        let config = ModelConfiguration("PinHaven",
            schema: Schema([Place.self]), url: directory.appendingPathComponent("places.store"),
            cloudKitDatabase: .none)
        return try ModelContainer(for: Place.self, configurations: config)
    }

    /// Append-only restore: existing IDs are skipped, never silently overwritten.
    static func importBackup(_ backup: PlaceBackup, into context: ModelContext) throws -> Int {
        let existing = Set(try context.fetch(FetchDescriptor<Place>()).map(\.id))
        var added = 0
        do {
            for record in backup.places where !existing.contains(record.id) {
                context.insert(Place.make(from: record)); added += 1
            }
            try context.save()
            return added
        } catch {
            context.rollback()
            throw error
        }
    }
}
