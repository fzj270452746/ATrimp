//
//  ATAuthViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

class ATAuthViewController: UIViewController {

    let scrollView = UIScrollView()
    let contentView = UIView()
    let fieldStack = UIStackView()
    let actionStack = UIStackView()

    private let footer = ATLegalFooter()
    private let headline: String
    private let standfirst: String

    init(headline: String, standfirst: String) {
        self.headline = headline
        self.standfirst = standfirst
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let close = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        close.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        close.tintColor = ATTheme.Palette.ink
        close.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        contentView.addSubview(close)

        let brand = UILabel()
        brand.text = headline
        brand.font = ATTheme.Typeface.serif(38, .semibold)
        brand.textColor = ATTheme.Palette.ink
        brand.numberOfLines = 0
        contentView.addSubview(brand)

        let rule = ATRule(color: ATTheme.Palette.accent)
        rule.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(3)
        }
        contentView.addSubview(rule)

        let standfirstLabel = UILabel()
        standfirstLabel.text = standfirst
        standfirstLabel.font = ATTheme.Typeface.body
        standfirstLabel.textColor = ATTheme.Palette.inkSoft
        standfirstLabel.numberOfLines = 0
        contentView.addSubview(standfirstLabel)

        fieldStack.axis = .vertical
        fieldStack.spacing = ATTheme.Space.lg
        contentView.addSubview(fieldStack)

        actionStack.axis = .vertical
        actionStack.spacing = ATTheme.Space.sm
        contentView.addSubview(actionStack)

        footer.onOpenDocument = { [weak self] document in
            self?.present(ATLegalViewController(document: document), animated: true)
        }
        view.addSubview(footer)

        close.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.width.height.equalTo(36)
        }

        brand.snp.makeConstraints { make in
            make.top.equalTo(close.snp.bottom).offset(ATTheme.Space.xl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(brand.snp.bottom).offset(ATTheme.Space.md)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        standfirstLabel.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        fieldStack.snp.makeConstraints { make in
            make.top.equalTo(standfirstLabel.snp.bottom).offset(ATTheme.Space.xl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        actionStack.snp.makeConstraints { make in
            make.top.equalTo(fieldStack.snp.bottom).offset(ATTheme.Space.xl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.lessThanOrEqualToSuperview().offset(-ATTheme.Space.xl)
        }

        footer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.lg)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.sm)
        }

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(footer.snp.top).offset(-ATTheme.Space.md)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
            make.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide.snp.height)
        }

        buildContent()
    }

    func buildContent() {}

    // MARK: - Behaviour

    @objc func handleClose() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    func showError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        ATToast.show(message, in: view)
    }

    func makeDivider(_ text: String) -> UIView {
        let container = UIView()

        let left = ATRule()
        let right = ATRule()
        let label = UILabel()
        label.text = text.lowercased()
        label.font = ATTheme.Typeface.caption
        label.textColor = ATTheme.Palette.inkFaint

        container.addSubview(left)
        container.addSubview(label)
        container.addSubview(right)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        left.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalTo(label.snp.leading).offset(-ATTheme.Space.sm)
            make.centerY.equalToSuperview()
        }
        right.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return container
    }
}
