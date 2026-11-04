import XCTest
import SwiftData
import MapKit
import Contacts
@testable import PinHaven

final class PinHavenTests: XCTestCase {
    func testCoordinateBoundariesAndEmptyNames() {
        XCTAssertTrue(PlaceRecord(name: "Origen", latitude: 0, longitude: 0).isValid)
        XCTAssertTrue(PlaceRecord(name: "Borde", latitude: -90, longitude: 180).isValid)
        XCTAssertFalse(PlaceRecord(name: "  \n", latitude: 0, longitude: 0).isValid)
        XCTAssertFalse(PlaceRecord(name: "Error", latitude: 90.01, longitude: 0).isValid)
        XCTAssertFalse(PlaceRecord(name: "Error", latitude: 0, longitude: .infinity).isValid)
        XCTAssertFalse(PlaceRecord(name: "Error", latitude: .nan, longitude: 0).isValid)
    }

    func testSearchIgnoresAccentsAndCase() {
        XCTAssertTrue(PlaceRecord.matches("Café de Diana", query: "CAFE"))
        XCTAssertFalse(PlaceRecord.matches("Restaurante", query: "parque"))
    }

    func testExplicitPinsAndUntrustedLinks() {
        let expected = MapPoint(latitude: 40.7, longitude: -73.9)
        XCTAssertEqual(MapLinks.point(from: "40.7, -73.9"), expected)
        XCTAssertEqual(MapLinks.point(from: "https://maps.apple.com/?ll=40.7,-73.9"), expected)
        XCTAssertEqual(MapLinks.point(from: "https://www.google.com/maps/search/?api=1&query=40.7%2C-73.9"), expected)
        XCTAssertNil(MapLinks.point(from: "https://maps.app.goo.gl/example"))
        XCTAssertNil(MapLinks.point(from: "https://www.google.com/maps/@40.7,-73.9,15z"))
        XCTAssertNil(MapLinks.point(from: "https://evil.example/?q=40.7,-73.9"))
        XCTAssertNil(MapLinks.point(from: "https://maps.apple.com.evil.example/?ll=40.7,-73.9"))
        XCTAssertNil(MapLinks.point(from: "javascript:40.7,-73.9"))
        XCTAssertNil(MapLinks.point(from: "91,0"))
    }

    func testSharedCoordinatesAreDestinationNotViewport() {
        let url = MapLinks.url(latitude: -3.5, longitude: -76.5, google: true, directions: true)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(items?.first(where: { $0.name == "destination" })?.value, "-3.5,-76.5")
        XCTAssertEqual(url.host, "www.google.com")
    }

    func testCoordinateURLsUseEncodedCommaAndRoundTrip() {
        for point in [MapPoint(latitude: 0, longitude: 0), MapPoint(latitude: -3.5, longitude: -76.5)] {
            for directions in [false, true] {
                let url = MapLinks.url(latitude: point.latitude, longitude: point.longitude, google: true, directions: directions)
                XCTAssertTrue(url.absoluteString.contains("%2C"))
                XCTAssertEqual(MapLinks.point(from: url.absoluteString), point)
                let native = MapLinks.googleAppURL(latitude: point.latitude, longitude: point.longitude, directions: directions)
                XCTAssertEqual(native.scheme, "comgooglemaps")
                let items = URLComponents(url: native, resolvingAgainstBaseURL: false)?.queryItems
                XCTAssertEqual(items?.first?.name, directions ? "daddr" : "q")
                XCTAssertEqual(items?.first?.value, "\(point.latitude),\(point.longitude)")
            }
        }
    }

    @MainActor
    func testPostalAddressKeepsCityStateAndZip() {
        let postal = CNMutablePostalAddress()
        postal.street = "123 Example Street"
        postal.city = "Example City"
        postal.state = "NY"
        postal.postalCode = "10001"
        postal.country = "United States"
        postal.isoCountryCode = "US"
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40, longitude: -73), postalAddress: postal)
        let address = AddressSearch.fullAddress(placemark)
        for component in ["123 Example Street", "Example City", "NY", "10001"] {
            XCTAssertTrue(address.contains(component))
        }
        XCTAssertFalse(address.contains("\n"))
    }

    @MainActor
    func testAddressSearchRegionRequiresExplicitValidReference() {
        XCTAssertNil(AddressSearch.region(near: nil))
        XCTAssertNil(AddressSearch.region(near: CLLocationCoordinate2D(latitude: 91, longitude: 0)))
        for coordinate in [CLLocationCoordinate2D(latitude: 0, longitude: 0),
                           CLLocationCoordinate2D(latitude: 40, longitude: -73)] {
            let region = AddressSearch.region(near: coordinate)
            XCTAssertEqual(region?.center.latitude, coordinate.latitude)
            XCTAssertEqual(region?.center.longitude, coordinate.longitude)
            XCTAssertGreaterThan(region?.span.latitudeDelta ?? 0, 0)
            XCTAssertLessThan(region?.span.latitudeDelta ?? 180, 1)
        }
    }

    func testBackupRoundTripAndCorruption() throws {
        let record = PlaceRecord(name: "Café ☕", notes: "Entrada lateral", latitude: 40.7, longitude: -73.9)
        let decoded = try PlaceBackup.decode(PlaceBackup(places: [record]).encoded())
        XCTAssertEqual(decoded.places.first?.id, record.id)
        XCTAssertEqual(decoded.places.first?.notes, record.notes)
        XCTAssertEqual(decoded.places.first?.name, record.name)
        XCTAssertThrowsError(try PlaceBackup.decode(Data("not JSON".utf8)))
        XCTAssertThrowsError(try PlaceBackup.decode(PlaceBackup(schemaVersion: 99, places: []).encoded()))
        XCTAssertThrowsError(try PlaceBackup.decode(PlaceBackup(places: [record, record]).encoded()))
        XCTAssertThrowsError(try PlaceBackup.decode(PlaceBackup(places: [PlaceRecord(name: "", latitude: 0, longitude: 0)]).encoded()))
    }

    @MainActor
    func testImportIsAppendOnlyAndPersists() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Place.self, configurations: configuration)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let record = PlaceRecord(name: "Original", latitude: 40, longitude: -73)
        XCTAssertEqual(try LocalStore.importBackup(PlaceBackup(places: [record]), into: context), 1)
        var changed = record; changed.name = "No debe sobrescribir"
        XCTAssertEqual(try LocalStore.importBackup(PlaceBackup(places: [changed]), into: context), 0)
        let reloadedContext = ModelContext(container)
        let places = try reloadedContext.fetch(FetchDescriptor<Place>())
        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places.first?.name, "Original")
    }

    @MainActor
    func testDiskStoreSurvivesContainerReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let config = ModelConfiguration(url: url, cloudKitDatabase: .none)
        let id = UUID()
        do {
            let first = try ModelContainer(for: Place.self, configurations: config)
            let context = ModelContext(first)
            context.insert(Place(id: id, name: "Mi sitio", latitude: 0, longitude: 0))
            try context.save()
        }
        let second = try ModelContainer(for: Place.self, configurations: config)
        let reloaded = try ModelContext(second).fetch(FetchDescriptor<Place>())
        XCTAssertEqual(reloaded.first?.id, id)
    }
}
