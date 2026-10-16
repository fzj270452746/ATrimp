//
//  ATAboutViewController.swift
//  ATrimp
//
import SnapKit
import UIKit

final class ATAboutViewController: UIViewController {

    private struct Feature {
        let symbol: String
        let title: String
        let detail: String
    }

    private let features: [Feature] = [
        Feature(
            symbol: "arrow.uturn.backward",
            title: "Write the honest version",
            detail: "File a trip under what you regret, what surprised you, the place nobody told you about, or the mistake that cost you a day."
        ),
        Feature(
            symbol: "mappin.and.ellipse",
            title: "Follow the places, not the guides",
            detail: "Every note carries a location, so you can read what people found on the same stretch of coast you are heading for."
        ),
        Feature(
            symbol: "bubble.left.and.bubble.right",
            title: "Talk to people on the same route",
            detail: "Conversations stay between people who follow each other or have added one another. There is no open inbox."
        ),
        Feature(
            symbol: "gift",
            title: "Send something back",
            detail: "Eight gifts, from a postcard to a round trip. A small way of saying a note saved you a wasted afternoon."
        ),
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let close = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        close.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        close.tintColor = ATTheme.Palette.ink
        close.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(close)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = ATTheme.Space.md
        scrollView.addSubview(content)

        let brand = UILabel()
        brand.text = "ATrimp"
        brand.font = ATTheme.Typeface.serif(40, .semibold)
        brand.textColor = ATTheme.Palette.ink
        content.addArrangedSubview(brand)

        let rule = ATRule(color: ATTheme.Palette.accent)
        rule.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(3)
        }
        let ruleHolder = UIView()
        ruleHolder.addSubview(rule)
        rule.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        content.addArrangedSubview(ruleHolder)

        let version = UILabel()
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        version.text = "Version \(shortVersion) (\(build))"
        version.font = ATTheme.Typeface.caption
        version.textColor = ATTheme.Palette.inkFaint
        content.addArrangedSubview(version)

        let intro = UILabel()
        intro.text = "ATrimp is a place to write down a trip after it has finished — not the itinerary you planned, but what actually happened. The detour that was worth it, the queue that was not, the town you would go back to tomorrow."
        intro.font = ATTheme.Typeface.body
        intro.textColor = ATTheme.Palette.inkSoft
        intro.numberOfLines = 0
        content.addArrangedSubview(intro)

        content.setCustomSpacing(ATTheme.Space.xl, after: intro)

        for feature in features {
            content.addArrangedSubview(makeRow(feature))
        }

        content.setCustomSpacing(ATTheme.Space.xl, after: content.arrangedSubviews.last!)

        let contact = UILabel()
        contact.text = "Questions, problems or a note that should not be here: support@atrimp.example.com"
        contact.font = ATTheme.Typeface.caption
        contact.textColor = ATTheme.Palette.inkFaint
        contact.numberOfLines = 0
        content.addArrangedSubview(contact)

        close.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.width.height.equalTo(36)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        content.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ATTheme.Space.xl)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xxl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width).offset(-ATTheme.Space.gutter * 2)
        }
    }

    private func makeRow(_ feature: Feature) -> UIView {
        let container = UIView()

        let symbolView = UIImageView()
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        symbolView.image = UIImage(systemName: feature.symbol, withConfiguration: configuration)
        symbolView.tintColor = ATTheme.Palette.accent
        symbolView.contentMode = .scaleAspectFit
        container.addSubview(symbolView)

        let title = UILabel()
        title.text = feature.title
        title.font = ATTheme.Typeface.subtitle
        title.textColor = ATTheme.Palette.ink
        title.numberOfLines = 0
        container.addSubview(title)

        let detail = UILabel()
        detail.text = feature.detail
        detail.font = ATTheme.Typeface.sans(14)
        detail.textColor = ATTheme.Palette.inkSoft
        detail.numberOfLines = 0
        container.addSubview(detail)

        symbolView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.width.height.equalTo(20)
        }

        title.snp.makeConstraints { make in
            make.leading.equalTo(symbolView.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }

        detail.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.trailing.equalToSuperview()
            make.top.equalTo(title.snp.bottom).offset(3)
            make.bottom.equalToSuperview()
        }

        return container
    }

    @objc private func handleClose() {
        dismiss(animated: true)
    }
}
