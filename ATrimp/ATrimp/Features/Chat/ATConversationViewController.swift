//
//  ATConversationViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATConversationViewController: ATViewController {

    private enum Row {
        case day(String)
        case message(ATMessage)
    }

    private let peer: ATUser
    private var conversation: ATConversation
    private var rows: [Row] = []

    private let table = UITableView(frame: .zero, style: .plain)
    private let composer = ATChatComposer()
    private let titleView = UIControl()
    private let titleAvatar = ATAvatarView(size: 30)
    private let titleName = UILabel()
    private let titleStatus = UILabel()

    init(peer: ATUser) {
        self.peer = peer
        self.conversation = ATStore.ensureConversation(withUser: peer.id)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        buildHeader()
        buildComposer()
        buildTable()
        reload()

        ATStore.markRead(conversationID: conversation.id)
    }

    // MARK: - Layout

    private func buildHeader() {
        let bar = installNavBar(title: nil)

        titleView.addTarget(self, action: #selector(handleOpenProfile), for: .touchUpInside)
        titleAvatar.set(user: peer)
        titleAvatar.isUserInteractionEnabled = false
        titleView.addSubview(titleAvatar)

        titleName.text = peer.displayName
        titleName.font = ATTheme.Typeface.subtitle
        titleName.textColor = ATTheme.Palette.ink
        titleName.isUserInteractionEnabled = false
        titleView.addSubview(titleName)

        titleStatus.text = peer.friendState == .friends ? "Connected" : peer.homeCity
        titleStatus.font = ATTheme.Typeface.sans(11)
        titleStatus.textColor = ATTheme.Palette.inkFaint
        titleStatus.isUserInteractionEnabled = false
        titleView.addSubview(titleStatus)

        titleAvatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        titleName.snp.makeConstraints { make in
            make.leading.equalTo(titleAvatar.snp.trailing).offset(ATTheme.Space.xs)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(1)
        }

        titleStatus.snp.makeConstraints { make in
            make.leading.equalTo(titleName)
            make.trailing.equalToSuperview()
            make.top.equalTo(titleName.snp.bottom).offset(1)
        }

        bar.addTrailing(view: titleView)
        bar.addTrailing(symbol: "video", action: #selector(handleVideoCall), target: self)
        bar.addTrailing(symbol: "ellipsis", action: #selector(handleMore), target: self)
    }

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        table.contentInsetAdjustmentBehavior = .never
        table.keyboardDismissMode = .interactive
        table.dataSource = self
        table.delegate = self
        table.register(ATMessageCell.self, forCellReuseIdentifier: ATMessageCell.reuseIdentifier)
        table.register(ATDayCell.self, forCellReuseIdentifier: ATDayCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(composer.snp.top)
        }
    }

    private func buildComposer() {
        composer.onSend = { [weak self] text in
            self?.send(text)
        }
        view.addSubview(composer)

        composer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
    }

    // MARK: - Data

    private func reload() {
        let messages = ATStore.messages(inConversation: conversation.id)

        var built: [Row] = []
        var lastDay: Date?

        for message in messages {
            if lastDay == nil || !ATTime.isSameDay(lastDay!, message.createdAt) {
                built.append(.day(ATTime.dayHeading(message.createdAt)))
                lastDay = message.createdAt
            }
            built.append(.message(message))
        }

        rows = built
        table.reloadData()
        scrollToBottom(animated: false)
    }

    private func scrollToBottom(animated: Bool) {
        guard !rows.isEmpty else { return }
        table.scrollToRow(
            at: IndexPath(row: rows.count - 1, section: 0),
            at: .bottom,
            animated: animated
        )
    }

    private func send(_ text: String) {
        guard let userID = ATSession.shared.userID else {
            requireSignIn(message: "Sign in to send messages.")
            return
        }

        ATStore.sendMessage(
            conversationID: conversation.id,
            senderID: userID,
            kind: .text,
            body: text
        )
        composer.clear()
        reload()
        scrollToBottom(animated: true)
    }

    // MARK: - Actions

    @objc private func handleOpenProfile() {
        push(ATUserProfileViewController(userID: peer.id))
    }

    @objc private func handleVideoCall() {
        let call = ATCallViewController(peer: peer)
        call.onFinished = { [weak self] _ in
            self?.recordCallOutcome()
        }
        call.modalPresentationStyle = .fullScreen
        present(call, animated: true)
    }

    private func recordCallOutcome() {
        guard let userID = ATSession.shared.userID else { return }
        ATStore.sendMessage(
            conversationID: conversation.id,
            senderID: userID,
            kind: .callLog,
            body: "Video call · Declined"
        )
        reload()
        scrollToBottom(animated: true)
    }

    @objc private func handleMore() {
        let report = ATReportViewController(target: .conversation(conversation)) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .dismissed:
                break
            case .removed:
                self.goBack()
            case .blocked:
                self.goBack()
            }
        }
        presentSheet(report, detents: [.medium(), .large()])
    }
}

// MARK: - Table

extension ATConversationViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .day(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: ATDayCell.reuseIdentifier, for: indexPath) as! ATDayCell
            cell.configure(title: title)
            return cell

        case .message(let message):
            let cell = tableView.dequeueReusableCell(withIdentifier: ATMessageCell.reuseIdentifier, for: indexPath) as! ATMessageCell
            cell.configure(message: message, peer: peer)
            return cell
        }
    }
}

extension ATConversationViewController: UITableViewDelegate {}

// MARK: - Cells

private final class ATDayCell: UITableViewCell {

    static let reuseIdentifier = "ATDayCell"

    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        label.font = ATTheme.Typeface.sans(11, .semibold)
        label.textColor = ATTheme.Palette.inkFaint
        label.textAlignment = .center
        contentView.addSubview(label)

        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(title: String) {
        label.text = title.uppercased()
    }
}

private final class ATMessageCell: UITableViewCell {

    static let reuseIdentifier = "ATMessageCell"

    private let bubble = UIView()
    private let bodyLabel = UILabel()
    private let mediaView = UIImageView()
    private let timeLabel = UILabel()

    private var bubbleLeading: Constraint?
    private var bubbleTrailing: Constraint?
    private var mediaConstraints: [Constraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        bubble.layer.cornerRadius = ATTheme.Radius.medium
        bubble.layer.cornerCurve = .continuous
        contentView.addSubview(bubble)

        bodyLabel.font = ATTheme.Typeface.sans(15)
        bodyLabel.numberOfLines = 0
        bubble.addSubview(bodyLabel)

        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = ATTheme.Radius.small
        mediaView.isHidden = true
        bubble.addSubview(mediaView)

        timeLabel.font = ATTheme.Typeface.sans(10.5)
        timeLabel.textColor = ATTheme.Palette.inkFaint
        contentView.addSubview(timeLabel)

        bubble.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.76)
            bubbleLeading = make.leading.equalToSuperview().offset(ATTheme.Space.gutter).constraint
            bubbleTrailing = make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter).constraint
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-10)
        }

        mediaView.snp.makeConstraints { make in
            mediaConstraints = [
                make.top.equalToSuperview().offset(6).constraint,
                make.leading.equalToSuperview().offset(6).constraint,
                make.trailing.equalToSuperview().offset(-6).constraint,
                make.bottom.equalToSuperview().offset(-6).constraint,
                make.width.equalTo(180).constraint,
                make.height.equalTo(180).constraint,
            ]
        }
        mediaConstraints.forEach { $0.deactivate() }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(bubble.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(message: ATMessage, peer: ATUser) {
        let isMine = message.senderID == ATSession.shared.userID

        bubbleLeading?.isActive = !isMine
        bubbleTrailing?.isActive = isMine

        timeLabel.text = ATTime.clock(message.createdAt)
        timeLabel.snp.remakeConstraints { make in
            make.top.equalTo(bubble.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
            if isMine {
                make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            } else {
                make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            }
        }

        bubble.layer.borderWidth = 0
        bubble.layer.borderColor = nil
        bodyLabel.textAlignment = .natural
        bodyLabel.text = nil

        let showsPhoto = message.kind == .image
        if showsPhoto {
            mediaConstraints.forEach { $0.activate() }
        } else {
            mediaConstraints.forEach { $0.deactivate() }
        }
        mediaView.isHidden = !showsPhoto
        bodyLabel.isHidden = showsPhoto

        switch message.kind {
        case .callLog:
            configureCallLog(message)
        case .image:
            mediaView.image = ATArt.photo(
                seed: message.body,
                size: CGSize(width: 180, height: 180),
                symbol: "photo"
            )
            bubble.backgroundColor = ATTheme.Palette.paperDeep

        case .gift:
            bodyLabel.text = message.body
            bodyLabel.font = ATTheme.Typeface.sans(14, .semibold)
            bodyLabel.textColor = ATTheme.Palette.paper
            bubble.backgroundColor = ATTheme.Palette.mist

        case .text:
            bodyLabel.font = ATTheme.Typeface.sans(15)
            bodyLabel.text = message.body
            bodyLabel.textColor = isMine ? ATTheme.Palette.paper : ATTheme.Palette.ink
            bubble.backgroundColor = isMine ? ATTheme.Palette.ink : ATTheme.Palette.paperRaised
            bubble.layer.borderWidth = isMine ? 0 : ATTheme.hairline
            bubble.layer.borderColor = isMine ? nil : ATTheme.Palette.rule.cgColor
        }
    }

    private func configureCallLog(_ message: ATMessage) {
        bodyLabel.text = message.body
        bodyLabel.font = ATTheme.Typeface.sans(12)
        bodyLabel.textColor = ATTheme.Palette.inkSoft
        bodyLabel.textAlignment = .center
        bubble.backgroundColor = ATTheme.Palette.paperDeep
        timeLabel.text = nil
    }
}

// MARK: - Composer

private final class ATChatComposer: UIView {

    var onSend: ((String) -> Void)?

    private let field = UITextField()
    private let sendButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paperRaised

        let topRule = ATRule()
        addSubview(topRule)

        field.placeholder = "Message"
        field.font = ATTheme.Typeface.sans(15)
        field.textColor = ATTheme.Palette.ink
        field.tintColor = ATTheme.Palette.accent
        field.attributedPlaceholder = NSAttributedString(
            string: "Message",
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
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.sm)
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
        let value = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        onSend?(value)
    }
}

extension ATChatComposer: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
