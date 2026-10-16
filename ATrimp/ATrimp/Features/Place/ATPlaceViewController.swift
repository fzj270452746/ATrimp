//
//  ATPlaceViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATPlaceViewController: ATViewController {

    private let place: ATPlace

    private var dossier: ATPlaceDossier
    private var posts: [ATPost] = []
    private var authors: [String: ATUser] = [:]
    private var media: [String: [ATPostMedia]] = [:]

    private let table = UITableView(frame: .zero, style: .plain)

    init(place: ATPlace) {
        self.place = place
        self.dossier = ATPlaceDossier(place: place, posts: [])
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: place.name)
        bar.addTrailing(symbol: "square.and.arrow.up", action: #selector(handleShare), target: self)

        buildTable()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Layout

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
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let header = ATPlaceHeaderView()
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 280)
        table.tableHeaderView = header
    }

    // MARK: - Data

    private func reload() {
        dossier = ATStore.dossier(for: place)
        posts = dossier.posts
        authors = ATStore.users(ids: Array(Set(posts.map(\.authorID))))
        media = ATStore.media(forPostIDs: posts.map(\.id))

        if let header = table.tableHeaderView as? ATPlaceHeaderView {
            header.configure(
                with: dossier,
                notes: ATStore.notes(forPlaceKey: place.key)
            )
        }
        table.reloadData()
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

    @objc private func handleShare() {
        share(cardFor: dossier, from: navBar?.trailingView)
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

    private func toggleLike(at index: Int, indexPath: IndexPath) {
        guard !requireSignIn(message: "Sign in to keep track of what you liked.") else { return }

        let post = posts[index]
        let liked = !post.isLiked
        ATStore.setLiked(liked, postID: post.id)

        guard let updated = ATStore.post(id: post.id) else { return }
        posts[index] = updated

        if let cell = table.cellForRow(at: indexPath) as? ATPostCell {
            cell.applyLike(liked: updated.isLiked, count: updated.likeCount)
        }
    }
}

// MARK: - Table

extension ATPlaceViewController: UITableViewDataSource {

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
        cell.onLocation = { [weak self] in
            self?.table.setContentOffset(.zero, animated: true)
        }
        return cell
    }
}

extension ATPlaceViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openPost(at: indexPath.row)
    }
}

// MARK: - Header

private final class ATPlaceHeaderView: UIView {

    private let nameLabel = UILabel()
    private let countryLabel = UILabel()
    private let metricsRow = UIStackView()
    private let filingsMetric = ATMetricLabel(symbol: "doc.text", text: "0")
    private let travellersMetric = ATMetricLabel(symbol: "person.2", text: "0")
    private let spanMetric = ATMetricLabel(symbol: "calendar", text: "—")
    private let notesBlock = UIView()
    private let notesCaption = UILabel()
    private let notesStack = UIStackView()
    private let lensCaption = UILabel()
    private let lensBar = ATLensBar()
    private let filingsCaption = UILabel()
    private let rule = ATRule()

    private var notesTop: Constraint?
    private var notesCollapse: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paper

        nameLabel.font = ATTheme.Typeface.serif(30, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        nameLabel.numberOfLines = 2
        addSubview(nameLabel)

        countryLabel.font = ATTheme.Typeface.sans(13, .medium)
        countryLabel.textColor = ATTheme.Palette.inkFaint
        addSubview(countryLabel)

        metricsRow.axis = .horizontal
        metricsRow.spacing = ATTheme.Space.md
        metricsRow.alignment = .center
        [filingsMetric, travellersMetric, spanMetric].forEach(metricsRow.addArrangedSubview)
        addSubview(metricsRow)

        notesCaption.attributedText = ATTheme.sectionLabel(
            "What you said you would do",
            color: ATTheme.Palette.mist
        )
        notesBlock.addSubview(notesCaption)

        notesStack.axis = .vertical
        notesStack.spacing = ATTheme.Space.xs
        notesBlock.addSubview(notesStack)
        addSubview(notesBlock)

        lensCaption.attributedText = ATTheme.sectionLabel("How it reads")
        addSubview(lensCaption)

        addSubview(lensBar)

        filingsCaption.attributedText = ATTheme.sectionLabel("The filings")
        addSubview(filingsCaption)

        rule.backgroundColor = ATTheme.Palette.rule
        addSubview(rule)

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        countryLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        metricsRow.snp.makeConstraints { make in
            make.top.equalTo(countryLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.gutter)
        }

        notesCaption.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        notesStack.snp.makeConstraints { make in
            make.top.equalTo(notesCaption.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        notesBlock.snp.makeConstraints { make in
            notesTop = make.top.equalTo(metricsRow.snp.bottom).offset(0).constraint
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            notesCollapse = make.height.equalTo(0).constraint
        }
        notesCollapse?.isActive = true

        lensCaption.snp.makeConstraints { make in
            make.top.equalTo(notesBlock.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        lensBar.snp.makeConstraints { make in
            make.top.equalTo(lensCaption.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        filingsCaption.snp.makeConstraints { make in
            make.top.equalTo(lensBar.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(filingsCaption.snp.bottom).offset(ATTheme.Space.sm)
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

    func configure(with dossier: ATPlaceDossier, notes: [ATNote]) {
        nameLabel.text = dossier.place.name
        countryLabel.text = dossier.place.country

        filingsMetric.set(
            symbol: "doc.text",
            tint: ATTheme.Palette.inkSoft
        )
        filingsMetric.set(
            text: "\(dossier.postCount) \(dossier.postCount == 1 ? "filing" : "filings")",
            tint: ATTheme.Palette.inkSoft
        )
        travellersMetric.set(
            text: "\(dossier.authorCount) \(dossier.authorCount == 1 ? "traveller" : "travellers")",
            tint: ATTheme.Palette.inkSoft
        )

        if let first = dossier.firstFiledAt {
            let year = Calendar.current.component(.year, from: first)
            spanMetric.set(text: "since \(year)", tint: ATTheme.Palette.inkSoft)
        } else {
            spanMetric.set(text: "no dates", tint: ATTheme.Palette.inkSoft)
        }

        lensBar.configure(with: dossier.themesByWeight, averages: dossier.averageIntensity)

        notesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let open = notes.filter { !$0.isResolved }
        for note in open {
            notesStack.addArrangedSubview(noteRow(note.body))
        }

        let hasNotes = !open.isEmpty
        notesBlock.isHidden = !hasNotes
        notesCollapse?.isActive = !hasNotes
        notesTop?.update(offset: hasNotes ? ATTheme.Space.lg : 0)

        setNeedsLayout()
    }

    private func noteRow(_ text: String) -> UIView {
        let container = UIView()

        let configuration = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let bullet = UIImageView(image: UIImage(systemName: "circle", withConfiguration: configuration))
        bullet.tintColor = ATTheme.Palette.mist
        container.addSubview(bullet)

        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: ATTheme.Typeface.sans(14.5),
                .foregroundColor: ATTheme.Palette.ink,
            ]
        )
        label.numberOfLines = 0
        container.addSubview(label)

        bullet.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(5)
            make.width.height.equalTo(11)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(bullet.snp.trailing).offset(ATTheme.Space.xs)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        return container
    }
}
