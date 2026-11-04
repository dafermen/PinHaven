import Foundation

struct MapPoint: Equatable {
    let latitude: Double
    let longitude: Double
    var isValid: Bool {
        latitude.isFinite && longitude.isFinite &&
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
}

enum MapLinks {
    /// Only parses explicit pin coordinates. Never treats a map viewport (@lat,lon)
    /// as the business location, and never fetches or follows untrusted URLs.
    static func point(from text: String) -> MapPoint? {
        if let direct = pair(text) { return direct }
        guard let components = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "https" || components.scheme?.lowercased() == "http",
              let host = components.host?.lowercased(),
              ["maps.apple.com", "google.com", "www.google.com", "maps.google.com"].contains(host)
        else { return nil }
        let items = components.queryItems ?? []
        // q takes precedence over ll (which can be only the map center).
        for key in ["query", "q", "destination"] {
            if let value = items.first(where: { $0.name == key })?.value,
               let point = pair(value) { return point }
        }
        if host == "maps.apple.com",
           let value = items.first(where: { $0.name == "ll" || $0.name == "coordinate" })?.value {
            return pair(value)
        }
        return nil
    }

    private static func pair(_ raw: String) -> MapPoint? {
        let parts = raw.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let point = MapPoint(latitude: lat, longitude: lon)
        return point.isValid ? point : nil
    }

    static func url(latitude: Double, longitude: Double, google: Bool, directions: Bool = false) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = google ? "www.google.com" : "maps.apple.com"
        let coordinates = "\(latitude),\(longitude)"
        if google {
            components.path = directions ? "/maps/dir/" : "/maps/search/"
            components.queryItems = [URLQueryItem(name: "api", value: "1"),
                                    URLQueryItem(name: directions ? "destination" : "query", value: coordinates)]
        } else {
            components.queryItems = [URLQueryItem(name: directions ? "daddr" : "ll", value: coordinates)]
        }
        // Constant scheme/hosts/path plus URLQueryItem guarantee a well-formed URL.
        // Google requires an encoded comma even though RFC URL queries allow it.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: ",", with: "%2C")
        return components.url!
    }

    static func googleAppURL(latitude: Double, longitude: Double, directions: Bool) -> URL {
        var components = URLComponents()
        components.scheme = "comgooglemaps"
        components.host = ""
        components.queryItems = [URLQueryItem(name: directions ? "daddr" : "q",
            value: "\(latitude),\(longitude)")]
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: ",", with: "%2C")
        return components.url!
    }

    static func shareText(name: String, address: String, latitude: Double, longitude: Double) -> String {
        [name, address, url(latitude: latitude, longitude: longitude, google: true).absoluteString]
            .filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
