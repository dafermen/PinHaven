import SwiftUI
import SwiftData
import MapKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var inboxMessage: String?
    @Query(sort: \Place.updatedAt, order: .reverse) private var places: [Place]
    @State private var query = ""
    @State private var category = "Todas"
    @State private var favoritesOnly = false
    @State private var sortByName = false
    @State private var mapMode = false
    @State private var adding = false

    private var filtered: [Place] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let selected = places.filter { place in
            (!favoritesOnly || place.isFavorite) && (category == "Todas" || place.category == category) &&
            (text.isEmpty || PlaceRecord.matches([place.name, place.address, place.notes, place.tags, place.category]
                .joined(separator: " "), query: text))
        }
        return sortByName ? selected.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } : selected
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Menu {
                        Picker("Categoría", selection: $category) {
                            Text("Todas").tag("Todas")
                            ForEach(Array(Set(places.map(\.category))).sorted(), id: \.self) { Text($0).tag($0) }
                        }
                        Toggle("Ordenar por nombre", isOn: $sortByName)
                    } label: { Label(category, systemImage: "line.3.horizontal.decrease.circle") }
                    Spacer()
                    Toggle(isOn: $favoritesOnly) { Label("Favoritos", systemImage: "star.fill") }
                        .toggleStyle(.button)
                }.padding(.horizontal).padding(.vertical, 8)
                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label(places.isEmpty ? "Tu agenda de lugares" : "Sin resultados", systemImage: "mappin.and.ellipse")
                    } description: {
                        Text(places.isEmpty ? "Guarda un restaurante, una entrada o cualquier punto que quieras recordar." : "Prueba otra búsqueda o cambia los filtros.")
                    } actions: {
                        if places.isEmpty { Button("Guardar mi primer sitio") { adding = true }.buttonStyle(.borderedProminent) }
                        else { Button("Limpiar filtros") { query = ""; category = "Todas"; favoritesOnly = false } }
                    }
                } else if mapMode {
                    Map {
                        ForEach(filtered) { place in
                            Annotation(place.name, coordinate: place.coordinate) {
                                NavigationLink {
                                    PlaceDetail(place: place)
                                } label: {
                                    Image(systemName: place.isFavorite ? "star.circle.fill" : "mappin.circle.fill")
                                        .font(.title).foregroundStyle(.teal).background(.background, in: Circle())
                                }.accessibilityLabel("Abrir \(place.name)")
                            }
                        }
                    }
                } else {
                    List(filtered) { place in
                        NavigationLink {
                            PlaceDetail(place: place)
                        } label: {
                            HStack {
                                Image(systemName: place.isFavorite ? "star.fill" : "mappin.circle.fill")
                                    .foregroundStyle(place.isFavorite ? .orange : .teal)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name).font(.headline)
                                    Text(place.address.isEmpty ? place.category : place.address)
                                        .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                    if !place.notes.isEmpty { Text(place.notes).font(.caption).lineLimit(1).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("PinHaven")
            .searchable(text: $query, prompt: "Nombre, dirección, notas o etiquetas")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { BackupView() } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Datos y privacidad")
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { mapMode.toggle() } label: { Image(systemName: mapMode ? "list.bullet" : "map") }
                        .accessibilityLabel(mapMode ? "Ver lista" : "Ver mapa")
                    Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Guardar sitio")
                }
            }
            .sheet(isPresented: $adding) { PlaceEditor() }
            .task { importSharedPlaces() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { importSharedPlaces() } }
            .alert("Lugares compartidos", isPresented: Binding(get: { inboxMessage != nil }, set: { if !$0 { inboxMessage = nil } })) {
                Button("Aceptar", role: .cancel) { inboxMessage = nil }
            } message: { Text(inboxMessage ?? "") }
        }
    }

    private func importSharedPlaces() {
        do {
            let result = try SharedInboxImport.consume(SharedInbox.live(), into: context)
            if result.failed > 0 {
                inboxMessage = "Se incorporaron \(result.added) lugares. Hay \(result.failed) entradas pendientes que no se pudieron incorporar; se conservaron para revisión."
            } else if result.added > 0 {
                inboxMessage = "Se incorporaron \(result.added) lugares compartidos a tu agenda."
            }
        } catch { inboxMessage = error.localizedDescription }
    }
}
