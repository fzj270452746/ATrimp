//
//  ATChatListViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATChatListViewController: ATViewController {

    private let table = UITableView(frame: .zero, style: .plain)
    private let signedOutView = UIView()
    private let signedOutPrompt = ATEmptyView(
        title: "Your conversations live here",
        message: "Sign in to pick up where you left off. Messages are only exchanged between people who have added one another.",
        actionTitle: "Sign in"
    )

    private var conversations: [ATConversation] = []
    private var peers: [String: ATUser] = [:]
    private var lastMessages: [String: ATMessage] = [:]
    private var suggestions: [ATUser] = []

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

        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Layout

    private func buildHeader() {
        let masthead = UILabel()
        masthead.text = "Conversations"
        masthead.font = ATTheme.Typeface.serif(34, .semibold)
        masthead.textColor = ATTheme.Palette.ink
        view.addSubview(masthead)

        let rule = ATRule(color: ATTheme.Palette.accent)
        view.addSubview(rule)

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

        divider.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.equalToSuperview()
        }

        headerDivider = divider
    }

    private var headerDivider: UIView?

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 84
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATConversationCell.self, forCellReuseIdentifier: ATConversationCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(headerDivider!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func buildSignedOutView() {
        view.addSubview(signedOutView)
        signedOutView.snp.makeConstraints { make in
            make.top.equalTo(headerDivider!.snp.bottom).offset(80)
            make.leading.trailing.equalToSuperview()
        }

        signedOutPrompt.onAction = { [weak self] in
            guard let self else { return }
            self.present(ATLoginViewController(), animated: true)
        }
        signedOutView.addSubview(signedOutPrompt)
        signedOutPrompt.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Data

    @objc private func sessionChanged() {
        reload()
    }

    private func reload() {
        let isSignedIn = ATSession.shared.isSignedIn

        signedOutView.isHidden = isSignedIn
        table.isHidden = !isSignedIn

        guard isSignedIn else {
            conversations = []
            table.reloadData()
            return
        }

        conversations = ATStore.conversations()
        peers = ATStore.users(ids: conversations.map(\.peerUserID))
        suggestions = ATStore.suggestedPeople(limit: 12)

        var messages: [String: ATMessage] = [:]
        for conversation in conversations {
            messages[conversation.id] = ATStore.lastMessage(inConversation: conversation.id)
        }
        lastMessages = messages

        table.reloadData()
    }

    private func open(_ conversation: ATConversation) {
        guard let peer = peers[conversation.peerUserID] else { return }

        guard peer.friendState == .friends else {
            showToast("You can only message people you are connected with.")
            return
        }

        ATStore.markRead(conversationID: conversation.id)
        push(ATConversationViewController(peer: peer))
    }

    private func handleSuggestion(_ user: ATUser) {
        switch user.friendState {
        case .friends:
            push(ATConversationViewController(peer: user))

        case .incoming:
            ATStore.setFriendState(.friends, userID: user.id)
            ATStore.setFollowing(true, userID: user.id)
            showToast("You are now connected with \(user.displayName).")
            reload()

        case .none:
            ATStore.setFriendState(.requested, userID: user.id)
            showToast("Request sent to \(user.displayName).")
            reload()

        case .requested:
            showToast("Your request to \(user.displayName) is still waiting.")
        }
    }
}

// MARK: - Table

extension ATChatListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? (suggestions.isEmpty ? 0 : 1) : conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "ATSuggestionsCell"
            ) as? ATSuggestionsCell ?? ATSuggestionsCell(style: .default, reuseIdentifier: "ATSuggestionsCell")
            cell.configure(with: suggestions)
            cell.onTapPerson = { [weak self] user in self?.handleSuggestion(user) }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ATConversationCell.reuseIdentifier, for: indexPath) as! ATConversationCell
        let conversation = conversations[indexPath.row]
        cell.configure(
            conversation: conversation,
            peer: peers[conversation.peerUserID],
            lastMessage: lastMessages[conversation.id]
        )
        return cell
    }
}

extension ATChatListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        open(conversations[indexPath.row])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !(section == 0 && suggestions.isEmpty) else { return nil }

        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paper

        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(
            section == 0 ? "People on your routes" : "Messages"
        )
        container.addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && suggestions.isEmpty { return 0 }
        return 36
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 1, conversations.isEmpty else { return nil }

        let label = UILabel()
        label.text = "No messages yet. Add someone from the row above to start one."
        label.font = ATTheme.Typeface.body
        label.textColor = ATTheme.Palette.inkFaint
        label.numberOfLines = 0

        let container = UIView()
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.lg)
            make.bottom.equalToSuperview()
        }
        return container
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == 1 && conversations.isEmpty ? UITableView.automaticDimension : 0
    }
}

// MARK: - Cells

private final class ATConversationCell: UITableViewCell {

    static let reuseIdentifier = "ATConversationCell"

    private let avatar = ATAvatarView(size: 50)
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()
    private let badge = UILabel()
    private let rule = ATRule()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        contentView.addSubview(avatar)

        nameLabel.font = ATTheme.Typeface.bodyStrong
        nameLabel.textColor = ATTheme.Palette.ink
        contentView.addSubview(nameLabel)

        previewLabel.font = ATTheme.Typeface.caption
        previewLabel.textColor = ATTheme.Palette.inkSoft
        previewLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(previewLabel)

        timeLabel.font = ATTheme.Typeface.caption
        timeLabel.textColor = ATTheme.Palette.inkFaint
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)

        badge.font = ATTheme.Typeface.sans(10.5, .semibold)
        badge.textColor = ATTheme.Palette.paper
        badge.backgroundColor = ATTheme.Palette.accent
        badge.textAlignment = .center
        badge.layer.cornerRadius = 9
        badge.clipsToBounds = true
        contentView.addSubview(badge)

        contentView.addSubview(rule)

        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.sm)
            make.top.equalTo(avatar.snp.top).offset(2)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-ATTheme.Space.xs)
        }

        previewLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
        }

        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(nameLabel)
            make.width.greaterThanOrEqualTo(40)
        }

        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(previewLabel)
            make.width.height.equalTo(18)
        }

        rule.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.md)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(conversation: ATConversation, peer: ATUser?, lastMessage: ATMessage?) {
        avatar.set(user: peer)
        nameLabel.text = peer?.displayName ?? "Removed account"
        timeLabel.text = ATTime.compact(conversation.lastMessageAt)

        if let lastMessage {
            let prefix = lastMessage.kind == .text ? "" : "\(lastMessage.kind == .callLog ? "Call" : "Media") · "
            previewLabel.text = prefix + lastMessage.body
        } else {
            previewLabel.text = "No messages yet"
        }

        badge.isHidden = conversation.unreadCount == 0
        badge.text = "\(conversation.unreadCount)"
    }
}

private final class ATSuggestionsCell: UITableViewCell {

    var onTapPerson: ((ATUser) -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var people: [ATUser] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: ATTheme.Space.gutter, bottom: 0, right: ATTheme.Space.gutter)
        contentView.addSubview(scrollView)

        stack.axis = .horizontal
        stack.spacing = ATTheme.Space.sm
        scrollView.addSubview(stack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(140)
        }

        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with people: [ATUser]) {
        self.people = people
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for person in people.prefix(12) {
            stack.addArrangedSubview(makeCard(person))
        }
    }

    private func makeCard(_ person: ATUser) -> UIControl {
        let card = UIControl()
        card.backgroundColor = ATTheme.Palette.paperRaised
        card.layer.cornerRadius = ATTheme.Radius.small
        card.layer.borderWidth = ATTheme.hairline
        card.layer.borderColor = ATTheme.Palette.rule.cgColor

        let avatar = ATAvatarView(size: 52)
        avatar.set(user: person)
        avatar.isUserInteractionEnabled = false
        card.addSubview(avatar)

        let name = UILabel()
        name.text = person.displayName
        name.font = ATTheme.Typeface.sans(12, .semibold)
        name.textColor = ATTheme.Palette.ink
        name.textAlignment = .center
        name.numberOfLines = 1
        name.lineBreakMode = .byTruncatingTail
        name.isUserInteractionEnabled = false
        card.addSubview(name)

        let city = UILabel()
        city.text = person.homeCity
        city.font = ATTheme.Typeface.sans(10.5)
        city.textColor = ATTheme.Palette.inkFaint
        city.textAlignment = .center
        city.isUserInteractionEnabled = false
        card.addSubview(city)

        let action = UILabel()
        action.text = actionTitle(for: person)
        action.font = ATTheme.Typeface.sans(10.5, .semibold)
        action.textColor = actionColor(for: person)
        action.textAlignment = .center
        action.isUserInteractionEnabled = false
        card.addSubview(action)

        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.centerX.equalToSuperview()
        }

        name.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(6)
        }

        city.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(1)
            make.leading.trailing.equalToSuperview().inset(6)
        }

        action.snp.makeConstraints { make in
            make.top.equalTo(city.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(6)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        card.snp.makeConstraints { make in
            make.width.equalTo(104)
        }

        card.addAction(UIAction { [weak self] _ in
            self?.onTapPerson?(person)
        }, for: .touchUpInside)

        return card
    }

    private func actionTitle(for person: ATUser) -> String {
        switch person.friendState {
        case .friends: return "Message"
        case .requested: return "Requested"
        case .incoming: return "Accept"
        case .none: return "Add friend"
        }
    }

    private func actionColor(for person: ATUser) -> UIColor {
        switch person.friendState {
        case .friends: return ATTheme.Palette.mist
        case .incoming: return ATTheme.Palette.accent
        case .requested: return ATTheme.Palette.inkFaint
        case .none: return ATTheme.Palette.ink
        }
    }
}
