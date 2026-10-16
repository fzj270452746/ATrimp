//
//  ATMediaLibrary.swift
//  ATrimp
//
//
import AVFoundation
import ImageIO
import UIKit

enum ATMediaLibrary {

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    static var directory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ATrimp", isDirectory: true)
            .appendingPathComponent("Media", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    // MARK: - Importing

    static func importImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.88) else { return nil }
        let name = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return "file:\(name)"
        } catch {
            return nil
        }
    }

    static func importAvatar(_ image: UIImage, side: CGFloat = 1024) -> String? {
        guard let square = squared(image, side: side) else { return nil }
        return importImage(square)
    }

    private static func squared(_ image: UIImage, side: CGFloat) -> UIImage? {
        let source = image.size
        guard source.width > 0, source.height > 0 else { return nil }

        let edge = min(source.width, source.height)
        let target = min(side, edge)
        let scale = target / edge

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(
            size: CGSize(width: target, height: target),
            format: format
        ).image { _ in
            image.draw(in: CGRect(
                x: (target - source.width * scale) / 2,
                y: (target - source.height * scale) / 2,
                width: source.width * scale,
                height: source.height * scale
            ))
        }
    }

    static func importVideo(at source: URL) -> String? {
        let name = "\(UUID().uuidString).\(source.pathExtension.isEmpty ? "mov" : source.pathExtension)"
        let destination = directory.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            return "file:\(name)"
        } catch {
            return nil
        }
    }

    // MARK: - Resolving

    static func fileURL(forReference reference: String) -> URL? {
        guard reference.hasPrefix("file:") else { return nil }
        let name = String(reference.dropFirst(5))
        let url = directory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func videoURL(forReference reference: String) -> URL? {
        if let picked = fileURL(forReference: reference) { return picked }
        return Bundle.main.url(forResource: reference, withExtension: "mp4")
    }

    static func image(for media: ATPostMedia, size: CGSize, symbol: String? = nil) -> UIImage {
        guard media.kind == .video, videoURL(forReference: media.reference) != nil else {
            return image(reference: media.reference, size: size, symbol: symbol)
        }
        return still(for: media, size: size, symbol: symbol)
    }

    /// The first frame of a clip, drawn into `size` the way a photograph would be:
    /// a clip is almost never the same shape as the box it lands in — a portrait
    /// clip in a square grid slot is the usual case — so the frame is scaled to
    /// cover the box and the overflow is cropped, never squeezed to fit.
    private static func still(for media: ATPostMedia, size: CGSize, symbol: String?) -> UIImage {
        let scale = UIScreen.main.scale
        let width = max(1, Int((size.width * scale).rounded()))
        let height = max(1, Int((size.height * scale).rounded()))
        let key = "still|\(media.reference)|\(width)x\(height)|\(symbol ?? "-")" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let renderSize = CGSize(width: width, height: height)
        let frame = posterImage(for: media, size: renderSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: renderSize, format: format).image { _ in
            drawFilling(frame, in: CGRect(origin: .zero, size: renderSize))

            guard let symbol else { return }
            let configuration = UIImage.SymbolConfiguration(
                pointSize: min(renderSize.width, renderSize.height) * 0.30,
                weight: .light
            )
            guard let glyph = UIImage(systemName: symbol, withConfiguration: configuration)?
                .withTintColor(UIColor(hex: 0xFCFAF5, alpha: 0.42), renderingMode: .alwaysOriginal) else { return }
            glyph.draw(at: CGPoint(
                x: (renderSize.width - glyph.size.width) / 2,
                y: (renderSize.height - glyph.size.height) / 2
            ))
        }

        cache.setObject(image, forKey: key, cost: width * height * 4)
        return image
    }

    /// Scales `image` until it covers `rect`, keeping its proportions, and centres
    /// the crop on it. Drawing it straight into the rect would stretch it.
    private static func drawFilling(_ image: UIImage, in rect: CGRect) {
        let source = image.size
        guard source.width > 0, source.height > 0 else { return }

        let factor = max(rect.width / source.width, rect.height / source.height)
        let drawn = CGSize(width: source.width * factor, height: source.height * factor)
        image.draw(in: CGRect(
            x: rect.midX - drawn.width / 2,
            y: rect.midY - drawn.height / 2,
            width: drawn.width,
            height: drawn.height
        ))
    }

    static func image(reference: String, size: CGSize, symbol: String? = nil) -> UIImage {
        let width = max(1, Int(size.width.rounded()))
        let height = max(1, Int(size.height.rounded()))

        if let url = fileURL(forReference: reference) {
            let key = "file|\(reference)|\(width)x\(height)" as NSString
            if let cached = cache.object(forKey: key) { return cached }
            if let image = downsample(url: url, to: CGSize(width: width, height: height)) {
                cache.setObject(image, forKey: key, cost: width * height * 4)
                return image
            }
        }

        return ATArt.photo(seed: reference, size: size, symbol: symbol)
    }

    static func posterImage(for media: ATPostMedia, size: CGSize) -> UIImage {
        if let url = videoURL(forReference: media.reference) {
            let key = "poster|\(media.reference)|\(Int(size.width))x\(Int(size.height))" as NSString
            if let cached = cache.object(forKey: key) { return cached }

            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = size

            if let frame = try? generator.copyCGImage(at: CMTime(seconds: 0.4, preferredTimescale: 600), actualTime: nil) {
                let image = UIImage(cgImage: frame)
                cache.setObject(image, forKey: key, cost: Int(size.width * size.height) * 4)
                return image
            }
        }

        return ATArt.photo(seed: media.reference, size: size, symbol: "play.fill")
    }

    static func purgeUnreferenced() {
        let referenced = Set(
            ATStore.posts(theme: nil, offset: 0, limit: 5_000)
                .flatMap { ATStore.media(forPost: $0.id) }
                .compactMap(\.localFileName)
        )

        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        for name in contents where !referenced.contains(name) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    // MARK: - Downsampling

    private static func downsample(url: URL, to size: CGSize) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }

        let maxPixel = max(size.width, size.height) * UIScreen.main.scale
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
