import SwiftUI
import UIKit

/// Link mode remains a single text item. Card mode adds the prepared image.
struct LocationShareSheet: UIViewControllerRepresentable {
    let payload: LocationSharePayload
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: payload.activityItems, applicationActivities: nil)
        if payload.image != nil {
            // Sharing does not add Photos/Contacts permissions or a local photo-saving feature.
            controller.excludedActivityTypes = [.saveToCameraRoll, .assignToContact]
        }
        controller.completionWithItemsHandler = { _, _, _, error in
            // Activity completion does not confirm transport or recipient delivery.
            let failed = error != nil
            DispatchQueue.main.async { onComplete(failed) }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct LocationSharePayload: Identifiable {
    let id = UUID()
    let text: String
    var image: UIImage? = nil

    var activityItems: [Any] {
        if let image { return [image, text] }
        return [text]
    }
}
