//
//  ATShare.swift
//  ATrimp
//
//
import UIKit

extension ATViewController {

    func share(card image: UIImage, from anchor: UIView?) {
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        if let popover = activity.popoverPresentationController, let anchor {
            popover.sourceView = anchor
            popover.sourceRect = anchor.bounds
        }

        present(activity, animated: true)
    }

    func share(cardFor post: ATPost, author: ATUser?, media: [ATPostMedia], from anchor: UIView?) {
        let image = ATCardRenderer.card(for: post, author: author, media: media)
        share(card: image, from: anchor)
    }

    func share(cardFor dossier: ATPlaceDossier, from anchor: UIView?) {
        guard dossier.postCount > 0 else {
            showToast("Nothing has been filed here yet.")
            return
        }
        share(card: ATCardRenderer.card(for: dossier), from: anchor)
    }
}
