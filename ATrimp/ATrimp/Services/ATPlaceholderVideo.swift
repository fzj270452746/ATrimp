//
//  ATPlaceholderVideo.swift
//  ATrimp
//
//
import AVFoundation
import UIKit

enum ATPlaceholderVideo {

    private static let queue = DispatchQueue(label: "com.atrim.placeholder-video", qos: .userInitiated)
    private static let lock = NSLock()
    private static var waiting: [String: [(URL?) -> Void]] = [:]

    private static let durationSeconds = 6
    private static let frameRate: Int32 = 24

    private static var directory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ATrimpVideo", isDirectory: true)
    }

    static func url(seed: String, aspect: Double, completion: @escaping (URL?) -> Void) {
        if let supplied = Bundle.main.url(forResource: seed, withExtension: "mp4") {
            completion(supplied)
            return
        }

        let name = safeName(seed)
        let target = directory.appendingPathComponent("\(name).mp4")

        if FileManager.default.fileExists(atPath: target.path) {
            completion(target)
            return
        }

        lock.lock()
        if waiting[name] != nil {
            waiting[name]?.append(completion)
            lock.unlock()
            return
        }
        waiting[name] = [completion]
        lock.unlock()

        queue.async {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var produced: URL?
            do {
                try render(seed: seed, aspect: aspect, to: target)
                produced = target
            } catch {
                produced = nil
            }

            lock.lock()
            let handlers = waiting.removeValue(forKey: name) ?? []
            lock.unlock()

            DispatchQueue.main.async {
                handlers.forEach { $0(produced) }
            }
        }
    }

    private static func safeName(_ seed: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return String(seed.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" })
    }

    // MARK: - Rendering

    private static func render(seed: String, aspect: Double, to url: URL) throws {
        let ratio = aspect > 0 ? aspect : 1
        let width = 1080
        let height = max(720, min(1920, Int(Double(width) / ratio / 2) * 2))
        let size = CGSize(width: width, height: height)

        try? FileManager.default.removeItem(at: url)

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
        )

        guard writer.canAdd(input) else { throw ATVideoError.cannotAddInput }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? ATVideoError.cannotStart }
        writer.startSession(atSourceTime: .zero)

        let totalFrames = Int(frameRate) * durationSeconds

        for frame in 0..<totalFrames {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.004)
            }
            guard let pool = adaptor.pixelBufferPool else { break }

            var buffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
                  let pixelBuffer = buffer else { break }

            draw(frame: frame, total: totalFrames, seed: seed, into: pixelBuffer, size: size)

            let time = CMTime(value: CMTimeValue(frame), timescale: frameRate)
            guard adaptor.append(pixelBuffer, withPresentationTime: time) else { break }
        }

        input.markAsFinished()

        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { semaphore.signal() }
        semaphore.wait()

        if writer.status != .completed {
            throw writer.error ?? ATVideoError.incomplete
        }
    }

    private static func draw(frame: Int, total: Int, seed: String, into buffer: CVPixelBuffer, size: CGSize) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        guard let context = CGContext(
            data: base,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return }

        let rect = CGRect(origin: .zero, size: size)
        let progress = Double(frame) / Double(max(1, total - 1))

        let colors = ATArt.gradientColors(seed: seed)
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        context.setFillColor(UIColor(hex: 0x14110F, alpha: 0.20).cgColor)
        context.fill(rect)

        let sweepX = -size.width * 0.4 + CGFloat(progress) * size.width * 1.8
        context.saveGState()
        context.translateBy(x: sweepX, y: 0)
        context.rotate(by: .pi / 7)
        context.setFillColor(UIColor(hex: 0xFCFAF5, alpha: 0.10).cgColor)
        context.fill(CGRect(x: 0, y: -size.height, width: size.width * 0.22, height: size.height * 3))
        context.restoreGState()

        let radius = size.width * 0.16
        let orbit = CGRect(
            x: size.width * 0.5 - radius * 3 + CGFloat(progress) * radius * 6,
            y: size.height * 0.5 - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.setFillColor(UIColor(hex: 0xFCFAF5, alpha: 0.16).cgColor)
        context.fillEllipse(in: orbit)

        context.setStrokeColor(UIColor(hex: 0xFCFAF5, alpha: 0.34).cgColor)
        context.setLineWidth(max(2, size.width * 0.004))
        let inset = size.width * 0.06
        let arm = size.width * 0.07
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: inset, y: inset + arm), CGPoint(x: inset, y: inset), CGPoint(x: inset + arm, y: inset)),
            (CGPoint(x: size.width - inset - arm, y: inset), CGPoint(x: size.width - inset, y: inset), CGPoint(x: size.width - inset, y: inset + arm)),
            (CGPoint(x: inset, y: size.height - inset - arm), CGPoint(x: inset, y: size.height - inset), CGPoint(x: inset + arm, y: size.height - inset)),
            (CGPoint(x: size.width - inset - arm, y: size.height - inset), CGPoint(x: size.width - inset, y: size.height - inset), CGPoint(x: size.width - inset, y: size.height - inset - arm)),
        ]
        for corner in corners {
            context.move(to: corner.0)
            context.addLine(to: corner.1)
            context.addLine(to: corner.2)
        }
        context.strokePath()
    }
}

enum ATVideoError: Error {
    case cannotAddInput
    case cannotStart
    case incomplete
}
