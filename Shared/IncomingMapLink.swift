import Foundation

enum IncomingMapLink {
    static let hosts: Set<String> = ["maps.app.goo.gl", "goo.gl", "maps.google.com", "google.com", "www.google.com", "maps.apple.com"]

    static func isAllowed(_ url: URL) -> Bool {
        guard url.absoluteString.count <= 8192, url.scheme?.lowercased() == "https",
              url.user == nil, url.password == nil, url.port == nil || url.port == 443,
              let host = url.host?.lowercased(), hosts.contains(host) else { return false }
        if host == "google.com" || host == "www.google.com" { return url.path == "/maps" || url.path.hasPrefix("/maps/") }
        if host == "goo.gl" { return url.path.hasPrefix("/maps/") }
        return true
    }

    static func extract(from text: String) -> URL? {
        guard text.utf8.count <= 32_768 else { return nil }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
           let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)), isAllowed(url) { return url }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let urls = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap(\.url).filter(isAllowed)
        let unique = Set(urls)
        return unique.count == 1 ? unique.first : nil
    }

    static func point(in url: URL) -> MapPoint? {
        guard isAllowed(url) else { return nil }
        if isRoute(url) {
            guard let destination = routeDestination(in: url), !destination.contains("://") else { return nil }
            return MapLinks.point(from: destination)
        }
        if let point = MapLinks.point(from: url.absoluteString) { return point }
        guard let host = url.host?.lowercased(), host.contains("google"),
              url.path.hasPrefix("/maps/place/"),
              let pattern = try? NSRegularExpression(pattern: "!3d(-?[0-9]+(?:\\.[0-9]+)?)!4d(-?[0-9]+(?:\\.[0-9]+)?)") else { return nil }
        // Google's explicit place data is distinct from the @lat,lon camera viewport.
        let value = url.path
        let matches = pattern.matches(in: value, range: NSRange(value.startIndex..., in: value))
        guard matches.count == 1, let match = matches.first,
              let latRange = Range(match.range(at: 1), in: value), let lonRange = Range(match.range(at: 2), in: value),
              let lat = Double(value[latRange]), let lon = Double(value[lonRange]) else { return nil }
        let point = MapPoint(latitude: lat, longitude: lon)
        return point.isValid ? point : nil
    }

    // Decode HTML-form spaces before percent decoding, preserving a literal %2B (e.g. C++).
    static func queryItems(in url: URL) -> [URLQueryItem] {
        guard isAllowed(url), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return [] }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%20")
        return components.queryItems ?? []
    }

    static func isRoute(_ url: URL) -> Bool {
        guard isAllowed(url), let host = url.host?.lowercased(),
              ["maps.google.com", "google.com", "www.google.com", "maps.apple.com"].contains(host) else { return false }
        return queryItems(in: url).contains { ["daddr", "destination"].contains($0.name) }
    }

    private static func routeDestination(in url: URL) -> String? {
        let values = queryItems(in: url).filter { ["daddr", "destination"].contains($0.name) }
            .map { ($0.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
        guard Set(values).count == 1, let value = values.first, !value.isEmpty else { return nil }
        return value
    }

    static func searchQuery(from url: URL) -> String? {
        guard isAllowed(url), let host = url.host?.lowercased(),
              ["maps.google.com", "google.com", "www.google.com", "maps.apple.com"].contains(host) else { return nil }
        if isRoute(url) {
            guard let value = routeDestination(in: url), value.count <= 2000, !value.contains("://") else { return nil }
            let parts = value.split(separator: ",", omittingEmptySubsequences: false)
            // Invalid coordinate pairs must not turn into geocoding queries or fall back to the origin.
            if parts.count == 2, parts.allSatisfy({ Double($0.trimmingCharacters(in: .whitespaces)) != nil }) { return nil }
            return value
        }
        let items = queryItems(in: url)
        for key in ["query", "q", "address"] {
            if let raw = items.first(where: { $0.name == key })?.value {
                let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty, value.count <= 2000, MapLinks.point(from: value) == nil { return value }
            }
        }
        return nil
    }

    static func suggestedName(from url: URL) -> String {
        guard isAllowed(url) else { return "" }
        if isRoute(url) { return String((searchQuery(from: url) ?? "Destino compartido").prefix(200)) }
        if !url.path.hasPrefix("/maps/place/") {
            if let name = queryItems(in: url).first(where: { $0.name == "name" })?.value { return String(name.prefix(200)) }
            return String((searchQuery(from: url) ?? "").prefix(200))
        }
        return String(url.path.dropFirst("/maps/place/".count).split(separator: "/").first ?? "")
            .replacingOccurrences(of: "+", with: " ").prefix(200).description
    }

    /// Resolve redirects only: never download or scrape the Google Maps page.
    static func expanded(_ original: URL, configuration: URLSessionConfiguration = .ephemeral) async throws -> URL {
        guard isAllowed(original) else { throw IncomingLinkError.unsupported }
        if point(in: original) != nil || searchQuery(from: original) != nil { return original }
        let config = configuration
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        config.urlCache = nil
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config, delegate: NoMapRedirects(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let deadline = Date().addingTimeInterval(15)
        var current = original
        var visited = Set<URL>()
        for _ in 0..<6 {
            try Task.checkCancellation()
            guard isAllowed(current), visited.insert(current).inserted else { throw IncomingLinkError.unsupported }
            if point(in: current) != nil || searchQuery(from: current) != nil { return current }
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else { throw URLError(.timedOut) }
            var request = URLRequest(url: current, timeoutInterval: remaining)
            request.httpMethod = "HEAD"
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw IncomingLinkError.unresolved }
            if [301, 302, 303, 307, 308].contains(http.statusCode) {
                guard let location = http.value(forHTTPHeaderField: "Location"),
                      let next = URL(string: location, relativeTo: current)?.absoluteURL, isAllowed(next) else {
                    throw IncomingLinkError.unsupported
                }
                current = next
            } else if (200...299).contains(http.statusCode) {
                return current
            } else { throw IncomingLinkError.unresolved }
        }
        throw IncomingLinkError.unresolved
    }
}

private final class NoMapRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil) // Validate every next host before making another request.
    }
}

enum IncomingLinkError: LocalizedError {
    case unsupported, unresolved
    var errorDescription: String? {
        switch self {
        case .unsupported: return "Comparte un solo enlace HTTPS de Google Maps o Apple Maps."
        case .unresolved: return "El enlace no identifica un punto. Búscalo o selecciónalo en el mapa."
        }
    }
}
