import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw BackupError.invalidData }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BackupView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Place.createdAt) private var places: [Place]
    @State private var document = BackupDocument()
    @State private var exporting = false
    @State private var importing = false
    @State private var pending: PlaceBackup?
    @State private var confirmImport = false
    @State private var message: String?

    var body: some View {
        Form {
            Section("Tus datos") {
                Text("\(places.count) sitios guardados en este iPhone")
                Text("La app no tiene cuenta ni sincronización. Conserva un respaldo manual antes de borrar la app o cambiar de teléfono.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button("Exportar todos los sitios") {
                    do {
                        let data = try PlaceBackup(places: places.map(\.record)).encoded()
                        // Never export a backup this version cannot import again.
                        _ = try PlaceBackup.decode(data)
                        document = BackupDocument(data: data); exporting = true
                    }
                    catch { message = "No se pudo preparar el respaldo: \(error.localizedDescription)" }
                }
                Button("Importar un respaldo") { importing = true }
            } header: { Text("Respaldo manual") } footer: {
                Text("El archivo contiene coordenadas y notas en texto legible. Elige ‘En mi iPhone’ o una unidad local para mantenerlo fuera de la nube. Los sitios con el mismo identificador se omiten al importar; no se sobrescriben.")
            }
            Section("Conexiones externas") {
                Text("Buscar sitios y cargar mapas utiliza servicios de Apple. Abrir Google Maps o compartir con WhatsApp entrega a esa aplicación el contenido que tú selecciones. No hay seguimiento en segundo plano.")
            }
        }
        .navigationTitle("Datos y privacidad")
        .fileExporter(isPresented: $exporting, document: document, contentType: .json,
                      defaultFilename: "PinHaven-respaldo") { result in
            if case .failure(let error) = result { message = "No se pudo exportar: \(error.localizedDescription)" }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let granted = url.startAccessingSecurityScopedResource()
                defer { if granted { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 20 * 1024 * 1024 else { throw BackupError.tooLarge }
                pending = try PlaceBackup.decode(Data(contentsOf: url, options: .mappedIfSafe))
                confirmImport = true
            } catch { message = "No se pudo leer el respaldo: \(error.localizedDescription)" }
        }
        .confirmationDialog("¿Importar \(pending?.places.count ?? 0) sitios?", isPresented: $confirmImport,
                            titleVisibility: .visible) {
            Button("Importar sitios nuevos") {
                guard let pending else { return }
                do {
                    let added = try LocalStore.importBackup(pending, into: context)
                    message = "Se agregaron \(added) sitios. Se omitieron \(pending.places.count - added) identificadores existentes."
                } catch { message = "No se pudo guardar la importación. \(error.localizedDescription)" }
                self.pending = nil
            }
            Button("Cancelar", role: .cancel) { pending = nil }
        }
        .alert("Respaldo", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("Aceptar", role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
    }
}
