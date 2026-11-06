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

    static func suggestedName(from url: URL) -> String {
        guard isAllowed(url) else { return "" }
        if !url.path.hasPrefix("/maps/place/") {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            for key in ["name", "query", "q"] {
                if let value = items.first(where: { $0.name == key })?.value,
                   MapLinks.point(from: value) == nil { return String(value.prefix(200)) }
            }
            return ""
        }
        return String(url.path.dropFirst("/maps/place/".count).split(separator: "/").first ?? "")
            .replacingOccurrences(of: "+", with: " ").prefix(200).description
    }

    /// Resolve redirects only: never download or scrape the Google Maps page.
    static func expanded(_ original: URL, configuration: URLSessionConfiguration = .ephemeral) async throws -> URL {
        guard isAllowed(original) else { throw IncomingLinkError.unsupported }
        if point(in: original) != nil { return original }
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
            if point(in: current) != nil { return current }
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
