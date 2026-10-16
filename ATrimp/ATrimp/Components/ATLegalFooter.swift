//
//  ATLegalFooter.swift
//  ATrimp
//
//
import SnapKit
import UIKit

// MARK: - Tappable label

final class ATLinkedLabel: UILabel {

    private struct Link {
        let range: NSRange
        let payload: Any
    }

    private var links: [Link] = []
    private var storage: NSTextStorage?
    private var manager: NSLayoutManager?
    private var container: NSTextContainer?

    var onLink: ((Any) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        numberOfLines = 0
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func set(_ text: NSAttributedString, links: [(NSRange, Any)]) {
        attributedText = text
        self.links = links.map { Link(range: $0.0, payload: $0.1) }
        rebuildTextKit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rebuildTextKit()
    }

    private func rebuildTextKit() {
        guard let attributedText, bounds.width > 0 else { return }

        let storage = NSTextStorage(attributedString: attributedText)
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = numberOfLines
        container.lineBreakMode = lineBreakMode

        manager.addTextContainer(container)
        storage.addLayoutManager(manager)

        self.storage = storage
        self.manager = manager
        self.container = container
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let payload = payload(at: recognizer.location(in: self)) else { return }
        onLink?(payload)
    }

    private func payload(at point: CGPoint) -> Any? {
        guard let manager, let container, let storage else { return nil }

        let used = manager.usedRect(for: container)
        let offset = max(0, (bounds.height - used.height) / 2)
        let adjusted = CGPoint(x: point.x, y: point.y - offset)

        let index = manager.characterIndex(
            for: adjusted,
            in: container,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        guard index < storage.length else { return nil }

        let glyphIndex = manager.glyphIndexForCharacter(at: index)
        let glyphRect = manager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 1),
            in: container
        )
        guard glyphRect.insetBy(dx: -6, dy: -8).contains(adjusted) else { return nil }

        return links.first { NSLocationInRange(index, $0.range) }?.payload
    }
}

// MARK: - Footer

final class ATLegalFooter: UIView {

    var onOpenDocument: ((ATLegalDocument) -> Void)?

    private let label = ATLinkedLabel()

    init(prefix: String = "By continuing you agree with") {
        super.init(frame: .zero)

        let base: [NSAttributedString.Key: Any] = [
            .font: ATTheme.Typeface.sans(11.5),
            .foregroundColor: ATTheme.Palette.inkFaint,
        ]
        let highlighted: [NSAttributedString.Key: Any] = [
            .font: ATTheme.Typeface.sans(11.5, .semibold),
            .foregroundColor: ATTheme.Palette.accent,
        ]

        let text = NSMutableAttributedString(string: "\(prefix) ", attributes: base)
        var links: [(NSRange, Any)] = []

        let documents: [ATLegalDocument] = [.terms, .privacy, .eula]
        for (index, document) in documents.enumerated() {
            let separator: String
            if index == 0 {
                separator = ""
            } else if index == documents.count - 1 {
                separator = " & "
            } else {
                separator = " & "
            }

            if !separator.isEmpty {
                text.append(NSAttributedString(string: separator, attributes: base))
            }

            let start = text.length
            text.append(NSAttributedString(string: document.shortTitle, attributes: highlighted))
            links.append((NSRange(location: start, length: document.shortTitle.count), document))
        }

        label.set(text, links: links)
        label.textAlignment = .center
        label.onLink = { [weak self] payload in
            guard let document = payload as? ATLegalDocument else { return }
            self?.onOpenDocument?(document)
        }

        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}
