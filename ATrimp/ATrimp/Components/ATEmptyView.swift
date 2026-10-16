//
//  ATEmptyView.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATEmptyView: UIView {

    private let rule = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    private var action: (() -> Void)?

    var onAction: (() -> Void)?

    init(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        super.init(frame: .zero)
        self.action = action

        rule.backgroundColor = ATTheme.Palette.rule
        addSubview(rule)

        titleLabel.text = title
        titleLabel.font = ATTheme.Typeface.title
        titleLabel.textColor = ATTheme.Palette.ink
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        messageLabel.text = message
        messageLabel.font = ATTheme.Typeface.body
        messageLabel.textColor = ATTheme.Palette.inkSoft
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        addSubview(messageLabel)

        actionButton.setAttributedTitle(ATTheme.sectionLabel(actionTitle ?? "", color: ATTheme.Palette.accent), for: .normal)
        actionButton.isHidden = actionTitle == nil
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        addSubview(actionButton)

        rule.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(2)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalTo(titleLabel)
        }

        actionButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(ATTheme.Space.lg)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func handleAction() {
        (onAction ?? action)?()
    }
}
