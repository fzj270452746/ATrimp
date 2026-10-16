//
//  ATFilterBar.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATFilterBar: UIView {

    var onSelect: ((ATPostTheme?) -> Void)?

    private(set) var selected: ATPostTheme?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private var entries: [(theme: ATPostTheme?, tint: UIColor)] = []
    private var buttons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paper

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: ATTheme.Space.gutter, bottom: 0, right: ATTheme.Space.gutter)
        addSubview(scrollView)

        stack.axis = .horizontal
        stack.spacing = ATTheme.Space.xs
        stack.alignment = .center
        scrollView.addSubview(stack)

        addChip(theme: nil, title: "Everything", symbol: "circle.grid.2x2", tint: ATTheme.Palette.ink)
        for theme in ATPostTheme.allCases {
            addChip(theme: theme, title: theme.title, symbol: theme.symbol, tint: theme.tint)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(50)
        }

        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func select(_ theme: ATPostTheme?, animated: Bool) {
        selected = theme
        if animated {
            UIView.animate(withDuration: 0.2) { self.refresh() }
        } else {
            refresh()
        }
    }

    // MARK: - Building

    private func addChip(theme: ATPostTheme?, title: String, symbol: String, tint: UIColor) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        )
        configuration.imagePadding = 5
        configuration.imagePlacement = .leading
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)

        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = ATTheme.Typeface.sans(13, .semibold)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.layer.borderWidth = ATTheme.hairline
        button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)

        entries.append((theme, tint))
        buttons.append(button)
        stack.addArrangedSubview(button)
    }

    private func refresh() {
        for (index, button) in buttons.enumerated() {
            let entry = entries[index]
            let isActive = entry.theme == selected

            button.backgroundColor = isActive ? entry.tint : .clear
            button.layer.borderColor = (isActive ? entry.tint : ATTheme.Palette.rule).cgColor

            var configuration = button.configuration
            configuration?.baseForegroundColor = isActive ? ATTheme.Palette.paper : ATTheme.Palette.inkSoft
            configuration?.background.backgroundColor = .clear
            button.configuration = configuration
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        guard let index = buttons.firstIndex(of: sender) else { return }
        let theme = entries[index].theme
        guard theme != selected else { return }
        selected = theme
        refresh()
        onSelect?(theme)
    }
}
