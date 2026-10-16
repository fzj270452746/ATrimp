//
//  ATMediaPicker.swift
//  ATrimp
//
//
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct ATPickedMedia {
    let kind: ATMediaKind
    let image: UIImage?
    let videoURL: URL?

    var aspect: Double {
        guard let image, image.size.height > 0 else { return 1 }
        return Double(image.size.width / image.size.height)
    }
}

final class ATMediaPicker: NSObject {

    enum Mode {
        case images(limit: Int)
        case video
    }

    private var completion: (([ATPickedMedia]) -> Void)?
    private weak var presenter: UIViewController?

    func present(from viewController: UIViewController, mode: Mode, completion: @escaping ([ATPickedMedia]) -> Void) {
        self.completion = completion
        self.presenter = viewController

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 0
        configuration.preferredAssetRepresentationMode = .current

        switch mode {
        case .images(let limit):
            configuration.filter = .images
            configuration.selectionLimit = limit
        case .video:
            configuration.filter = .videos
            configuration.selectionLimit = 1
        }

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.view.tintColor = ATTheme.Palette.accent
        viewController.present(picker, animated: true)
    }

    private func finish(with media: [ATPickedMedia]) {
        let handler = completion
        completion = nil
        handler?(media)
    }
}

extension ATMediaPicker: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            finish(with: [])
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var collected: [(Int, ATPickedMedia)] = []

        for (index, result) in results.enumerated() {
            let provider = result.itemProvider

            if provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    defer { group.leave() }
                    guard let image = object as? UIImage else { return }
                    lock.lock()
                    collected.append((index, ATPickedMedia(kind: .image, image: image, videoURL: nil)))
                    lock.unlock()
                }
                continue
            }

            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    defer { group.leave() }
                    guard let url else { return }
                    let staged = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString)-\(url.lastPathComponent)")
                    guard (try? FileManager.default.copyItem(at: url, to: staged)) != nil else { return }
                    lock.lock()
                    collected.append((index, ATPickedMedia(kind: .video, image: nil, videoURL: staged)))
                    lock.unlock()
                }
                continue
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.finish(with: collected.sorted { $0.0 < $1.0 }.map(\.1))
        }
    }
}
