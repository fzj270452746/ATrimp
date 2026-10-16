//
//  ATControls.swift
//
//
import SnapKit
import UIKit

// MARK: - Rule

final class ATRule: UIView {
    init(color: UIColor = ATTheme.Palette.rule) {
        super.init(frame: .zero)
        backgroundColor = color
        snp.makeConstraints { make in
            make.height.equalTo(ATTheme.hairline)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

// MARK: - Buttons

final class ATPrimaryButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = ATTheme.Typeface.action
        backgroundColor = ATTheme.Palette.ink
        setTitleColor(ATTheme.Palette.paper, for: .normal)
        layer.cornerRadius = ATTheme.Radius.small
        layer.cornerCurve = .continuous
        snp.makeConstraints { make in
            make.height.equalTo(52)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.alpha = self.isHighlighted ? 0.82 : 1
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.4
        }
    }
}

class ATInsetButton: UIButton {

    var contentPadding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(
            width: base.width + contentPadding.left + contentPadding.right,
            height: base.height + contentPadding.top + contentPadding.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let base = super.sizeThatFits(size)
        return CGSize(
            width: base.width + contentPadding.left + contentPadding.right,
            height: base.height + contentPadding.top + contentPadding.bottom
        )
    }

    override func contentRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: contentPadding)
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        super.titleRect(forContentRect: contentRect)
    }
}

final class ATGhostButton: ATInsetButton {

    init(title: String, tint: UIColor = ATTheme.Palette.ink) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = ATTheme.Typeface.sans(14, .semibold)
        setTitleColor(tint, for: .normal)
        backgroundColor = .clear
        layer.borderWidth = ATTheme.hairline
        layer.borderColor = tint.withAlphaComponent(0.45).cgColor
        layer.cornerRadius = ATTheme.Radius.small
        layer.cornerCurve = .continuous
        contentPadding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func apply(title: String, tint: UIColor) {
        setTitle(title, for: .normal)
        setTitleColor(tint, for: .normal)
        layer.borderColor = tint.withAlphaComponent(0.45).cgColor
    }
}

final class ATPillButton: ATInsetButton {

    init(title: String, filled: Bool = false, tint: UIColor = ATTheme.Palette.ink) {
        super.init(frame: .zero)
        titleLabel?.font = ATTheme.Typeface.sans(13, .semibold)
        contentPadding = UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        apply(title: title, filled: filled, tint: tint)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func apply(title: String, filled: Bool, tint: UIColor) {
        setTitle(title, for: .normal)
        setTitleColor(filled ? ATTheme.Palette.paper : tint, for: .normal)
        backgroundColor = filled ? tint : .clear
        layer.borderWidth = filled ? 0 : ATTheme.hairline
        layer.borderColor = tint.withAlphaComponent(0.5).cgColor
    }
}

// MARK: - Link

final class ATLinkLabel: UIControl {

    var onTap: (() -> Void)?

    private let label = UILabel()
    private let tint: UIColor
    private let underline: UIColor

    init(font: UIFont, tint: UIColor, underline: UIColor) {
        self.tint = tint
        self.underline = underline
        super.init(frame: .zero)

        label.font = font
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.55 : 1 }
    }

    func setText(_ text: String) {
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: label.font as Any,
                .foregroundColor: tint,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: underline,
            ]
        )
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize { label.intrinsicContentSize }

    @objc private func handleTap() { onTap?() }
}

// MARK: - Intensity

final class ATIntensityMark: UIView {

    private var bars: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 3
        row.alignment = .bottom
        addSubview(row)

        for step in 1...5 {
            let bar = UIView()
            bar.layer.cornerRadius = 1.5
            bar.layer.borderWidth = 1
            bar.snp.makeConstraints { make in
                make.width.equalTo(9)
                make.height.equalTo(5 + CGFloat(step - 1) * 2.5)
            }
            row.addArrangedSubview(bar)
            bars.append(bar)
        }

        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(value: Int?, tint: UIColor) {
        guard let value else {
            isHidden = true
            return
        }
        isHidden = false

        for (index, bar) in bars.enumerated() {
            let filled = value >= index + 1
            bar.backgroundColor = filled ? tint : .clear
            bar.layer.borderColor = (filled ? tint : ATTheme.Palette.ruleStrong).cgColor
        }
    }
}

// MARK: - Field

final class ATFieldRow: UIView {

    let textField = UITextField()

    private let captionLabel = UILabel()
    private let underline = UIView()

    init(caption: String, placeholder: String, secure: Bool = false, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)

        captionLabel.attributedText = ATTheme.sectionLabel(caption)
        addSubview(captionLabel)

        textField.placeholder = placeholder
        textField.font = ATTheme.Typeface.sans(16)
        textField.textColor = ATTheme.Palette.ink
        textField.isSecureTextEntry = secure
        textField.keyboardType = keyboard
        textField.autocapitalizationType = keyboard == .emailAddress ? .none : .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.tintColor = ATTheme.Palette.accent
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: ATTheme.Typeface.sans(16),
                .foregroundColor: ATTheme.Palette.inkFaint,
            ]
        )
        textField.addTarget(self, action: #selector(editingBegan), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)
        addSubview(textField)

        underline.backgroundColor = ATTheme.Palette.rule
        addSubview(underline)

        captionLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(captionLabel.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
        }

        underline.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ATTheme.hairline)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func editingBegan() {
        UIView.animate(withDuration: 0.18) {
            self.underline.backgroundColor = ATTheme.Palette.ink
        }
    }

    @objc private func editingEnded() {
        UIView.animate(withDuration: 0.18) {
            self.underline.backgroundColor = ATTheme.Palette.rule
        }
    }
}

// MARK: - Checkbox

final class ATCheckbox: UIControl {

    private let box = UIView()
    private let tick = UIImageView()
    private let label = UILabel()

    override var isSelected: Bool {
        didSet { refresh() }
    }

    init(text: String) {
        super.init(frame: .zero)

        box.layer.borderWidth = 1
        box.layer.borderColor = ATTheme.Palette.inkSoft.cgColor
        box.layer.cornerRadius = ATTheme.Radius.hairline
        box.isUserInteractionEnabled = false
        addSubview(box)

        let configuration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        tick.image = UIImage(systemName: "checkmark", withConfiguration: configuration)
        tick.tintColor = ATTheme.Palette.paper
        tick.contentMode = .center
        box.addSubview(tick)

        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        addSubview(label)

        box.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.width.height.equalTo(20)
        }

        tick.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(box.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setAttributedText(_ text: NSAttributedString) {
        label.attributedText = text
    }

    @objc private func toggle() {
        isSelected.toggle()
        sendActions(for: .valueChanged)
    }

    private func refresh() {
        UIView.animate(withDuration: 0.16) {
            self.box.backgroundColor = self.isSelected ? ATTheme.Palette.ink : .clear
            self.box.layer.borderColor = (self.isSelected ? ATTheme.Palette.ink : ATTheme.Palette.inkSoft).cgColor
            self.tick.alpha = self.isSelected ? 1 : 0
        }
    }
}

// MARK: - Theme tag

final class ATThemeChip: UIView {

    private let symbolView = UIImageView()
    private let label = UILabel()

    init(theme: ATPostTheme, compact: Bool = false) {
        super.init(frame: .zero)

        backgroundColor = theme.tint.withAlphaComponent(0.13)
        layer.cornerRadius = ATTheme.Radius.pill
        layer.borderWidth = ATTheme.hairline
        layer.borderColor = theme.tint.withAlphaComponent(0.32).cgColor

        let configuration = UIImage.SymbolConfiguration(pointSize: compact ? 9 : 10.5, weight: .semibold)
        symbolView.image = UIImage(systemName: theme.symbol, withConfiguration: configuration)
        symbolView.tintColor = theme.tint
        symbolView.contentMode = .scaleAspectFit
        addSubview(symbolView)

        label.text = theme.title.uppercased()
        label.font = ATTheme.Typeface.sans(compact ? 9.5 : 10.5, .semibold)
        label.textColor = theme.tint
        addSubview(label)

        symbolView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(compact ? 7 : 9)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(compact ? 10 : 12)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(symbolView.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(compact ? -7 : -9)
            make.top.equalToSuperview().offset(compact ? 3 : 4)
            make.bottom.equalToSuperview().offset(compact ? -3 : -4)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

// MARK: - Meta line

final class ATMetricLabel: UIView {

    private let symbolView = UIImageView()
    private let label = UILabel()

    init(symbol: String, text: String, tint: UIColor = ATTheme.Palette.inkSoft) {
        super.init(frame: .zero)

        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        symbolView.image = UIImage(systemName: symbol, withConfiguration: configuration)
        symbolView.tintColor = tint
        symbolView.contentMode = .scaleAspectFit
        addSubview(symbolView)

        label.text = text
        label.font = ATTheme.Typeface.sans(12.5, .medium)
        label.textColor = tint
        addSubview(label)

        symbolView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(15)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(symbolView.snp.trailing).offset(5)
            make.trailing.top.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func set(text: String, tint: UIColor) {
        label.text = text
        symbolView.tintColor = tint
        label.textColor = tint
    }

    func set(symbol: String, tint: UIColor) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        symbolView.image = UIImage(systemName: symbol, withConfiguration: configuration)
        symbolView.tintColor = tint
    }
}
