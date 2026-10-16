//
//  ATMediaGrid.swift
//  ATrimp
//
//
import UIKit

enum ATMediaGridLayout {

    static let spacing: CGFloat = 3

    static func height(for media: [ATPostMedia], width: CGFloat) -> CGFloat {
        guard !media.isEmpty else { return 0 }

        switch media.count {
        case 1:
            let ratio = CGFloat(media[0].aspect)
            let clamped = min(max(ratio, 0.72), 1.6)
            return (width / clamped).rounded()
        case 2:
            return ((width - spacing) / 2).rounded()
        case 3:
            return (width * 0.62).rounded()
        case 4:
            return ((width - spacing) / 2 * 2 + spacing).rounded()
        default:
            let column = (width - spacing * 2) / 3
            return (column * 2 + spacing).rounded()
        }
    }
}

final class ATMediaGrid: UIView {

    private var media: [ATPostMedia] = []
    private var imageViews: [UIImageView] = []
    private var badgeViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = ATTheme.Palette.paperDeep
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with media: [ATPostMedia]) {
        self.media = media
        imageViews.forEach { $0.removeFromSuperview() }
        badgeViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        badgeViews.removeAll()

        for item in media {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = ATTheme.Palette.paperDeep
            addSubview(imageView)
            imageViews.append(imageView)

            if item.kind == .video {
                let badge = makePlayBadge()
                imageView.addSubview(badge)
                badgeViews.append(badge)
            }
        }

        if media.count > 6 {
            let overflow = makeOverflowLabel(count: media.count - 6)
            addSubview(overflow)
            badgeViews.append(overflow)
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = bounds.width
        let gap = ATMediaGridLayout.spacing
        let count = media.count
        guard count > 0, width > 0 else { return }

        switch count {
        case 1:
            imageViews[0].frame = bounds
        case 2:
            let side = (width - gap) / 2
            imageViews[0].frame = CGRect(x: 0, y: 0, width: side, height: bounds.height)
            imageViews[1].frame = CGRect(x: side + gap, y: 0, width: side, height: bounds.height)
        case 3:
            let leftWidth = (width * 0.62).rounded()
            let rightWidth = width - leftWidth - gap
            let smallHeight = (bounds.height - gap) / 2
            imageViews[0].frame = CGRect(x: 0, y: 0, width: leftWidth, height: bounds.height)
            imageViews[1].frame = CGRect(x: leftWidth + gap, y: 0, width: rightWidth, height: smallHeight)
            imageViews[2].frame = CGRect(x: leftWidth + gap, y: smallHeight + gap, width: rightWidth, height: smallHeight)
        case 4:
            let side = (width - gap) / 2
            for index in 0..<4 {
                let column = CGFloat(index % 2)
                let row = CGFloat(index / 2)
                imageViews[index].frame = CGRect(
                    x: column * (side + gap),
                    y: row * (side + gap),
                    width: side,
                    height: side
                )
            }
        default:
            let columns = 3
            let side = (width - gap * CGFloat(columns - 1)) / CGFloat(columns)
            let rows = bounds.height / (side + gap)
            for index in 0..<min(count, 6) {
                let column = CGFloat(index % columns)
                let row = CGFloat(index / columns)
                let isLastSlot = index == 5
                imageViews[index].frame = CGRect(
                    x: column * (side + gap),
                    y: row * (side + gap),
                    width: side,
                    height: isLastSlot && rows > 1.5 ? side : side
                )
            }
        }

        for (index, item) in media.enumerated() where index < imageViews.count {
            let frame = imageViews[index].frame
            guard frame.width > 1, frame.height > 1 else { continue }
            let symbol = item.kind == .video ? "play.fill" : nil
            imageViews[index].image = ATMediaLibrary.image(for: item, size: frame.size, symbol: symbol)
        }

        for badge in badgeViews {
            if let play = badge as? UIImageView {
                let host = play.superview
                play.frame = CGRect(
                    x: ((host?.bounds.width ?? 0) - 30) / 2,
                    y: ((host?.bounds.height ?? 0) - 30) / 2,
                    width: 30,
                    height: 30
                )
            } else {
                badge.frame = CGRect(x: bounds.width - 66, y: bounds.height - 34, width: 58, height: 26)
            }
        }
    }

    private func makePlayBadge() -> UIImageView {
        let badge = UIImageView()
        badge.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.55)
        badge.layer.cornerRadius = 15
        badge.contentMode = .center
        let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        badge.image = UIImage(systemName: "play.fill", withConfiguration: configuration)?
            .withTintColor(ATTheme.Palette.paper, renderingMode: .alwaysOriginal)
        return badge
    }

    private func makeOverflowLabel(count: Int) -> UILabel {
        let label = UILabel()
        label.text = "+\(count)"
        label.font = ATTheme.Typeface.sans(13, .semibold)
        label.textColor = ATTheme.Palette.paper
        label.textAlignment = .center
        label.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.55)
        label.layer.cornerRadius = 13
        label.clipsToBounds = true
        return label
    }
}
