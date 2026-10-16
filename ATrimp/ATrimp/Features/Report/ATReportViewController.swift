//
//  ATReportViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

enum ATReportTarget {
    case post(ATPost)
    case comment(ATComment)
    case user(ATUser)
    case conversation(ATConversation)

    var subject: String {
        switch self {
        case .post: return "post"
        case .comment: return "comment"
        case .user: return "profile"
        case .conversation: return "conversation"
        }
    }

    var accountID: String? {
        switch self {
        case .post(let post): return post.authorID
        case .comment(let comment): return comment.authorID
        case .user(let user): return user.id
        case .conversation: return nil
        }
    }

    var accountName: String? {
        switch self {
        case .post(let post): return ATStore.user(id: post.authorID)?.displayName
        case .comment(let comment): return ATStore.user(id: comment.authorID)?.displayName
        case .user(let user): return user.displayName
        case .conversation(let conversation): return ATStore.user(id: conversation.peerUserID)?.displayName
        }
    }
}

enum ATReportOutcome {
    case dismissed
    case removed
    case blocked(String)

    var didRemoveContent: Bool {
        switch self {
        case .dismissed: return false
        case .removed, .blocked: return true
        }
    }
}

final class ATReportViewController: UIViewController {

    private struct Option {
        let title: String
        let detail: String
        let blocksAccount: Bool
    }

    private let target: ATReportTarget
    private let onFinished: ((ATReportOutcome) -> Void)?
    private var hasFinished = false

    private let options: [Option] = [
        Option(title: "Illegal content", detail: "Something unlawful, or promoting something unlawful.", blocksAccount: false),
        Option(title: "Inappropriate content", detail: "Harassment, hate, or explicit material.", blocksAccount: false),
        Option(title: "Block user", detail: "Remove the account and everything it has posted.", blocksAccount: true),
        Option(title: "Other", detail: "Something else that should not be here.", blocksAccount: false),
    ]

    init(target: ATReportTarget, onFinished: ((ATReportOutcome) -> Void)? = nil) {
        self.target = target
        self.onFinished = onFinished
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        let heading = UILabel()
        heading.text = "Report this \(target.subject)"
        heading.font = ATTheme.Typeface.serif(24, .semibold)
        heading.textColor = ATTheme.Palette.ink
        heading.numberOfLines = 0

        let rule = ATRule(color: ATTheme.Palette.accent)
        rule.snp.makeConstraints { make in
            make.width.equalTo(36)
            make.height.equalTo(3)
        }

        let note = UILabel()
        note.text = "Choose the closest match. The \(target.subject) is removed straight away, and nothing is sent to the person who wrote it."
        note.font = ATTheme.Typeface.caption
        note.textColor = ATTheme.Palette.inkSoft
        note.numberOfLines = 0

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ATTheme.Space.xs

        for option in options {
            stack.addArrangedSubview(makeRow(option))
        }

        let cancel = ATGhostButton(title: "Cancel")
        cancel.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)

        for subview in [heading, rule, note, stack, cancel] as [UIView] {
            view.addSubview(subview)
        }

        heading.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.xl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(heading.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
        }

        note.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        stack.snp.makeConstraints { make in
            make.top.equalTo(note.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        cancel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(stack.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.md)
        }
    }

    private func makeRow(_ option: Option) -> UIControl {
        let container = UIControl()
        container.backgroundColor = ATTheme.Palette.paperRaised
        container.layer.cornerRadius = ATTheme.Radius.small
        container.layer.borderWidth = ATTheme.hairline
        container.layer.borderColor = ATTheme.Palette.rule.cgColor

        let title = UILabel()
        title.text = option.title
        title.font = ATTheme.Typeface.sans(15, .semibold)
        title.textColor = ATTheme.Palette.ink
        title.isUserInteractionEnabled = false

        let detail = UILabel()
        detail.text = option.detail
        detail.font = ATTheme.Typeface.sans(12.5)
        detail.textColor = ATTheme.Palette.inkSoft
        detail.numberOfLines = 0
        detail.isUserInteractionEnabled = false

        let chevron = UIImageView()
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: configuration)
        chevron.tintColor = ATTheme.Palette.inkFaint
        chevron.isUserInteractionEnabled = false

        container.addSubview(title)
        container.addSubview(detail)
        container.addSubview(chevron)

        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-ATTheme.Space.sm)
        }

        detail.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(2)
            make.leading.equalTo(title)
            make.trailing.equalTo(chevron.snp.leading).offset(-ATTheme.Space.sm)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
            make.centerY.equalToSuperview()
        }

        container.addAction(UIAction { [weak self] _ in
            self?.apply(option)
        }, for: .touchUpInside)

        return container
    }

    // MARK: - Acting

    private func apply(_ option: Option) {
        guard !hasFinished else { return }
        hasFinished = true

        var outcome: ATReportOutcome = .removed

        switch target {
        case .post(let post):
            ATStore.deletePost(id: post.id)
            if option.blocksAccount { blockAccount(post.authorID); outcome = .blocked(post.authorID) }

        case .comment(let comment):
            ATStore.deleteComment(id: comment.id)
            if option.blocksAccount { blockAccount(comment.authorID); outcome = .blocked(comment.authorID) }

        case .user(let user):
            blockAccount(user.id)
            outcome = .blocked(user.id)

        case .conversation(let conversation):
            ATStore.deleteConversation(id: conversation.id)
            if option.blocksAccount {
                blockAccount(conversation.peerUserID)
                outcome = .blocked(conversation.peerUserID)
            }
        }

        let finalOutcome = outcome
        dismiss(animated: true) { [weak self] in
            self?.onFinished?(finalOutcome)
        }
    }

    private func blockAccount(_ userID: String) {
        guard !userID.isEmpty else { return }
        ATStore.deleteUser(id: userID)
    }

    @objc private func handleCancel() {
        guard !hasFinished else { return }
        hasFinished = true
        dismiss(animated: true) { [weak self] in
            self?.onFinished?(.dismissed)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !hasFinished {
            hasFinished = true
            onFinished?(.dismissed)
        }
    }
}
