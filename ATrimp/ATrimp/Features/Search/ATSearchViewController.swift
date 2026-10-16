//
//  ATSearchViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATSearchViewController: ATViewController {

    private enum Section: Int, CaseIterable {
        case places
        case people
        case posts
    }

    private let field = UITextField()
    private let table = UITableView(frame: .zero, style: .plain)
    private let emptyView = ATEmptyView(
        title: "Look for a town, a person, or a line",
        message: "Search runs over everything filed, and over everyone in the library."
    )

    private var results = ATStore.ATSearchResults()
    private var authors: [String: ATUser] = [:]
    private var media: [String: [ATPostMedia]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: "Search")
        bar.addTrailing(view: field)
        field.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.height.equalTo(32)
        }

        buildField()
        buildTable()

        field.becomeFirstResponder()
        refresh()
    }

    // MARK: - Layout

    private func buildField() {
        field.placeholder = "Kyoto, Marisol, mint tea…"
        field.font = ATTheme.Typeface.sans(15)
        field.textColor = ATTheme.Palette.ink
        field.attributedPlaceholder = NSAttributedString(
            string: "Kyoto, Marisol, mint tea…",
            attributes: [
                .font: ATTheme.Typeface.sans(15),
                .foregroundColor: ATTheme.Palette.inkFaint,
            ]
        )
        field.tintColor = ATTheme.Palette.accent
        field.returnKeyType = .search
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        field.textAlignment = .right
        field.addTarget(self, action: #selector(refresh), for: .editingChanged)
    }

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 320
        table.contentInsetAdjustmentBehavior = .never
        table.keyboardDismissMode = .onDrag
        table.dataSource = self
        table.delegate = self
        table.register(ATPostCell.self, forCellReuseIdentifier: ATPostCell.reuseIdentifier)
        table.register(ATPersonCell.self, forCellReuseIdentifier: ATPersonCell.reuseIdentifier)
        table.register(ATPlaceResultCell.self, forCellReuseIdentifier: ATPlaceResultCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom).offset(70)
            make.leading.trailing.equalToSuperview()
        }
        emptyView.isHidden = true
    }

    // MARK: - Data

    @objc private func refresh() {
        results = ATStore.search(field.text ?? "")
        authors = ATStore.users(ids: Array(Set(results.posts.map(\.authorID))))
        media = ATStore.media(forPostIDs: results.posts.map(\.id))

        table.reloadData()
        emptyView.isHidden = !results.isEmpty || !(field.text ?? "").isEmpty
    }

    private func open(_ indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) ?? .places {
        case .places:
            push(ATPlaceViewController(place: results.places[indexPath.row].place))
        case .people:
            push(ATUserProfileViewController(userID: results.people[indexPath.row].id))
        case .posts:
            push(ATPostDetailViewController(postID: results.posts[indexPath.row].id))
        }
    }

    private func count(in section: Section) -> Int {
        switch section {
        case .places: return results.places.count
        case .people: return results.people.count
        case .posts: return results.posts.count
        }
    }
}

// MARK: - Table

extension ATSearchViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        count(in: Section(rawValue: section) ?? .places)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .places {
        case .places:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ATPlaceResultCell.reuseIdentifier,
                for: indexPath
            ) as! ATPlaceResultCell
            cell.configure(with: results.places[indexPath.row])
            return cell

        case .people:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ATPersonCell.reuseIdentifier,
                for: indexPath
            ) as! ATPersonCell
            cell.configure(person: results.people[indexPath.row], action: nil)
            return cell

        case .posts:
            let post = results.posts[indexPath.row]
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ATPostCell.reuseIdentifier,
                for: indexPath
            ) as! ATPostCell
            cell.configure(
                with: ATPostPresentation(
                    post: post,
                    author: authors[post.authorID],
                    media: media[post.id] ?? []
                ),
                width: tableView.bounds.width
            )
            cell.onOpen = { [weak self] in self?.open(indexPath) }
            cell.onLike = { [weak self] in self?.toggleLike(at: indexPath) }
            cell.onSame = { [weak self] in self?.toggleSame(at: indexPath) }
            cell.onAuthor = { [weak self] in
                guard let self, let author = self.authors[post.authorID] else { return }
                self.push(ATUserProfileViewController(userID: author.id))
            }
            cell.onComment = { [weak self] in self?.open(indexPath) }
            cell.onLocation = { [weak self] in
                self?.push(ATPlaceViewController(place: ATPlace.resolve(
                    locationName: post.locationName,
                    country: post.country
                )))
            }
            return cell
        }
    }

    private func toggleLike(at indexPath: IndexPath) {
        guard !requireSignIn(message: "Sign in to keep track of what you liked.") else { return }

        let post = results.posts[indexPath.row]
        ATStore.setLiked(!post.isLiked, postID: post.id)

        guard let updated = ATStore.post(id: post.id) else { return }
        results.posts[indexPath.row] = updated
        (table.cellForRow(at: indexPath) as? ATPostCell)?
            .applyLike(liked: updated.isLiked, count: updated.likeCount)
    }

    private func toggleSame(at indexPath: IndexPath) {
        let cell = table.cellForRow(at: indexPath) as? ATPostCell
        toggleSameHere(on: results.posts[indexPath.row]) { [weak self] updated in
            self?.results.posts[indexPath.row] = updated
            cell?.applySame(isSame: updated.isSameHere, count: updated.sameCount)
        }
    }
}

extension ATSearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let kind = Section(rawValue: section) ?? .places
        guard count(in: kind) > 0 else { return nil }

        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paper

        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(
            "\(title(for: kind)) · \(count(in: kind))"
        )
        container.addSubview(label)

        let rule = ATRule()
        container.addSubview(rule)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.lg)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        count(in: Section(rawValue: section) ?? .places) > 0 ? UITableView.automaticDimension : 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        open(indexPath)
    }

    private func title(for section: Section) -> String {
        switch section {
        case .places: return "Places"
        case .people: return "People"
        case .posts: return "Filings"
        }
    }
}

// MARK: - Place row

private final class ATPlaceResultCell: UITableViewCell {

    static let reuseIdentifier = "ATPlaceResultCell"

    private let dot = UIView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        dot.layer.cornerRadius = 5
        contentView.addSubview(dot)

        nameLabel.font = ATTheme.Typeface.serif(17, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        contentView.addSubview(nameLabel)

        detailLabel.font = ATTheme.Typeface.caption
        detailLabel.textColor = ATTheme.Palette.inkFaint
        contentView.addSubview(detailLabel)

        dot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(10)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with dossier: ATPlaceDossier) {
        dot.backgroundColor = dossier.dominantTheme?.tint ?? ATTheme.Palette.ruleStrong
        nameLabel.text = dossier.place.title

        let lens = dossier.dominantTheme.map { "mostly \($0.title.lowercased())" } ?? "nothing filed"
        let filings = dossier.postCount == 1 ? "1 filing" : "\(dossier.postCount) filings"
        detailLabel.text = "\(filings) · \(lens)"
    }
}
