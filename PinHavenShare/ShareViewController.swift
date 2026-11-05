import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let root = ShareCaptureView(load: { [weak self] in
            guard let self else { throw IncomingLinkError.unsupported }
            return try await self.sharedText()
        }, close: { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        })
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
    }

    private func sharedText() async throws -> String {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        for item in items.prefix(8) {
            for provider in (item.attachments ?? []).prefix(8) {
                for type in [UTType.url.identifier, UTType.plainText.identifier, UTType.text.identifier] where provider.hasItemConformingToTypeIdentifier(type) {
                    let text: String? = try? await withCheckedThrowingContinuation { continuation in
                        provider.loadItem(forTypeIdentifier: type, options: nil) { value, error in
                            if let error { continuation.resume(throwing: error); return }
                            if let url = value as? URL { continuation.resume(returning: url.absoluteString) }
                            else if let text = value as? String { continuation.resume(returning: text) }
                            else if let data = value as? Data, data.count <= 32_768 {
                                continuation.resume(returning: String(data: data, encoding: .utf8))
                            }
                            else { continuation.resume(returning: nil) }
                        }
                    }
                    if let text, IncomingMapLink.extract(from: text) != nil { return text }
                }
            }
            if let text = item.attributedContentText?.string, IncomingMapLink.extract(from: text) != nil { return text }
        }
        throw IncomingLinkError.unsupported
    }
}
