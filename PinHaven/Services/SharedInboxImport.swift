import Foundation
import SwiftData

@MainActor
enum SharedInboxImport {
    /// Save before acknowledging; a crash in between is retried without duplicate IDs.
    static func consume(_ inbox: SharedInbox, into context: ModelContext) throws -> (added: Int, failed: Int) {
        var added = 0
        var failed = 0
        for file in try inbox.files().prefix(200) {
            do {
                let capture = try inbox.read(file)
                let count = try LocalStore.importBackup(PlaceBackup(places: [capture.record]), into: context)
                added += count
                try inbox.acknowledge(capture.id)
            } catch { failed += 1 }
        }
        return (added, failed)
    }
}
