import UIKit
import MapKit
import Combine

struct LocationMapSnapshot {
    let image: UIImage
    let pin: CGPoint
}

@MainActor
protocol LocationMapSnapshotProvider: AnyObject {
    func snapshot(at point: MapPoint) async throws -> LocationMapSnapshot
    func cancel()
}

@MainActor
private final class AppleLocationMapSnapshotProvider: LocationMapSnapshotProvider {
    private var snapshotter: MKMapSnapshotter?

    func snapshot(at point: MapPoint) async throws -> LocationMapSnapshot {
        let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 900, longitudinalMeters: 900)
        // Logical phone-sized map at 2x: street labels remain readable in the shared card.
        options.size = CGSize(width: 540, height: 320)
        options.scale = 2
        options.mapType = .standard
        options.showsBuildings = true
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
        let worker = MKMapSnapshotter(options: options)
        snapshotter = worker
        defer { if snapshotter === worker { snapshotter = nil } }
        let result = try await worker.start()
        try Task.checkCancellation()
        return LocationMapSnapshot(image: result.image, pin: result.point(for: coordinate))
    }

    func cancel() { snapshotter?.cancel(); snapshotter = nil }
}

@MainActor
enum LocationMapCardComposer {
    private static let teal = UIColor(red: 0, green: 0.49, blue: 0.52, alpha: 1)
    private static let ink = UIColor(red: 0.08, green: 0.15, blue: 0.19, alpha: 1)

    static func render(_ content: LocationShareContent, snapshot: LocationMapSnapshot) throws -> UIImage {
        let sourceSize = snapshot.image.size
        let pin = snapshot.pin
        guard sourceSize.width > 0, sourceSize.height > 0, sourceSize.width.isFinite, sourceSize.height.isFinite,
              pin.x.isFinite, pin.y.isFinite, pin.x >= 40, pin.y >= 90,
              pin.x <= sourceSize.width - 40, pin.y <= sourceSize.height - 40 else {
            throw LocationShareError.unavailableMap
        }
        let width: CGFloat = 1080, padding: CGFloat = 48, bodyWidth = width - 2 * padding
        let mapHeight = bodyWidth * sourceSize.height / sourceSize.width
        guard mapHeight >= 200, mapHeight <= 900 else { throw LocationShareError.unavailableMap }
        let nameFont = UIFont.systemFont(ofSize: 52, weight: .bold)
        let addressFont = UIFont.systemFont(ofSize: 34)
        let nameHeight = height(content.name, font: nameFont, width: bodyWidth, lines: 3)
        let addressHeight = content.address.isEmpty ? 0 : height(content.address, font: addressFont, width: bodyWidth, lines: 5)
        let nameY: CGFloat = 128 + mapHeight + 32
        let addressY = nameY + nameHeight + 16
        let coordinatesY = addressY + addressHeight + (addressHeight > 0 ? 24 : 0)
        let footerY = coordinatesY + 70
        let size = CGSize(width: width, height: footerY + 108)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            UIColor.white.setFill(); renderer.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.93, green: 0.98, blue: 0.98, alpha: 1).setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: width, height: 96))
            draw("PinHaven", at: CGRect(x: padding, y: 27, width: 300, height: 48),
                 font: .systemFont(ofSize: 36, weight: .bold), color: teal)
            draw("UN LUGAR PARA RECORDAR", at: CGRect(x: 440, y: 38, width: 592, height: 32),
                 font: .systemFont(ofSize: 22, weight: .semibold), color: ink)
            let mapRect = CGRect(x: padding, y: 128, width: bodyWidth, height: mapHeight)
            // Draw the complete snapshot: never crop, cover or replace map attribution.
            snapshot.image.draw(in: mapRect)
            let scale = bodyWidth / sourceSize.width
            drawPin(at: CGPoint(x: mapRect.minX + pin.x * scale, y: mapRect.minY + pin.y * scale),
                    context: renderer.cgContext)
            draw(content.name, at: CGRect(x: padding, y: nameY, width: bodyWidth, height: nameHeight),
                 font: nameFont, color: ink, lines: 3)
            if !content.address.isEmpty {
                draw(content.address, at: CGRect(x: padding, y: addressY, width: bodyWidth, height: addressHeight),
                     font: addressFont, color: .darkGray, lines: 5)
            }
            draw(content.coordinates, at: CGRect(x: padding, y: coordinatesY, width: bodyWidth, height: 44),
                 font: .monospacedDigitSystemFont(ofSize: 28, weight: .regular), color: .darkGray)
            UIColor(red: 0.83, green: 0.92, blue: 0.92, alpha: 1).setFill()
            renderer.fill(CGRect(x: padding, y: footerY - 12, width: bodyWidth, height: 2))
            draw("Abre el enlace que acompaña esta tarjeta", at: CGRect(x: padding, y: footerY + 10, width: bodyWidth, height: 42),
                 font: .systemFont(ofSize: 30, weight: .semibold), color: teal)
            draw("Mapa: Apple Maps · Ubicación compartida con PinHaven", at: CGRect(x: padding, y: footerY + 59, width: bodyWidth, height: 34),
                 font: .systemFont(ofSize: 23), color: .darkGray)
        }
    }

    private static func height(_ text: String, font: UIFont, width: CGFloat, lines: Int) -> CGFloat {
        let measured = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil).height
        return ceil(min(CGFloat(lines) * font.lineHeight, max(font.lineHeight, measured)))
    }

    private static func draw(_ text: String, at rect: CGRect, font: UIFont, color: UIColor, lines: Int = 1) {
        let label = UILabel(frame: rect)
        label.text = text; label.font = font; label.textColor = color
        label.numberOfLines = lines; label.lineBreakMode = .byTruncatingTail
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState(); context.translateBy(x: rect.minX, y: rect.minY)
        label.drawText(in: CGRect(origin: .zero, size: rect.size))
        context.restoreGState()
    }

    private static func drawPin(at point: CGPoint, context: CGContext) {
        let x = point.x, y = point.y
        let path = UIBezierPath()
        path.move(to: point)
        path.addCurve(to: CGPoint(x: x - 32, y: y - 52), controlPoint1: CGPoint(x: x - 8, y: y - 17), controlPoint2: CGPoint(x: x - 32, y: y - 32))
        path.addCurve(to: CGPoint(x: x, y: y - 84), controlPoint1: CGPoint(x: x - 32, y: y - 70), controlPoint2: CGPoint(x: x - 18, y: y - 84))
        path.addCurve(to: CGPoint(x: x + 32, y: y - 52), controlPoint1: CGPoint(x: x + 18, y: y - 84), controlPoint2: CGPoint(x: x + 32, y: y - 70))
        path.addCurve(to: point, controlPoint1: CGPoint(x: x + 32, y: y - 32), controlPoint2: CGPoint(x: x + 8, y: y - 17))
        path.close()
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 3), blur: 6, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        teal.setFill(); path.fill(); UIColor.white.setStroke(); path.lineWidth = 3; path.stroke()
        context.restoreGState()
        UIColor.white.setFill(); UIBezierPath(ovalIn: CGRect(x: x - 10, y: y - 64, width: 20, height: 20)).fill()
    }
}

@MainActor
final class LocationMapCard: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?
    private let provider: LocationMapSnapshotProvider
    private let timeoutNanoseconds: UInt64
    private var generation = UUID()

    init(provider: LocationMapSnapshotProvider? = nil, timeoutNanoseconds: UInt64 = 15_000_000_000) {
        self.provider = provider ?? AppleLocationMapSnapshotProvider()
        self.timeoutNanoseconds = timeoutNanoseconds
    }

    func prepare(_ content: LocationShareContent) async {
        cancel()
        let token = generation
        isLoading = true
        let timeout = Task { @MainActor in
            do { try await Task.sleep(nanoseconds: timeoutNanoseconds) } catch { return }
            guard generation == token else { return }
            generation = UUID(); provider.cancel(); isLoading = false
            message = LocationShareError.unavailableMap.localizedDescription
        }
        defer { timeout.cancel(); if generation == token { isLoading = false } }
        do {
            let snapshot = try await provider.snapshot(at: content.point)
            try Task.checkCancellation()
            guard generation == token else { return }
            image = try LocationMapCardComposer.render(content, snapshot: snapshot)
        } catch {
            guard generation == token else { return }
            if !Task.isCancelled { message = LocationShareError.unavailableMap.localizedDescription }
        }
    }

    func cancel(keepingPreview: Bool = false) {
        generation = UUID(); provider.cancel(); isLoading = false
        if !keepingPreview { image = nil; message = nil }
        else if image == nil { message = "Pulsa Reintentar mapa para continuar o comparte solo el enlace." }
    }
}
