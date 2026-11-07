import Foundation
import MapKit
import Combine

@MainActor
protocol ReverseAddressProvider: AnyObject {
    func addresses(at coordinate: CLLocationCoordinate2D) async throws -> [String]
    func cancel()
}

@MainActor
private final class AppleReverseAddressProvider: ReverseAddressProvider {
    private let geocoder = CLGeocoder()
    func addresses(at coordinate: CLLocationCoordinate2D) async throws -> [String] {
        let results = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        return results.map { AddressSearch.fullAddress(MKPlacemark(placemark: $0)) }
    }
    func cancel() { geocoder.cancelGeocode() }
}

@MainActor
final class PointAddressLookup: ObservableObject {
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?
    private let provider: ReverseAddressProvider
    private var generation = UUID()

    init(provider: ReverseAddressProvider? = nil) { self.provider = provider ?? AppleReverseAddressProvider() }

    func lookup(_ coordinate: CLLocationCoordinate2D) async {
        cancel()
        guard MapPoint(latitude: coordinate.latitude, longitude: coordinate.longitude).isValid else {
            message = "Selecciona un punto válido antes de consultar su dirección."
            return
        }
        let token = generation
        isLoading = true
        let timeout = Task { @MainActor in
            do { try await Task.sleep(nanoseconds: 12_000_000_000) }
            catch { return }
            guard generation == token else { return }
            provider.cancel()
        }
        defer { timeout.cancel(); if generation == token { isLoading = false } }
        do {
            let values = try await provider.addresses(at: coordinate)
            try Task.checkCancellation()
            guard generation == token else { return }
            var seen = Set<String>()
            suggestions = Array(values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count <= 2000 && seen.insert($0).inserted }.prefix(3))
            message = suggestions.isEmpty ? "No encontramos una dirección postal para este punto. Puedes escribirla o dejarla vacía." : nil
        } catch {
            guard generation == token else { return }
            message = "No se pudo consultar la dirección del punto. Revisa la conexión o escríbela manualmente."
        }
    }

    func cancel() {
        generation = UUID()
        provider.cancel()
        suggestions = []
        message = nil
        isLoading = false
    }
}
