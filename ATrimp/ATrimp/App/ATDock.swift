//
//  ATDock.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATDock: UIView {

    struct Item {
        let symbol: String
        let activeSymbol: String
    }

    var onSelect: ((Int) -> Void)?

    private(set) var selectedIndex = 0

    private let items: [Item]
    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private let indicator = UIView()

    static let height: CGFloat = 60

    private static let sideInset: CGFloat = 10

    init(items: [Item]) {
        self.items = items
        super.init(frame: .zero)

        backgroundColor = ATTheme.Palette.ink
        layer.cornerRadius = Self.height / 2
        layer.cornerCurve = .continuous
        layer.borderWidth = ATTheme.hairline
        layer.borderColor = ATTheme.Palette.paper.withAlphaComponent(0.12).cgColor
        ATTheme.Elevation.apply(to: self, level: 2)

        indicator.backgroundColor = ATTheme.Palette.accent
        indicator.layer.cornerRadius = 1.5

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        addSubview(stack)

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.tintColor = ATTheme.Palette.paper
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            button.accessibilityLabel = item.symbol
            stack.addArrangedSubview(button)
            buttons.append(button)
        }

        addSubview(indicator)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 8, left: Self.sideInset, bottom: 8, right: Self.sideInset)
            )
        }

        snp.makeConstraints { make in
            make.height.equalTo(Self.height)
        }

        refresh(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width: CGFloat = 18
        let height: CGFloat = 3

        let column = (bounds.width - Self.sideInset * 2) / CGFloat(buttons.count)
        let center = Self.sideInset + column * (CGFloat(selectedIndex) + 0.5)

        indicator.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        indicator.center = CGPoint(x: center, y: bounds.height - 11)
    }

    func select(_ index: Int, animated: Bool) {
        guard items.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
        refresh(animated: animated)
        onSelect?(index)
    }

    private func refresh(animated: Bool) {
        for (index, button) in buttons.enumerated() {
            let item = items[index]
            let isActive = index == selectedIndex
            let configuration = UIImage.SymbolConfiguration(pointSize: isActive ? 20 : 19, weight: isActive ? .semibold : .regular)
            let name = isActive ? item.activeSymbol : item.symbol

            UIView.transition(with: button, duration: animated ? 0.2 : 0, options: .transitionCrossDissolve) {
                button.setImage(UIImage(systemName: name, withConfiguration: configuration), for: .normal)
                button.tintColor = isActive
                    ? ATTheme.Palette.paper
                    : ATTheme.Palette.paper.withAlphaComponent(0.44)
            }
        }

        setNeedsLayout()

        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        select(sender.tag, animated: true)
    }
}
