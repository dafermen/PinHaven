import SwiftUI
import SwiftData
import CoreLocation

struct PlaceEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var addresses = AddressSearch()
    @FocusState private var addressFocused: Bool
    @StateObject private var gps = LocationService()
    let place: Place?
    @State private var draft: PlaceRecord
    @State private var latitudeText: String
    @State private var longitudeText: String
    @State private var showMap = false
    @State private var errorMessage: String?
    @State private var accuracy: Double?
    static let categories = ["Restaurantes", "Familia", "Trabajo", "Compras", "Viajes", "Otros"]

    init(place: Place? = nil) {
        self.place = place
        let record = place?.record ?? PlaceRecord(name: "", latitude: 0, longitude: 0)
        _draft = State(initialValue: record)
        _latitudeText = State(initialValue: place == nil ? "" : String(record.latitude))
        _longitudeText = State(initialValue: place == nil ? "" : String(record.longitude))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("El lugar") {
                    TextField("Nombre para recordarlo", text: $draft.name)
                    TextField("Dirección, ciudad o código postal", text: $draft.address, axis: .vertical)
                        .focused($addressFocused)
                        .onChange(of: draft.address) { _, value in
                            if addressFocused { gps.cancel(); addresses.update(value, near: point) }
                        }
                    if addressFocused {
                        ForEach(Array(addresses.suggestions.enumerated()), id: \.offset) { _, suggestion in
                            Button {
                                Task { @MainActor in
                                    guard let item = await addresses.resolve(suggestion) else { return }
                                    addressFocused = false
                                    setPoint(item.placemark.coordinate)
                                    draft.address = AddressSearch.fullAddress(item.placemark)
                                    if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        draft.name = item.name ?? suggestion.title
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(suggestion.title)
                                    Text(suggestion.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            }.disabled(addresses.isResolving)
                        }
                    }
                    if addresses.isResolving { ProgressView("Completando dirección…") }
                    if let message = addresses.errorMessage {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Elige una sugerencia para actualizar dirección y coordenadas juntas. Incluye ciudad o código postal para distinguir calles con el mismo nombre. Revisa el punto en el mapa antes de guardar.")
                        .font(.caption).foregroundStyle(.secondary)
                    Picker("Categoría", selection: $draft.category) {
                        ForEach(Array(Set(Self.categories + [draft.category])).sorted(), id: \.self) { Text($0) }
                    }
                    Toggle("Favorito", isOn: $draft.isFavorite)
                }
                Section {
                    Button { addressFocused = false; addresses.stop(); gps.request() } label: {
                        Label(gps.isLoading ? "Obteniendo ubicación…" : "Usar mi ubicación actual", systemImage: "location.fill")
                    }.disabled(gps.isLoading)
                    Button { addressFocused = false; addresses.stop(); gps.cancel(); showMap = true } label: {
                        Label("Buscar o seleccionar en el mapa", systemImage: "map")
                    }
                    TextField("Latitud: -90 a 90", text: $latitudeText)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitud: -180 a 180", text: $longitudeText)
                        .keyboardType(.numbersAndPunctuation)
                    if let accuracy {
                        Text("Precisión aproximada: ±\(Int(accuracy)) m. Revisa el punto si necesitas una entrada exacta.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: { Text("Ubicación") } footer: {
                    Text("Usa grados decimales con punto. También puedes guardar un lugar sin dirección postal.")
                }
                Section("Detalles") {
                    TextField("Observaciones", text: $draft.notes, axis: .vertical).lineLimit(3...8)
                    TextField("Etiquetas separadas por comas", text: $draft.tags)
                    TextField("Enlace original (opcional)", text: $draft.sourceURL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    Button("Leer coordenadas del enlace") { parseLink() }
                    Text("Compatible con coordenadas explícitas en enlaces de Apple Maps y Google Maps. Los enlaces cortos requieren seleccionar el punto manualmente.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(place == nil ? "Guardar sitio" : "Editar sitio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }.disabled(addresses.isResolving || draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showMap) {
                MapPicker(initial: point) { coordinate, name, address in
                    setPoint(coordinate)
                    if draft.name.isEmpty, let name { draft.name = name }
                    if let address { draft.address = address }
                }
            }
            .onDisappear { addresses.stop(); gps.cancel() }
            .onReceive(gps.$location.compactMap { $0 }) { fix in
                setPoint(fix.coordinate); accuracy = fix.horizontalAccuracy
            }
            .onReceive(gps.$errorMessage.compactMap { $0 }) { errorMessage = $0 }
            .alert("Revisa los datos", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Aceptar", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var point: CLLocationCoordinate2D? {
        guard let lat = Double(latitudeText), let lon = Double(longitudeText),
              MapPoint(latitude: lat, longitude: lon).isValid else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func setPoint(_ coordinate: CLLocationCoordinate2D) {
        gps.cancel()
        latitudeText = String(coordinate.latitude); longitudeText = String(coordinate.longitude)
        accuracy = nil
    }

    private func parseLink() {
        addressFocused = false; addresses.stop()
        guard let p = MapLinks.point(from: draft.sourceURL) else {
            errorMessage = "Este enlace no contiene un punto compatible. Consérvalo como referencia y selecciona el lugar en el mapa."
            return
        }
        setPoint(CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude))
    }

    private func save() {
        guard let point else { errorMessage = "Selecciona una ubicación o escribe coordenadas válidas."; return }
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.latitude = point.latitude; draft.longitude = point.longitude; draft.updatedAt = .now
        guard draft.isValid else { errorMessage = "Revisa la longitud del nombre, notas y demás campos."; return }
        do {
            if let place { place.apply(draft) } else { context.insert(Place.make(from: draft)) }
            try context.save(); dismiss()
        } catch {
            context.rollback(); errorMessage = "No se pudo guardar. \(error.localizedDescription)"
        }
    }
}
