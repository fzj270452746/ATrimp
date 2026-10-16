//
//  ATPostListViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATPostListViewController: ATViewController {

    enum Source {
        case liked
        case ownWorks
        case authored(String)
    }

    private let source: Source
    private let emptyTitle: String
    private let emptyMessage: String

    private var allowsRemoval: Bool {
        if case .ownWorks = source { return true }
        return false
    }

    private enum Arrangement {
        case list
        case timeline
    }

    private var arrangement: Arrangement = .list
    private var months: [(start: Date, posts: [ATPost])] = []

    private let table = UITableView(frame: .zero, style: .plain)
    private var posts: [ATPost] = []
    private var authors: [String: ATUser] = [:]
    private var media: [String: [ATPostMedia]] = [:]
    private lazy var emptyView = ATEmptyView(title: emptyTitle, message: emptyMessage)

    private let arrangementBar = UIView()
    private var arrangementButtons: [ATPostListViewController.Arrangement: ATPillButton] = [:]

    init(source: Source, title: String, emptyTitle: String, emptyMessage: String) {
        self.source = source
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: title)

        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 340
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATPostCell.self, forCellReuseIdentifier: ATPostCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom).offset(80)
            make.leading.trailing.equalToSuperview()
        }

        buildArrangementBar()
        reload()
    }

    private func buildArrangementBar() {
        guard allowsRemoval else { return }

        arrangementBar.backgroundColor = ATTheme.Palette.paper
        arrangementBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 54)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.xs
        arrangementBar.addSubview(row)

        for (kind, title) in [(Arrangement.list, "Newest first"), (Arrangement.timeline, "By month")] {
            let button = ATPillButton(title: title)
            button.addTarget(self, action: #selector(chooseArrangement(_:)), for: .touchUpInside)
            row.addArrangedSubview(button)
            arrangementButtons[kind] = button
        }

        row.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.centerY.equalToSuperview()
        }

        table.tableHeaderView = arrangementBar
        markArrangement()
    }

    @objc private func chooseArrangement(_ sender: ATPillButton) {
        guard let kind = arrangementButtons.first(where: { $0.value === sender })?.key else { return }
        arrangement = kind
        markArrangement()
        table.reloadData()
    }

    private func markArrangement() {
        for (kind, button) in arrangementButtons {
            button.apply(
                title: kind == .list ? "Newest first" : "By month",
                filled: kind == arrangement,
                tint: ATTheme.Palette.ink
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Data

    private func reload() {
        switch source {
        case .liked:
            posts = ATStore.likedPosts()
        case .ownWorks:
            posts = ATSession.shared.userID.map { ATStore.posts(byAuthor: $0) } ?? []
        case .authored(let userID):
            posts = ATStore.posts(byAuthor: userID)
        }

        authors = ATStore.users(ids: Array(Set(posts.map(\.authorID))))
        media = ATStore.media(forPostIDs: posts.map(\.id))

        let calendar = Calendar.current
        var order: [Date] = []
        var buckets: [Date: [ATPost]] = [:]
        for post in posts {
            let parts = calendar.dateComponents([.year, .month], from: post.createdAt)
            guard let start = calendar.date(from: parts) else { continue }
            if buckets[start] == nil { order.append(start) }
            buckets[start, default: []].append(post)
        }
        months = order.sorted(by: >).map { (start: $0, posts: buckets[$0] ?? []) }

        table.reloadData()
        emptyView.isHidden = !posts.isEmpty
    }

    private func post(at indexPath: IndexPath) -> ATPost {
        arrangement == .list ? posts[indexPath.row] : months[indexPath.section].posts[indexPath.row]
    }

    private func presentation(at index: Int) -> ATPostPresentation {
        let post = posts[index]
        return ATPostPresentation(post: post, author: authors[post.authorID], media: media[post.id] ?? [])
    }

    private func toggleLike(at index: Int, indexPath: IndexPath) {
        guard !requireSignIn(message: "Sign in to keep track of what you liked.") else { return }

        let post = posts[index]
        ATStore.setLiked(!post.isLiked, postID: post.id)

        if case .liked = source {
            reload()
            return
        }

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

    private func openPost(at index: Int) {
        push(ATPostDetailViewController(postID: posts[index].id))
    }

    private func openAuthor(of index: Int) {
        guard let author = authors[posts[index].authorID] else { return }
        push(ATUserProfileViewController(userID: author.id))
    }

    private func openPlace(of index: Int) {
        push(ATPlaceViewController(place: ATPlace.resolve(
            locationName: posts[index].locationName,
            country: posts[index].country
        )))
    }

    private func delete(at index: Int, from source: UIView? = nil) {
        let post = posts[index]
        let alert = UIAlertController(
            title: "Remove this post?",
            message: "\(post.locationName), \(post.country). This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            ATStore.deletePost(id: post.id)
            ATSession.shared.refresh()
            self?.reload()
        })
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))

        if let popover = alert.popoverPresentationController, let source {
            popover.sourceView = source
            popover.sourceRect = source.bounds
        }
        present(alert, animated: true)
    }
}

// MARK: - Table

extension ATPostListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        arrangement == .list ? 1 : max(1, months.count)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrangement == .list ? posts.count : (months.isEmpty ? 0 : months[section].posts.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = index(of: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: ATPostCell.reuseIdentifier, for: indexPath) as! ATPostCell
        cell.configure(
            with: presentation(at: index),
            width: tableView.bounds.width,
            showsMenu: allowsRemoval
        )
        cell.onOpen = { [weak self] in self?.openPost(at: index) }
        cell.onLike = { [weak self] in self?.toggleLike(at: index, indexPath: indexPath) }
        cell.onSame = { [weak self] in self?.toggleSame(at: index, indexPath: indexPath) }
        cell.onAuthor = { [weak self] in self?.openAuthor(of: index) }
        cell.onComment = { [weak self] in self?.openPost(at: index) }
        cell.onLocation = { [weak self] in self?.openPlace(of: index) }
        cell.onMenu = { [weak self] anchor in
            self?.delete(at: index, from: anchor)
        }
        return cell
    }

    private func index(of indexPath: IndexPath) -> Int {
        guard arrangement == .timeline, months.indices.contains(indexPath.section) else {
            return indexPath.row
        }
        let target = months[indexPath.section].posts[indexPath.row]
        return posts.firstIndex(where: { $0.id == target.id }) ?? indexPath.row
    }
}

extension ATPostListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard arrangement == .timeline, months.indices.contains(section) else { return nil }

        let month = months[section]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paper

        let label = UILabel()
        label.text = formatter.string(from: month.start)
        label.font = ATTheme.Typeface.serif(17, .semibold)
        label.textColor = ATTheme.Palette.ink
        container.addSubview(label)

        let tally = UILabel()
        tally.text = "\(month.posts.count)"
        tally.font = ATTheme.Typeface.mono(13, .semibold)
        tally.textColor = ATTheme.Palette.inkFaint
        container.addSubview(tally)

        let stripe = ATLensStripe()
        stripe.configure(with: Dictionary(grouping: month.posts, by: \.theme)
            .map { (theme: $0.key, count: $0.value.count) }
            .sorted { $0.count == $1.count ? $0.theme.title < $1.theme.title : $0.count > $1.count })
        container.addSubview(stripe)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
        }

        tally.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalTo(label)
        }

        stripe.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.top.equalTo(label.snp.bottom).offset(ATTheme.Space.xs)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        arrangement == .timeline ? 56 : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPost(at: index(of: indexPath))
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard case .ownWorks = source else { return nil }

        let index = index(of: indexPath)
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            self?.delete(at: index)
            completion(true)
        }
        remove.backgroundColor = ATTheme.Palette.danger

        return UISwipeActionsConfiguration(actions: [remove])
    }
}
