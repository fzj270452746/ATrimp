//
//  ATPlacePickerViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATPlacePickerViewController: ATViewController {

    private enum Row {
        case typed(ATPlace)
        case entry(ATPlacePickerEntry)
    }

    private let screenTitle: String
    private let standfirst: String
    private let all: [ATPlacePickerEntry]
    private let allowsTypedPlace: Bool
    private let presentedModally: Bool
    private let onPick: (ATPlace) -> Void

    private let field = UITextField()
    private let standfirstLabel = UILabel()
    private let table = UITableView(frame: .zero, style: .plain)
    private let emptyView = ATEmptyView(
        title: "Nothing matches that",
        message: "Try a shorter search — or clear the box to see every place the library knows."
    )

    private var rows: [Row] = []

    init(
        title: String,
        standfirst: String,
        entries: [ATPlacePickerEntry],
        excluding: Set<String> = [],
        allowsTypedPlace: Bool = false,
        presentedModally: Bool = false,
        onPick: @escaping (ATPlace) -> Void
    ) {
        self.screenTitle = title
        self.standfirst = standfirst
        self.all = entries.filter { !excluding.contains($0.place.key) }
        self.allowsTypedPlace = allowsTypedPlace
        self.presentedModally = presentedModally
        self.onPick = onPick
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: screenTitle)
        if presentedModally {
            bar.onBack = { [weak self] in self?.dismiss(animated: true) }
        }
        bar.addTrailing(view: field)
        field.snp.makeConstraints { make in
            make.width.equalTo(186)
            make.height.equalTo(32)
        }

        buildField()
        buildStandfirst()
        buildTable()
        refresh()
    }

    // MARK: - Layout

    private func buildField() {
        field.font = ATTheme.Typeface.sans(15)
        field.textColor = ATTheme.Palette.ink
        field.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [
                .font: ATTheme.Typeface.sans(15),
                .foregroundColor: ATTheme.Palette.inkFaint,
            ]
        )
        field.tintColor = ATTheme.Palette.accent
        field.returnKeyType = .done
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        field.textAlignment = .right
        field.addTarget(self, action: #selector(refresh), for: .editingChanged)
        field.addTarget(self, action: #selector(refresh), for: .editingDidEndOnExit)
    }

    private func buildStandfirst() {
        standfirstLabel.text = standfirst
        standfirstLabel.font = ATTheme.Typeface.caption
        standfirstLabel.textColor = ATTheme.Palette.inkFaint
        standfirstLabel.numberOfLines = 0
        view.addSubview(standfirstLabel)

        standfirstLabel.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }
    }

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 64
        table.contentInsetAdjustmentBehavior = .never
        table.keyboardDismissMode = .onDrag
        table.dataSource = self
        table.delegate = self
        table.register(ATPlacePickerCell.self, forCellReuseIdentifier: ATPlacePickerCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(standfirstLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(table.snp.top).offset(50)
            make.leading.trailing.equalToSuperview()
        }
        emptyView.isHidden = true
    }

    // MARK: - Data

    @objc private func refresh() {
        let text = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        var entries = all
        if !text.isEmpty {
            let needle = ATPlace.normalize(text)
            entries = all.filter {
                ATPlace.normalize($0.place.name).contains(needle)
                    || ATPlace.normalize($0.place.country).contains(needle)
            }
        }

        var built: [Row] = []
        if allowsTypedPlace, !text.isEmpty {
            let typed = ATPlace.resolve(locationName: text)
            if !entries.contains(where: { $0.place.key == typed.key }) {
                built.append(.typed(typed))
            }
        }
        built.append(contentsOf: entries.map { Row.entry($0) })

        rows = built
        table.reloadData()
        emptyView.isHidden = !rows.isEmpty
    }

    private func pick(_ place: ATPlace) {
        onPick(place)
    }
}

// MARK: - Table

extension ATPlacePickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ATPlacePickerCell.reuseIdentifier,
            for: indexPath
        ) as! ATPlacePickerCell

        switch rows[indexPath.row] {
        case let .entry(entry):
            cell.configure(with: entry)
        case let .typed(place):
            cell.configureTyped(place.name)
        }
        return cell
    }
}

extension ATPlacePickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case let .entry(entry): pick(entry.place)
        case let .typed(place): pick(place)
        }
    }
}

// MARK: - Row

private final class ATPlacePickerCell: UITableViewCell {

    static let reuseIdentifier = "ATPlacePickerCell"

    private let mark = UIView()
    private let icon = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let badge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        mark.layer.cornerRadius = 3
        mark.layer.cornerCurve = .continuous
        contentView.addSubview(mark)

        icon.contentMode = .center
        icon.tintColor = ATTheme.Palette.accent
        contentView.addSubview(icon)

        nameLabel.font = ATTheme.Typeface.sans(16, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)

        detailLabel.font = ATTheme.Typeface.caption
        detailLabel.textColor = ATTheme.Palette.inkFaint
        detailLabel.numberOfLines = 1
        contentView.addSubview(detailLabel)

        badge.font = ATTheme.Typeface.mono(12, .semibold)
        badge.textColor = ATTheme.Palette.mist
        badge.textAlignment = .right
        contentView.addSubview(badge)

        mark.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.centerY.equalTo(nameLabel)
            make.width.equalTo(6)
            make.height.equalTo(26)
        }

        icon.snp.makeConstraints { make in
            make.center.equalTo(mark)
            make.width.height.equalTo(18)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(mark.snp.trailing).offset(ATTheme.Space.sm)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.trailing.lessThanOrEqualTo(badge.snp.leading).offset(-ATTheme.Space.xs)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.lastBaseline.equalTo(nameLabel)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with entry: ATPlacePickerEntry) {
        mark.backgroundColor = entry.tint
        mark.isHidden = false
        icon.isHidden = true

        nameLabel.text = entry.place.name
        nameLabel.font = ATTheme.Typeface.sans(16, .semibold)
        nameLabel.textColor = ATTheme.Palette.ink
        detailLabel.text = entry.place.country.isEmpty ? entry.detail : "\(entry.place.country) · \(entry.detail)"

        badge.text = entry.noteCount > 0 ? "\(entry.noteCount)" : ""
        badge.isHidden = false
    }

    func configureTyped(_ name: String) {
        mark.backgroundColor = .clear
        mark.isHidden = true
        icon.isHidden = false
        icon.image = UIImage(
            systemName: "magnifyingglass",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )

        nameLabel.text = "Use “\(name)”"
        nameLabel.font = ATTheme.Typeface.sans(16, .semibold)
        nameLabel.textColor = ATTheme.Palette.accent
        detailLabel.text = "Not in the library yet — it will be filed under this name."
        badge.text = ""
        badge.isHidden = true
    }
}
