//
//  ATMonthViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATMonthViewController: ATViewController {

    private let monthStart: Date

    private let table = UITableView(frame: .zero, style: .plain)
    private var posts: [ATPost] = []
    private var authors: [String: ATUser] = [:]
    private var media: [String: [ATPostMedia]] = [:]
    private let emptyView = ATEmptyView(
        title: "Nothing filed this month",
        message: "The library has no entries with a date inside these weeks."
    )

    init(monthStart: Date) {
        self.monthStart = monthStart
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: Self.title(for: monthStart), showsBack: true)
        buildHeader()
        buildTable()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private static func title(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Layout

    private let header = ATMonthHeaderView()

    private func buildHeader() {
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 130)
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
        table.tableHeaderView = header
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
    }

    // MARK: - Data

    private func reload() {
        posts = ATStore.posts(inMonthStarting: monthStart)
        authors = ATStore.users(ids: Array(Set(posts.map(\.authorID))))
        media = ATStore.media(forPostIDs: posts.map(\.id))

        let placeCount = Set(posts.map {
            ATPlace.resolve(locationName: $0.locationName, country: $0.country).key
        }).count

        let grouped = Dictionary(grouping: posts, by: \.theme)
        let themes: [(theme: ATPostTheme, count: Int)] = grouped
            .map { (theme: $0.key, count: $0.value.count) }
            .sorted { left, right in
                if left.count != right.count { return left.count > right.count }
                return left.theme.title < right.theme.title
            }

        header.configure(
            count: posts.count,
            places: placeCount,
            travellers: Set(posts.map(\.authorID)).count,
            themes: themes
        )

        table.reloadData()
        emptyView.isHidden = !posts.isEmpty
    }

    private func presentation(at index: Int) -> ATPostPresentation {
        let post = posts[index]
        return ATPostPresentation(post: post, author: authors[post.authorID], media: media[post.id] ?? [])
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
}

// MARK: - Table

extension ATMonthViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ATPostCell.reuseIdentifier,
            for: indexPath
        ) as! ATPostCell

        cell.configure(with: presentation(at: indexPath.row), width: tableView.bounds.width)
        cell.onOpen = { [weak self] in self?.openPost(at: indexPath.row) }
        cell.onLike = { [weak self] in self?.toggleLike(at: indexPath.row, indexPath: indexPath) }
        cell.onSame = { [weak self] in self?.toggleSame(at: indexPath.row, indexPath: indexPath) }
        cell.onAuthor = { [weak self] in self?.openAuthor(of: indexPath.row) }
        cell.onComment = { [weak self] in self?.openPost(at: indexPath.row) }
        cell.onLocation = { [weak self] in self?.openPlace(of: indexPath.row) }
        return cell
    }
}

extension ATMonthViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPost(at: indexPath.row)
    }
}

// MARK: - Header

private final class ATMonthHeaderView: UIView {

    private let metrics = UIStackView()
    private let filings = ATMetricLabel(symbol: "doc.text", text: "0")
    private let places = ATMetricLabel(symbol: "mappin.and.ellipse", text: "0")
    private let travellers = ATMetricLabel(symbol: "person.2", text: "0")
    private let stripe = ATLensStripe()
    private let note = UILabel()
    private let rule = ATRule()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ATTheme.Palette.paper

        metrics.axis = .horizontal
        metrics.spacing = ATTheme.Space.md
        metrics.alignment = .center
        [filings, places, travellers].forEach(metrics.addArrangedSubview)
        addSubview(metrics)

        addSubview(stripe)

        note.font = ATTheme.Typeface.caption
        note.textColor = ATTheme.Palette.inkFaint
        note.numberOfLines = 0
        addSubview(note)

        rule.backgroundColor = ATTheme.Palette.rule
        addSubview(rule)

        metrics.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        stripe.snp.makeConstraints { make in
            make.top.equalTo(metrics.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        note.snp.makeConstraints { make in
            make.top.equalTo(stripe.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(note.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
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

    func configure(
        count: Int,
        places: Int,
        travellers: Int,
        themes: [(theme: ATPostTheme, count: Int)]
    ) {
        filings.set(text: "\(count) \(count == 1 ? "filing" : "filings")", tint: ATTheme.Palette.inkSoft)
        self.places.set(text: "\(places) \(places == 1 ? "place" : "places")", tint: ATTheme.Palette.inkSoft)
        self.travellers.set(
            text: "\(travellers) \(travellers == 1 ? "traveller" : "travellers")",
            tint: ATTheme.Palette.inkSoft
        )

        stripe.configure(with: themes)

        if let lead = themes.first {
            note.text = "\(count) filed this month, reading mostly as \(lead.theme.title.lowercased())."
        } else {
            note.text = "Nothing was filed this month."
        }

        setNeedsLayout()
    }
}
