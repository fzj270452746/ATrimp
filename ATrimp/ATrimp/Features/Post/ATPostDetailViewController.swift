//
//  ATPostDetailViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATPostDetailViewController: ATViewController {

    private enum Section: Int, CaseIterable {
        case content
        case answer
        case comments
    }

    private let postID: String
    private var post: ATPost
    private var author: ATUser?
    private var media: [ATPostMedia] = []
    private var comments: [ATComment] = []
    private var commentAuthors: [String: ATUser] = [:]
    private var noteCount = 0
    private var answer: ATPost?
    private var answerMedia: [ATPostMedia] = []
    private var answered: ATPost?

    private let table = UITableView(frame: .zero, style: .plain)
    private let composer = ATCommentComposer()
    private var composerBottom: Constraint?

    init(postID: String) {
        self.postID = postID
        self.post = ATStore.post(id: postID) ?? ATPost(
            id: postID, authorID: "", body: "", themeRaw: ATPostTheme.surprise.rawValue,
            locationName: "", country: "", createdAt: Date(),
            likeCount: 0, commentCount: 0, giftCount: 0, isLiked: false,
            redeemedAt: nil, intensity: nil,
            sameCount: 0, isSameHere: false, answersPostID: nil
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        post = ATStore.post(id: postID) ?? post
        author = ATStore.user(id: post.authorID)
        media = ATStore.media(forPost: postID)

        let bar = installNavBar(title: post.locationName)
        bar.addTrailing(symbol: "square.and.arrow.up", action: #selector(handleShare), target: self)
        bar.addTrailing(symbol: "ellipsis", action: #selector(handleMore), target: self)

        buildComposer()
        buildTable()
        reloadComments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadHeader()
    }

    // MARK: - Layout

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 220
        table.contentInsetAdjustmentBehavior = .never
        table.keyboardDismissMode = .interactive
        table.dataSource = self
        table.delegate = self
        table.register(ATPostBodyCell.self, forCellReuseIdentifier: ATPostBodyCell.reuseIdentifier)
        table.register(ATPostMediaStripCell.self, forCellReuseIdentifier: ATPostMediaStripCell.reuseIdentifier)
        table.register(ATPostActionsCell.self, forCellReuseIdentifier: ATPostActionsCell.reuseIdentifier)
        table.register(ATReturnTripCell.self, forCellReuseIdentifier: ATReturnTripCell.reuseIdentifier)
        table.register(ATCommentCell.self, forCellReuseIdentifier: ATCommentCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(composer.snp.top)
        }
    }

    private func buildComposer() {
        composer.onSend = { [weak self] text in
            self?.sendComment(text)
        }
        view.addSubview(composer)

        composer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
    }

    // MARK: - Data

    private func reloadComments() {
        comments = ATStore.comments(forPost: postID)
        commentAuthors = ATStore.users(ids: Array(Set(comments.map(\.authorID))))
        table.reloadData()
    }

    private func reloadHeader() {
        guard let fresh = ATStore.post(id: postID) else { return }
        post = fresh
        noteCount = ATStore.noteCount(forPlaceKey: ATPlace.resolve(
            locationName: post.locationName,
            country: post.country
        ).key)

        answer = ATStore.answer(toPost: postID)
        answerMedia = answer.map { ATStore.media(forPost: $0.id) } ?? []
        answered = ATStore.answeredPost(ofRevisit: post)

        table.reloadSections(
            IndexSet(integersIn: Section.content.rawValue...Section.answer.rawValue),
            with: .none
        )
    }

    private func openMedia(at index: Int) {
        guard !media.isEmpty else { return }
        present(ATMediaViewerViewController(media: media, startAt: index), animated: true)
    }

    private func openPlace() {
        push(ATPlaceViewController(place: ATPlace.resolve(
            locationName: post.locationName,
            country: post.country
        )))
    }

    // MARK: - Actions

    private var isMyPost: Bool {
        !post.authorID.isEmpty && post.authorID == ATSession.shared.userID
    }

    @objc private func handleShare() {
        share(cardFor: post, author: author, media: media, from: navBar?.trailingView)
    }

    @objc private func handleMore() {
        if isMyPost {
            openOwnPostMenu()
            return
        }

        let report = ATReportViewController(target: .post(post)) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .removed:
                self.goBack()
            case .blocked(let userID):
                self.removeContent(byUser: userID)
            case .dismissed:
                break
            }
        }
        presentSheet(report, detents: [.medium(), .large()])
    }

    private func openOwnPostMenu() {
        let alert = UIAlertController(title: "Your filing", message: nil, preferredStyle: .actionSheet)

        if let answer {
            alert.addAction(UIAlertAction(title: "Read the return trip", style: .default) { [weak self] _ in
                self?.push(ATPostDetailViewController(postID: answer.id))
            })
        } else {
            alert.addAction(UIAlertAction(title: "I went back", style: .default) { [weak self] _ in
                self?.openRevisitSheet()
            })
        }

        if post.isRedeemed {
            alert.addAction(UIAlertAction(title: "Undo \"went back\"", style: .default) { [weak self] _ in
                guard let self else { return }
                ATStore.setRedeemed(false, postID: self.postID)
                self.reloadHeader()
            })
        }

        alert.addAction(UIAlertAction(title: "Delete post", style: .destructive) { [weak self] _ in
            self?.confirmRemove()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let anchor = navBar?.trailingView {
            presentSheetAlert(alert, from: anchor)
        } else {
            present(alert, animated: true)
        }
    }

    private func openRevisitSheet() {
        let sheet = ATRevisitSheetViewController(post: post) { [weak self] filed in
            guard let self else { return }
            self.reloadHeader()
            if filed.id == self.postID {
                self.showToast("Stamped. The place gets a second reading.")
            } else {
                self.showToast("Filed. Your return trip is on the place.")
            }
        }
        sheet.modalPresentationStyle = .pageSheet
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = ATTheme.Radius.large
        }
        present(sheet, animated: true)
    }

    private func handleNote() {
        guard !requireSignIn(message: "Sign in to keep notes about a place.") else { return }

        let place = ATPlace.resolve(locationName: post.locationName, country: post.country)
        if ATStore.notes(forPlaceKey: place.key).isEmpty {
            promptForNote(in: place)
        } else {
            push(ATNotesViewController(focusing: place))
        }
    }

    private func promptForNote(in place: ATPlace) {
        let alert = UIAlertController(
            title: "Note for \(place.name)",
            message: "What will you do differently? It stays on this device, and shows up next time you open \(place.name).",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = "Skip the queue and take the ferry"
            field.autocapitalizationType = .sentences
            field.font = ATTheme.Typeface.sans(15)
        }
        alert.addAction(UIAlertAction(title: "Keep it", style: .default) { [weak self, weak alert] _ in
            guard let self, let text = alert?.textFields?.first?.text else { return }
            if ATStore.addNote(place: place, body: text, sourcePostID: self.postID) != nil {
                self.showToast("Kept for \(place.name).")
                self.reloadHeader()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func confirmRemove() {
        let alert = UIAlertController(
            title: "Remove this post?",
            message: "\(post.locationName), \(post.country). This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            guard let self else { return }
            ATStore.deletePost(id: self.postID)
            ATSession.shared.refresh()
            self.goBack()
        })
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))
        present(alert, animated: true)
    }

    private func handleLike() {
        guard !requireSignIn(message: "Sign in to keep track of what you liked.") else { return }
        ATStore.setLiked(!post.isLiked, postID: postID)
        reloadHeader()
    }

    private func handleSame() {
        guard !requireSignIn(message: "Sign in to say you did the same.") else { return }
        ATStore.setSameHere(!post.isSameHere, postID: postID)
        reloadHeader()
    }

    private func handleGift() {
        guard !requireSignIn(message: "Sign in to send a gift.") else { return }

        let sheet = ATGiftSheetViewController(post: post) { [weak self] _ in
            self?.reloadHeader()
        }
        presentSheet(sheet, detents: [.large()])
    }

    private func handleAuthor() {
        guard !post.authorID.isEmpty else { return }
        push(ATUserProfileViewController(userID: post.authorID))
    }

    private func openCommentMenu(for comment: ATComment, from anchor: UIView) {
        if comment.isMine {
            let alert = UIAlertController(
                title: "Your comment",
                message: nil,
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Delete comment", style: .destructive) { [weak self] _ in
                ATStore.deleteComment(id: comment.id)
                self?.reloadComments()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            presentSheetAlert(alert, from: anchor)
            return
        }

        let report = ATReportViewController(target: .comment(comment)) { [weak self] outcome in
            guard let self, outcome.didRemoveContent else { return }
            self.reloadComments()
        }
        presentSheet(report, detents: [.medium(), .large()])
    }

    private func sendComment(_ text: String) {
        guard !requireSignIn(message: "Sign in to join the discussion.") else { return }
        guard let userID = ATSession.shared.userID, !text.isEmpty else { return }

        ATStore.addComment(postID: postID, authorID: userID, body: text)
        composer.clear()
        reloadComments()

        guard !comments.isEmpty else { return }
        table.scrollToRow(
            at: IndexPath(row: comments.count - 1, section: Section.comments.rawValue),
            at: .bottom,
            animated: true
        )
    }

    private func removeContent(byUser userID: String) {
        ATStore.deleteUser(id: userID)
        goBack()
    }

    private func presentSheetAlert(_ alert: UIAlertController, from anchor: UIView) {
        if let popover = alert.popoverPresentationController {
            popover.sourceView = anchor
            popover.sourceRect = anchor.bounds
            popover.permittedArrowDirections = [.up, .down]
        }
        present(alert, animated: true)
    }
}

// MARK: - Table

extension ATPostDetailViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .content {
        case .content:
            return media.isEmpty ? 2 : 3
        case .answer:
            return answer == nil ? 0 : 1
        case .comments:
            return comments.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .content {
        case .content:
            let hasMedia = !media.isEmpty

            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: ATPostBodyCell.reuseIdentifier, for: indexPath) as! ATPostBodyCell
                cell.configure(
                    post: post,
                    author: author,
                    isSignedIn: ATSession.shared.isSignedIn,
                    answering: answered
                )
                cell.onAuthor = { [weak self] in self?.handleAuthor() }
                cell.onLocation = { [weak self] in self?.openPlace() }
                cell.onAnswering = { [weak self] in
                    guard let original = self?.answered else { return }
                    self?.push(ATPostDetailViewController(postID: original.id))
                }
                return cell
            }

            if hasMedia && indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: ATPostMediaStripCell.reuseIdentifier, for: indexPath) as! ATPostMediaStripCell
                cell.configure(with: media)
                cell.onOpen = { [weak self] index in self?.openMedia(at: index) }
                return cell
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: ATPostActionsCell.reuseIdentifier, for: indexPath) as! ATPostActionsCell
            cell.configure(post: post, noteCount: noteCount)
            cell.onLike = { [weak self] in self?.handleLike() }
            cell.onSame = { [weak self] in self?.handleSame() }
            cell.onGift = { [weak self] in self?.handleGift() }
            cell.onNote = { [weak self] in self?.handleNote() }
            return cell

        case .answer:
            let cell = tableView.dequeueReusableCell(withIdentifier: ATReturnTripCell.reuseIdentifier, for: indexPath) as! ATReturnTripCell
            if let answer {
                cell.configure(with: answer, media: answerMedia)
            }
            cell.onOpen = { [weak self] in
                guard let id = self?.answer?.id else { return }
                self?.push(ATPostDetailViewController(postID: id))
            }
            return cell

        case .comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: ATCommentCell.reuseIdentifier, for: indexPath) as! ATCommentCell
            let comment = comments[indexPath.row]
            cell.configure(comment: comment, author: commentAuthors[comment.authorID])
            cell.onMenu = { [weak self] anchor in
                self?.openCommentMenu(for: comment, from: anchor)
            }
            cell.onAuthor = { [weak self] in
                guard !comment.authorID.isEmpty else { return }
                self?.push(ATUserProfileViewController(userID: comment.authorID))
            }
            return cell
        }
    }
}

extension ATPostDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let kind = Section(rawValue: section) ?? .content
        guard kind == .comments || (kind == .answer && answer != nil) else { return nil }

        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paper

        let label = UILabel()
        label.attributedText = kind == .answer
            ? ATTheme.sectionLabel("The return trip", color: ATTheme.Palette.mist)
            : ATTheme.sectionLabel(comments.isEmpty ? "Comments" : "Comments · \(comments.count)")
        container.addSubview(label)

        let rule = ATRule()
        container.addSubview(rule)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        rule.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch Section(rawValue: section) ?? .content {
        case .answer:
            return answer == nil ? 0 : 40
        case .comments:
            return 40
        case .content:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard Section(rawValue: section) == .comments, comments.isEmpty else { return nil }

        let label = UILabel()
        label.text = "No comments yet. Be the first to add something useful."
        label.font = ATTheme.Typeface.body
        label.textColor = ATTheme.Palette.inkFaint
        label.numberOfLines = 0

        let container = UIView()
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.lg)
        }
        return container
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        Section(rawValue: section) == .comments && comments.isEmpty ? UITableView.automaticDimension : 0
    }
}

// MARK: - Post body

private final class ATPostBodyCell: UITableViewCell {

    static let reuseIdentifier = "ATPostBodyCell"

    var onAuthor: (() -> Void)?
    var onLocation: (() -> Void)?
    var onAnswering: (() -> Void)?

    private let header = UIControl()
    private let avatar = ATAvatarView(size: 44)
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()

    private let answeringRow = UIControl()
    private let answeringLabel = UILabel()

    private let chipHolder = UIView()
    private let locationLink = ATLinkLabel(
        font: ATTheme.Typeface.captionStrong,
        tint: ATTheme.Palette.inkSoft,
        underline: ATTheme.Palette.ruleStrong
    )
    private let intensityMark = ATIntensityMark()
    private let redemptionRow = UIView()
    private let stamp = ATStamp(text: "Went back")
    private let redemptionLabel = UILabel()
    private let bodyLabel = UILabel()

    private var chip: ATThemeChip?
    private var redemptionHeight: Constraint?
    private var bodyTop: Constraint?
    private var answeringHeight: Constraint?
    private var headerTop: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        answeringRow.clipsToBounds = true
        answeringRow.isHidden = true
        answeringRow.addTarget(self, action: #selector(handleAnswering), for: .touchUpInside)
        contentView.addSubview(answeringRow)

        answeringLabel.font = ATTheme.Typeface.sans(13, .semibold)
        answeringLabel.textColor = ATTheme.Palette.mist
        answeringLabel.numberOfLines = 1
        answeringLabel.adjustsFontSizeToFitWidth = true
        answeringLabel.minimumScaleFactor = 0.8
        answeringLabel.isUserInteractionEnabled = false
        answeringRow.addSubview(answeringLabel)

        header.addTarget(self, action: #selector(handleAuthor), for: .touchUpInside)
        contentView.addSubview(header)
        header.addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.serif(19, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        header.addSubview(nameLabel)

        metaLabel.font = ATTheme.Typeface.caption
        metaLabel.textColor = ATTheme.Palette.inkFaint
        metaLabel.numberOfLines = 0
        header.addSubview(metaLabel)

        contentView.addSubview(chipHolder)

        locationLink.onTap = { [weak self] in self?.onLocation?() }
        chipHolder.addSubview(locationLink)

        chipHolder.addSubview(intensityMark)

        intensityMark.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(locationLink.snp.trailing).offset(ATTheme.Space.sm)
        }

        redemptionRow.clipsToBounds = true
        redemptionRow.isHidden = true
        contentView.addSubview(redemptionRow)

        redemptionRow.addSubview(stamp)

        redemptionLabel.font = ATTheme.Typeface.caption
        redemptionLabel.textColor = ATTheme.Palette.mist
        redemptionLabel.numberOfLines = 1
        redemptionRow.addSubview(redemptionLabel)

        bodyLabel.font = ATTheme.Typeface.sans(16.5)
        bodyLabel.textColor = ATTheme.Palette.ink
        bodyLabel.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 5
        bodyLabel.attributedText = nil
        contentView.addSubview(bodyLabel)

        answeringRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            answeringHeight = make.height.equalTo(0).constraint
        }

        answeringLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        header.snp.makeConstraints { make in
            headerTop = make.top.equalTo(answeringRow.snp.bottom).offset(0).constraint
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        avatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(2)
        }

        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }

        chipHolder.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.height.equalTo(24)
        }

        locationLink.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        redemptionRow.snp.makeConstraints { make in
            make.top.equalTo(chipHolder.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            redemptionHeight = make.height.equalTo(0).constraint
        }

        stamp.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        redemptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(stamp.snp.trailing).offset(ATTheme.Space.sm)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        bodyLabel.snp.makeConstraints { make in
            bodyTop = make.top.equalTo(redemptionRow.snp.bottom).offset(0).constraint
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.lg)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(post: ATPost, author: ATUser?, isSignedIn: Bool, answering: ATPost? = nil) {
        if let answering {
            answeringRow.isHidden = false
            answeringHeight?.update(offset: 22)
            headerTop?.update(offset: ATTheme.Space.md)
            answeringLabel.text = "Answering \(answering.locationName), \(answering.country) — tap to read it"
        } else {
            answeringRow.isHidden = true
            answeringHeight?.update(offset: 0)
            headerTop?.update(offset: 0)
        }

        avatar.set(user: author)
        nameLabel.text = author?.displayName ?? "Removed account"
        metaLabel.text = [
            author?.homeCity,
            ATTime.relative(post.createdAt),
        ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")

        chip?.removeFromSuperview()
        let newChip = ATThemeChip(theme: post.theme)
        chipHolder.addSubview(newChip)
        newChip.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        chip = newChip

        if let redeemedAt = post.redeemedAt {
            redemptionRow.isHidden = false
            redemptionHeight?.update(offset: 26)
            bodyTop?.update(offset: ATTheme.Space.md)
            redemptionLabel.text = "Went back in \(ATTime.monthYear(redeemedAt))"
        } else {
            redemptionRow.isHidden = true
            redemptionHeight?.update(offset: 0)
            bodyTop?.update(offset: 0)
        }

        intensityMark.configure(value: post.intensity, tint: post.theme.tint)

        locationLink.setText("\(post.locationName), \(post.country)")
        locationLink.snp.remakeConstraints { make in
            make.leading.equalTo(newChip.snp.trailing).offset(ATTheme.Space.xs)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 5
        bodyLabel.attributedText = NSAttributedString(
            string: post.body,
            attributes: [
                .font: ATTheme.Typeface.sans(16.5),
                .foregroundColor: ATTheme.Palette.ink,
                .paragraphStyle: paragraph,
            ]
        )
    }

    @objc private func handleAuthor() { onAuthor?() }
    @objc private func handleAnswering() { onAnswering?() }
}

// MARK: - The return trip

private final class ATReturnTripCell: UITableViewCell {

    static let reuseIdentifier = "ATReturnTripCell"

    var onOpen: (() -> Void)?

    private let card = UIControl()
    private let stamp = ATStamp(text: "Went back")
    private let whenLabel = UILabel()
    private let cover = UIImageView()
    private let bodyLabel = UILabel()
    private let footnote = UILabel()

    private var coverHeight: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        card.backgroundColor = ATTheme.Palette.paperDeep
        card.layer.cornerRadius = ATTheme.Radius.medium
        card.layer.cornerCurve = .continuous
        card.addTarget(self, action: #selector(handleOpen), for: .touchUpInside)
        contentView.addSubview(card)

        card.addSubview(stamp)

        whenLabel.font = ATTheme.Typeface.caption
        whenLabel.textColor = ATTheme.Palette.inkFaint
        whenLabel.numberOfLines = 1
        card.addSubview(whenLabel)

        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true
        cover.layer.cornerRadius = ATTheme.Radius.small
        cover.layer.cornerCurve = .continuous
        cover.backgroundColor = ATTheme.Palette.paper
        card.addSubview(cover)

        bodyLabel.font = ATTheme.Typeface.sans(15.5)
        bodyLabel.textColor = ATTheme.Palette.ink
        bodyLabel.numberOfLines = 4
        card.addSubview(bodyLabel)

        footnote.attributedText = ATTheme.sectionLabel("Read the return trip", color: ATTheme.Palette.accent)
        card.addSubview(footnote)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        stamp.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(ATTheme.Space.md)
        }

        whenLabel.snp.makeConstraints { make in
            make.leading.equalTo(stamp.snp.trailing).offset(ATTheme.Space.sm)
            make.centerY.equalTo(stamp)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.md)
        }

        cover.snp.makeConstraints { make in
            make.top.equalTo(stamp.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
            coverHeight = make.height.equalTo(0).constraint
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(cover.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
        }

        footnote.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.md)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        onOpen = nil
    }

    func configure(with answer: ATPost, media: [ATPostMedia]) {
        whenLabel.text = "\(ATTime.relative(answer.createdAt)) · \(answer.theme.title)"

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        paragraph.lineBreakMode = .byTruncatingTail
        bodyLabel.attributedText = NSAttributedString(
            string: answer.body,
            attributes: [
                .font: ATTheme.Typeface.sans(15.5),
                .foregroundColor: ATTheme.Palette.ink,
                .paragraphStyle: paragraph,
            ]
        )

        if let first = media.first {
            cover.isHidden = false
            cover.image = ATMediaLibrary.image(
                for: first,
                size: CGSize(width: 1080, height: 700),
                symbol: first.kind == .video ? "play.fill" : nil
            )
            coverHeight?.update(offset: 200)
        } else {
            cover.isHidden = true
            coverHeight?.update(offset: 0)
        }
    }

    @objc private func handleOpen() { onOpen?() }
}

// MARK: - Media strip

private final class ATPostMediaStripCell: UITableViewCell {

    static let reuseIdentifier = "ATPostMediaStripCell"

    var onOpen: ((Int) -> Void)?

    private var media: [ATPostMedia] = []
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = ATTheme.Space.xs
        layout.sectionInset = UIEdgeInsets(top: 0, left: ATTheme.Space.gutter, bottom: 0, right: ATTheme.Space.gutter)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(ATMediaStripItem.self, forCellWithReuseIdentifier: ATMediaStripItem.reuseIdentifier)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper
        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(300)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with media: [ATPostMedia]) {
        self.media = media
        collectionView.reloadData()
    }
}

extension ATPostMediaStripCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        media.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ATMediaStripItem.reuseIdentifier,
            for: indexPath
        ) as! ATMediaStripItem

        let item = media[indexPath.item]
        cell.configure(
            with: item,
            size: CGSize(width: collectionView.bounds.width * 0.82, height: 300)
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: max(1, collectionView.bounds.width * 0.82), height: 300)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onOpen?(indexPath.item)
    }
}

private final class ATMediaStripItem: UICollectionViewCell {

    static let reuseIdentifier = "ATMediaStripItem"

    private let imageView = UIImageView()
    private let playBadge = UIImageView()
    private let counterLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = ATTheme.Radius.small
        contentView.backgroundColor = ATTheme.Palette.paperDeep

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playBadge.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.55)
        playBadge.layer.cornerRadius = 18
        playBadge.contentMode = .center
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        playBadge.image = UIImage(systemName: "play.fill", withConfiguration: configuration)?
            .withTintColor(ATTheme.Palette.paper, renderingMode: .alwaysOriginal)
        contentView.addSubview(playBadge)
        playBadge.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(36)
        }

        counterLabel.font = ATTheme.Typeface.sans(11, .semibold)
        counterLabel.textColor = ATTheme.Palette.paper
        counterLabel.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.5)
        counterLabel.textAlignment = .center
        counterLabel.layer.cornerRadius = 10
        counterLabel.clipsToBounds = true
        contentView.addSubview(counterLabel)
        counterLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
            make.width.equalTo(46)
            make.height.equalTo(20)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with media: ATPostMedia, size: CGSize, position: Int? = nil, total: Int? = nil) {
        imageView.image = ATMediaLibrary.image(
            for: media,
            size: size,
            symbol: media.kind == .video ? "play.fill" : nil
        )
        playBadge.isHidden = media.kind != .video

        if let position, let total, total > 1 {
            counterLabel.isHidden = false
            counterLabel.text = "\(position + 1)/\(total)"
        } else {
            counterLabel.isHidden = true
        }
    }
}

// MARK: - Actions

private final class ATPostActionsCell: UITableViewCell {

    static let reuseIdentifier = "ATPostActionsCell"

    var onLike: (() -> Void)?
    var onSame: (() -> Void)?
    var onGift: (() -> Void)?
    var onNote: (() -> Void)?

    private let likeButton = UIButton(type: .system)
    private let commentMetric = ATMetricLabel(symbol: "bubble.left", text: "0")
    private let giftMetric = ATMetricLabel(symbol: "gift", text: "0")
    private let giftButton = ATPillButton(title: "Send a gift")
    private let sameButton = ATPillButton(title: "Same here")
    private let noteButton = ATGhostButton(title: "Keep a note")
    private let rule = ATRule()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        likeButton.titleLabel?.font = ATTheme.Typeface.sans(13.5, .semibold)
        likeButton.tintColor = ATTheme.Palette.inkSoft
        likeButton.addTarget(self, action: #selector(handleLike), for: .touchUpInside)
        contentView.addSubview(likeButton)

        contentView.addSubview(commentMetric)
        contentView.addSubview(giftMetric)

        giftButton.addTarget(self, action: #selector(handleGift), for: .touchUpInside)
        contentView.addSubview(giftButton)

        sameButton.addTarget(self, action: #selector(handleSame), for: .touchUpInside)
        contentView.addSubview(sameButton)

        noteButton.addTarget(self, action: #selector(handleNote), for: .touchUpInside)
        contentView.addSubview(noteButton)

        contentView.addSubview(rule)

        likeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
        }

        commentMetric.snp.makeConstraints { make in
            make.leading.equalTo(likeButton.snp.trailing).offset(ATTheme.Space.lg)
            make.centerY.equalTo(likeButton)
        }

        giftMetric.snp.makeConstraints { make in
            make.leading.equalTo(commentMetric.snp.trailing).offset(ATTheme.Space.lg)
            make.centerY.equalTo(likeButton)
        }

        giftButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalTo(likeButton)
        }

        sameButton.snp.makeConstraints { make in
            make.top.equalTo(likeButton.snp.bottom).offset(ATTheme.Space.md)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        noteButton.snp.makeConstraints { make in
            make.top.equalTo(sameButton.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(noteButton.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(post: ATPost, noteCount: Int) {
        if noteCount > 0 {
            noteButton.apply(
                title: noteCount == 1
                    ? "Your note for \(post.locationName)"
                    : "Your \(noteCount) notes for \(post.locationName)",
                tint: ATTheme.Palette.mist
            )
        } else {
            noteButton.apply(title: "Keep a note", tint: ATTheme.Palette.ink)
        }
        configure(post: post)
    }

    private func configure(post: ATPost) {
        let tint = post.isLiked ? ATTheme.Palette.accent : ATTheme.Palette.inkSoft
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)

        likeButton.setImage(
            UIImage(systemName: post.isLiked ? "heart.fill" : "heart", withConfiguration: configuration),
            for: .normal
        )
        likeButton.setTitle(" \(post.likeCount)", for: .normal)
        likeButton.setTitleColor(tint, for: .normal)
        likeButton.tintColor = tint
        likeButton.semanticContentAttribute = .forceLeftToRight

        commentMetric.set(text: "\(post.commentCount)", tint: ATTheme.Palette.inkSoft)
        giftMetric.set(text: "\(post.giftCount)", tint: ATTheme.Palette.inkSoft)

        sameButton.apply(
            title: post.sameCount > 0 ? "Same here · \(post.sameCount)" : "Same here",
            filled: post.isSameHere,
            tint: ATTheme.Palette.mist
        )
    }

    @objc private func handleLike() { onLike?() }
    @objc private func handleSame() { onSame?() }
    @objc private func handleGift() { onGift?() }
    @objc private func handleNote() { onNote?() }
}

// MARK: - Comment

private final class ATCommentCell: UITableViewCell {

    static let reuseIdentifier = "ATCommentCell"

    var onMenu: ((UIView) -> Void)?
    var onAuthor: (() -> Void)?

    private let header = UIControl()
    private let avatar = ATAvatarView(size: 30)
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let bodyLabel = UILabel()
    private let menuButton = UIButton(type: .system)
    private let marker = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        header.addTarget(self, action: #selector(handleAuthor), for: .touchUpInside)
        contentView.addSubview(header)
        header.addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.captionStrong
        nameLabel.textColor = ATTheme.Palette.ink
        header.addSubview(nameLabel)

        timeLabel.font = ATTheme.Typeface.caption
        timeLabel.textColor = ATTheme.Palette.inkFaint
        header.addSubview(timeLabel)

        marker.font = ATTheme.Typeface.sans(9.5, .semibold)
        marker.textColor = ATTheme.Palette.accent
        marker.text = "YOU"
        header.addSubview(marker)

        bodyLabel.font = ATTheme.Typeface.sans(14.5)
        bodyLabel.textColor = ATTheme.Palette.inkSoft
        bodyLabel.numberOfLines = 0
        contentView.addSubview(bodyLabel)

        let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        menuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: configuration), for: .normal)
        menuButton.tintColor = ATTheme.Palette.inkFaint
        menuButton.addTarget(self, action: #selector(handleMenu), for: .touchUpInside)
        contentView.addSubview(menuButton)

        header.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.trailing.lessThanOrEqualTo(menuButton.snp.leading).offset(-ATTheme.Space.xs)
        }

        avatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.xs)
            make.top.equalToSuperview()
        }

        marker.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(5)
            make.centerY.equalTo(nameLabel)
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.bottom.equalToSuperview()
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter + 30 + ATTheme.Space.xs)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.md)
        }

        menuButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter + 6)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.width.height.equalTo(28)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(comment: ATComment, author: ATUser?) {
        avatar.set(user: author)
        nameLabel.text = author?.displayName ?? "Removed account"
        timeLabel.text = ATTime.compact(comment.createdAt)
        bodyLabel.text = comment.body
        marker.isHidden = !comment.isMine
    }

    @objc private func handleMenu() { onMenu?(menuButton) }
    @objc private func handleAuthor() { onAuthor?() }
}

// MARK: - Composer

private final class ATCommentComposer: UIView {

    var onSend: ((String) -> Void)?

    private let field = UITextField()
    private let sendButton = UIButton(type: .system)

    var text: String { field.text ?? "" }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paperRaised
        layer.borderWidth = ATTheme.hairline
        layer.borderColor = ATTheme.Palette.rule.cgColor

        let topRule = ATRule()
        addSubview(topRule)

        field.placeholder = "Add a comment"
        field.font = ATTheme.Typeface.sans(15)
        field.textColor = ATTheme.Palette.ink
        field.tintColor = ATTheme.Palette.accent
        field.attributedPlaceholder = NSAttributedString(
            string: "Add a comment",
            attributes: [
                .font: ATTheme.Typeface.sans(15),
                .foregroundColor: ATTheme.Palette.inkFaint,
            ]
        )
        field.returnKeyType = .send
        field.delegate = self
        field.backgroundColor = ATTheme.Palette.paperDeep
        field.layer.cornerRadius = ATTheme.Radius.pill
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.rightViewMode = .always
        addSubview(field)

        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: configuration), for: .normal)
        sendButton.tintColor = ATTheme.Palette.ink
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        addSubview(sendButton)

        topRule.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        field.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.height.equalTo(38)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.sm)
        }

        sendButton.snp.makeConstraints { make in
            make.leading.equalTo(field.snp.trailing).offset(ATTheme.Space.xs)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
            make.centerY.equalTo(field)
            make.width.height.equalTo(36)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func clear() {
        field.text = nil
    }

    @objc private func handleSend() {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        onSend?(value)
    }
}

extension ATCommentComposer: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
