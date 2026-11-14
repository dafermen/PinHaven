import XCTest
import UIKit
@testable import PinHaven

final class LocationSharingTests: XCTestCase {
    private func record() -> PlaceRecord {
        PlaceRecord(name: "Café de la Plaza", address: "123 Example Street, Example City, NY 10001",
                    notes: "PRIVATE NOTES", category: "PRIVATE CATEGORY", tags: "PRIVATE TAGS",
                    latitude: 40, longitude: -73, isFavorite: true,
                    sourceURL: "https://maps.app.goo.gl/Fixture?g_st=app")
    }

    func testShareContentOmitsPersonalFieldsAndUsesSavedCoordinates() throws {
        let value = record()
        let content = try LocationShareContent(record: value)
        XCTAssertTrue(content.text.contains(value.name)); XCTAssertTrue(content.text.contains(value.address))
        XCTAssertEqual(MapLinks.point(from: content.url.absoluteString), MapPoint(latitude: 40, longitude: -73))
        for field in [value.notes, value.category, value.tags, value.sourceURL] { XCTAssertFalse(content.text.contains(field)) }
        XCTAssertEqual(content.coordinates, "40.000000, -73.000000")
        var empty = value; empty.address = "  "
        XCTAssertFalse(try LocationShareContent(record: empty).text.contains("\n\n"))
    }

    func testExplicitPlaceLinkIsVerifiedAndCleanedWithoutNetwork() async throws {
        var value = record(); value.latitude = 0; value.longitude = 0
        value.sourceURL = "https://www.google.com/maps/place/Example/data=!3d0!4d0?g_st=private&entry=ttu#extra"
        var requests = 0
        let content = try await LocationShareLink.prepare(value) { url in requests += 1; return url }
        XCTAssertEqual(requests, 0)
        XCTAssertEqual(content.url.absoluteString, "https://www.google.com/maps/place/Example/data=!3d0!4d0")
        XCTAssertEqual(content.point, MapPoint(latitude: 0, longitude: 0))
    }

    func testMovedTextualViewportRouteAndUntrustedLinksUseSavedPin() async throws {
        let links = [
            "https://www.google.com/maps/place/Other/data=!3d41!4d-72",
            "https://www.google.com/maps/place/Viewport/@40,-73,14z",
            "https://maps.google.com/?q=Cafe+in+Another+City&ftid=123",
            "https://maps.google.com/?daddr=40,-73&saddr=12,34",
            "https://maps.apple.com/?daddr=40,-73&saddr=12,34",
            "https://evil.example/maps/place/Cafe/data=!3d40!4d-73",
            "https://user:secret@www.google.com/maps/place/Cafe/data=!3d40!4d-73"
        ]
        for link in links {
            var value = record(); value.sourceURL = link
            let content = try await LocationShareLink.prepare(value) { _ in XCTFail("Must not fetch"); throw URLError(.badURL) }
            XCTAssertEqual(content.url, MapLinks.url(latitude: 40, longitude: -73, google: true))
            XCTAssertFalse(content.text.contains("saddr")); XCTAssertFalse(content.text.contains("secret"))
        }
    }

    func testShortLinkRequiresMatchingResolvedPlaceAndDropsQuery() async throws {
        let value = record()
        let match = URL(string: "https://www.google.com/maps/place/Cafe/data=!3d40!4d-73")!
        let content = try await LocationShareLink.prepare(value) { url in
            XCTAssertEqual(url.absoluteString, "https://maps.app.goo.gl/Fixture")
            return match
        }
        XCTAssertEqual(content.url.absoluteString, "https://maps.app.goo.gl/Fixture")
        for target in ["https://www.google.com/maps/place/Other/data=!3d41!4d-72",
                       "https://maps.google.com/?daddr=40,-73&saddr=12,34",
                       "https://maps.google.com/?q=Cafe+City",
                       "https://evil.example/maps/place/Cafe/data=!3d40!4d-73",
                       "https://www.google.com/maps/place/Ambiguous/data=!3d40!4d-73!3d41!4d-72"] {
            let fallback = try await LocationShareLink.prepare(value) { _ in URL(string: target)! }
            XCTAssertEqual(fallback.url, MapLinks.url(latitude: 40, longitude: -73, google: true))
        }
    }

    func testOfflineLinkFallsBackAndCancelledRequestDoesNotShare() async throws {
        let content = try await LocationShareLink.prepare(record()) { _ in throw URLError(.notConnectedToInternet) }
        XCTAssertEqual(content.url, MapLinks.url(latitude: 40, longitude: -73, google: true))
        let value = record()
        let task = Task { try await LocationShareLink.prepare(value) }
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancelled request must not produce a payload") }
        catch is CancellationError { }
        catch { XCTFail("Unexpected error: \(error)") }
    }

    func testInvalidRecordCannotBeShared() throws {
        var value = record(); value.latitude = .nan
        XCTAssertThrowsError(try LocationShareContent(record: value))
        value = record(); value.name = "  "
        XCTAssertThrowsError(try LocationShareContent(record: value))
    }

    @MainActor
    func testCardRendersNormalAndLongTextWithImageAndLink() throws {
        let snapshot = Self.fixtureSnapshot()
        let normal = try LocationShareContent(record: record())
        let image = try LocationMapCardComposer.render(normal, snapshot: snapshot)
        XCTAssertEqual(image.size.width, 1080)
        XCTAssertGreaterThan(image.size.height, snapshot.image.size.height)
        let items = LocationSharePayload(text: normal.text, image: image).activityItems
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.first is UIImage)
        XCTAssertEqual(items.last as? String, normal.text)
        XCTAssertEqual(LocationSharePayload(text: normal.text).activityItems.count, 1)
        try XCTUnwrap(image.pngData()).write(to: FileManager.default.temporaryDirectory.appendingPathComponent("PinHavenCardPreview.png"))

        var long = record()
        long.name = String(repeating: "Café ☕ entrada de la plaza ", count: 12).prefix(200).description
        long.address = String(repeating: "Dirección de prueba, ciudad, estado, código postal. ", count: 50).prefix(2000).description
        let longContent = try LocationShareContent(record: long)
        let longImage = try LocationMapCardComposer.render(longContent, snapshot: snapshot)
        XCTAssertLessThan(longImage.size.height, 1600)
        XCTAssertGreaterThan(longImage.size.height, image.size.height)
        XCTAssertTrue(longContent.text.contains(long.address))
        try XCTUnwrap(longImage.pngData()).write(to: FileManager.default.temporaryDirectory.appendingPathComponent("PinHavenCardLongPreview.png"))
    }

    @MainActor
    func testOffMapInvalidOrMissingSnapshotCannotProduceMisleadingCard() throws {
        let content = try LocationShareContent(record: record())
        let image = Self.fixtureSnapshot().image
        for point in [CGPoint(x: -1, y: 320), CGPoint(x: 540, y: 10), CGPoint(x: CGFloat.nan, y: 320)] {
            XCTAssertThrowsError(try LocationMapCardComposer.render(content, snapshot: LocationMapSnapshot(image: image, pin: point)))
        }
        XCTAssertThrowsError(try LocationMapCardComposer.render(content, snapshot: LocationMapSnapshot(image: UIImage(), pin: .zero)))
    }

    @MainActor
    func testPreparationUsesConfirmedPointAndRecoversFromFailure() async throws {
        var value = record(); value.latitude = 0; value.longitude = 0
        let content = try LocationShareContent(record: value)
        let provider = CardSnapshotFixture()
        let card = LocationMapCard(provider: provider)
        await card.prepare(content)
        XCTAssertEqual(provider.points, [MapPoint(latitude: 0, longitude: 0)])
        XCTAssertNotNil(card.image); XCTAssertFalse(card.isLoading); XCTAssertNil(card.message)
        let preview = card.image
        card.cancel(keepingPreview: true)
        XCTAssertTrue(card.image === preview)
        provider.fail = true
        await card.prepare(content)
        XCTAssertNil(card.image); XCTAssertNotNil(card.message); XCTAssertFalse(card.isLoading)
        XCTAssertTrue(content.text.contains(content.url.absoluteString))
    }

    @MainActor
    func testCancelledMapPreparationIgnoresLateImage() async throws {
        let provider = CardSnapshotFixture(); provider.wait = true
        let card = LocationMapCard(provider: provider)
        let content = try LocationShareContent(record: record())
        let work = Task { await card.prepare(content) }
        for _ in 0..<40 where provider.pending == nil { await Task.yield() }
        XCTAssertNotNil(provider.pending)
        card.cancel()
        provider.finish()
        await work.value
        XCTAssertNil(card.image); XCTAssertFalse(card.isLoading); XCTAssertNil(card.message)
    }

    @MainActor
    func testNewMapWinsOverLatePreviousSnapshot() async throws {
        let provider = CardSnapshotFixture(); provider.wait = true
        let card = LocationMapCard(provider: provider)
        let content = try LocationShareContent(record: record())
        let old = Task { await card.prepare(content) }
        for _ in 0..<40 where provider.pending == nil { await Task.yield() }
        XCTAssertNotNil(provider.pending)
        provider.wait = false
        var value = record(); value.latitude = 41
        await card.prepare(try LocationShareContent(record: value))
        let winningImage = card.image
        XCTAssertNotNil(winningImage)
        provider.finish()
        await old.value
        XCTAssertTrue(card.image === winningImage)
        XCTAssertEqual(provider.points.last?.latitude, 41)
    }

    @MainActor
    func testMapTimeoutRejectsLateResult() async throws {
        let provider = CardSnapshotFixture(); provider.wait = true
        let card = LocationMapCard(provider: provider, timeoutNanoseconds: 5_000_000)
        let content = try LocationShareContent(record: record())
        let work = Task { await card.prepare(content) }
        for _ in 0..<40 where provider.pending == nil { await Task.yield() }
        XCTAssertNotNil(provider.pending)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(card.isLoading); XCTAssertNotNil(card.message)
        provider.finish()
        await work.value
        XCTAssertNil(card.image)
    }

    @MainActor
    fileprivate static func fixtureSnapshot() -> LocationMapSnapshot {
        let size = CGSize(width: 1080, height: 640)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            UIColor(red: 0.92, green: 0.95, blue: 0.94, alpha: 1).setFill()
            renderer.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.71, green: 0.86, blue: 0.73, alpha: 1).setFill()
            renderer.fill(CGRect(x: 90, y: 140, width: 250, height: 210))
            UIColor.white.setFill()
            for x in stride(from: 30, to: 1080, by: 140) { renderer.fill(CGRect(x: x, y: 0, width: 24, height: 640)) }
            for y in stride(from: 70, to: 640, by: 130) { renderer.fill(CGRect(x: 0, y: y, width: 1080, height: 24)) }
            ("MAPA DE PRUEBA · Sin datos reales" as NSString).draw(at: CGPoint(x: 28, y: 596),
                withAttributes: [.font: UIFont.systemFont(ofSize: 25), .foregroundColor: UIColor.darkGray])
        }
        return LocationMapSnapshot(image: image, pin: CGPoint(x: 540, y: 320))
    }
}

@MainActor
private final class CardSnapshotFixture: LocationMapSnapshotProvider {
    var wait = false
    var fail = false
    var points: [MapPoint] = []
    var pending: CheckedContinuation<LocationMapSnapshot, Error>?
    func snapshot(at point: MapPoint) async throws -> LocationMapSnapshot {
        points.append(point)
        if fail { throw URLError(.notConnectedToInternet) }
        if wait { return try await withCheckedThrowingContinuation { pending = $0 } }
        return LocationSharingTests.fixtureSnapshot()
    }
    func cancel() {}
    func finish() {
        let continuation = pending; pending = nil
        continuation?.resume(returning: LocationSharingTests.fixtureSnapshot())
    }
}
