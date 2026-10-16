//
//  ATAvatarView.swift
//  ATrimp
//
import SnapKit
import UIKit

final class ATAvatarView: UIImageView {

    private let side: CGFloat

    init(size: CGFloat) {
        self.side = size
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        layer.cornerRadius = size / 2
        snp.makeConstraints { make in
            make.width.height.equalTo(size)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func set(user: ATUser?) {
        guard let user else {
            image = ATArt.avatarImage(seed: "unknown", initials: "?", size: side)
            return
        }
        set(seed: user.avatarSeed, initials: user.initials)
    }

    func set(seed: String, initials: String) {
        if seed.hasPrefix("file:") {
            image = ATMediaLibrary.image(
                reference: seed,
                size: CGSize(width: side * 3, height: side * 3)
            )
        } else {
            image = ATArt.avatarImage(seed: seed, initials: initials, size: side)
        }
    }
}
