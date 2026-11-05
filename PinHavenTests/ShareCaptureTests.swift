import XCTest
import SwiftData
@testable import PinHaven

final class ShareCaptureTests: XCTestCase {
    func testAcceptsOnlySingleHTTPSMapLink() throws {
        let expected = URL(string: "https://maps.app.goo.gl/Example")!
        XCTAssertEqual(IncomingMapLink.extract(from: "Un lugar\n\(expected.absoluteString)"), expected)
        XCTAssertNil(IncomingMapLink.extract(from: "https://maps.app.goo.gl/A https://maps.app.goo.gl/B"))
        for value in ["http://maps.app.goo.gl/A", "https://maps.app.goo.gl.evil.example/A",
                      "https://www.google.com/search?q=home", "https://goo.gl/other/A",
                      "https://user:secret@maps.app.goo.gl/A", "https://maps.app.goo.gl:444/A",
                      "file:///tmp/map", "https://127.0.0.1/maps"] {
            XCTAssertFalse(IncomingMapLink.isAllowed(try XCTUnwrap(URL(string: value))), value)
        }
    }

    func testPlaceDataNeverUsesViewportOrAmbiguousCoordinates() throws {
        let prefix = "https://www.google.com/maps/place/Example/@10,20,14z/"
        XCTAssertNil(IncomingMapLink.point(in: try XCTUnwrap(URL(string: prefix))))
        XCTAssertEqual(IncomingMapLink.point(in: try XCTUnwrap(URL(string: prefix + "data=!3d40.5!4d-73.5"))),
                       MapPoint(latitude: 40.5, longitude: -73.5))
        XCTAssertNil(IncomingMapLink.point(in: try XCTUnwrap(URL(string: prefix + "data=!3d40!4d-73!3d41!4d-72"))))
        XCTAssertNil(IncomingMapLink.point(in: try XCTUnwrap(URL(string: prefix + "data=!3d91!4d-73"))))
        XCTAssertEqual(IncomingMapLink.point(in: URL(string: "https://maps.apple.com/?ll=0,0")!), MapPoint(latitude: 0, longitude: 0))
    }

    func testInboxRejectsInvalidAndKeepsCorruptionForReview() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let inbox = SharedInbox(directory: directory)
        var record = PlaceRecord(name: "Café ☕", latitude: 0, longitude: 0)
        record.sourceURL = "https://maps.apple.com/?ll=0,0"
        let capture = SharedCapture(record: record)
        try inbox.enqueue(capture)
        let file = try XCTUnwrap(inbox.files().first)
        XCTAssertEqual(try inbox.read(file).record, record)
        var future = capture; future.schemaVersion = 99
        XCTAssertThrowsError(try inbox.enqueue(future))
        record.sourceURL = "https://evil.example/"
        XCTAssertThrowsError(try inbox.enqueue(SharedCapture(record: record)))
        try Data("broken".utf8).write(to: file)
        XCTAssertThrowsError(try inbox.read(file))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
    }

    @MainActor
    func testInboxRetriesAfterSaveWithoutDuplicatingOrOverwriting() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let inbox = SharedInbox(directory: directory)
        let container = try ModelContainer(for: Place.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var record = PlaceRecord(name: "Original", latitude: 0, longitude: 0)
        record.sourceURL = "https://maps.apple.com/?ll=0,0"
        try inbox.enqueue(SharedCapture(record: record))
        // Simulate app exit after saving to SwiftData but before removing the inbox entry.
        XCTAssertEqual(try LocalStore.importBackup(PlaceBackup(places: [record]), into: context), 1)
        record.name = "Should not replace"
        try inbox.enqueue(SharedCapture(record: record))
        let result = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(result.added, 0)
        XCTAssertEqual(result.failed, 0)
        XCTAssertTrue(try inbox.files().isEmpty)
        let persisted = try context.fetch(FetchDescriptor<Place>())
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.first?.name, "Original")
        let again = try SharedInboxImport.consume(inbox, into: context)
        XCTAssertEqual(again.added, 0)
    }

    func testRedirectResolutionStopsAtExplicitDestinationWithoutDownloadingPage() async throws {
        let start = URL(string: "https://maps.app.goo.gl/Fixture")!
        let destination = "https://www.google.com/maps/place/Test/data=!3d40!4d-73"
        MapRedirectFixture.reset([start.absoluteString: (302, destination)])
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MapRedirectFixture.self]
        let resolved = try await IncomingMapLink.expanded(start, configuration: config)
        XCTAssertEqual(resolved.absoluteString, destination)
        XCTAssertEqual(MapRedirectFixture.requests().count, 1)
        XCTAssertEqual(MapRedirectFixture.requests().first?.httpMethod, "HEAD")
    }

    func testRedirectResolutionRejectsExternalHostAndCycles() async throws {
        let start = URL(string: "https://maps.app.goo.gl/Fixture")!
        for target in ["https://evil.example/private", "http://maps.google.com/maps", start.absoluteString] {
            MapRedirectFixture.reset([start.absoluteString: (302, target)])
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MapRedirectFixture.self]
            do {
                _ = try await IncomingMapLink.expanded(start, configuration: config)
                XCTFail("Must reject redirect: \(target)")
            } catch { }
            XCTAssertEqual(MapRedirectFixture.requests().count, 1)
        }
    }
}

private final class MapRedirectFixture: URLProtocol {
    private static let lock = NSLock()
    private static var routes: [String: (Int, String)] = [:]
    private static var received: [URLRequest] = []
    static func reset(_ values: [String: (Int, String)]) {
        lock.lock(); defer { lock.unlock() }
        routes = values; received = []
    }
    static func requests() -> [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return received
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.received.append(request)
        let route = Self.routes[request.url!.absoluteString]
        Self.lock.unlock()
        guard let route, let response = HTTPURLResponse(url: request.url!, statusCode: route.0,
            httpVersion: nil, headerFields: ["Location": route.1]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse)); return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
