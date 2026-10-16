//
//  ATPostCell.swift
//  ATrimp
//
//
import SnapKit
import UIKit

struct ATPostPresentation {
    let post: ATPost
    let author: ATUser?
    let media: [ATPostMedia]
}

// MARK: - Standard entry

final class ATPostCell: UITableViewCell {

    static let reuseIdentifier = "ATPostCell"

    var onOpen: (() -> Void)?
    var onLike: (() -> Void)?
    var onSame: (() -> Void)?
    var onAuthor: (() -> Void)?
    var onComment: (() -> Void)?
    var onGift: (() -> Void)?
    var onLocation: (() -> Void)?
    var onMenu: ((UIView) -> Void)?

    private let header = UIControl()
    private let avatar = ATAvatarView(size: 38)
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()

    private let tagRow = UIView()
    private let locationLink = ATLinkLabel(
        font: ATTheme.Typeface.caption,
        tint: ATTheme.Palette.inkSoft,
        underline: ATTheme.Palette.ruleStrong
    )

    private let bodyLabel = UILabel()
    private let grid = ATMediaGrid()
    private let menuButton = UIButton(type: .system)

    private let likeMetric = ATMetricLabel(symbol: "heart", text: "0")
    private let sameMetric = ATMetricLabel(symbol: "person.2", text: "0")
    private let commentMetric = ATMetricLabel(symbol: "bubble.left", text: "0")
    private let giftMetric = ATMetricLabel(symbol: "gift", text: "0")
    private let stampHolder = UIView()
    private let stamp = ATStamp(text: "Went back", compact: true)
    private let footerRule = ATRule()

    private var gridHeight: Constraint?
    private var headerTrailing: Constraint?
    private var currentTheme: ATPostTheme = .surprise
    private var currentMedia: [ATPostMedia] = []
    private var chip: ATThemeChip?
    private weak var openGesture: UITapGestureRecognizer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleOpen))
        gesture.delegate = self
        contentView.addGestureRecognizer(gesture)
        openGesture = gesture

        header.addTarget(self, action: #selector(handleAuthor), for: .touchUpInside)
        contentView.addSubview(header)

        header.addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.bodyStrong
        nameLabel.textColor = ATTheme.Palette.ink
        header.addSubview(nameLabel)

        metaLabel.font = ATTheme.Typeface.caption
        metaLabel.textColor = ATTheme.Palette.inkFaint
        header.addSubview(metaLabel)

        contentView.addSubview(tagRow)
        locationLink.onTap = { [weak self] in self?.onLocation?() }
        tagRow.addSubview(locationLink)

        bodyLabel.font = ATTheme.Typeface.body
        bodyLabel.textColor = ATTheme.Palette.ink
        bodyLabel.numberOfLines = 5
        bodyLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(bodyLabel)

        contentView.addSubview(grid)

        let metrics = UIStackView(arrangedSubviews: [likeMetric, sameMetric, commentMetric, giftMetric])
        metrics.axis = .horizontal
        metrics.spacing = ATTheme.Space.md
        contentView.addSubview(metrics)

        likeMetric.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))
        sameMetric.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSame)))
        commentMetric.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleComment)))
        giftMetric.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGift)))

        contentView.addSubview(footerRule)

        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        menuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: configuration), for: .normal)
        menuButton.tintColor = ATTheme.Palette.inkFaint
        menuButton.isHidden = true
        menuButton.addTarget(self, action: #selector(handleMenu), for: .touchUpInside)
        contentView.addSubview(menuButton)

        menuButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter + 6)
            make.top.equalToSuperview().offset(ATTheme.Space.xs)
            make.width.height.equalTo(32)
        }

        header.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            headerTrailing = make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter).constraint
        }

        avatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.lessThanOrEqualToSuperview()
            make.top.equalToSuperview().offset(1)
        }

        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.bottom.equalToSuperview()
        }

        tagRow.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.height.equalTo(24)
        }

        locationLink.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(tagRow.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        grid.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            gridHeight = make.height.equalTo(0).constraint
        }

        metrics.snp.makeConstraints { make in
            make.top.equalTo(grid.snp.bottom).offset(ATTheme.Space.md)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        contentView.addSubview(stampHolder)
        stampHolder.isHidden = true
        stampHolder.addSubview(stamp)
        stamp.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stampHolder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalTo(metrics)
            make.leading.greaterThanOrEqualTo(metrics.snp.trailing).offset(ATTheme.Space.sm)
        }

        footerRule.snp.makeConstraints { make in
            make.top.equalTo(metrics.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpen = nil
        onLike = nil
        onSame = nil
        onAuthor = nil
        onComment = nil
        onGift = nil
        onLocation = nil
        onMenu = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inner = contentView.bounds.width - ATTheme.Space.gutter * 2
        guard inner > 0 else { return }

        let target = ATMediaGridLayout.height(for: currentMedia, width: inner)
        if abs((gridHeight?.layoutConstraints.first?.constant ?? 0) - target) > 0.5 {
            gridHeight?.update(offset: target)
        }
    }

    func configure(with presentation: ATPostPresentation, width: CGFloat, showsMenu: Bool = false) {
        let post = presentation.post
        currentTheme = post.theme

        menuButton.isHidden = !showsMenu
        headerTrailing?.update(offset: -(ATTheme.Space.gutter + (showsMenu ? 30 : 0)))

        avatar.set(user: presentation.author)
        nameLabel.text = presentation.author?.displayName ?? "Removed account"
        metaLabel.text = [
            presentation.author?.homeCity,
            ATTime.compact(post.createdAt),
        ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")

        chip?.removeFromSuperview()
        let newChip = ATThemeChip(theme: post.theme, compact: true)
        tagRow.addSubview(newChip)
        newChip.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        chip = newChip

        locationLink.setText("\(post.locationName), \(post.country)")
        locationLink.snp.remakeConstraints { make in
            make.leading.equalTo(newChip.snp.trailing).offset(ATTheme.Space.xs)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        stampHolder.isHidden = !post.isRedeemed

        bodyLabel.text = post.body

        currentMedia = presentation.media
        grid.configure(with: presentation.media)
        grid.isHidden = presentation.media.isEmpty

        let inner = (width > 0 ? width : UIScreen.main.bounds.width) - ATTheme.Space.gutter * 2
        gridHeight?.update(offset: ATMediaGridLayout.height(for: presentation.media, width: inner))

        applyMetrics(post: post)
    }

    func applyLike(liked: Bool, count: Int) {
        likeMetric.set(
            symbol: liked ? "heart.fill" : "heart",
            tint: liked ? ATTheme.Palette.accent : ATTheme.Palette.inkSoft
        )
        likeMetric.set(text: "\(count)", tint: liked ? ATTheme.Palette.accent : ATTheme.Palette.inkSoft)
    }

    func applySame(isSame: Bool, count: Int) {
        sameMetric.set(
            symbol: isSame ? "person.2.fill" : "person.2",
            tint: isSame ? ATTheme.Palette.mist : ATTheme.Palette.inkSoft
        )
        sameMetric.set(text: "\(count)", tint: isSame ? ATTheme.Palette.mist : ATTheme.Palette.inkSoft)
    }

    private func applyMetrics(post: ATPost) {
        applyLike(liked: post.isLiked, count: post.likeCount)
        applySame(isSame: post.isSameHere, count: post.sameCount)
        commentMetric.set(text: "\(post.commentCount)", tint: ATTheme.Palette.inkSoft)
        giftMetric.set(text: "\(post.giftCount)", tint: ATTheme.Palette.inkSoft)
    }

    // MARK: - Actions

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touched = touch.view else { return true }
        return !touched.isDescendant(of: header)
            && !touched.isDescendant(of: menuButton)
            && !touched.isDescendant(of: locationLink)
            && !touched.isDescendant(of: likeMetric)
            && !touched.isDescendant(of: sameMetric)
            && !touched.isDescendant(of: commentMetric)
            && !touched.isDescendant(of: giftMetric)
    }

    @objc private func handleOpen() { onOpen?() }
    @objc private func handleLike() { onLike?() }
    @objc private func handleSame() { onSame?() }
    @objc private func handleAuthor() { onAuthor?() }
    @objc private func handleComment() { onComment?() }
    @objc private func handleGift() { onGift?() }
    @objc private func handleMenu() { onMenu?(menuButton) }
}

// MARK: - Feature entry

final class ATFeatureCell: UITableViewCell {

    static let reuseIdentifier = "ATFeatureCell"

    var onOpen: (() -> Void)?
    var onLike: (() -> Void)?
    var onSame: (() -> Void)?
    var onAuthor: (() -> Void)?
    var onLocation: (() -> Void)?

    private let hero = UIImageView()
    private let scrim = UIView()
    private let chip = UIView()
    private let headline = UILabel()
    private let locationLink = ATLinkLabel(
        font: ATTheme.Typeface.sans(11.5, .semibold),
        tint: ATTheme.Palette.paper.withAlphaComponent(0.9),
        underline: ATTheme.Palette.paper.withAlphaComponent(0.42)
    )

    private let header = UIControl()
    private let avatar = ATAvatarView(size: 32)
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let likeMetric = ATMetricLabel(symbol: "heart", text: "0")
    private let sameMetric = ATMetricLabel(symbol: "person.2", text: "0")
    private let footerRule = ATRule()

    private var currentChip: ATThemeChip?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleOpen))
        gesture.delegate = self
        contentView.addGestureRecognizer(gesture)

        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true
        contentView.addSubview(hero)

        scrim.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.42)
        hero.addSubview(scrim)

        hero.addSubview(chip)

        headline.font = ATTheme.Typeface.serif(19, .semibold)
        headline.textColor = ATTheme.Palette.paper
        headline.numberOfLines = 2
        hero.addSubview(headline)

        locationLink.onTap = { [weak self] in self?.onLocation?() }
        hero.addSubview(locationLink)

        header.addTarget(self, action: #selector(handleAuthor), for: .touchUpInside)
        contentView.addSubview(header)
        header.addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.captionStrong
        nameLabel.textColor = ATTheme.Palette.ink
        header.addSubview(nameLabel)

        timeLabel.font = ATTheme.Typeface.caption
        timeLabel.textColor = ATTheme.Palette.inkFaint
        header.addSubview(timeLabel)

        contentView.addSubview(likeMetric)
        likeMetric.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLike)))

        contentView.addSubview(sameMetric)
        sameMetric.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSame)))

        contentView.addSubview(footerRule)

        hero.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(hero.snp.width).multipliedBy(0.62)
        }

        scrim.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        chip.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
        }

        headline.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.bottom.equalTo(locationLink.snp.top).offset(-6)
        }

        locationLink.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.md)
        }

        header.snp.makeConstraints { make in
            make.top.equalTo(hero.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        avatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.xs)
            make.top.equalToSuperview()
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.bottom.equalToSuperview()
        }

        likeMetric.snp.makeConstraints { make in
            make.centerY.equalTo(header)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
        }

        sameMetric.snp.makeConstraints { make in
            make.centerY.equalTo(header)
            make.trailing.equalTo(likeMetric.snp.leading).offset(-ATTheme.Space.md)
        }

        footerRule.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpen = nil
        onLike = nil
        onSame = nil
        onAuthor = nil
        onLocation = nil
    }

    func configure(with presentation: ATPostPresentation, width: CGFloat) {
        let post = presentation.post

        currentChip?.removeFromSuperview()
        let newChip = ATThemeChip(theme: post.theme, compact: true)
        chip.addSubview(newChip)
        newChip.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        currentChip = newChip

        let firstSentence = post.body
            .split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) + "." }
            ?? post.body
        headline.text = firstSentence

        locationLink.setText("\(post.locationName.uppercased()) · \(post.country.uppercased())")

        // The clip's own first frame where there is one, so the feed's wide video
        // slots show the film rather than the photograph filed beside it. A clip
        // that has no file yet falls back to the post's own first photograph: a
        // placeholder gradient is no way to fill the widest card in the feed.
        let clip = presentation.media.first { $0.kind == .video }
        let playable = clip.flatMap {
            ATMediaLibrary.videoURL(forReference: $0.reference) != nil ? $0 : nil
        }
        let cover = playable ?? presentation.media.first { $0.kind == .image } ?? clip

        if let cover {
            hero.image = ATMediaLibrary.image(
                for: cover,
                size: CGSize(width: width, height: width * 0.62),
                symbol: clip == nil ? nil : "play.fill"
            )
        } else {
            hero.image = ATArt.photo(seed: post.id, size: CGSize(width: width, height: width * 0.62))
        }

        avatar.set(user: presentation.author)
        nameLabel.text = presentation.author?.displayName ?? "Removed account"
        timeLabel.text = ATTime.compact(post.createdAt)

        applyLike(liked: post.isLiked, count: post.likeCount)
        applySame(isSame: post.isSameHere, count: post.sameCount)
    }

    func applyLike(liked: Bool, count: Int) {
        likeMetric.set(
            symbol: liked ? "heart.fill" : "heart",
            tint: liked ? ATTheme.Palette.accent : ATTheme.Palette.inkSoft
        )
        likeMetric.set(text: "\(count)", tint: liked ? ATTheme.Palette.accent : ATTheme.Palette.inkSoft)
    }

    func applySame(isSame: Bool, count: Int) {
        sameMetric.set(
            symbol: isSame ? "person.2.fill" : "person.2",
            tint: isSame ? ATTheme.Palette.mist : ATTheme.Palette.inkSoft
        )
        sameMetric.set(text: "\(count)", tint: isSame ? ATTheme.Palette.mist : ATTheme.Palette.inkSoft)
    }

    @objc private func handleOpen() { onOpen?() }
    @objc private func handleLike() { onLike?() }
    @objc private func handleSame() { onSame?() }
    @objc private func handleAuthor() { onAuthor?() }
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touched = touch.view else { return true }
        return !touched.isDescendant(of: header)
            && !touched.isDescendant(of: likeMetric)
            && !touched.isDescendant(of: sameMetric)
            && !touched.isDescendant(of: locationLink)
    }
}
