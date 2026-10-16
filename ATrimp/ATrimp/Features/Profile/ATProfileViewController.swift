//
//  ATProfileViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATProfileViewController: ATViewController {

    private enum Row {
        case editProfile
        case likes
        case following
        case works
        case notes
        case reading
        case about
    }

    private let table = UITableView(frame: .zero, style: .plain)
    private let headerRule = ATRule()

    private let signedOutView = UIView()
    private let signedOutPrompt = ATEmptyView(
        title: "You are browsing as a guest",
        message: "Sign in to publish trips, send gifts and keep a record of what you liked.",
        actionTitle: "Sign in"
    )

    private let rows: [Row] = [.editProfile, .likes, .following, .works, .notes, .reading, .about]

    override func viewDidLoad() {
        super.viewDidLoad()

        buildHeader()
        buildTable()
        buildSignedOutView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionChanged),
            name: ATSession.didChange,
            object: nil
        )

        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ATSession.shared.refresh()
        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bottom = view.safeAreaInsets.bottom + ATTheme.Space.sm
        guard abs(table.contentInset.bottom - bottom) > 0.5 else { return }
        table.contentInset.bottom = bottom
        table.verticalScrollIndicatorInsets.bottom = bottom
    }

    // MARK: - Layout

    private func buildHeader() {
        let masthead = UILabel()
        masthead.text = "Your account"
        masthead.font = ATTheme.Typeface.serif(34, .semibold)
        masthead.textColor = ATTheme.Palette.ink
        view.addSubview(masthead)

        let rule = ATRule(color: ATTheme.Palette.accent)
        view.addSubview(rule)

        view.addSubview(headerRule)

        masthead.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(masthead.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.width.equalTo(40)
            make.height.equalTo(3)
        }

        headerRule.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview()
        }
    }

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 240
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATProfileHeaderCell.self, forCellReuseIdentifier: ATProfileHeaderCell.reuseIdentifier)
        table.register(ATMenuCell.self, forCellReuseIdentifier: ATMenuCell.reuseIdentifier)
        table.register(ATDangerCell.self, forCellReuseIdentifier: ATDangerCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(headerRule.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func buildSignedOutView() {
        signedOutPrompt.onAction = { [weak self] in
            guard let self else { return }
            self.present(ATLoginViewController(), animated: true)
        }

        view.addSubview(signedOutView)
        signedOutView.addSubview(signedOutPrompt)

        signedOutView.snp.makeConstraints { make in
            make.top.equalTo(headerRule.snp.bottom).offset(64)
            make.leading.trailing.equalToSuperview()
        }

        signedOutPrompt.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - State

    @objc private func sessionChanged() {
        refresh()
    }

    private func refresh() {
        let isSignedIn = ATSession.shared.isSignedIn
        table.isHidden = !isSignedIn
        signedOutView.isHidden = isSignedIn
        table.reloadData()
    }

    private func confirmSignOut() {
        let alert = UIAlertController(
            title: "Sign out?",
            message: "You can sign back in at any time.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Sign out", style: .destructive) { [weak self] _ in
            ATLoadingOverlay.run(duration: 1.2) {
                ATSession.shared.signOut()
                self?.refresh()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete your account?",
            message: "Your profile, your trips, your comments and your messages are all removed. This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Delete everything", style: .destructive) { [weak self] _ in
            ATLoadingOverlay.run(duration: 1.2) {
                ATSession.shared.deleteAccount()
                self?.refresh()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Table

extension ATProfileViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return rows.count
        default: return 2
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = ATSession.shared.currentUser else { return UITableViewCell() }

        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: ATProfileHeaderCell.reuseIdentifier, for: indexPath) as! ATProfileHeaderCell
            cell.configure(user: user)
            cell.onEdit = { [weak self] in
                self?.push(ATEditProfileViewController())
            }
            cell.onFollowing = { [weak self] in
                self?.push(ATPeopleListViewController(source: .following, title: "Following"))
            }
            cell.onFollowers = { [weak self] in
                self?.push(ATPeopleListViewController(source: .followers, title: "Followers"))
            }
            cell.onPosts = { [weak self] in
                self?.push(ATPostListViewController(
                    source: .ownWorks,
                    title: "Your works",
                    emptyTitle: "Nothing filed yet",
                    emptyMessage: "Trips you publish appear here, and can be removed from this screen."
                ))
            }
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ATMenuCell.reuseIdentifier, for: indexPath) as! ATMenuCell
            switch rows[indexPath.row] {
            case .editProfile:
                cell.configure(symbol: "person.crop.circle", title: "Edit profile", detail: "Name, photograph, description")
            case .likes:
                cell.configure(symbol: "heart", title: "Your likes", detail: "Everything you have saved")
            case .following:
                cell.configure(symbol: "person.2", title: "People you follow", detail: "Follow or unfollow from here")
            case .works:
                cell.configure(symbol: "square.stack", title: "Your works", detail: "Remove a trip you no longer want up")
            case .notes:
                let pending = ATStore.notes().filter { !$0.isResolved }.count
                cell.configure(
                    symbol: "bookmark",
                    title: "Your notes",
                    detail: pending == 0
                        ? "What you mean to do differently"
                        : "\(pending) still to do"
                )
            case .reading:
                cell.configure(
                    symbol: "chart.bar",
                    title: "How you read",
                    detail: "The shape of your eight lenses"
                )
            case .about:
                cell.configure(symbol: "info.circle", title: "About ATrimp", detail: "What the app is for")
            }
            return cell

        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: ATDangerCell.reuseIdentifier, for: indexPath) as! ATDangerCell
            if indexPath.row == 0 {
                cell.configure(title: "Sign out", destructive: false)
            } else {
                cell.configure(title: "Delete account", destructive: true)
            }
            return cell
        }
    }
}

extension ATProfileViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else {
            if indexPath.section == 2 {
                indexPath.row == 0 ? confirmSignOut() : confirmDeleteAccount()
            }
            return
        }

        switch rows[indexPath.row] {
        case .editProfile:
            push(ATEditProfileViewController())
        case .likes:
            push(ATPostListViewController(
                source: .liked,
                title: "Your likes",
                emptyTitle: "Nothing liked yet",
                emptyMessage: "Tap the heart on a post and it will be kept here."
            ))
        case .following:
            push(ATPeopleListViewController(source: .following, title: "People you follow"))
        case .works:
            push(ATPostListViewController(
                source: .ownWorks,
                title: "Your works",
                emptyTitle: "Nothing filed yet",
                emptyMessage: "Trips you publish appear here, and can be removed from this screen."
            ))
        case .notes:
            push(ATNotesViewController())
        case .reading:
            push(ATReadingViewController())
        case .about:
            present(ATAboutViewController(), animated: true)
        }
    }
}

// MARK: - Header cell

private final class ATProfileHeaderCell: UITableViewCell {

    static let reuseIdentifier = "ATProfileHeaderCell"

    var onEdit: (() -> Void)?
    var onFollowing: (() -> Void)?
    var onFollowers: (() -> Void)?
    var onPosts: (() -> Void)?

    private let avatar = ATAvatarView(size: 76)
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let cityLabel = UILabel()
    private let bioLabel = UILabel()
    private let countsRow = UIStackView()

    private let followingStat = ATStatView(caption: "Following")
    private let followerStat = ATStatView(caption: "Followers")
    private let postStat = ATStatView(caption: "Posts")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleEdit)))
        contentView.addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.serif(24, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        contentView.addSubview(nameLabel)

        handleLabel.font = ATTheme.Typeface.caption
        handleLabel.textColor = ATTheme.Palette.inkFaint
        contentView.addSubview(handleLabel)

        cityLabel.font = ATTheme.Typeface.caption
        cityLabel.textColor = ATTheme.Palette.inkSoft
        contentView.addSubview(cityLabel)

        bioLabel.font = ATTheme.Typeface.sans(14.5)
        bioLabel.textColor = ATTheme.Palette.inkSoft
        bioLabel.numberOfLines = 0
        contentView.addSubview(bioLabel)

        countsRow.axis = .horizontal
        countsRow.distribution = .fillEqually
        countsRow.spacing = ATTheme.Space.sm
        countsRow.addArrangedSubview(followingStat)
        countsRow.addArrangedSubview(followerStat)
        countsRow.addArrangedSubview(postStat)
        contentView.addSubview(countsRow)

        followingStat.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleFollowing)))
        followerStat.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleFollowers)))
        postStat.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePosts)))

        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.md)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(avatar.snp.top).offset(2)
        }

        handleLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }

        cityLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(handleLabel.snp.bottom).offset(2)
        }

        bioLabel.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        countsRow.snp.makeConstraints { make in
            make.top.equalTo(bioLabel.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.lg)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(user: ATUser) {
        avatar.set(user: user)
        nameLabel.text = user.displayName
        handleLabel.text = "@\(user.username)"
        cityLabel.text = user.homeCity
        bioLabel.text = user.bio.isEmpty ? "No description yet. Tap the photograph to add one." : user.bio

        followingStat.setValue("\(ATStore.followingCount())")
        followerStat.setValue("\(ATStore.followerCount())")
        postStat.setValue("\(ATStore.posts(byAuthor: user.id).count)")
    }

    @objc private func handleEdit() { onEdit?() }
    @objc private func handleFollowing() { onFollowing?() }
    @objc private func handleFollowers() { onFollowers?() }
    @objc private func handlePosts() { onPosts?() }
}

// MARK: - Stat

private final class ATStatView: UIControl {

    private let valueLabel = UILabel()
    private let captionLabel = UILabel()

    init(caption: String) {
        super.init(frame: .zero)

        backgroundColor = ATTheme.Palette.paperDeep
        layer.cornerRadius = ATTheme.Radius.small

        valueLabel.font = ATTheme.Typeface.metric
        valueLabel.textColor = ATTheme.Palette.ink
        valueLabel.textAlignment = .center
        valueLabel.isUserInteractionEnabled = false
        addSubview(valueLabel)

        captionLabel.attributedText = ATTheme.sectionLabel(caption)
        captionLabel.textAlignment = .center
        captionLabel.isUserInteractionEnabled = false
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

// MARK: - Menu cell

private final class ATMenuCell: UITableViewCell {

    static let reuseIdentifier = "ATMenuCell"

    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let chevron = UIImageView()
    private let rule = ATRule()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .default
        contentView.backgroundColor = ATTheme.Palette.paper

        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = ATTheme.Palette.accent
        contentView.addSubview(symbolView)

        titleLabel.font = ATTheme.Typeface.bodyStrong
        titleLabel.textColor = ATTheme.Palette.ink
        contentView.addSubview(titleLabel)

        detailLabel.font = ATTheme.Typeface.caption
        detailLabel.textColor = ATTheme.Palette.inkFaint
        contentView.addSubview(detailLabel)

        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: configuration)
        chevron.tintColor = ATTheme.Palette.inkFaint
        contentView.addSubview(chevron)

        contentView.addSubview(rule)

        symbolView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(symbolView.snp.trailing).offset(ATTheme.Space.sm)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-ATTheme.Space.sm)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-ATTheme.Space.sm)
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalToSuperview()
        }

        rule.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(detailLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(symbol: String, title: String, detail: String) {
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        symbolView.image = UIImage(systemName: symbol, withConfiguration: configuration)
        titleLabel.text = title
        detailLabel.text = detail
    }
}

// MARK: - Danger cell

private final class ATDangerCell: UITableViewCell {

    static let reuseIdentifier = "ATDangerCell"

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        label.font = ATTheme.Typeface.action
        label.textAlignment = .center
        contentView.addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: ATTheme.Space.gutter, bottom: 14, right: ATTheme.Space.gutter))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(title: String, destructive: Bool) {
        label.text = title
        label.textColor = destructive ? ATTheme.Palette.danger : ATTheme.Palette.inkSoft
    }
}
