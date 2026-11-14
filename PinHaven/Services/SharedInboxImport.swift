import Foundation
import SwiftData

@MainActor
enum SharedInboxImport {
    /// New locations still arrive automatically; possible duplicates stay available for review.
    static func consume(_ inbox: SharedInbox, into context: ModelContext) throws -> (added: Int, failed: Int, duplicates: Int) {
        var added = 0, failed = 0, duplicates = 0
        for file in try inbox.files().prefix(200) {
            do {
                let records = try context.fetch(FetchDescriptor<Place>()).map(\.record)
                let capture = try inbox.read(file)
                if try finishPrevious(capture.id, inbox: inbox, records: records) { continue }
                if !PlaceDuplicates.matches(capture.record, among: records).isEmpty {
                    duplicates += 1; continue
                }
                try persist(capture.record, captureID: capture.id, inbox: inbox, into: context)
                added += 1
            } catch { failed += 1 }
        }
        return (added, failed, duplicates)
    }

    /// Only called after an explicit review. The original capture ID is independent of the target place ID.
    static func accept(_ record: PlaceRecord, captureID: UUID, inbox: SharedInbox, into context: ModelContext) throws {
        let capture = try inbox.read(inbox.directory.appendingPathComponent(captureID.uuidString + ".json"))
        let records = try context.fetch(FetchDescriptor<Place>()).map(\.record)
        if try finishPrevious(capture.id, inbox: inbox, records: records) { return }
        try persist(record, captureID: capture.id, inbox: inbox, into: context)
    }

    private static func finishPrevious(_ id: UUID, inbox: SharedInbox, records: [PlaceRecord]) throws -> Bool {
        if try inbox.receipt(for: id) != nil {
            // Even if the final place was later deleted, a retry must not resurrect it.
            try inbox.acknowledge(id); return true
        }
        if let saved = records.first(where: { $0.id == id }) {
            try inbox.recordReceipt(captureID: id, placeID: saved.id)
            try inbox.acknowledge(id); return true
        }
        return false
    }

    private static func persist(_ record: PlaceRecord, captureID: UUID, inbox: SharedInbox, into context: ModelContext) throws {
        guard record.isValid else { throw InboxError.invalid }
        do {
            if let existing = try context.fetch(FetchDescriptor<Place>()).first(where: { $0.id == record.id }) {
                existing.apply(record)
            } else { context.insert(Place.make(from: record)) }
            try context.save()
        } catch { context.rollback(); throw error }
        // Never remove the pending capture until both the place and the receipt are durable.
        try inbox.recordReceipt(captureID: captureID, placeID: record.id)
        try inbox.acknowledge(captureID)
    }
}
