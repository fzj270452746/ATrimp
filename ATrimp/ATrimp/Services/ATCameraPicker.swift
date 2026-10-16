//
//  ATCameraPicker.swift
//  ATrimp
//
//
import AVFoundation
import UIKit

final class ATCameraPicker: NSObject {

    private var completion: ((ATPickedMedia?) -> Void)?

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func present(from viewController: UIViewController, completion: @escaping (ATPickedMedia?) -> Void) {
        guard Self.isAvailable else {
            completion(nil)
            presentNotice(
                title: "No camera on this device",
                message: "Choose a photograph from your library instead.",
                from: viewController
            )
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.open(from: viewController, granted: granted, completion: completion)
                }
            }

        case .denied, .restricted:
            open(from: viewController, granted: false, completion: completion)

        default:
            open(from: viewController, granted: true, completion: completion)
        }
    }

    private func open(
        from viewController: UIViewController,
        granted: Bool,
        completion: @escaping (ATPickedMedia?) -> Void
    ) {
        guard granted else {
            completion(nil)

            if AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
                presentNotice(
                    title: "Camera access is off",
                    message: "Camera use is restricted on this device. Choose a photograph from your library instead.",
                    from: viewController
                )
            } else {
                presentRefusal(from: viewController)
            }
            return
        }

        self.completion = completion

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        picker.view.tintColor = ATTheme.Palette.accent
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    private func presentRefusal(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Camera access is off",
            message: "Allow ATrimp to use the camera in Settings, or choose a photograph from your library instead.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alert, animated: true)
    }

    private func presentNotice(title: String, message: String, from viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        viewController.present(alert, animated: true)
    }

    private func finish(with media: ATPickedMedia?) {
        let handler = completion
        completion = nil
        handler?(media)
    }
}

extension ATCameraPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        finish(with: image.map { ATPickedMedia(kind: .image, image: $0, videoURL: nil) })
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finish(with: nil)
    }
}
