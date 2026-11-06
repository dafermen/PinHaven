import SwiftUI
import MapKit

@MainActor
struct PointAddressSuggestionView: View {
    @Binding var address: String
    let point: CLLocationCoordinate2D?
    var onChoose: () -> Void = {}
    @StateObject private var lookup = PointAddressLookup()

    private var pointKey: MapPoint? {
        point.map { MapPoint(latitude: $0.latitude, longitude: $0.longitude) }
    }

    var body: some View {
        Group {
            Button {
                if let point { Task { await lookup.lookup(point) } }
            } label: {
                Label(lookup.isLoading ? "Consultando dirección…" : "Sugerir dirección de este punto", systemImage: "mappin.and.ellipse")
            }.disabled(pointKey?.isValid != true || lookup.isLoading)
            ForEach(lookup.suggestions, id: \.self) { suggestion in
                Button {
                    onChoose()
                    address = suggestion
                    lookup.cancel()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion)
                        Text("Usar esta dirección sin mover el pin").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if !lookup.suggestions.isEmpty {
                Text("Dirección aproximada del pin. Revisa el número, ciudad y código postal antes de guardarla.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let message = lookup.message { Text(message).font(.caption).foregroundStyle(.secondary) }
        }
        .onChange(of: pointKey) { _, _ in lookup.cancel() }
        .onDisappear { lookup.cancel() }
    }
}
