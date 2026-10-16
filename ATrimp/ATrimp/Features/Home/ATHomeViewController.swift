//
//  ATHomeViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATHomeViewController: ATViewController {

    private let masthead = UILabel()
    private let standfirst = UILabel()
    private let filterBar = ATFilterBar()
    private let table = UITableView(frame: .zero, style: .plain)
    private let refreshControl = ATRefreshControl()
    private lazy var emptyView = ATEmptyView(
        title: "Nothing filed under this yet",
        message: "When someone writes up a trip in this category it will appear here.",
        actionTitle: "Show everything"
    ) { [weak self] in
        self?.filterBar.select(nil, animated: true)
        self?.applyFilter(nil)
    }

    private var posts: [ATPost] = []
    private var authors: [String: ATUser] = [:]
    private var media: [String: [ATPostMedia]] = [:]

    private var selectedTheme: ATPostTheme?

    private let feedSize = 15
    private let videoAllowance = 3

    private var headerDivider: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        buildHeader()
        buildTable()

        filterBar.onSelect = { [weak self] theme in
            self?.applyFilter(theme)
        }

        load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshFromStore()
    }

    // MARK: - Layout

    private func buildHeader() {
        masthead.text = "ATrimp"
        masthead.font = ATTheme.Typeface.serif(34, .semibold)
        masthead.textColor = ATTheme.Palette.ink
        view.addSubview(masthead)

        let rule = ATRule(color: ATTheme.Palette.accent)
        view.addSubview(rule)

        let mapButton = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        mapButton.setImage(UIImage(systemName: "map", withConfiguration: configuration), for: .normal)
        mapButton.tintColor = ATTheme.Palette.ink
        mapButton.accessibilityLabel = "Map of every place"
        mapButton.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        view.addSubview(mapButton)

        let searchButton = UIButton(type: .system)
        searchButton.setImage(
            UIImage(systemName: "magnifyingglass", withConfiguration: configuration),
            for: .normal
        )
        searchButton.tintColor = ATTheme.Palette.ink
        searchButton.accessibilityLabel = "Search"
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        view.addSubview(searchButton)

        standfirst.text = "Notes from the road, kept honestly."
        standfirst.font = ATTheme.Typeface.caption
        standfirst.textColor = ATTheme.Palette.inkFaint
        standfirst.numberOfLines = 1
        view.addSubview(standfirst)

        view.addSubview(filterBar)

        let divider = ATRule()
        view.addSubview(divider)

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

        mapButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalTo(masthead)
            make.width.height.equalTo(34)
        }

        searchButton.snp.makeConstraints { make in
            make.trailing.equalTo(mapButton.snp.leading).offset(-ATTheme.Space.xs)
            make.centerY.equalTo(masthead)
            make.width.height.equalTo(34)
        }

        standfirst.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        filterBar.snp.makeConstraints { make in
            make.top.equalTo(standfirst.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview()
        }

        divider.snp.makeConstraints { make in
            make.top.equalTo(filterBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        self.headerDivider = divider
    }

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 360
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATPostCell.self, forCellReuseIdentifier: ATPostCell.reuseIdentifier)
        table.register(ATFeatureCell.self, forCellReuseIdentifier: ATFeatureCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(headerDivider!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        refreshControl.onRefresh = { [weak self] in
            guard let self else { return }
            self.load()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.refreshControl.endRefreshing()
            }
        }
        refreshControl.attach(to: table)

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(headerDivider!.snp.bottom).offset(80)
            make.leading.trailing.equalToSuperview()
        }
        emptyView.isHidden = true
    }

    // MARK: - Data

    private func applyFilter(_ theme: ATPostTheme?) {
        selectedTheme = theme
        standfirst.text = theme?.blurb ?? "Notes from the road, kept honestly."
        load()
        table.setContentOffset(.zero, animated: false)
    }

    private func load() {
        readFeed()
        table.reloadData()
        updateEmptyState()
    }

    /// A revisit is filed on the page of the post it answers and carries the same
    /// photographs, so the digest keeps the original and leaves the revisit there —
    /// no entry and no picture shows up twice.
    private func readFeed() {
        let moving = ATStore.posts(
            theme: selectedTheme,
            limit: videoAllowance,
            carryingVideo: true,
            includingRevisits: false
        )
        let stills = ATStore.posts(
            theme: selectedTheme,
            limit: feedSize - moving.count,
            carryingVideo: false,
            includingRevisits: false
        )

        posts = (moving + stills).sorted { $0.createdAt > $1.createdAt }
        indexContent()
    }

    private func indexContent() {
        authors = ATStore.users(ids: Array(Set(posts.map(\.authorID))))
        media = ATStore.media(forPostIDs: posts.map(\.id))
    }

    private func refreshFromStore() {
        let before = posts.map(\.id)
        readFeed()

        if posts.map(\.id) != before {
            table.reloadData()
            updateEmptyState()

            if posts.first?.id != before.first {
                table.setContentOffset(.zero, animated: false)
            }
        } else {
            let visible = table.indexPathsForVisibleRows ?? []
            if !visible.isEmpty {
                table.reloadRows(at: visible, with: .none)
            }
        }
    }

    private func updateEmptyState() {
        emptyView.isHidden = !posts.isEmpty
    }

    private func isFeature(at index: Int) -> Bool {
        guard index % 5 == 2 else { return false }
        return !(media[posts[index].id] ?? []).isEmpty
    }

    private func presentation(at index: Int) -> ATPostPresentation {
        let post = posts[index]
        return ATPostPresentation(
            post: post,
            author: authors[post.authorID],
            media: media[post.id] ?? []
        )
    }

    // MARK: - Actions

    private func toggleLike(at index: Int, indexPath: IndexPath) {
        guard !requireSignIn(message: "Sign in to keep track of what you liked.") else { return }

        let post = posts[index]
        let liked = !post.isLiked
        ATStore.setLiked(liked, postID: post.id)

        guard let updated = ATStore.post(id: post.id) else { return }
        posts[index] = updated

        if let cell = table.cellForRow(at: indexPath) as? ATPostCell {
            cell.applyLike(liked: updated.isLiked, count: updated.likeCount)
        } else if let cell = table.cellForRow(at: indexPath) as? ATFeatureCell {
            cell.applyLike(liked: updated.isLiked, count: updated.likeCount)
        }
    }

    private func toggleSame(at index: Int, indexPath: IndexPath) {
        let cell = table.cellForRow(at: indexPath) as? ATPostCell
        toggleSameHere(on: posts[index]) { [weak self] updated in
            self?.posts[index] = updated
            cell?.applySame(isSame: updated.isSameHere, count: updated.sameCount)
        }
    }

    private func openGifts(at index: Int) {
        guard !requireSignIn(message: "Sign in to send a gift.") else { return }

        let post = posts[index]
        let sheet = ATGiftSheetViewController(post: post) { [weak self] _ in
            guard let self, let updated = ATStore.post(id: post.id),
                  let position = self.posts.firstIndex(where: { $0.id == post.id }) else { return }
            self.posts[position] = updated
            let indexPath = IndexPath(row: position, section: 0)
            if let cell = self.table.cellForRow(at: indexPath) as? ATPostCell {
                cell.configure(with: self.presentation(at: position), width: self.table.bounds.width)
            } else if let cell = self.table.cellForRow(at: indexPath) as? ATFeatureCell {
                cell.configure(with: self.presentation(at: position), width: self.table.bounds.width)
            }
        }
        presentSheet(sheet, detents: [.large()])
    }

    private func openPost(at index: Int) {
        push(ATPostDetailViewController(postID: posts[index].id))
    }

    private func openAuthor(of index: Int) {
        guard let author = authors[posts[index].authorID] else { return }
        push(ATUserProfileViewController(userID: author.id))
    }

    @objc private func openMap() {
        push(ATPlaceMapViewController())
    }

    @objc private func openSearch() {
        push(ATSearchViewController())
    }

    private func openPlace(of index: Int) {
        push(ATPlaceViewController(place: ATPlace.resolve(
            locationName: posts[index].locationName,
            country: posts[index].country
        )))
    }
}

// MARK: - Table

extension ATHomeViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let presentation = presentation(at: indexPath.row)
        let width = tableView.bounds.width

        if isFeature(at: indexPath.row),
           let cell = tableView.dequeueReusableCell(withIdentifier: ATFeatureCell.reuseIdentifier, for: indexPath) as? ATFeatureCell {
            cell.configure(with: presentation, width: width)
            cell.onOpen = { [weak self] in self?.openPost(at: indexPath.row) }
            cell.onLike = { [weak self] in self?.toggleLike(at: indexPath.row, indexPath: indexPath) }
            cell.onSame = { [weak self] in self?.toggleSame(at: indexPath.row, indexPath: indexPath) }
            cell.onAuthor = { [weak self] in self?.openAuthor(of: indexPath.row) }
            cell.onLocation = { [weak self] in self?.openPlace(of: indexPath.row) }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ATPostCell.reuseIdentifier, for: indexPath) as! ATPostCell
        cell.configure(with: presentation, width: width)
        cell.onOpen = { [weak self] in self?.openPost(at: indexPath.row) }
        cell.onLike = { [weak self] in self?.toggleLike(at: indexPath.row, indexPath: indexPath) }
        cell.onSame = { [weak self] in self?.toggleSame(at: indexPath.row, indexPath: indexPath) }
        cell.onAuthor = { [weak self] in self?.openAuthor(of: indexPath.row) }
        cell.onComment = { [weak self] in self?.openPost(at: indexPath.row) }
        cell.onGift = { [weak self] in self?.openGifts(at: indexPath.row) }
        cell.onLocation = { [weak self] in self?.openPlace(of: indexPath.row) }
        return cell
    }
}

extension ATHomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPost(at: indexPath.row)
    }
}
