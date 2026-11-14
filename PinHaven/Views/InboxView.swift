import SwiftUI
import SwiftData

private struct InboxEntry: Identifiable {
    let file: URL
    let capture: SharedCapture?
    var id: URL { file }
}

@MainActor
struct InboxView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var places: [Place]
    @State private var entries: [InboxEntry] = []
    @State private var selected: SharedCapture?
    @State private var discarding: URL?
    @State private var errorMessage: String?
    @State private var notice: String?
    @State private var limit = 200
    @State private var total = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Los lugares nuevos se incorporan al abrir PinHaven. Aquí puedes revisar posibles duplicados y entradas que no pudieron guardarse.")
                        .font(.subheadline)
                    Button("Reintentar incorporación") { retry() }
                    if let notice { Text(notice).font(.caption).foregroundStyle(.secondary) }
                }
                Section("Pendientes: \(total)") {
                    if entries.isEmpty { Text("No hay lugares pendientes.").foregroundStyle(.secondary) }
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            if let capture = entry.capture {
                                Text(capture.record.name).font(.headline)
                                if !capture.record.address.isEmpty { Text(capture.record.address).font(.subheadline) }
                                Text(status(capture)).font(.caption).foregroundStyle(.secondary)
                                Button("Revisar lugar") { selected = capture }
                            } else {
                                Label("No se pudo leer esta entrada", systemImage: "exclamationmark.triangle")
                                Text("Reintenta. Si el archivo sigue dañado, vuelve a compartir el lugar desde Maps antes de descartarlo.")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(entry.file.deletingPathExtension().lastPathComponent).font(.caption2).lineLimit(1)
                            }
                            Button("Descartar entrada pendiente", role: .destructive) { discarding = entry.file }
                        }.padding(.vertical, 4)
                    }
                    if total > entries.count {
                        Button("Mostrar más pendientes") { limit += 200; reload() }
                    }
                }
            }
            .navigationTitle("Bandeja de Maps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } } }
            .task { reload() }
            .refreshable { reload() }
            .sheet(item: $selected, onDismiss: { reload() }) { capture in
                let target = reviewTarget(for: capture)
                PlaceEditor(place: target, incoming: target == nil ? capture.record : nil) { record in
                    try SharedInboxImport.accept(record, captureID: capture.id, inbox: SharedInbox.live(), into: context)
                }
            }
            .alert("¿Descartar esta entrada?", isPresented: Binding(get: { discarding != nil }, set: { if !$0 { discarding = nil } })) {
                Button("Cancelar", role: .cancel) { discarding = nil }
                Button("Descartar", role: .destructive) {
                    do {
                        if let file = discarding { try SharedInbox.live().discard(file) }
                        discarding = nil; reload()
                    } catch { discarding = nil; errorMessage = error.localizedDescription }
                }
            } message: { Text("Solo se retirará de la bandeja. Los sitios de tu agenda se conservarán.") }
            .alert("Bandeja no disponible", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("Aceptar", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func status(_ capture: SharedCapture) -> String {
        if let inbox = try? SharedInbox.live(), let receipt = try? inbox.receipt(for: capture.id) {
            return receipt.completed ? "Ya incorporado; reintentar retirará el pendiente."
                : "Incorporación interrumpida: comprueba el sitio guardado antes de confirmar."
        }
        if places.contains(where: { $0.id == capture.id }) { return "Ya guardado; reintentar terminará la incorporación." }
        return PlaceDuplicates.matches(capture.record, among: places.map(\.record)).isEmpty
            ? "Pendiente de incorporación" : "Posible duplicado: revisa antes de guardar."
    }

    private func reviewTarget(for capture: SharedCapture) -> Place? {
        guard let inbox = try? SharedInbox.live(), let receipt = try? inbox.receipt(for: capture.id),
              !receipt.completed else { return nil }
        return places.first(where: { $0.id == receipt.placeID })
    }

    private func reload() {
        do {
            let inbox = try SharedInbox.live()
            let files = try inbox.files(); total = files.count
            entries = files.prefix(limit).map { InboxEntry(file: $0, capture: try? inbox.read($0)) }
        } catch { errorMessage = error.localizedDescription }
    }

    private func retry() {
        do {
            let result = try SharedInboxImport.consume(SharedInbox.live(), into: context)
            notice = "Incorporados: \(result.added). Posibles duplicados: \(result.duplicates). Con error: \(result.failed)."
            reload()
        } catch { errorMessage = error.localizedDescription }
    }
}
