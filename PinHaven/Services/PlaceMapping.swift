import Foundation

extension Place {
    var record: PlaceRecord {
        PlaceRecord(id: id, name: name, address: address, notes: notes, category: category,
                    tags: tags, latitude: latitude, longitude: longitude, isFavorite: isFavorite,
                    sourceURL: sourceURL, createdAt: createdAt, updatedAt: updatedAt)
    }

    func apply(_ record: PlaceRecord) {
        name = record.name; address = record.address; notes = record.notes
        category = record.category; tags = record.tags; latitude = record.latitude
        longitude = record.longitude; isFavorite = record.isFavorite; sourceURL = record.sourceURL
        updatedAt = record.updatedAt
    }

    static func make(from r: PlaceRecord) -> Place {
        Place(id: r.id, name: r.name, address: r.address, notes: r.notes, category: r.category,
              tags: r.tags, latitude: r.latitude, longitude: r.longitude, isFavorite: r.isFavorite,
              sourceURL: r.sourceURL, createdAt: r.createdAt, updatedAt: r.updatedAt)
    }
}
