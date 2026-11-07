import XCTest
import MapKit
@testable import PinHaven

final class PointAddressLookupTests: XCTestCase {
    @MainActor
    func testZeroPointAndAddressCleanup() async {
        let provider = ReverseAddressFixture()
        provider.result = ["  123 Example Street  ", "123 Example Street", "", String(repeating: "x", count: 2001)]
        let lookup = PointAddressLookup(provider: provider)
        await lookup.lookup(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        XCTAssertEqual(lookup.suggestions, ["123 Example Street"])
        XCTAssertEqual(provider.points.first?.latitude, 0)
        XCTAssertFalse(lookup.isLoading)
        XCTAssertNil(lookup.message)
        let region = AddressSearch.region(near: CLLocationCoordinate2D(latitude: 40, longitude: -73), meters: 4_000)
        XCTAssertLessThan(region?.span.latitudeDelta ?? 180, 0.1)
        XCTAssertNil(AddressSearch.region(near: CLLocationCoordinate2D(latitude: 40, longitude: -73), meters: -1))
    }

    @MainActor
    func testCancelledLookupIgnoresLateAddress() async {
        let provider = ReverseAddressFixture()
        provider.wait = true
        let lookup = PointAddressLookup(provider: provider)
        let work = Task { await lookup.lookup(CLLocationCoordinate2D(latitude: 40, longitude: -73)) }
        for _ in 0..<20 where provider.pending == nil { await Task.yield() }
        XCTAssertNotNil(provider.pending)
        lookup.cancel()
        provider.finish(["Obsolete address"])
        await work.value
        XCTAssertTrue(lookup.suggestions.isEmpty)
        XCTAssertFalse(lookup.isLoading)
        XCTAssertNil(lookup.message)
    }

    @MainActor
    func testNewPointWinsOverPreviousRequest() async {
        let provider = ReverseAddressFixture()
        provider.wait = true
        let lookup = PointAddressLookup(provider: provider)
        let old = Task { await lookup.lookup(CLLocationCoordinate2D(latitude: 40, longitude: -73)) }
        for _ in 0..<20 where provider.pending == nil { await Task.yield() }
        XCTAssertNotNil(provider.pending)
        provider.wait = false
        provider.result = ["New address"]
        await lookup.lookup(CLLocationCoordinate2D(latitude: 41, longitude: -72))
        provider.finish(["Old address"])
        await old.value
        XCTAssertEqual(lookup.suggestions, ["New address"])
        XCTAssertFalse(lookup.isLoading)
    }

    @MainActor
    func testInvalidPointAndLookupFailureAreRecoverable() async {
        let provider = ReverseAddressFixture()
        let lookup = PointAddressLookup(provider: provider)
        await lookup.lookup(CLLocationCoordinate2D(latitude: 91, longitude: 0))
        XCTAssertTrue(provider.points.isEmpty)
        XCTAssertNotNil(lookup.message)
        provider.fail = true
        await lookup.lookup(CLLocationCoordinate2D(latitude: 40, longitude: -73))
        XCTAssertTrue(lookup.suggestions.isEmpty)
        XCTAssertNotNil(lookup.message)
        XCTAssertFalse(lookup.isLoading)
    }
}

@MainActor
private final class ReverseAddressFixture: ReverseAddressProvider {
    var result: [String] = []
    var wait = false
    var fail = false
    var points: [CLLocationCoordinate2D] = []
    var pending: CheckedContinuation<[String], Error>?
    func addresses(at coordinate: CLLocationCoordinate2D) async throws -> [String] {
        points.append(coordinate)
        if fail { throw URLError(.notConnectedToInternet) }
        if wait { return try await withCheckedThrowingContinuation { pending = $0 } }
        return result
    }
    func cancel() {}
    func finish(_ values: [String]) {
        let continuation = pending; pending = nil
        continuation?.resume(returning: values)
    }
}
