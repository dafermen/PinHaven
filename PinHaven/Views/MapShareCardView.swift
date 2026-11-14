import SwiftUI
import UIKit

@MainActor
struct MapShareCardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var card = LocationMapCard()
    let content: LocationShareContent
    @State private var payload: LocationSharePayload?
    @State private var sharingFailed = false
    @State private var errorMessage: String?
    @State private var copied = false
    @State private var attempt = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let image = card.image {
                        Image(uiImage: image).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.secondary.opacity(0.15)))
                            .accessibilityLabel("Tarjeta de \(content.name), \(content.address), coordenadas \(content.coordinates)")
                    } else if card.isLoading {
                        ProgressView("Preparando mapa…").frame(maxWidth: .infinity, minHeight: 220)
                    } else if let message = card.message {
                        Label(message, systemImage: "wifi.exclamationmark")
                        Button("Reintentar mapa") { attempt = UUID() }
                    }
                    Text("Se compartirán la imagen y el enlace. La app elegida decide cómo mostrarlos. Revisa el contenido antes de compartir.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(content.text).font(.callout).textSelection(.enabled)
                    Button { share(image: card.image) } label: {
                        Label("Compartir tarjeta con mapa", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).disabled(card.image == nil)
                    Button { share(image: nil) } label: {
                        Label("Compartir solo enlace", systemImage: "link").frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                    Button {
                        UIPasteboard.general.string = content.text
                        copied = true
                        UIAccessibility.post(notification: .announcement, argument: "Enlace copiado")
                    } label: { Label(copied ? "Enlace copiado" : "Copiar dirección y enlace", systemImage: copied ? "checkmark" : "doc.on.doc") }
                }.padding()
            }
            .navigationTitle("Tarjeta con mapa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { card.cancel(); dismiss() } } }
            .task(id: attempt) {
                if card.image == nil { await card.prepare(content) }
            }
            .onDisappear { card.cancel(keepingPreview: true) }
            .sheet(item: $payload, onDismiss: {
                if sharingFailed {
                    errorMessage = "No se pudo completar la operación. Puedes compartir solo el enlace o copiarlo y pegarlo en WhatsApp."
                    sharingFailed = false
                }
            }) { value in
                LocationShareSheet(payload: value) { failed in sharingFailed = failed; payload = nil }
            }
            .alert("No se completó la operación", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Aceptar", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func share(image: UIImage?) {
        sharingFailed = false
        payload = LocationSharePayload(text: content.text, image: image)
    }
}
