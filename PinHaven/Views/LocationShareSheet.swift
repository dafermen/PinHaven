import SwiftUI
import UIKit

/// Pass one plain-text item, including the link, to messaging extensions.
struct LocationShareSheet: UIViewControllerRepresentable {
    let text: String
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
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
}
