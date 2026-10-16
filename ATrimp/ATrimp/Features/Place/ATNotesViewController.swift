//
//  ATNotesViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATNotesViewController: ATViewController {

    private struct Group {
        let placeKey: String
        let placeName: String
        let country: String
        var notes: [ATNote]
    }

    private let focusing: ATPlace?

    private let table = UITableView(frame: .zero, style: .plain)
    private let emptyView = ATEmptyView(
        title: "Nothing kept yet",
        message: "Open a trip and press \"Keep a note\" — what you would do differently next time lands here, filed under the place."
    )

    private var groups: [Group] = []
    private var didScrollToFocus = false
    private weak var bell: UIButton?
    private let summary = ATNotesSummaryView()

    init(focusing place: ATPlace? = nil) {
        self.focusing = place
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: "Your notes")
        bell = bar.addTrailing(symbol: "bell", action: #selector(toggleReminders), target: self)
        refreshBell()

        buildTable()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bottom = view.safeAreaInsets.bottom + ATTheme.Space.sm
        if abs(table.contentInset.bottom - bottom) > 0.5 {
            table.contentInset.bottom = bottom
            table.verticalScrollIndicatorInsets.bottom = bottom
        }

        guard !didScrollToFocus, let focusing,
              let section = groups.firstIndex(where: { $0.placeKey == focusing.key }),
              table.numberOfSections > section
        else { return }
        didScrollToFocus = true
        table.scrollToRow(
            at: IndexPath(row: 0, section: section),
            at: .top,
            animated: false
        )
    }

    // MARK: - Layout

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 90
        table.contentInsetAdjustmentBehavior = .never
        table.dataSource = self
        table.delegate = self
        table.register(ATNoteCell.self, forCellReuseIdentifier: ATNoteCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        summary.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 96)
        table.tableHeaderView = summary

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom).offset(90)
            make.leading.trailing.equalToSuperview()
        }
        emptyView.isHidden = true
    }

    // MARK: - Data

    private func reload() {
        var order: [String] = []
        var buckets: [String: Group] = [:]

        for note in ATStore.notes() {
            if buckets[note.placeKey] == nil {
                order.append(note.placeKey)
                buckets[note.placeKey] = Group(
                    placeKey: note.placeKey,
                    placeName: note.placeName,
                    country: note.country,
                    notes: []
                )
            }
            buckets[note.placeKey]?.notes.append(note)
        }

        groups = order.compactMap { buckets[$0] }

        let all = groups.flatMap(\.notes)
        summary.configure(
            kept: all.count,
            done: all.filter(\.isResolved).count,
            places: groups.count
        )

        table.tableHeaderView = all.isEmpty ? nil : summary

        table.reloadData()
        emptyView.isHidden = !groups.isEmpty
    }

    @objc private func toggleReminders() {
        if ATNotifications.isEnabled {
            ATNotifications.disable()
            refreshBell()
            showToast("Reminders off.")
            return
        }

        ATNotifications.enable { [weak self] granted in
            self?.refreshBell()
            self?.showToast(granted
                ? "On. You will hear when somewhere you noted gets a new filing."
                : "Notifications are switched off for ATrimp in Settings.")
        }
    }

    private func refreshBell() {
        let on = ATNotifications.isEnabled
        bell?.setImage(
            UIImage(
                systemName: on ? "bell.fill" : "bell",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            ),
            for: .normal
        )
        bell?.tintColor = on ? ATTheme.Palette.accent : ATTheme.Palette.ink
        bell?.accessibilityLabel = on ? "Turn reminders off" : "Turn reminders on"
    }

    private func toggle(_ note: ATNote) {
        ATStore.setNoteResolved(!note.isResolved, id: note.id)
        reload()
    }

    private func remove(_ note: ATNote) {
        ATStore.deleteNote(id: note.id)
        reload()
    }
}

// MARK: - Table

extension ATNotesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { groups.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[section].notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ATNoteCell.reuseIdentifier,
            for: indexPath
        ) as! ATNoteCell
        let note = groups[indexPath.section].notes[indexPath.row]
        cell.configure(with: note)
        cell.onToggle = { [weak self] in self?.toggle(note) }
        return cell
    }
}

extension ATNotesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = groups[section]

        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paper

        let name = UILabel()
        name.text = group.placeName
        name.font = ATTheme.Typeface.subtitle
        name.textColor = ATTheme.Palette.ink
        container.addSubview(name)

        let where_ = UILabel()
        where_.text = group.country
        where_.font = ATTheme.Typeface.caption
        where_.textColor = ATTheme.Palette.inkFaint
        container.addSubview(where_)

        let tally = UILabel()
        tally.text = "\(group.notes.count)"
        tally.font = ATTheme.Typeface.mono(13, .semibold)
        tally.textColor = ATTheme.Palette.inkFaint
        container.addSubview(tally)

        let rule = ATRule()
        container.addSubview(rule)

        name.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.lg)
        }

        where_.snp.makeConstraints { make in
            make.leading.equalTo(name.snp.trailing).offset(ATTheme.Space.xs)
            make.lastBaseline.equalTo(name)
        }

        tally.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.lastBaseline.equalTo(name)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let note = groups[indexPath.section].notes[indexPath.row]
        let drop = UIContextualAction(style: .destructive, title: "Drop") { [weak self] _, _, completion in
            self?.remove(note)
            completion(true)
        }
        drop.backgroundColor = ATTheme.Palette.danger
        return UISwipeActionsConfiguration(actions: [drop])
    }
}

// MARK: - Note row

private final class ATNoteCell: UITableViewCell {

    static let reuseIdentifier = "ATNoteCell"

    var onToggle: (() -> Void)?

    private let tick = UIControl()
    private let tickMark = UIImageView()
    private let bodyLabel = UILabel()
    private let metaLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        tick.layer.borderWidth = 1
        tick.layer.borderColor = ATTheme.Palette.inkSoft.cgColor
        tick.layer.cornerRadius = 11
        tick.addTarget(self, action: #selector(handleToggle), for: .touchUpInside)
        contentView.addSubview(tick)

        let configuration = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        tickMark.image = UIImage(systemName: "checkmark", withConfiguration: configuration)
        tickMark.tintColor = ATTheme.Palette.paper
        tickMark.contentMode = .center
        tick.addSubview(tickMark)

        bodyLabel.font = ATTheme.Typeface.sans(15.5)
        bodyLabel.textColor = ATTheme.Palette.ink
        bodyLabel.numberOfLines = 0
        contentView.addSubview(bodyLabel)

        metaLabel.font = ATTheme.Typeface.caption
        metaLabel.textColor = ATTheme.Palette.inkFaint
        metaLabel.numberOfLines = 1
        contentView.addSubview(metaLabel)

        tick.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(2)
            make.width.height.equalTo(22)
        }

        tickMark.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(tick.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalToSuperview()
        }

        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(bodyLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.gutter)
            make.top.equalTo(bodyLabel.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.md)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with note: ATNote) {
        let done = note.isResolved

        bodyLabel.attributedText = NSAttributedString(
            string: note.body,
            attributes: [
                .font: ATTheme.Typeface.sans(15.5),
                .foregroundColor: done ? ATTheme.Palette.inkFaint : ATTheme.Palette.ink,
                .strikethroughStyle: done ? NSUnderlineStyle.single.rawValue : 0,
                .strikethroughColor: ATTheme.Palette.inkFaint,
            ]
        )

        metaLabel.text = [
            note.sourcePostID == nil ? "Written by you" : "From a filing",
            done ? "Done" : ATTime.compact(note.createdAt),
        ].joined(separator: " · ")

        tick.backgroundColor = done ? ATTheme.Palette.mist : .clear
        tick.layer.borderColor = (done ? ATTheme.Palette.mist : ATTheme.Palette.inkSoft).cgColor
        tickMark.alpha = done ? 1 : 0
    }

    @objc private func handleToggle() { onToggle?() }
}

// MARK: - Summary

private final class ATNotesSummaryView: UIView {

    private let keptLabel = UILabel()
    private let doneLabel = UILabel()
    private let track = UIView()
    private let fill = UIView()
    private let caption = UILabel()
    private let rule = ATRule()

    private var fillWidth: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ATTheme.Palette.paper

        keptLabel.font = ATTheme.Typeface.mono(17, .semibold)
        keptLabel.textColor = ATTheme.Palette.ink
        addSubview(keptLabel)

        doneLabel.font = ATTheme.Typeface.mono(17, .semibold)
        doneLabel.textColor = ATTheme.Palette.mist
        doneLabel.textAlignment = .right
        addSubview(doneLabel)

        track.backgroundColor = ATTheme.Palette.paperDeep
        track.layer.cornerRadius = 3
        track.layer.cornerCurve = .continuous
        track.clipsToBounds = true
        addSubview(track)

        fill.backgroundColor = ATTheme.Palette.mist
        track.addSubview(fill)

        caption.font = ATTheme.Typeface.caption
        caption.textColor = ATTheme.Palette.inkFaint
        caption.numberOfLines = 0
        addSubview(caption)

        addSubview(rule)

        keptLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.leading.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        doneLabel.snp.makeConstraints { make in
            make.centerY.equalTo(keptLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.leading.greaterThanOrEqualTo(keptLabel.snp.trailing).offset(ATTheme.Space.sm)
        }

        track.snp.makeConstraints { make in
            make.top.equalTo(keptLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.height.equalTo(6)
        }

        fill.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            fillWidth = make.width.equalTo(0).constraint
        }

        caption.snp.makeConstraints { make in
            make.top.equalTo(track.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(caption.snp.bottom).offset(ATTheme.Space.sm)
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

    func configure(kept: Int, done: Int, places: Int) {
        keptLabel.text = "\(kept) kept across \(places) \(places == 1 ? "place" : "places")"
        keptLabel.font = ATTheme.Typeface.sans(14, .semibold)
        doneLabel.text = done == 0 ? "none done yet" : "\(done) done"
        doneLabel.font = ATTheme.Typeface.sans(14, .semibold)

        let ratio = kept > 0 ? CGFloat(done) / CGFloat(kept) : 0
        fillWidth?.update(offset: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.fillWidth?.update(offset: self.track.bounds.width * ratio)
            UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() }
        }

        switch (kept, done) {
        case (0, _):
            caption.text = "Nothing kept yet."
        case (_, 0):
            caption.text = "None of these has been done yet. Tick one off when you get back."
        case let (total, finished) where total == finished:
            caption.text = "Every one of them done. That is the whole idea."
        default:
            caption.text = "The rest are still waiting on a trip."
        }

        setNeedsLayout()
    }
}
