//
//  ATGiftSheetViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATGiftSheetViewController: UIViewController {

    private let post: ATPost
    private let onSent: ((ATGift) -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let noticeLabel = UILabel()
    private let grid = UIStackView()
    private let footNote = UILabel()

    private var tiles: [ATGiftTile] = []
    private var isPurchasing = false

    init(post: ATPost, onSent: ((ATGift) -> Void)? = nil) {
        self.post = post
        self.onSent = onSent
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        titleLabel.text = "Send a gift"
        titleLabel.font = ATTheme.Typeface.serif(26, .semibold)
        titleLabel.textColor = ATTheme.Palette.ink

        let authorName = ATStore.user(id: post.authorID)?.displayName ?? "this traveller"
        subtitleLabel.text = "It appears on the post for \(authorName) to see."
        subtitleLabel.font = ATTheme.Typeface.caption
        subtitleLabel.textColor = ATTheme.Palette.inkSoft
        subtitleLabel.numberOfLines = 0

        noticeLabel.font = ATTheme.Typeface.caption
        noticeLabel.textColor = ATTheme.Palette.danger
        noticeLabel.numberOfLines = 0
        noticeLabel.isHidden = true

        let rule = ATRule(color: ATTheme.Palette.accent)
        rule.snp.makeConstraints { make in
            make.width.equalTo(36)
            make.height.equalTo(3)
        }

        grid.axis = .vertical
        grid.spacing = ATTheme.Space.md
        grid.distribution = .fillEqually

        footNote.text = "Gifts are one-off purchases handled by the App Store. They carry no cash value."
        footNote.font = ATTheme.Typeface.sans(11.5)
        footNote.textColor = ATTheme.Palette.inkFaint
        footNote.numberOfLines = 0

        view.addSubview(titleLabel)
        view.addSubview(rule)
        view.addSubview(subtitleLabel)
        view.addSubview(noticeLabel)
        view.addSubview(grid)
        view.addSubview(footNote)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.xl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        noticeLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        grid.snp.makeConstraints { make in
            make.top.equalTo(noticeLabel.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        footNote.snp.makeConstraints { make in
            make.top.equalTo(grid.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.md)
        }

        buildGrid()
        loadPrices()
    }

    private func buildGrid() {
        for row in 0..<2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = ATTheme.Space.sm
            rowStack.distribution = .fillEqually

            for column in 0..<4 {
                let index = row * 4 + column
                guard index < ATGiftCatalog.tiers.count else { continue }

                let gift = ATGiftCatalog.tiers[index]
                let tile = ATGiftTile(gift: gift, price: ATStoreKit.shared.price(for: gift))
                tile.onTap = { [weak self] in self?.send(gift: gift, tier: index) }
                tiles.append(tile)
                rowStack.addArrangedSubview(tile)
            }
            grid.addArrangedSubview(rowStack)
        }
    }

    private func loadPrices() {
        Task { @MainActor in
            let products = await ATStoreKit.shared.loadProducts()

            if products.isEmpty {
                noticeLabel.text = "The App Store is not reachable right now, so gifts cannot be sent."
                noticeLabel.isHidden = false
                footNote.text = "Check your connection and open this again."
            } else {
                noticeLabel.isHidden = true
                for (index, tile) in tiles.enumerated() {
                    guard index < ATGiftCatalog.tiers.count else { continue }
                    tile.setPrice(ATStoreKit.shared.price(for: ATGiftCatalog.tiers[index]))
                }
            }
        }
    }

    // MARK: - Purchase

    private func send(gift: ATGift, tier: Int) {
        guard !isPurchasing else { return }
        guard let userID = ATSession.shared.userID else {
            ATToast.show("Sign in to send a gift.", in: view)
            return
        }

        isPurchasing = true
        setInteractionEnabled(false)
        tiles[tier].setBusy(true)

        Task { @MainActor in
            defer {
                self.isPurchasing = false
                self.setInteractionEnabled(true)
                self.tiles[tier].setBusy(false)
            }

            do {
                let transactionID = try await ATStoreKit.shared.purchase(gift: gift)
                ATStore.recordPurchase(sku: gift.sku, transactionID: transactionID)
                ATStore.addGift(postID: post.id, fromUserID: userID, gift: gift, tierIndex: tier)

                dismiss(animated: true) {
                    self.onSent?(gift)
                }
            } catch {
                if let purchaseError = error as? ATPurchaseError, purchaseError.errorDescription == nil {
                    return
                }
                ATToast.show((error as? LocalizedError)?.errorDescription ?? "The purchase did not complete.", in: view)
            }
        }
    }

    private func setInteractionEnabled(_ enabled: Bool) {
        tiles.forEach { $0.isUserInteractionEnabled = enabled }
        view.alpha = enabled ? 1 : 0.92
    }
}

// MARK: - Tile

private final class ATGiftTile: UIControl {

    var onTap: (() -> Void)?

    private let gift: ATGift
    private let iconHolder = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(gift: ATGift, price: String) {
        self.gift = gift
        super.init(frame: .zero)

        iconHolder.backgroundColor = ATTheme.Palette.accentSoft.withAlphaComponent(0.5)
        iconHolder.layer.cornerRadius = 26
        iconHolder.isUserInteractionEnabled = false
        addSubview(iconHolder)

        if let artwork = gift.artwork.flatMap({ UIImage(named: $0) }) {
            iconView.image = artwork.withRenderingMode(.alwaysOriginal)
            iconView.contentMode = .scaleAspectFit
        } else {
            let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            iconView.image = UIImage(systemName: gift.symbol, withConfiguration: configuration)
            iconView.tintColor = ATTheme.Palette.ink
            iconView.contentMode = .center
        }
        iconHolder.addSubview(iconView)

        nameLabel.text = gift.name
        nameLabel.font = ATTheme.Typeface.sans(11, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.isUserInteractionEnabled = false
        addSubview(nameLabel)

        priceLabel.text = price
        priceLabel.font = ATTheme.Typeface.sans(11, .medium)
        priceLabel.textColor = ATTheme.Palette.inkSoft
        priceLabel.textAlignment = .center
        priceLabel.isUserInteractionEnabled = false
        addSubview(priceLabel)

        spinner.hidesWhenStopped = true
        spinner.color = ATTheme.Palette.ink
        addSubview(spinner)

        iconHolder.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(52)
        }

        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconHolder.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(2)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        spinner.snp.makeConstraints { make in
            make.center.equalTo(iconHolder)
        }

        layer.cornerRadius = ATTheme.Radius.small
        layer.borderWidth = ATTheme.hairline
        layer.borderColor = ATTheme.Palette.rule.cgColor

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setPrice(_ price: String) {
        priceLabel.text = price
    }

    func setBusy(_ busy: Bool) {
        if busy {
            spinner.startAnimating()
            iconHolder.alpha = 0.2
        } else {
            spinner.stopAnimating()
            iconHolder.alpha = 1
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? ATTheme.Palette.paperDeep : .clear
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
