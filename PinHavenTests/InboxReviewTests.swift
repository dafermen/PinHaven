import XCTest
import SwiftData
@testable import PinHaven

final class InboxReviewTests: XCTestCase {
    private func record(_ name: String = "Cafe", lat: Double = 40, lon: Double = -73) -> PlaceRecord {
        var value = PlaceRecord(name: name, latitude: lat, longitude: lon)
        value.sourceURL = "https://maps.apple.com/?ll=\(lat),\(lon)"
        return value
    }

    private func inbox() -> SharedInbox {
        SharedInbox(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    }

    @MainActor private func container() throws -> ModelContainer {
        try ModelContainer(for: Place.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }

    func testDuplicateDistanceNameAndSelfExclusion() {
        let incoming = record("  CAFÉ ", lat: 40, lon: -73)
        let near = record("Another business", lat: 40.0001)
        let named = record("cafe", lat: 40.001)
        let unrelated = record("Other", lat: 40.001)
        let far = record("cafe", lat: 41)
        let results = PlaceDuplicates.matches(incoming, among: [incoming, near, named, unrelated, far], excluding: incoming.id)
        XCTAssertEqual(results.map(\.id), [near.id, named.id])
        XCTAssertTrue(results.allSatisfy { $0.meters > 0 })
    }

    func testMapIdentityIgnoresTrackingButNotPlaceOrRoutes() {
        var incoming = record()
        incoming.sourceURL = "https://maps.app.goo.gl/Example?g_st=app"
        var same = record(lat: 41)
        same.sourceURL = "https://maps.app.goo.gl/Example?g_st=other"
        var other = record(lat: 42)
        other.sourceURL = "https://maps.app.goo.gl/Other?g_st=app"
        XCTAssertEqual(PlaceDuplicates.matches(incoming, among: [same, other]).map(\.id), [same.id])
        incoming.sourceURL = "https://maps.google.com/?daddr=40,-73&saddr=10,20"
        same.sourceURL = incoming.sourceURL
        XCTAssertTrue(PlaceDuplicates.matches(incoming, among: [same]).isEmpty)
        incoming.sourceURL = "https://maps.google.com/"
        same.sourceURL = incoming.sourceURL
        XCTAssertTrue(PlaceDuplicates.matches(incoming, among: [same]).isEmpty)
    }

    func testDuplicatesAcceptZeroButRejectInvalidCoordinates() {
        let zero = record(lat: 0, lon: 0)
        XCTAssertEqual(PlaceDuplicates.matches(zero, among: [record(lat: 0, lon: 0)]).count, 1)
        var invalid = zero; invalid.latitude = .nan
        XCTAssertTrue(PlaceDuplicates.matches(invalid, among: [zero]).isEmpty)
        XCTAssertTrue(PlaceDuplicates.matches(zero, among: [invalid]).isEmpty)
    }

    func testLocationUpdatePreservesAllPersonalFields() {
        var existing = record("My cafe")
        existing.notes = "Private note"; existing.tags = "family"; existing.category = "Trabajo"
        existing.isFavorite = true; existing.createdAt = Date(timeIntervalSince1970: 123)
        var incoming = record("Provider name", lat: 41)
        incoming.address = "New address"; incoming.notes = "Should not replace"
        let updated = PlaceDuplicates.updatingLocation(existing, with: incoming)
        XCTAssertEqual(updated.id, existing.id)
        XCTAssertEqual(updated.createdAt, existing.createdAt)
        XCTAssertEqual(updated.name, existing.name)
        XCTAssertEqual(updated.notes, existing.notes)
        XCTAssertEqual(updated.category, existing.category)
        XCTAssertEqual(updated.tags, existing.tags)
        XCTAssertEqual(updated.isFavorite, existing.isFavorite)
        XCTAssertEqual(updated.latitude, incoming.latitude)
        XCTAssertEqual(updated.address, incoming.address)
        XCTAssertEqual(updated.sourceURL, incoming.sourceURL)
        incoming.address = "  "; incoming.sourceURL = ""
        existing.address = "Keep address"
        let sparse = PlaceDuplicates.updatingLocation(existing, with: incoming)
        XCTAssertEqual(sparse.address, existing.address)
        XCTAssertEqual(sparse.sourceURL, existing.sourceURL)
    }

    @MainActor func testAutomaticImportHoldsPotentialDuplicateAndAcceptsDistinctPlace() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        let existing = record("Existing")
        _ = try LocalStore.importBackup(PlaceBackup(places: [existing]), into: context)
        let duplicate = record("Different name", lat: 40.0001)
        let distinct = record("Distant", lat: 42)
        try inbox.enqueue(SharedCapture(record: duplicate)); try inbox.enqueue(SharedCapture(record: distinct))
        let result = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(result.added, 1); XCTAssertEqual(result.duplicates, 1); XCTAssertEqual(result.failed, 0)
        XCTAssertEqual(try inbox.files().map { try inbox.read($0).id }, [duplicate.id])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Place>()).count, 2)
        XCTAssertEqual(try inbox.receipt(for: distinct.id)?.placeID, distinct.id)
    }

    @MainActor func testExplicitKeepBothAndRepeatedCaptureDoNotOverwrite() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        let existing = record("Original"); var received = record("Second")
        _ = try LocalStore.importBackup(PlaceBackup(places: [existing]), into: context)
        try inbox.enqueue(SharedCapture(record: received))
        try SharedInboxImport.accept(received, captureID: received.id, inbox: inbox, into: context)
        received.name = "Changed retry"
        try inbox.enqueue(SharedCapture(record: received))
        _ = try SharedInboxImport.consume(inbox, into: context)
        let records = try context.fetch(FetchDescriptor<Place>()).map(\.record)
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.first(where: { $0.id == received.id })?.name, "Second")
        XCTAssertEqual(records.first(where: { $0.id == existing.id })?.name, "Original")
        XCTAssertTrue(try inbox.files().isEmpty)
    }

    @MainActor func testExplicitUpdateReceiptStopsRetryAndResurrection() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        var existing = record("Personal name"); existing.notes = "Keep me"
        let received = record("Received", lat: 40.0001)
        _ = try LocalStore.importBackup(PlaceBackup(places: [existing]), into: context)
        try inbox.enqueue(SharedCapture(record: received))
        try SharedInboxImport.accept(PlaceDuplicates.updatingLocation(existing, with: received),
                                     captureID: received.id, inbox: inbox, into: context)
        XCTAssertEqual(try inbox.receipt(for: received.id)?.placeID, existing.id)
        let saved = try XCTUnwrap(context.fetch(FetchDescriptor<Place>()).first)
        XCTAssertEqual(saved.name, existing.name); XCTAssertEqual(saved.notes, existing.notes)
        XCTAssertEqual(saved.latitude, received.latitude)
        try inbox.enqueue(SharedCapture(record: received))
        let retry = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(retry.added, 0); XCTAssertEqual(retry.failed, 0)
        context.delete(saved); try context.save()
        try inbox.enqueue(SharedCapture(record: received))
        _ = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Place>()).isEmpty)
        XCTAssertTrue(try inbox.files().isEmpty)
    }

    @MainActor func testReceiptWriteFailureRetainsCaptureAndRetryDoesNotDuplicate() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        let capture = SharedCapture(record: record())
        try inbox.enqueue(capture)
        let blocker = inbox.directory.appendingPathComponent("Processed")
        try Data("not a directory".utf8).write(to: blocker)
        let first = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(first.failed, 1)
        XCTAssertEqual(try inbox.files().count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Place>()).count, 0)
        try FileManager.default.removeItem(at: blocker)
        let retry = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(retry.added, 1); XCTAssertEqual(retry.failed, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Place>()).count, 1)
        XCTAssertTrue(try inbox.files().isEmpty)
    }

    @MainActor func testCorruptEntryIsRetainedUntilExplicitDiscard() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container)
        try inbox.enqueue(SharedCapture(record: record()))
        let file = try XCTUnwrap(inbox.files().first)
        try Data("broken".utf8).write(to: file)
        XCTAssertEqual(try SharedInboxImport.consume(inbox, into: context).failed, 1)
        XCTAssertEqual(try inbox.files(), [file])
        XCTAssertThrowsError(try inbox.discard(inbox.directory))
        XCTAssertThrowsError(try inbox.discard(inbox.directory.appendingPathComponent("../outside.json")))
        try inbox.discard(file)
        XCTAssertTrue(try inbox.files().isEmpty)
    }

    @MainActor func testInterruptedUpdateStaysForReviewWithoutCreatingAnotherSite() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        let existing = record("Personal name")
        let received = record("Provider", lat: 40.0001)
        _ = try LocalStore.importBackup(PlaceBackup(places: [existing]), into: context)
        try inbox.enqueue(SharedCapture(record: received))
        // Simulate exit after saving a corrected, distant point but before the completion receipt.
        var corrected = received; corrected.latitude = 42; corrected.sourceURL = ""
        let updated = PlaceDuplicates.updatingLocation(existing, with: corrected)
        try inbox.recordReceipt(captureID: received.id, placeID: existing.id, completed: false)
        let target = try XCTUnwrap(context.fetch(FetchDescriptor<Place>()).first)
        target.apply(updated); try context.save()
        let retry = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(retry.added, 0); XCTAssertEqual(retry.failed, 1)
        XCTAssertEqual(try inbox.files().count, 1)
        let saved = try context.fetch(FetchDescriptor<Place>())
        XCTAssertEqual(saved.count, 1); XCTAssertEqual(saved.first?.latitude, corrected.latitude)
        XCTAssertEqual(saved.first?.name, existing.name)
        try SharedInboxImport.accept(updated, captureID: received.id, inbox: inbox, into: context)
        XCTAssertTrue(try inbox.files().isEmpty)
        XCTAssertEqual(try inbox.receipt(for: received.id)?.completed, true)
    }

    @MainActor func testIntentWithoutSavedPlaceRequiresExplicitReview() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        let received = record()
        try inbox.enqueue(SharedCapture(record: received))
        try inbox.recordReceipt(captureID: received.id, placeID: received.id, completed: false)
        let retry = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(retry.failed, 1); XCTAssertEqual(retry.added, 0)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Place>()).isEmpty)
        try SharedInboxImport.accept(received, captureID: received.id, inbox: inbox, into: context)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Place>()).count, 1)
        XCTAssertTrue(try inbox.files().isEmpty)
    }

    @MainActor func testInvalidReviewDoesNotMutateStoreOrAcknowledge() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let container = try container(); let context = ModelContext(container); context.autosaveEnabled = false
        let received = record()
        try inbox.enqueue(SharedCapture(record: received))
        var invalid = received; invalid.name = "  "
        XCTAssertThrowsError(try SharedInboxImport.accept(invalid, captureID: received.id, inbox: inbox, into: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<Place>()).isEmpty)
        XCTAssertEqual(try inbox.files().count, 1)
        XCTAssertNil(try inbox.receipt(for: received.id))
    }

    func testReceiptValidationAndDiscardDoNotFollowSymbolicLinks() throws {
        let inbox = inbox(); defer { try? FileManager.default.removeItem(at: inbox.directory) }
        let capture = SharedCapture(record: record())
        try inbox.enqueue(capture)
        let original = try XCTUnwrap(inbox.files().first)
        let link = inbox.directory.appendingPathComponent(UUID().uuidString + ".json")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: original)
        XCTAssertThrowsError(try inbox.read(link))
        try inbox.discard(link)
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        try inbox.recordReceipt(captureID: capture.id, placeID: capture.id)
        let receipt = inbox.directory.appendingPathComponent("Processed/\(capture.id.uuidString).json")
        try Data(repeating: 0, count: 4097).write(to: receipt)
        XCTAssertThrowsError(try inbox.receipt(for: capture.id))
    }
}
