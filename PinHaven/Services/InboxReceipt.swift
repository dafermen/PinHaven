import Foundation

/// Minimal local acknowledgement. Also prevents a retry of an update from creating a second place.
struct InboxReceipt: Codable {
    var schemaVersion = 1
    let captureID: UUID
    let placeID: UUID
    let completed: Bool
}

extension SharedInbox {
    private var receiptsDirectory: URL { directory.appendingPathComponent("Processed", isDirectory: true) }

    func receipt(for id: UUID) throws -> InboxReceipt? {
        let file = receiptsDirectory.appendingPathComponent(id.uuidString + ".json")
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else { throw InboxError.invalid }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 4097) ?? Data()
        guard data.count <= 4096 else { throw InboxError.invalid }
        let receipt = try JSONDecoder().decode(InboxReceipt.self, from: data)
        guard receipt.schemaVersion == 1, receipt.captureID == id else { throw InboxError.invalid }
        return receipt
    }

    func recordReceipt(captureID: UUID, placeID: UUID, completed: Bool = true) throws {
        try FileManager.default.createDirectory(at: receiptsDirectory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        var folder = receiptsDirectory
        var attributes = URLResourceValues(); attributes.isExcludedFromBackup = true
        try folder.setResourceValues(attributes)
        let data = try JSONEncoder().encode(InboxReceipt(captureID: captureID, placeID: placeID, completed: completed))
        try data.write(to: receiptsDirectory.appendingPathComponent(captureID.uuidString + ".json"),
                       options: [.atomic, .completeFileProtection])
    }

    /// Explicit discard only; never recursively removes a folder or a path outside the inbox.
    func discard(_ file: URL) throws {
        guard file.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL,
              file.pathExtension == "json" else { throw InboxError.invalid }
        let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        guard values.isRegularFile == true || values.isSymbolicLink == true else { throw InboxError.invalid }
        try FileManager.default.removeItem(at: file)
    }
}
