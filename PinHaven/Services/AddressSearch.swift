import Foundation
import Combine
import MapKit
import Contacts

/// Suggestions are hints only; resolve the chosen result before changing the draft.
@MainActor
final class AddressSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var isResolving = false
    @Published private(set) var errorMessage: String?
    private var completer: MKLocalSearchCompleter?
    private var search: MKLocalSearch?
    private var generation = UUID()
    private var searchRegion: MKCoordinateRegion?

    func update(_ text: String, near coordinate: CLLocationCoordinate2D?, meters: Double = 40_000) {
        stop()
        errorMessage = nil
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else { return }
        let next = MKLocalSearchCompleter()
        next.delegate = self
        next.resultTypes = [.address, .pointOfInterest]
        searchRegion = Self.region(near: coordinate, meters: meters)
        if let searchRegion {
            next.region = searchRegion
            // Keep Xcode 15/iOS 17 builds supported; strict regional scope starts at iOS 18.
            #if compiler(>=6.0)
            if #available(iOS 18.0, *) { next.regionPriority = .required }
            #endif
        }
        completer = next
        next.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard completer === self.completer else { return }
        suggestions = Array(completer.results.prefix(6))
        errorMessage = suggestions.isEmpty ? "Sin sugerencias. Añade ciudad, estado o código postal, o elige un punto en el mapa." : nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        guard completer === self.completer else { return }
        suggestions = []
        errorMessage = "No se pudieron cargar sugerencias. Revisa la conexión o usa el mapa."
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> MKMapItem? {
        stop()
        let token = generation
        isResolving = true
        errorMessage = nil
        let request = MKLocalSearch.Request(completion: completion)
        if let searchRegion {
            request.region = searchRegion
            #if compiler(>=6.0)
            if #available(iOS 18.0, *) { request.regionPriority = .required }
            #endif
        }
        let current = MKLocalSearch(request: request)
        search = current
        let timeout = Task { @MainActor in
            do { try await Task.sleep(nanoseconds: 15_000_000_000) }
            catch { return }
            guard generation == token else { return }
            current.cancel()
        }
        defer {
            timeout.cancel()
            if generation == token { isResolving = false; search = nil }
        }
        do {
            let response = try await current.start()
            guard generation == token else { return nil }
            // Do not silently choose an arbitrary match if the completion is ambiguous.
            guard response.mapItems.count == 1, let item = response.mapItems.first,
                  CLLocationCoordinate2DIsValid(item.placemark.coordinate) else {
                errorMessage = "El resultado no identifica un único punto. Añade ciudad o código postal, o selecciónalo en el mapa."
                return nil
            }
            return item
        } catch {
            guard generation == token else { return nil }
            errorMessage = "No se pudo resolver la dirección. Reintenta o selecciona el punto en el mapa."
            return nil
        }
    }

    func stop() {
        generation = UUID()
        completer?.delegate = nil
        completer?.cancel()
        completer = nil
        search?.cancel()
        search = nil
        suggestions = []
        isResolving = false
    }

    /// A 40 km square around an explicit search reference, never an implicit 0,0.
    static func region(near coordinate: CLLocationCoordinate2D?, meters: Double = 40_000) -> MKCoordinateRegion? {
        guard let coordinate, CLLocationCoordinate2DIsValid(coordinate), meters.isFinite, meters > 0 else { return nil }
        return MKCoordinateRegion(center: coordinate, latitudinalMeters: meters, longitudinalMeters: meters)
    }

    static func fullAddress(_ placemark: MKPlacemark) -> String {
        if let postal = placemark.postalAddress {
            let formatted = CNPostalAddressFormatter.string(from: postal, style: .mailingAddress)
                .components(separatedBy: .newlines).filter { !$0.isEmpty }.joined(separator: ", ")
            if !formatted.isEmpty { return formatted }
        }
        return placemark.title ?? ""
    }
}
