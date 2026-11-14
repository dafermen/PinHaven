import Foundation
import CoreLocation

/// Deliberately contains no notes, tags, category, favorite or route origin.
struct LocationShareContent {
    let name: String
    let address: String
    let point: MapPoint
    let url: URL

    init(record: PlaceRecord, url: URL? = nil) throws {
        guard record.isValid else { throw LocationShareError.invalidPoint }
        name = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
        address = record.address.trimmingCharacters(in: .whitespacesAndNewlines)
        point = MapPoint(latitude: record.latitude, longitude: record.longitude)
        self.url = url ?? MapLinks.url(latitude: record.latitude, longitude: record.longitude, google: true)
    }

    var text: String { [name, address, url.absoluteString].filter { !$0.isEmpty }.joined(separator: "\n") }
    var coordinates: String {
        String(format: "%.6f, %.6f", locale: Locale(identifier: "en_US_POSIX"), point.latitude, point.longitude)
    }
}

enum LocationShareLink {
    /// Reuse a Google place link only after verifying its explicit pin against the saved point.
    /// Failed/offline resolution falls back to the saved coordinates, never a textual guess.
    static func prepare(_ record: PlaceRecord,
                        expand: (URL) async throws -> URL = { try await IncomingMapLink.expanded($0) }) async throws -> LocationShareContent {
        let fallback = try LocationShareContent(record: record)
        try Task.checkCancellation()
        guard let original = URL(string: record.sourceURL), IncomingMapLink.isAllowed(original),
              !IncomingMapLink.isRoute(original),
              var parts = URLComponents(url: original, resolvingAgainstBaseURL: false) else { return fallback }
        let host = original.host?.lowercased() ?? ""
        let short = host == "maps.app.goo.gl" || (host == "goo.gl" && original.path.hasPrefix("/maps/"))
        let place = ["www.google.com", "google.com", "maps.google.com"].contains(host)
            && original.path.hasPrefix("/maps/place/")
        guard short || place else { return fallback }
        // No app tracking, fragments, route parameters or unrelated query data leave PinHaven.
        parts.query = nil; parts.fragment = nil
        guard let clean = parts.url else { return fallback }
        var resolved = clean
        if short {
            do { resolved = try await expand(clean) }
            catch {
                try Task.checkCancellation()
                return fallback
            }
        }
        try Task.checkCancellation()
        guard IncomingMapLink.isAllowed(resolved), !IncomingMapLink.isRoute(resolved),
              ["www.google.com", "google.com", "maps.google.com"].contains(resolved.host?.lowercased() ?? ""),
              resolved.path.hasPrefix("/maps/place/"), let target = IncomingMapLink.point(in: resolved),
              distance(target, fallback.point) <= 1 else { return fallback }
        return try LocationShareContent(record: record, url: clean)
    }

    private static func distance(_ lhs: MapPoint, _ rhs: MapPoint) -> Double {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }
}

enum LocationShareError: LocalizedError {
    case invalidPoint, unavailableMap
    var errorDescription: String? {
        switch self {
        case .invalidPoint: return "Revisa los datos del sitio y selecciona un punto válido antes de compartir."
        case .unavailableMap: return "No se pudo preparar el mapa. Reintenta con conexión o utiliza Compartir enlace."
        }
    }
}
