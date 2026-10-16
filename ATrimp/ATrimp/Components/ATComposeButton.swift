//
//  ATComposeButton.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATComposeButton: UIButton {

    static let size: CGFloat = 56

    var onTap: (() -> Void)?

    private(set) var isShown = false

    init() {
        super.init(frame: .zero)

        backgroundColor = ATTheme.Palette.accent
        layer.cornerRadius = Self.size / 2
        layer.cornerCurve = .continuous
        layer.borderWidth = ATTheme.hairline
        layer.borderColor = ATTheme.Palette.paper.withAlphaComponent(0.24).cgColor
        ATTheme.Elevation.apply(to: self, level: 2)

        let configuration = UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)
        setImage(UIImage(systemName: "square.and.pencil", withConfiguration: configuration), for: .normal)
        tintColor = ATTheme.Palette.paper
        accessibilityLabel = "File a trip"

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        alpha = 0
        isUserInteractionEnabled = false
        transform = Self.restingTransform

        snp.makeConstraints { make in
            make.width.height.equalTo(Self.size)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setShown(_ shown: Bool, animated: Bool) {
        guard shown != isShown else { return }
        isShown = shown
        isUserInteractionEnabled = shown

        let changes = {
            self.alpha = shown ? 1 : 0
            self.transform = shown ? .identity : Self.restingTransform
        }

        if animated {
            UIView.animate(withDuration: 0.24, delay: 0, options: .curveEaseInOut, animations: changes)
        } else {
            changes()
        }
    }

    private static var restingTransform: CGAffineTransform {
        CGAffineTransform(translationX: 0, y: size * 0.5)
            .scaledBy(x: 0.85, y: 0.85)
    }

    override var isHighlighted: Bool {
        didSet {
            guard isShown else { return }
            UIView.animate(withDuration: 0.12) {
                self.alpha = self.isHighlighted ? 0.82 : 1
            }
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
