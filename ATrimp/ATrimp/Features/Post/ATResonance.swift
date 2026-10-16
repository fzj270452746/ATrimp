//
//  ATResonance.swift
//  ATrimp
//
//
//
import UIKit

extension ATViewController {

    @discardableResult
    func toggleSameHere(on post: ATPost, repaint: (ATPost) -> Void) -> ATPost? {
        guard !requireSignIn(message: "Sign in to say you did the same.") else { return nil }

        ATStore.setSameHere(!post.isSameHere, postID: post.id)
        guard let updated = ATStore.post(id: post.id) else { return nil }

        repaint(updated)
        return updated
    }
}
