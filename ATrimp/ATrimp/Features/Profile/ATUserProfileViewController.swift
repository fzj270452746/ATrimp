//
//  ATUserProfileViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATUserProfileViewController: ATViewController {

    private enum Tab: Int, CaseIterable {
        case posts
        case activity

        var title: String {
            switch self {
            case .posts: return "Trips"
            case .activity: return "Activity"
            }
        }
    }

    private let userID: String
    private var user: ATUser?

    private let table = UITableView(frame: .zero, style: .plain)
    private let switcher = UISegmentedControl(items: Tab.allCases.map(\.title))
    private var activeTab: Tab = .posts

    private var posts: [ATPost] = []
    private var media: [String: [ATPostMedia]] = [:]
    private var authoredComments: [ATComment] = []
    private var commentPosts: [String: ATPost] = [:]

    private var isSelf: Bool { userID == ATSession.shared.userID }

    init(userID: String) {
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        user = ATStore.user(id: userID)

        let bar = installNavBar(title: user?.displayName ?? "Profile")
        if !isSelf {
            bar.addTrailing(symbol: "ellipsis", action: #selector(handleReport), target: self)
        }

        buildSwitcher()
        buildTable()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        user = ATStore.user(id: userID)
        reload()
    }

    // MARK: - Layout

    private func buildSwitcher() {
        switcher.selectedSegmentIndex = 0
        switcher.selectedSegmentTintColor = ATTheme.Palette.ink
        switcher.backgroundColor = ATTheme.Palette.paperDeep
        switcher.setTitleTextAttributes([
            .font: ATTheme.Typeface.sans(13, .semibold),
            .foregroundColor: ATTheme.Palette.inkSoft,
        ], for: .normal)
        switcher.setTitleTextAttributes([
            .font: ATTheme.Typeface.sans(13, .semibold),
            .foregroundColor: ATTheme.Palette.paper,
        ], for: .selected)
        switcher.addTarget(self, action: #selector(handleTabChange), for: .valueChanged)
        view.addSubview(switcher)

        switcher.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.height.equalTo(34)
        }
    }

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 340
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATPostCell.self, forCellReuseIdentifier: ATPostCell.reuseIdentifier)
        table.register(ATActivityCell.self, forCellReuseIdentifier: ATActivityCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(switcher.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.bottom.equalToSuperview()
        }

        table.tableHeaderView = makeHeader()
    }

    private func makeHeader() -> UIView {
        let container = ProfileHeaderView()
        container.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        container.onFollow = { [weak self] in self?.handleFollow() }
        container.onFriend = { [weak self] in self?.handleFriend() }
        container.onEdit = { [weak self] in
            self?.push(ATEditProfileViewController())
        }
        container.configure(user: user, isSelf: isSelf)
        return container
    }

    // MARK: - Data

    private func reload() {
        posts = ATStore.posts(byAuthor: userID)
        media = ATStore.media(forPostIDs: posts.map(\.id))

        authoredComments = ATStore.comments(byAuthor: userID)
        var relatedPosts: [String: ATPost] = [:]
        for comment in authoredComments {
            if let post = ATStore.post(id: comment.postID) {
                relatedPosts[post.id] = post
            }
        }
        commentPosts = relatedPosts

        if let header = table.tableHeaderView as? ProfileHeaderView {
            header.configure(user: user, isSelf: isSelf)
        }

        table.reloadData()
    }

    // MARK: - Actions

    @objc private func handleTabChange() {
        activeTab = Tab(rawValue: switcher.selectedSegmentIndex) ?? .posts
        table.reloadData()
    }

    private func handleFollow() {
        guard !requireSignIn(message: "Sign in to follow people.") else { return }
        ATStore.setFollowing(!ATStore.isFollowing(userID), userID: userID)
        reload()
    }

    private func handleFriend() {
        guard !requireSignIn(message: "Sign in to add people.") else { return }
        guard let user else { return }

        switch user.friendState {
        case .none:
            ATStore.setFriendState(.requested, userID: userID)
            showToast("Request sent to \(user.displayName).")
        case .incoming:
            ATStore.setFriendState(.friends, userID: userID)
            ATStore.setFollowing(true, userID: userID)
            showToast("You are now connected with \(user.displayName).")
        case .requested:
            showToast("Your request is still waiting.")
        case .friends:
            push(ATConversationViewController(peer: user))
            return
        }
        reload()
    }

    @objc private func handleReport() {
        guard let user else { return }

        let report = ATReportViewController(target: .user(user)) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .dismissed:
                break
            case .removed, .blocked:
                self.returnToSourceModule()
            }
        }
        presentSheet(report, detents: [.medium(), .large()])
    }

    private func returnToSourceModule() {
        navigationController?.popToRootViewController(animated: true)
    }

    private func openPost(at index: Int) {
        push(ATPostDetailViewController(postID: posts[index].id))
    }

    private func openPlace(of index: Int) {
        push(ATPlaceViewController(place: ATPlace.resolve(
            locationName: posts[index].locationName,
            country: posts[index].country
        )))
    }

    private func toggleLike(at index: Int, indexPath: IndexPath) {
        guard !requireSignIn(message: "Sign in to keep track of what you liked.") else { return }

        let post = posts[index]
        ATStore.setLiked(!post.isLiked, postID: post.id)

        guard let updated = ATStore.post(id: post.id) else { return }
        posts[index] = updated
        (table.cellForRow(at: indexPath) as? ATPostCell)?
            .applyLike(liked: updated.isLiked, count: updated.likeCount)
    }

    private func toggleSame(at index: Int, indexPath: IndexPath) {
        let cell = table.cellForRow(at: indexPath) as? ATPostCell
        toggleSameHere(on: posts[index]) { [weak self] updated in
            self?.posts[index] = updated
            cell?.applySame(isSame: updated.isSameHere, count: updated.sameCount)
        }
    }
}

// MARK: - Table

extension ATUserProfileViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        activeTab == .posts ? posts.count : authoredComments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if activeTab == .posts {
            let post = posts[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: ATPostCell.reuseIdentifier, for: indexPath) as! ATPostCell
            cell.configure(
                with: ATPostPresentation(post: post, author: user, media: media[post.id] ?? []),
                width: tableView.bounds.width
            )
            cell.onOpen = { [weak self] in self?.openPost(at: indexPath.row) }
            cell.onLike = { [weak self] in self?.toggleLike(at: indexPath.row, indexPath: indexPath) }
            cell.onSame = { [weak self] in self?.toggleSame(at: indexPath.row, indexPath: indexPath) }
            cell.onComment = { [weak self] in self?.openPost(at: indexPath.row) }
            cell.onLocation = { [weak self] in self?.openPlace(of: indexPath.row) }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ATActivityCell.reuseIdentifier, for: indexPath) as! ATActivityCell
        let comment = authoredComments[indexPath.row]
        cell.configure(comment: comment, post: commentPosts[comment.postID])
        return cell
    }
}

extension ATUserProfileViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard activeTab == .posts else {
            let comment = authoredComments[indexPath.row]
            push(ATPostDetailViewController(postID: comment.postID))
            return
        }
        openPost(at: indexPath.row)
    }
}

// MARK: - Header

private final class ProfileHeaderView: UIView {

    var onFollow: (() -> Void)?
    var onFriend: (() -> Void)?
    var onEdit: (() -> Void)?

    private let avatar = ATAvatarView(size: 84)
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let cityLabel = UILabel()
    private let bioLabel = UILabel()

    private let sharedBlock = UIView()
    private let sharedCaption = UILabel()
    private let sharedChips = UIStackView()
    private let sharedNote = UILabel()
    private var sharedHeight: Constraint?
    private var sharedTop: Constraint?

    private let followMarker = UILabel()
    private let countsRow = UIStackView()
    private let followingStat = HeaderStat(caption: "Following")
    private let followerStat = HeaderStat(caption: "Followers")
    private let postStat = HeaderStat(caption: "Trips")
    private let followButton = ATPillButton(title: "Follow")
    private let friendButton = ATPillButton(title: "Add friend")
    private let editButton = ATGhostButton(title: "Edit profile")
    private let rule = ATRule()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paper

        addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.serif(24, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        addSubview(nameLabel)

        handleLabel.font = ATTheme.Typeface.caption
        handleLabel.textColor = ATTheme.Palette.inkFaint
        addSubview(handleLabel)

        cityLabel.font = ATTheme.Typeface.caption
        cityLabel.textColor = ATTheme.Palette.inkSoft
        addSubview(cityLabel)

        followMarker.font = ATTheme.Typeface.sans(10.5, .semibold)
        followMarker.textColor = ATTheme.Palette.mist
        followMarker.text = "FOLLOWS YOU"
        addSubview(followMarker)

        bioLabel.font = ATTheme.Typeface.sans(14.5)
        bioLabel.textColor = ATTheme.Palette.inkSoft
        bioLabel.numberOfLines = 0
        addSubview(bioLabel)

        sharedCaption.attributedText = ATTheme.sectionLabel("You both filed", color: ATTheme.Palette.mist)
        sharedBlock.addSubview(sharedCaption)

        sharedChips.axis = .horizontal
        sharedChips.spacing = ATTheme.Space.xs
        sharedChips.alignment = .center
        sharedBlock.addSubview(sharedChips)

        sharedNote.font = ATTheme.Typeface.caption
        sharedNote.textColor = ATTheme.Palette.inkFaint
        sharedNote.numberOfLines = 0
        sharedBlock.addSubview(sharedNote)

        addSubview(sharedBlock)

        countsRow.axis = .horizontal
        countsRow.distribution = .fillEqually
        countsRow.spacing = ATTheme.Space.sm
        countsRow.addArrangedSubview(followingStat)
        countsRow.addArrangedSubview(followerStat)
        countsRow.addArrangedSubview(postStat)
        addSubview(countsRow)

        followButton.addTarget(self, action: #selector(handleFollow), for: .touchUpInside)
        friendButton.addTarget(self, action: #selector(handleFriend), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        addSubview(followButton)
        addSubview(friendButton)
        addSubview(editButton)

        addSubview(rule)

        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.md)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(avatar.snp.top).offset(4)
        }

        handleLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }

        cityLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(handleLabel.snp.bottom).offset(2)
        }

        followMarker.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(cityLabel.snp.bottom).offset(4)
        }

        bioLabel.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        sharedCaption.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        sharedChips.snp.makeConstraints { make in
            make.top.equalTo(sharedCaption.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
        }

        sharedNote.snp.makeConstraints { make in
            make.top.equalTo(sharedChips.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        sharedBlock.snp.makeConstraints { make in
            sharedTop = make.top.equalTo(bioLabel.snp.bottom).offset(0).constraint
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            sharedHeight = make.height.equalTo(0).constraint
        }
        sharedHeight?.isActive = true

        countsRow.snp.makeConstraints { make in
            make.top.equalTo(sharedBlock.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        followButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalTo(countsRow.snp.bottom).offset(ATTheme.Space.md)
        }

        friendButton.snp.makeConstraints { make in
            make.leading.equalTo(followButton.snp.trailing).offset(ATTheme.Space.xs)
            make.centerY.equalTo(followButton)
        }

        editButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalTo(countsRow.snp.bottom).offset(ATTheme.Space.md)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(followButton.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        let target = systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if abs(target.height - bounds.height) > 0.5 {
            frame.size.height = target.height
        }
    }

    func configure(user: ATUser?, isSelf: Bool) {
        guard let user else { return }

        avatar.set(user: user)
        nameLabel.text = user.displayName
        handleLabel.text = "@\(user.username)"
        cityLabel.text = user.homeCity
        followMarker.isHidden = !ATStore.followsUs(user.id) || isSelf
        bioLabel.text = user.bio

        followingStat.setValue("\(isSelf ? ATStore.followingCount() : user.followingCount)")
        followerStat.setValue("\(isSelf ? ATStore.followerCount() : user.followerCount)")
        postStat.setValue("\(ATStore.posts(byAuthor: user.id).count)")

        configureSharedGround(with: user, isSelf: isSelf)

        followButton.isHidden = isSelf
        friendButton.isHidden = isSelf || user.friendState == .friends
        editButton.isHidden = !isSelf

        if !isSelf {
            let isFollowing = ATStore.isFollowing(user.id)
            followButton.apply(
                title: isFollowing ? "Following" : "Follow",
                filled: !isFollowing,
                tint: ATTheme.Palette.ink
            )

            switch user.friendState {
            case .none:
                friendButton.apply(title: "Add friend", filled: false, tint: ATTheme.Palette.ink)
            case .requested:
                friendButton.apply(title: "Requested", filled: false, tint: ATTheme.Palette.inkFaint)
            case .incoming:
                friendButton.apply(title: "Accept request", filled: true, tint: ATTheme.Palette.accent)
            case .friends:
                break
            }
        }
    }

    private func configureSharedGround(with user: ATUser, isSelf: Bool) {
        sharedChips.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let theirs = ATStore.posts(byAuthor: user.id)
        let overlap = isSelf ? [] : ATStore.sharedThemes(withUser: user.id)
        let mine = ATStore.readerThemes()
        let familiar = theirs.filter { mine.contains($0.theme) }.count

        let hasGround = !overlap.isEmpty
        sharedBlock.isHidden = !hasGround
        sharedHeight?.isActive = !hasGround
        sharedTop?.update(offset: hasGround ? ATTheme.Space.md : 0)
        guard hasGround else { return }

        for theme in overlap.prefix(4) {
            sharedChips.addArrangedSubview(ATThemeChip(theme: theme, compact: true))
        }
        if overlap.count > 4 {
            let more = UILabel()
            more.text = "+\(overlap.count - 4)"
            more.font = ATTheme.Typeface.captionStrong
            more.textColor = ATTheme.Palette.inkFaint
            sharedChips.addArrangedSubview(more)
        }

        sharedNote.text = familiar > 0
            ? "You read this way, and \(familiar) of their \(theirs.count) filings sit on it — that is where to start."
            : "You read this way. Nothing of theirs is filed under it yet, but the ground is shared."
    }

    @objc private func handleFollow() { onFollow?() }
    @objc private func handleFriend() { onFriend?() }
    @objc private func handleEdit() { onEdit?() }
}

private final class HeaderStat: UIView {

    private let valueLabel = UILabel()
    private let captionLabel = UILabel()

    init(caption: String) {
        super.init(frame: .zero)

        backgroundColor = ATTheme.Palette.paperDeep
        layer.cornerRadius = ATTheme.Radius.small

        valueLabel.font = ATTheme.Typeface.metric
        valueLabel.textColor = ATTheme.Palette.ink
        valueLabel.textAlignment = .center
        addSubview(valueLabel)

        captionLabel.attributedText = ATTheme.sectionLabel(caption)
        captionLabel.textAlignment = .center
        addSubview(captionLabel)

        valueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview()
        }

        captionLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(1)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

// MARK: - Activity cell

private final class ATActivityCell: UITableViewCell {

    static let reuseIdentifier = "ATActivityCell"

    private let symbolView = UIImageView()
    private let bodyLabel = UILabel()
    private let contextLabel = UILabel()
    private let rule = ATRule()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        symbolView.image = UIImage(systemName: "bubble.left", withConfiguration: configuration)
        symbolView.tintColor = ATTheme.Palette.inkFaint
        contentView.addSubview(symbolView)

        bodyLabel.font = ATTheme.Typeface.sans(14.5)
        bodyLabel.textColor = ATTheme.Palette.ink
        bodyLabel.numberOfLines = 0
        contentView.addSubview(bodyLabel)

        contextLabel.font = ATTheme.Typeface.caption
        contextLabel.textColor = ATTheme.Palette.inkFaint
        contextLabel.numberOfLines = 1
        contentView.addSubview(contextLabel)

        contentView.addSubview(rule)

        symbolView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.width.height.equalTo(18)
        }

        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(symbolView.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
        }

        contextLabel.snp.makeConstraints { make in
            make.leading.equalTo(bodyLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(bodyLabel.snp.bottom).offset(3)
        }

        rule.snp.makeConstraints { make in
            make.leading.equalTo(bodyLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(contextLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(comment: ATComment, post: ATPost?) {
        bodyLabel.text = comment.body
        let place = post.map { "\($0.locationName), \($0.country)" } ?? "a removed post"
        contextLabel.text = "On \(place) · \(ATTime.compact(comment.createdAt))"
    }
}
