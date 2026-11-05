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
                        Text("Comprueba que el pin corresponde al lugar. El centro de un mapa no se interpreta como destino.")
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
                    MapPicker(initial: coordinate) { point, name, address in
                        coordinate = point
                        if record.name.isEmpty, let name { record.name = name }
                        if let address { record.address = address }
                    }
                }
                .task { await readIncoming() }
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
            record.name = IncomingMapLink.suggestedName(from: resolved)
            if let point = IncomingMapLink.point(in: resolved) {
                coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            } else {
                message = "El enlace no contiene un punto verificable. Búscalo o márcalo en el mapa antes de guardar."
            }
        } catch is CancellationError { return }
        catch { message = error.localizedDescription }
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
