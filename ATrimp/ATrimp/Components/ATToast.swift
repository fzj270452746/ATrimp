//
//  ATToast.swift
//  ATrimp
//
//
import SnapKit
import UIKit

enum ATToast {

    private static let tag = 9_142

    static func show(_ message: String, in view: UIView? = nil) {
        guard let host = view ?? keyWindow else { return }
        host.viewWithTag(tag)?.removeFromSuperview()

        let container = UIView()
        container.tag = tag
        container.backgroundColor = ATTheme.Palette.ink
        container.layer.cornerRadius = ATTheme.Radius.small
        container.layer.cornerCurve = .continuous
        container.alpha = 0
        container.transform = CGAffineTransform(translationX: 0, y: 12)
        ATTheme.Elevation.apply(to: container, level: 2)

        let accent = UIView()
        accent.backgroundColor = ATTheme.Palette.accent
        accent.layer.cornerRadius = 1

        let label = UILabel()
        label.text = message
        label.font = ATTheme.Typeface.sans(14, .medium)
        label.textColor = ATTheme.Palette.paper
        label.numberOfLines = 0
        label.textAlignment = .left

        container.addSubview(accent)
        container.addSubview(label)
        host.addSubview(container)

        accent.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.width.equalTo(2)
            make.top.equalToSuperview().offset(13)
            make.bottom.equalToSuperview().offset(-13)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(accent.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
            make.bottom.equalTo(host.safeAreaLayoutGuide.snp.bottom).offset(-96)
        }

        host.layoutIfNeeded()

        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            container.alpha = 1
            container.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            UIView.animate(withDuration: 0.24, animations: {
                container.alpha = 0
                container.transform = CGAffineTransform(translationX: 0, y: 8)
            }, completion: { _ in
                container.removeFromSuperview()
            })
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
