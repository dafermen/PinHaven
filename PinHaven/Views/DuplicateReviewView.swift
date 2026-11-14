import SwiftUI
import SwiftData

@MainActor
struct DuplicateReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let incoming: PlaceRecord
    let matches: [PlaceDuplicates.Match]
    let editing: Bool
    let commit: (PlaceRecord) throws -> Void
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Hay sitios cercanos o con el mismo enlace. Pueden ser lugares diferentes: revisa antes de decidir.")
                    Text("Nuevo punto: \(incoming.name)").font(.headline)
                    if !incoming.address.isEmpty { Text(incoming.address) }
                }
                ForEach(matches) { match in
                    Section {
                        NavigationLink {
                            DuplicateLocationReview(incoming: incoming, existingID: match.id, editing: editing, commit: commit)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.record.name).font(.headline)
                                Text(match.record.address).font(.subheadline)
                                Text("Aproximadamente \(Int(match.meters.rounded())) m\(match.sameLink ? " · mismo enlace" : "")")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(editing ? "Ver sitio existente" : "Ver sitio o actualizar su ubicación")
                                    .font(.caption)
                            }
                        }
                    }
                }
                Section {
                    Button(editing ? "Guardar cambios de este sitio" : "Guardar otro sitio") { perform(incoming) }
                } footer: {
                    Text(editing ? "Los demás sitios se conservarán." : "Se conservarán ambos sitios con sus propios datos.")
                }
            }
            .navigationTitle("Posibles duplicados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Volver") { dismiss() } } }
            .alert("No se pudo guardar", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Aceptar", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func perform(_ record: PlaceRecord) {
        do { try commit(record) } catch { errorMessage = error.localizedDescription }
    }
}

@MainActor
private struct DuplicateLocationReview: View {
    @Query private var places: [Place]
    let incoming: PlaceRecord
    let existingID: UUID
    let editing: Bool
    let commit: (PlaceRecord) throws -> Void
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let place = places.first(where: { $0.id == existingID }) {
                Section("Sitio guardado") {
                    NavigationLink("Abrir \(place.name)") { PlaceDetail(place: place) }
                    Text(place.address.isEmpty ? "Sin dirección postal" : place.address)
                    Text("\(place.latitude), \(place.longitude)").font(.caption)
                }
                if !editing {
                    Section("Ubicación propuesta") {
                        Text(incoming.address.isEmpty ? "Conservar la dirección actual" : incoming.address)
                        Text("\(incoming.latitude), \(incoming.longitude)").font(.caption)
                        Text("Se conservarán el nombre personal, notas, categoría, etiquetas, favorito y fecha de creación. Se actualizarán el punto, la dirección y el enlace recibido si están disponibles.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Confirmar actualización de ubicación") {
                            do { try commit(PlaceDuplicates.updatingLocation(place.record, with: incoming)) }
                            catch { errorMessage = error.localizedDescription }
                        }
                    }
                }
            } else { Text("Este sitio ya no está en la agenda. Vuelve y guarda un sitio nuevo.") }
        }
        .navigationTitle("Revisar sitio")
        .navigationBarTitleDisplayMode(.inline)
        .alert("No se pudo guardar", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Aceptar", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}
