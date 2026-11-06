import SwiftUI
import MapKit

struct MapPicker: View {
    @Environment(\.dismiss) private var dismiss
    let initial: CLLocationCoordinate2D?
    let onSelect: (CLLocationCoordinate2D, String?, String?) -> Void
    @State private var camera: MapCameraPosition
    @State private var selected: CLLocationCoordinate2D?
    @State private var selectedName: String?
    @State private var selectedAddress: String?
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var search: MKLocalSearch?
    @State private var visibleRegion: MKCoordinateRegion?

    init(initial: CLLocationCoordinate2D?, initialQuery: String = "", onSelect: @escaping (CLLocationCoordinate2D, String?, String?) -> Void) {
        self.initial = initial; self.onSelect = onSelect
        _query = State(initialValue: initialQuery)
        _selected = State(initialValue: initial)
        _camera = State(initialValue: initial.map {
            .region(MKCoordinateRegion(center: $0, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        } ?? .automatic)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField("Dirección o establecimiento", text: $query).textFieldStyle(.roundedBorder)
                        .submitLabel(.search).onSubmit { runSearch() }
                    Button { runSearch() } label: { Image(systemName: "magnifyingglass") }
                        .accessibilityLabel("Buscar en el mapa")
                        .disabled(loading || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding()
                if loading { ProgressView("Buscando…").padding(.bottom) }
                if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red).padding() }
                if !results.isEmpty {
                    List(Array(results.enumerated()), id: \.offset) { _, item in
                        Button {
                            selected = item.placemark.coordinate
                            selectedName = item.name
                            selectedAddress = AddressSearch.fullAddress(item.placemark)
                            camera = .region(MKCoordinateRegion(center: item.placemark.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
                            results = []
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "Lugar")
                                Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.frame(maxHeight: 200)
                }
                MapReader { proxy in
                    Map(position: $camera) {
                        if let selected { Marker(selectedName ?? "Punto seleccionado", coordinate: selected) }
                    }
                    .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            selected = coordinate; selectedName = nil; selectedAddress = nil
                        }
                    }
                }
                Text("Toca el mapa para marcar un punto. La búsqueda y la carga del mapa pueden necesitar internet.")
                    .font(.caption).foregroundStyle(.secondary).padding()
            }
            .navigationTitle("Elegir ubicación").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Usar punto") {
                        if let selected { onSelect(selected, selectedName, selectedAddress); dismiss() }
                    }.disabled(selected == nil)
                }
            }
            .task { if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { runSearch() } }
            .onDisappear { search?.cancel() }
        }
    }

    private func runSearch() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !loading else { return }
        loading = true; errorMessage = nil; results = []
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        if let visibleRegion { request.region = visibleRegion }
        let currentSearch = MKLocalSearch(request: request)
        search = currentSearch
        Task { @MainActor in
            defer { loading = false; search = nil }
            do {
                let response = try await currentSearch.start()
                results = response.mapItems
                if results.isEmpty { errorMessage = "No encontramos resultados. Puedes marcar el punto manualmente." }
            } catch { errorMessage = "No se pudo buscar. Verifica la conexión o selecciona un punto manualmente." }
        }
    }
}
