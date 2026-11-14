import Foundation
import CoreLocation

/// A warning, never proof of identity: neighbouring businesses may share a building.
enum PlaceDuplicates {
    struct Match: Identifiable {
        let record: PlaceRecord
        let meters: Double
        let sameLink: Bool
        var id: UUID { record.id }
    }

    static func matches(_ incoming: PlaceRecord, among records: [PlaceRecord], excluding id: UUID? = nil) -> [Match] {
        guard incoming.isValid else { return [] }
        let point = CLLocation(latitude: incoming.latitude, longitude: incoming.longitude)
        let link = mapIdentity(incoming.sourceURL)
        return records.compactMap { record -> Match? in
            guard record.id != id, record.isValid else { return nil }
            let meters = point.distance(from: CLLocation(latitude: record.latitude, longitude: record.longitude))
            let sameLink = link != nil && link == mapIdentity(record.sourceURL)
            let sameName = normalized(incoming.name) == normalized(record.name)
            guard sameLink || meters <= 50 || (meters <= 200 && sameName) else { return nil }
            return Match(record: record, meters: meters, sameLink: sameLink)
        }.sorted {
            if $0.sameLink != $1.sameLink { return $0.sameLink }
            if $0.meters != $1.meters { return $0.meters < $1.meters }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    /// Updating a location must retain personal descriptions and the original identity.
    static func updatingLocation(_ existing: PlaceRecord, with incoming: PlaceRecord) -> PlaceRecord {
        var result = existing
        result.latitude = incoming.latitude; result.longitude = incoming.longitude
        if !incoming.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { result.address = incoming.address }
        if !incoming.sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { result.sourceURL = incoming.sourceURL }
        result.updatedAt = .now
        return result
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es"))
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private static func mapIdentity(_ text: String) -> String? {
        guard let url = URL(string: text), IncomingMapLink.isAllowed(url),
              var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        // Route links may identify an origin and a destination: distance is safer here.
        guard !IncomingMapLink.isRoute(url) else { return nil }
        parts.fragment = nil
        parts.host = parts.host?.lowercased()
        let tracking: Set<String> = ["g_st", "g_ep", "skid", "entry", "lucs", "shh"]
        let items = (parts.queryItems ?? []).filter { !tracking.contains($0.name.lowercased()) }
            .sorted { $0.name == $1.name ? ($0.value ?? "") < ($1.value ?? "") : $0.name < $1.name }
        parts.queryItems = items.isEmpty ? nil : items
        // A bare map homepage is not an identity for a place.
        guard !items.isEmpty || (parts.path != "" && parts.path != "/" && parts.path != "/maps" && parts.path != "/maps/") else { return nil }
        return parts.string
    }
}
