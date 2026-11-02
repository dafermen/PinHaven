import Foundation
import CoreLocation
import Combine

/// Foreground, one-shot GPS. No background tracking or location history.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    private let manager = CLLocationManager()
    private var timeout: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func request() {
        guard !isLoading else { return }
        errorMessage = nil; location = nil; isLoading = true
        timeout?.invalidate()
        timeout = Timer.scheduledTimer(withTimeInterval: 25, repeats: false) { [weak self] _ in
            self?.fail("No se pudo obtener una ubicación a tiempo. Intenta de nuevo o selecciona un punto en el mapa.")
        }
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: fail("Permiso de ubicación desactivado. Puedes habilitarlo en Ajustes o elegir un punto manualmente.")
        @unknown default: fail("La ubicación no está disponible.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isLoading else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: fail("No se autorizó el acceso a la ubicación. Puedes seleccionar un punto en el mapa.")
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isLoading, let fix = locations.last, fix.horizontalAccuracy >= 0,
              abs(fix.timestamp.timeIntervalSinceNow) < 60 else { return }
        timeout?.invalidate(); timeout = nil
        location = fix; isLoading = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isLoading else { return }
        fail("No se pudo obtener la ubicación: \(error.localizedDescription)")
    }

    private func fail(_ message: String) {
        timeout?.invalidate(); timeout = nil
        manager.stopUpdatingLocation()
        isLoading = false; errorMessage = message
    }

    deinit { timeout?.invalidate() }
}
