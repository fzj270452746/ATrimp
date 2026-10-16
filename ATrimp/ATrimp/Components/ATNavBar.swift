//
//  ATNavBar.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATNavBar: UIView {

    var onBack: (() -> Void)?

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let trailingStack = UIStackView()
    private let rule = UIView()

    private let showsBack: Bool

    init(title: String?, showsBack: Bool = true) {
        self.showsBack = showsBack
        super.init(frame: .zero)

        backgroundColor = ATTheme.Palette.paper

        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        backButton.setImage(UIImage(systemName: "arrow.left", withConfiguration: configuration), for: .normal)
        backButton.tintColor = ATTheme.Palette.ink
        backButton.contentHorizontalAlignment = .leading
        backButton.isHidden = !showsBack
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        addSubview(backButton)

        titleLabel.text = title
        titleLabel.font = ATTheme.Typeface.title
        titleLabel.textColor = ATTheme.Palette.ink
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        addSubview(titleLabel)

        trailingStack.axis = .horizontal
        trailingStack.spacing = ATTheme.Space.sm
        trailingStack.alignment = .center
        addSubview(trailingStack)

        rule.backgroundColor = ATTheme.Palette.rule
        addSubview(rule)

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.centerY.equalToSuperview()
            make.width.equalTo(showsBack ? 34 : 0)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(backButton.snp.trailing).offset(showsBack ? ATTheme.Space.sm : 0)
            make.centerY.equalToSuperview()
        }

        trailingStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(ATTheme.Space.sm)
        }

        rule.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ATTheme.hairline)
        }

        snp.makeConstraints { make in
            make.height.equalTo(56)
        }

    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    @discardableResult
    func addTrailing(symbol: String, action: Selector, target: Any) -> UIButton {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        button.setImage(UIImage(systemName: symbol, withConfiguration: configuration), for: .normal)
        button.tintColor = ATTheme.Palette.ink
        button.addTarget(target, action: action, for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        trailingStack.addArrangedSubview(button)
        return button
    }

    func addTrailing(view: UIView) {
        trailingStack.addArrangedSubview(view)
    }

    var trailingView: UIStackView { trailingStack }

    @objc private func handleBack() {
        onBack?()
    }
}
