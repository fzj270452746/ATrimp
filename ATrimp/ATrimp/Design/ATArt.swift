//
//  ATArt.swift
//  ATrimp
//
//
//
import UIKit

enum ATArt {

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()

    // MARK: - Seeded palette

    private static func seedHash(_ seed: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in seed.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    static func gradientColors(seed: String) -> [CGColor] {
        let hash = seedHash(seed)
        let baseHue = CGFloat(hash % 360) / 360
        let drift = 0.06 + CGFloat((hash >> 11) % 9) / 100
        let secondHue = (baseHue + drift).truncatingRemainder(dividingBy: 1)

        let top = UIColor(hue: baseHue, saturation: 0.26, brightness: 0.74, alpha: 1)
        let bottom = UIColor(hue: secondHue, saturation: 0.40, brightness: 0.44, alpha: 1)
        return [top.cgColor, bottom.cgColor]
    }

    static func gradientTopColor(seed: String) -> UIColor {
        UIColor(cgColor: gradientColors(seed: seed)[0])
    }

    // MARK: - Photos

    static func bundled(_ reference: String) -> UIImage? {
        guard let image = UIImage(named: reference) else { return nil }
        return image
    }

    static func photo(seed: String, size: CGSize, symbol: String? = nil) -> UIImage {
        if let supplied = bundled(seed) { return supplied }

        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))
        let key = "photo|\(seed)|\(width)x\(height)|\(symbol ?? "-")" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let renderSize = CGSize(width: width, height: height)
        let image = renderer(size: renderSize, scale: 1).image { context in
            let cgContext = context.cgContext
            let colors = gradientColors(seed: seed)
            drawLinearGradient(cgContext, colors: colors, in: CGRect(origin: .zero, size: renderSize))

            cgContext.saveGState()
            cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.10).cgColor)
            cgContext.setLineWidth(1)
            let hash = seedHash(seed)
            for index in 0..<3 {
                let offset = CGFloat((hash >> (index * 7)) % 100) / 100
                cgContext.move(to: CGPoint(x: -renderSize.width * 0.2 + offset * renderSize.width * 1.4, y: 0))
                cgContext.addLine(to: CGPoint(x: renderSize.width * 0.2 + offset * renderSize.width * 1.4, y: renderSize.height))
            }
            cgContext.strokePath()
            cgContext.restoreGState()

            if let symbol {
                drawSymbol(symbol, in: cgContext, bounds: CGRect(origin: .zero, size: renderSize), alpha: 0.42)
            }
        }

        cache.setObject(image, forKey: key, cost: width * height * 4)
        return image
    }

    // MARK: - Avatars

    static func avatar(seed: String, initials: String, size: CGFloat) -> UIImage {
        let side = max(1, Int(size.rounded()))
        let key = "avatar|\(seed)|\(side)|\(initials)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let renderSize = CGSize(width: side, height: side)
        let image = renderer(size: renderSize, scale: 3).image { context in
            let cgContext = context.cgContext
            drawLinearGradient(
                cgContext,
                colors: gradientColors(seed: seed),
                in: CGRect(origin: .zero, size: renderSize)
            )

            let text = initials.uppercased() as NSString
            let font = ATTheme.Typeface.serif(CGFloat(side) * 0.40, .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(hex: 0xFCFAF5, alpha: 0.92),
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: (renderSize.width - textSize.width) / 2,
                    y: (renderSize.height - textSize.height) / 2
                ),
                withAttributes: attributes
            )
        }

        cache.setObject(image, forKey: key, cost: side * side * 4)
        return image
    }

    static func avatarImage(seed: String, initials: String, size: CGFloat) -> UIImage {
        if let supplied = bundled(seed) { return supplied }

        let side = max(1, Int(size.rounded()))
        let key = "avatarRing|\(seed)|\(side)|\(initials)" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let renderSize = CGSize(width: side, height: side)
        let image = renderer(size: renderSize, scale: 3).image { context in
            let cgContext = context.cgContext
            let rect = CGRect(x: 1, y: 1, width: side - 2, height: side - 2)

            cgContext.saveGState()
            cgContext.addEllipse(in: rect)
            cgContext.clip()
            drawLinearGradient(cgContext, colors: gradientColors(seed: seed), in: rect)
            cgContext.restoreGState()

            let text = initials.uppercased() as NSString
            let font = ATTheme.Typeface.serif(CGFloat(side) * 0.38, .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(hex: 0xFCFAF5, alpha: 0.92),
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(
                    x: (renderSize.width - textSize.width) / 2,
                    y: (renderSize.height - textSize.height) / 2
                ),
                withAttributes: attributes
            )

            cgContext.setStrokeColor(ATTheme.Palette.paper.cgColor)
            cgContext.setLineWidth(2)
            cgContext.strokeEllipse(in: rect)
        }

        cache.setObject(image, forKey: key, cost: side * side * 4)
        return image
    }

    // MARK: - Drawing helpers

    private static func renderer(size: CGSize, scale: CGFloat) -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format)
    }

    private static func drawLinearGradient(_ context: CGContext, colors: [CGColor], in rect: CGRect) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else { return }

        context.saveGState()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
        context.restoreGState()
    }

    private static func drawSymbol(_ name: String, in context: CGContext, bounds: CGRect, alpha: CGFloat) {
        let configuration = UIImage.SymbolConfiguration(pointSize: min(bounds.width, bounds.height) * 0.30, weight: .light)
        guard let symbol = UIImage(systemName: name, withConfiguration: configuration)?
            .withTintColor(UIColor(hex: 0xFCFAF5, alpha: alpha), renderingMode: .alwaysOriginal) else { return }

        let size = symbol.size
        let origin = CGPoint(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2
        )
        context.saveGState()
        symbol.draw(at: origin)
        context.restoreGState()
    }
}
