import SwiftUI
import UIKit
import SwiftData
import MapKit

struct PlaceDetail: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    let place: Place
    @State private var editing = false
    @State private var deleting = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Map(initialPosition: .region(MKCoordinateRegion(center: place.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))) {
                    Marker(place.name, coordinate: place.coordinate)
                }.frame(height: 220).id("\(place.latitude),\(place.longitude)")
                if !place.address.isEmpty { Text(place.address).textSelection(.enabled) }
                Text("\(place.latitude), \(place.longitude)").font(.caption).textSelection(.enabled)
            }
            Section("Detalles") {
                LabeledContent("Categoría", value: place.category)
                if !place.tags.isEmpty { LabeledContent("Etiquetas", value: place.tags) }
                if !place.notes.isEmpty { Text(place.notes).textSelection(.enabled) }
                if !place.sourceURL.isEmpty { Text(place.sourceURL).font(.caption).textSelection(.enabled) }
                LabeledContent("Guardado", value: place.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
            Section("Compartir y llegar") {
                ShareLink(item: MapLinks.shareText(name: place.name, address: place.address,
                    latitude: place.latitude, longitude: place.longitude)) {
                    Label("Compartir sitio", systemImage: "square.and.arrow.up")
                }
                Button("Cómo llegar con Apple Maps") { navigate(google: false) }
                Button("Cómo llegar con Google Maps") { navigate(google: true) }
                Button("Copiar dirección y enlace") {
                    UIPasteboard.general.string = MapLinks.shareText(name: place.name, address: place.address,
                        latitude: place.latitude, longitude: place.longitude)
                }
            }
            Section { Button("Eliminar sitio", role: .destructive) { deleting = true } }
        }
        .navigationTitle(place.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { toggleFavorite() } label: {
                    Image(systemName: place.isFavorite ? "star.fill" : "star")
                }.accessibilityLabel(place.isFavorite ? "Quitar de favoritos" : "Marcar favorito")
                Button("Editar") { editing = true }
            }
        }
        .sheet(isPresented: $editing) { PlaceEditor(place: place) }
        .confirmationDialog("¿Eliminar este sitio?", isPresented: $deleting, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                do { context.delete(place); try context.save(); dismiss() }
                catch { context.rollback(); errorMessage = "No se pudo eliminar el sitio." }
            }
        } message: { Text("Puedes recuperarlo solamente si conservas un respaldo anterior.") }
        .alert("No se completó la operación", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("Aceptar", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func navigate(google: Bool) {
        openURL(MapLinks.url(latitude: place.latitude, longitude: place.longitude, google: google, directions: true))
    }
    private func toggleFavorite() {
        place.isFavorite.toggle(); place.updatedAt = .now
        do { try context.save() } catch { context.rollback(); errorMessage = "No se pudo actualizar el favorito." }
    }
}
