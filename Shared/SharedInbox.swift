import Foundation

struct SharedCapture: Codable, Identifiable {
    var schemaVersion = 1
    var record: PlaceRecord
    var id: UUID { record.id }

    func validated() throws -> SharedCapture {
        guard schemaVersion == 1, record.isValid,
              let url = URL(string: record.sourceURL), IncomingMapLink.isAllowed(url) else { throw InboxError.invalid }
        return self
    }
}

struct SharedInbox {
    static let groupIdentifier = "group.com.innovalogic.pinhaven"
    let directory: URL

    static func live() throws -> SharedInbox {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            throw InboxError.unavailable
        }
        return SharedInbox(directory: root.appendingPathComponent("PendingPlaces", isDirectory: true))
    }

    func enqueue(_ capture: SharedCapture) throws {
        _ = try capture.validated()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        var folder = directory
        var attributes = URLResourceValues()
        attributes.isExcludedFromBackup = true
        try folder.setResourceValues(attributes)
        let encoder = JSONEncoder()
        let data = try encoder.encode(capture)
        guard data.count <= 128 * 1024 else { throw InboxError.invalid }
        try data.write(to: file(for: capture.id), options: [.atomic, .completeFileProtection])
    }

    func files() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            .filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func read(_ file: URL) throws -> SharedCapture {
        guard file.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL else { throw InboxError.invalid }
        let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else { throw InboxError.invalid }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 128 * 1024 + 1) ?? Data()
        guard data.count <= 128 * 1024 else { throw InboxError.invalid }
        let capture = try JSONDecoder().decode(SharedCapture.self, from: data).validated()
        guard file.lastPathComponent == self.file(for: capture.id).lastPathComponent else { throw InboxError.invalid }
        return capture
    }

    func acknowledge(_ id: UUID) throws { try FileManager.default.removeItem(at: file(for: id)) }
    private func file(for id: UUID) -> URL { directory.appendingPathComponent(id.uuidString + ".json") }
}

enum InboxError: LocalizedError {
    case unavailable, invalid
    var errorDescription: String? {
        switch self {
        case .unavailable: return "No se pudo abrir la bandeja compartida. Comprueba App Groups y la firma de PinHaven."
        case .invalid: return "Hay una entrada compartida inválida. Se ha conservado para revisión."
        }
    }
}
