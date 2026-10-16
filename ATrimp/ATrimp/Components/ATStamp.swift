//
//  ATStamp.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATStamp: UIView {

    private let label = UILabel()
    private let inset: UIEdgeInsets

    init(text: String, tint: UIColor = ATTheme.Palette.mist, compact: Bool = false) {
        self.inset = compact
            ? UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
            : UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        super.init(frame: .zero)

        backgroundColor = .clear
        isUserInteractionEnabled = false

        label.text = text.uppercased()
        label.font = ATTheme.Typeface.sans(compact ? 9 : 10, .heavy)
        label.textColor = tint
        addSubview(label)

        layer.borderColor = tint.withAlphaComponent(0.7).cgColor
        layer.borderWidth = compact ? 1 : 1.4
        layer.cornerRadius = ATTheme.Radius.hairline

        label.attributedText = NSAttributedString(
            string: text.uppercased(),
            attributes: [
                .font: ATTheme.Typeface.sans(compact ? 9 : 10, .heavy),
                .foregroundColor: tint,
                .kern: compact ? 0.8 : 1.2,
            ]
        )

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(inset)
        }

        transform = CGAffineTransform(rotationAngle: -3.5 * .pi / 180)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}
