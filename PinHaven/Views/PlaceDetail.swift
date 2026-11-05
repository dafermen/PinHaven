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
    @State private var showingGoogleWeb = false
    @State private var sharePayload: LocationSharePayload?
    @State private var sharingFailed = false
    @State private var showingCopyNotice = false
    @State private var copyNoticeID = UUID()
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
                Button {
                    sharingFailed = false
                    sharePayload = LocationSharePayload(text: MapLinks.shareText(name: place.name,
                        address: place.address, latitude: place.latitude, longitude: place.longitude))
                } label: {
                    Label("Compartir con otras apps", systemImage: "square.and.arrow.up")
                }
                Button("Cómo llegar con Apple Maps") { navigate(google: false) }
                Button("Ver punto en Google Maps") { openGoogle(directions: false) }
                Button("Cómo llegar con Google Maps") { openGoogle(directions: true) }
                Button("Abrir Google Maps en la web") {
                    showingGoogleWeb = true
                }
                Button("Copiar dirección y enlace") {
                    copyLocation()
                }
            }
            Section { Button("Eliminar sitio", role: .destructive) { deleting = true } }
        }
        .overlay(alignment: .bottom) {
            if showingCopyNotice {
                Label("Enlace copiado", systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 4)
                    .padding(.bottom, 20)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showingCopyNotice)
        .task(id: copyNoticeID) {
            guard showingCopyNotice else { return }
            do { try await Task.sleep(nanoseconds: 2_000_000_000) }
            catch { return }
            showingCopyNotice = false
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
        .sheet(item: $sharePayload, onDismiss: {
            if sharingFailed {
                errorMessage = "No se pudo completar la operación de compartir. Usa Copiar dirección y enlace y pégalo directamente en WhatsApp."
                sharingFailed = false
            }
        }) { payload in
            LocationShareSheet(text: payload.text) { failed in
                sharingFailed = failed
                sharePayload = nil
            }
        }
        .sheet(isPresented: $editing) { PlaceEditor(place: place) }
        .sheet(isPresented: $showingGoogleWeb) {
            MapsWebView(url: MapLinks.url(latitude: place.latitude, longitude: place.longitude, google: true))
        }
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

    private func copyLocation() {
        UIPasteboard.general.string = MapLinks.shareText(name: place.name, address: place.address,
            latitude: place.latitude, longitude: place.longitude)
        showingCopyNotice = true
        copyNoticeID = UUID()
        UIAccessibility.post(notification: .announcement, argument: "Enlace copiado")
    }

    private func navigate(google: Bool) {
        openURL(MapLinks.url(latitude: place.latitude, longitude: place.longitude, google: google, directions: true))
    }
    private func openGoogle(directions: Bool) {
        guard MapPoint(latitude: place.latitude, longitude: place.longitude).isValid else {
            errorMessage = "Las coordenadas guardadas no son válidas. Edita el sitio y elige una dirección o un punto."
            return
        }
        let appURL = MapLinks.googleAppURL(latitude: place.latitude, longitude: place.longitude, directions: directions)
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:]) { opened in
                if !opened {
                    openURL(MapLinks.url(latitude: place.latitude, longitude: place.longitude, google: true, directions: directions))
                }
            }
        } else {
            openURL(MapLinks.url(latitude: place.latitude, longitude: place.longitude, google: true, directions: directions))
        }
    }

    private func toggleFavorite() {
        place.isFavorite.toggle(); place.updatedAt = .now
        do { try context.save() } catch { context.rollback(); errorMessage = "No se pudo actualizar el favorito." }
    }
}
