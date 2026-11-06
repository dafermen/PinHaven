import SwiftUI
import MapKit

struct ShareCaptureView: View {
    let load: () async throws -> String
    let close: () -> Void
    @State private var record = PlaceRecord(name: "", latitude: 0, longitude: 0)
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var loading = true
    @State private var saving = false
    @State private var saved = false
    @State private var choosingPoint = false
    @State private var message: String?
    @State private var candidates: [MKMapItem] = []
    @State private var receivedRoute = false
    @State private var candidateSearch: MKLocalSearch?

    var body: some View {
        NavigationStack {
            if saved {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(.teal)
                    Text("Lugar confirmado").font(.title2)
                    Text("Abre PinHaven para incorporarlo a tu agenda. Tus sitios existentes se conservan.")
                        .multilineTextAlignment(.center)
                    Button("Listo", action: close).buttonStyle(.borderedProminent)
                }.padding()
            } else {
                Form {
                    if loading { ProgressView("Leyendo ubicación…") }
                    if let message { Text(message).foregroundStyle(.secondary) }
                    Section("Revisa el lugar") {
                        TextField("Nombre", text: $record.name)
                        TextField("Dirección (opcional)", text: $record.address, axis: .vertical)
                        Picker("Categoría", selection: $record.category) {
                            ForEach(["Restaurantes", "Familia", "Trabajo", "Compras", "Viajes", "Otros"], id: \.self) { Text($0) }
                        }
                        TextField("Notas (opcional)", text: $record.notes, axis: .vertical)
                        Toggle("Favorito", isOn: $record.isFavorite)
                    }.disabled(loading || saving)
                    if !candidates.isEmpty, coordinate == nil {
                        Section("Elige el resultado correcto") {
                            ForEach(Array(candidates.enumerated()), id: \.offset) { _, item in
                                Button {
                                    coordinate = item.placemark.coordinate
                                    if let name = item.name, !name.isEmpty { record.name = name }
                                    record.address = AddressSearch.fullAddress(item.placemark)
                                    candidates = []
                                    message = "Revisa el pin del lugar elegido y pulsa Guardar."
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name ?? "Lugar")
                                        Text(AddressSearch.fullAddress(item.placemark))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    Section("Punto que se guardará") {
                        if let coordinate {
                            Map(initialPosition: .region(MKCoordinateRegion(center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))) {
                                Marker(record.name.isEmpty ? "Punto recibido" : record.name, coordinate: coordinate)
                            }.frame(height: 170).id("\(coordinate.latitude),\(coordinate.longitude)")
                            Text("\(coordinate.latitude), \(coordinate.longitude)").font(.caption)
                        }
                        Button("Buscar o corregir punto en el mapa") { choosingPoint = true }
                            .disabled(loading || record.sourceURL.isEmpty)
                        Text(receivedRoute
                            ? "Recibiste una ruta. Se guardará el punto de destino, no el origen ni el recorrido. El enlace original seguirá como referencia. Revisa el pin y el nombre."
                            : "Comprueba que el pin corresponde al lugar. El centro de un mapa no se interpreta como destino.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("Enlace recibido") { Text(record.sourceURL).font(.caption).textSelection(.enabled) }
                }
                .navigationTitle("Guardar en PinHaven").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: close) }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(saving ? "Guardando…" : "Guardar") { save() }
                            .disabled(loading || saving || coordinate == nil || record.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .sheet(isPresented: $choosingPoint) {
                    MapPicker(initial: coordinate, initialQuery: [record.name == "Destino compartido" && receivedRoute ? "" : record.name, record.address].filter { !$0.isEmpty }.joined(separator: ", ")) { point, name, address in
                        coordinate = point
                        if record.name.isEmpty, let name { record.name = name }
                        if let address { record.address = address }
                    }
                }
                .task { await readIncoming() }
                .onDisappear { candidateSearch?.cancel() }
            }
        }.tint(.teal)
    }

    @MainActor private func readIncoming() async {
        guard loading else { return }
        defer { loading = false }
        do {
            let text = try await load()
            try Task.checkCancellation()
            guard let original = IncomingMapLink.extract(from: text), original.absoluteString.count <= 4000 else {
                throw IncomingLinkError.unsupported
            }
            record.sourceURL = original.absoluteString
            var resolved = original
            do { resolved = try await IncomingMapLink.expanded(original) }
            catch is CancellationError { return }
            catch { message = "No se pudo resolver el enlace. Puedes elegir el punto en el mapa." }
            try Task.checkCancellation()
            receivedRoute = IncomingMapLink.isRoute(resolved)
            record.name = IncomingMapLink.suggestedName(from: resolved)
            if record.name.isEmpty {
                let title = text.components(separatedBy: .newlines).first { !$0.trimmingCharacters(in: .whitespaces).isEmpty && !$0.contains("://") }
                record.name = String((title ?? "").prefix(200))
            }
            let items = IncomingMapLink.queryItems(in: resolved)
            record.address = String((items.first { $0.name == "address" }?.value ?? "").prefix(2000))
            if let point = IncomingMapLink.point(in: resolved) {
                coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            } else if let query = IncomingMapLink.searchQuery(from: resolved) {
                message = "Google Maps envió nombre y dirección. Buscando coincidencias para que confirmes el lugar…"
                await findCandidates(query)
            } else {
                message = "El enlace no contiene un punto verificable. Búscalo o márcalo en el mapa antes de guardar."
            }
        } catch is CancellationError { return }
        catch { message = error.localizedDescription }
    }

    @MainActor private func findCandidates(_ query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        let search = MKLocalSearch(request: request)
        candidateSearch = search
        let timeout = Task { @MainActor in
            do { try await Task.sleep(nanoseconds: 12_000_000_000) }
            catch { return }
            search.cancel()
        }
        defer { timeout.cancel(); candidateSearch = nil }
        do {
            let response = try await search.start()
            try Task.checkCancellation()
            candidates = Array(response.mapItems.filter { CLLocationCoordinate2DIsValid($0.placemark.coordinate) }.prefix(5))
            message = candidates.isEmpty
                ? "No encontramos coincidencias. Busca o marca el punto en el mapa antes de guardar."
                : "Elige una coincidencia y comprueba su dirección y pin antes de guardar."
        } catch is CancellationError { return }
        catch {
            message = "No se pudo buscar la dirección. Revisa la conexión o elige el punto en el mapa."
        }
    }

    private func save() {
        guard !saving, let coordinate else { return }
        saving = true
        defer { saving = false }
        record.name = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
        record.latitude = coordinate.latitude
        record.longitude = coordinate.longitude
        record.updatedAt = .now
        do {
            try SharedInbox.live().enqueue(SharedCapture(record: record))
            saved = true
        } catch { message = error.localizedDescription }
    }
}
