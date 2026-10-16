//
//  ATPeopleListViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATPeopleListViewController: ATViewController {

    enum Source {
        case following
        case followers
        case friends
    }

    private let source: Source
    private let table = UITableView(frame: .zero, style: .plain)
    private var people: [ATUser] = []
    private lazy var emptyView = ATEmptyView(title: emptyTitle, message: emptyMessage)

    private var emptyTitle: String {
        switch source {
        case .following: return "Not following anyone yet"
        case .followers: return "No followers yet"
        case .friends: return "No connections yet"
        }
    }

    private var emptyMessage: String {
        switch source {
        case .following: return "Follow someone from a post and they will appear here."
        case .followers: return "When someone follows you they will be listed here."
        case .friends: return "Connections come from requests you accept in Conversations."
        }
    }

    init(source: Source, title: String) {
        self.source = source
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
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 76
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATPersonCell.self, forCellReuseIdentifier: ATPersonCell.reuseIdentifier)
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

        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        switch source {
        case .following: people = ATStore.following()
        case .followers: people = ATStore.followers()
        case .friends: people = ATStore.friends()
        }
        table.reloadData()
        emptyView.isHidden = !people.isEmpty
    }

    private func action(for person: ATUser) -> (title: String, filled: Bool)? {
        switch source {
        case .following:
            return ("Following", false)
        case .followers, .friends:
            return ATStore.isFollowing(person.id) ? ("Following", false) : ("Follow", true)
        }
    }

    private func handleAction(for person: ATUser) {
        ATStore.setFollowing(!ATStore.isFollowing(person.id), userID: person.id)
        reload()
    }
}

extension ATPeopleListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        people.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ATPersonCell.reuseIdentifier, for: indexPath) as! ATPersonCell
        let person = people[indexPath.row]
        cell.configure(person: person, action: action(for: person))
        cell.onAction = { [weak self] in self?.handleAction(for: person) }
        return cell
    }
}

extension ATPeopleListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        push(ATUserProfileViewController(userID: people[indexPath.row].id))
    }
}

// MARK: - Cell

final class ATPersonCell: UITableViewCell {

    static let reuseIdentifier = "ATPersonCell"

    var onAction: (() -> Void)?

    private let avatar = ATAvatarView(size: 44)
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let actionButton = ATPillButton(title: "Follow")
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

        detailLabel.font = ATTheme.Typeface.caption
        detailLabel.textColor = ATTheme.Palette.inkFaint
        detailLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(detailLabel)

        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        contentView.addSubview(actionButton)

        contentView.addSubview(rule)

        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(ATTheme.Space.sm)
            make.top.equalTo(avatar.snp.top).offset(2)
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-ATTheme.Space.sm)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-ATTheme.Space.sm)
        }

        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.centerY.equalTo(avatar)
        }

        rule.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.sm)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(person: ATUser, action: (title: String, filled: Bool)?) {
        avatar.set(user: person)
        nameLabel.text = person.displayName
        detailLabel.text = [person.homeCity, person.bio]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")

        if let action {
            actionButton.isHidden = false
            actionButton.apply(title: action.title, filled: action.filled, tint: ATTheme.Palette.ink)
        } else {
            actionButton.isHidden = true
        }
    }

    @objc private func handleAction() {
        onAction?()
    }
}
