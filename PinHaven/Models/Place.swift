import Foundation
import SwiftData
import CoreLocation

@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var notes: String
    var category: String
    var tags: String
    var latitude: Double
    var longitude: Double
    var isFavorite: Bool
    var sourceURL: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, address: String = "", notes: String = "",
         category: String = "Otros", tags: String = "", latitude: Double,
         longitude: Double, isFavorite: Bool = false, sourceURL: String = "",
         createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id; self.name = name; self.address = address; self.notes = notes
        self.category = category; self.tags = tags; self.latitude = latitude
        self.longitude = longitude; self.isFavorite = isFavorite; self.sourceURL = sourceURL
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
