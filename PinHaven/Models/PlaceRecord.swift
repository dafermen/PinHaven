import Foundation

/// Portable format, independent of SwiftData. Coordinates use decimal degrees.
struct PlaceRecord: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var address: String = ""
    var notes: String = ""
    var category: String = "Otros"
    var tags: String = ""
    var latitude: Double
    var longitude: Double
    var isFavorite: Bool = false
    var sourceURL: String = ""
    var createdAt: Date = .now
    var updatedAt: Date = .now

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        name.count <= 200 && address.count <= 2000 && notes.count <= 20000 &&
        tags.count <= 2000 && category.count <= 100 && sourceURL.count <= 4000 &&
        latitude.isFinite && longitude.isFinite &&
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    static func matches(_ value: String, query: String) -> Bool {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es"))
            .contains(query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es")))
    }
}

struct PlaceBackup: Codable {
    var schemaVersion: Int = 1
    var exportedAt: Date = .now
    var places: [PlaceRecord]

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> PlaceBackup {
        guard data.count <= 20 * 1024 * 1024 else { throw BackupError.tooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(PlaceBackup.self, from: data)
        guard backup.schemaVersion == 1 else { throw BackupError.unsupportedVersion }
        guard backup.places.count <= 10000,
              Set(backup.places.map(\.id)).count == backup.places.count,
              backup.places.allSatisfy(\.isValid) else { throw BackupError.invalidData }
        return backup
    }
}

enum BackupError: LocalizedError {
    case tooLarge, unsupportedVersion, invalidData
    var errorDescription: String? {
        switch self {
        case .tooLarge: return "El archivo supera el límite de 20 MB."
        case .unsupportedVersion: return "La versión del respaldo no es compatible."
        case .invalidData: return "El respaldo contiene datos inválidos o identificadores repetidos."
        }
    }
}
