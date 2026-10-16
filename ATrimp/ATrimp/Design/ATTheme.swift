//
//  ATTheme.swift
//  ATrimp
//
//
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255,
            blue: CGFloat(hex & 0x0000FF) / 255,
            alpha: alpha
        )
    }
}

enum ATTheme {

    // MARK: - Colour

    enum Palette {
        static let paper = UIColor(hex: 0xF4F1EA)
        static let paperDeep = UIColor(hex: 0xEAE5D9)
        static let paperRaised = UIColor(hex: 0xFCFAF5)

        static let ink = UIColor(hex: 0x14110F)
        static let inkSoft = UIColor(hex: 0x5A544C)
        static let inkFaint = UIColor(hex: 0x9A9384)

        static let rule = UIColor(hex: 0xD9D3C5)
        static let ruleStrong = UIColor(hex: 0xC3BCAA)

        static let accent = UIColor(hex: 0xC8452D)
        static let accentSoft = UIColor(hex: 0xEBD9D2)
        static let mist = UIColor(hex: 0x2F5D62)
        static let danger = UIColor(hex: 0xA82F2F)

        static let scrim = UIColor(hex: 0x14110F, alpha: 0.62)
    }

    // MARK: - Type

    enum Typeface {

        static func serif(_ size: CGFloat, _ weight: UIFont.Weight = .semibold) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        static func sans(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
            UIFont.systemFont(ofSize: size, weight: weight)
        }

        static func mono(_ size: CGFloat, _ weight: UIFont.Weight = .medium) -> UIFont {
            UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        }

        static var display: UIFont { serif(32, .semibold) }
        static var title: UIFont { serif(23, .semibold) }
        static var subtitle: UIFont { serif(17, .semibold) }
        static var body: UIFont { sans(15.5, .regular) }
        static var bodyStrong: UIFont { sans(15.5, .semibold) }
        static var caption: UIFont { sans(12.5, .regular) }
        static var captionStrong: UIFont { sans(12.5, .semibold) }
        static var action: UIFont { sans(15, .semibold) }
        static var metric: UIFont { mono(17, .semibold) }
    }

    static func sectionLabel(_ text: String, color: UIColor = Palette.inkSoft) -> NSAttributedString {
        NSAttributedString(
            string: text.uppercased(),
            attributes: [
                .font: Typeface.sans(11.5, .semibold),
                .foregroundColor: color,
                .kern: 1.6,
            ]
        )
    }

    // MARK: - Metrics

    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let gutter: CGFloat = 20
    }

    enum Radius {
        static let hairline: CGFloat = 2
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let pill: CGFloat = 999
    }

    enum Elevation {
        static func apply(to view: UIView, level: Int = 1) {
            view.layer.shadowColor = Palette.ink.cgColor
            view.layer.shadowOpacity = level >= 2 ? 0.16 : 0.09
            view.layer.shadowRadius = level >= 2 ? 24 : 12
            view.layer.shadowOffset = CGSize(width: 0, height: level >= 2 ? 10 : 4)
        }
    }

    // MARK: - Line

    static let hairline: CGFloat = 1 / UIScreen.main.scale
}
