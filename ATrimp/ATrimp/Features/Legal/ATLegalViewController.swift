//
//  ATLegalViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit
import WebKit

final class ATLegalViewController: UIViewController {

    private let document: ATLegalDocument

    private let webView = WKWebView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let failureView = UIView()
    private let failureLabel = UILabel()
    private let retryButton = ATGhostButton(title: "Try again")
    private let safariButton = ATGhostButton(title: "Open in Safari")

    init(document: ATLegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        let close = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        close.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        close.tintColor = ATTheme.Palette.ink
        close.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(close)

        let title = UILabel()
        title.text = document.title
        title.font = ATTheme.Typeface.serif(28, .semibold)
        title.textColor = ATTheme.Palette.ink
        title.numberOfLines = 0
        view.addSubview(title)

        let rule = ATRule()
        view.addSubview(rule)

        // The page arrives over the network, so the web view stays out of sight
        // until it is ready and the sheet keeps the paper ground meanwhile.
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = ATTheme.Palette.paper
        webView.scrollView.backgroundColor = ATTheme.Palette.paper
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.overrideUserInterfaceStyle = .light
        webView.isHidden = true
        view.addSubview(webView)

        spinner.color = ATTheme.Palette.inkFaint
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        buildFailureView()

        close.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.width.height.equalTo(36)
        }

        title.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ATTheme.Space.md)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.trailing.lessThanOrEqualTo(close.snp.leading).offset(-ATTheme.Space.sm)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        webView.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        spinner.snp.makeConstraints { make in
            make.center.equalTo(webView)
        }

        load()
    }

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    // MARK: - Loading

    private func buildFailureView() {
        failureView.isHidden = true
        view.addSubview(failureView)

        failureLabel.text = "The page could not be loaded. Check your connection and try again."
        failureLabel.font = ATTheme.Typeface.sans(15)
        failureLabel.textColor = ATTheme.Palette.inkSoft
        failureLabel.textAlignment = .center
        failureLabel.numberOfLines = 0
        failureView.addSubview(failureLabel)

        let buttons = UIStackView(arrangedSubviews: [retryButton, safariButton])
        buttons.axis = .horizontal
        buttons.spacing = ATTheme.Space.sm
        buttons.distribution = .fillEqually
        failureView.addSubview(buttons)

        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
        safariButton.addTarget(self, action: #selector(handleOpenInSafari), for: .touchUpInside)

        failureView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
        }

        failureLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        buttons.snp.makeConstraints { make in
            make.top.equalTo(failureLabel.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func load() {
        failureView.isHidden = true
        webView.isHidden = true
        spinner.startAnimating()
        webView.load(URLRequest(url: document.url))
    }

    @objc private func handleRetry() {
        load()
    }

    @objc private func handleOpenInSafari() {
        UIApplication.shared.open(document.url)
    }
}

// MARK: - Navigation

extension ATLegalViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        webView.isHidden = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        handle(error)
    }

    private func handle(_ error: Error) {
        // A cancelled load is the page redirecting, not a failure.
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        spinner.stopAnimating()
        failureView.isHidden = false
    }
}
