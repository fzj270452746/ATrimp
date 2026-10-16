//
//  ATLedgerViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATLedgerViewController: ATViewController {

    private let table = UITableView(frame: .zero, style: .plain)
    private let header = ATLedgerHeaderView()

    private let emptyView = ATEmptyView(
        title: "Nothing spent yet",
        message: "Everything you log lands here, grouped by place — so the trip tells you where the money went.",
        actionTitle: "Add the first expense"
    )

    private let guestView = ATEmptyView(
        title: "You are browsing as a guest",
        message: "Sign in to keep a ledger of what a trip cost.",
        actionTitle: "Sign in"
    )

    private var ledger = ATExpenseLedger([])
    private var groups: [(place: ATPlace, expenses: [ATExpense], total: Decimal)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: "Trip ledger")
        bar.addTrailing(symbol: "plus", action: #selector(addExpense), target: self)

        emptyView.onAction = { [weak self] in self?.addExpense() }
        guestView.onAction = { [weak self] in
            guard let self,
                  !self.requireSignIn(message: "Sign in to keep a ledger of what the trip cost.")
            else { return }
            self.reload()
        }

        buildTable()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: ATSession.didChange,
            object: nil
        )

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
    }

    // MARK: - Layout

    private func buildTable() {
        table.backgroundColor = ATTheme.Palette.paper
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 64
        table.contentInsetAdjustmentBehavior = .never
        table.sectionHeaderTopPadding = 0
        table.dataSource = self
        table.delegate = self
        table.register(ATExpenseCell.self, forCellReuseIdentifier: ATExpenseCell.reuseIdentifier)
        view.addSubview(table)

        table.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 240)

        for empty in [emptyView, guestView] {
            view.addSubview(empty)
            empty.snp.makeConstraints { make in
                make.top.equalTo(navBar!.snp.bottom).offset(70)
                make.leading.trailing.equalToSuperview()
            }
            empty.isHidden = true
        }
    }

    // MARK: - Data

    @objc private func reload() {
        ledger = ATExpenseLedger(ATStore.expenses())
        groups = ledger.byPlace

        header.configure(with: ledger)

        if ledger.isEmpty {
            table.tableHeaderView = nil
        } else {
            let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
            header.frame = CGRect(x: 0, y: 0, width: width, height: header.height(forWidth: width))
            table.tableHeaderView = header
        }

        table.reloadData()

        let signedIn = ATSession.shared.isSignedIn
        emptyView.isHidden = !(ledger.isEmpty && signedIn)
        guestView.isHidden = !(ledger.isEmpty && !signedIn)
    }

    // MARK: - Actions

    @objc private func addExpense() {
        guard !requireSignIn(message: "Sign in to keep a ledger of what the trip cost.") else { return }

        let sheet = ATExpenseSheetViewController(
            editing: nil,
            defaultPlace: groups.first?.place
        ) { [weak self] in
            guard let self else { return }
            let before = self.ledger.entryCount
            self.reload()
            self.showToast(self.ledger.entryCount > before ? "Added." : "Could not save that.")
        }

        presentSheet(sheet, detents: [.large()])
    }

    private func edit(_ expense: ATExpense) {
        let sheet = ATExpenseSheetViewController(
            editing: expense,
            defaultPlace: nil
        ) { [weak self] in
            self?.reload()
        }

        presentSheet(sheet, detents: [.large()])
    }

    private func remove(_ expense: ATExpense) {
        ATStore.deleteExpense(id: expense.id)
        reload()
    }
}

// MARK: - Table

extension ATLedgerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { groups.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups[section].expenses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ATExpenseCell.reuseIdentifier,
            for: indexPath
        ) as! ATExpenseCell
        cell.configure(with: groups[indexPath.section].expenses[indexPath.row])
        return cell
    }
}

extension ATLedgerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = groups[section]

        let control = UIControl()
        control.backgroundColor = ATTheme.Palette.paper

        let name = UILabel()
        name.text = group.place.name
        name.font = ATTheme.Typeface.subtitle
        name.textColor = ATTheme.Palette.ink
        control.addSubview(name)

        let country = UILabel()
        country.text = group.place.country
        country.font = ATTheme.Typeface.caption
        country.textColor = ATTheme.Palette.inkFaint
        control.addSubview(country)

        let subtotal = UILabel()
        subtotal.text = ATMoney.format(group.total)
        subtotal.font = ATTheme.Typeface.mono(13, .semibold)
        subtotal.textColor = ATTheme.Palette.ink
        control.addSubview(subtotal)

        let rule = ATRule()
        control.addSubview(rule)

        name.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.top.equalToSuperview().offset(ATTheme.Space.lg)
        }

        country.snp.makeConstraints { make in
            make.leading.equalTo(name.snp.trailing).offset(ATTheme.Space.xs)
            make.lastBaseline.equalTo(name)
        }

        subtotal.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.lastBaseline.equalTo(name)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview()
        }

        control.addAction(
            UIAction { [weak self] _ in
                self?.push(ATPlaceViewController(place: group.place))
            },
            for: .touchUpInside
        )

        return control
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        edit(groups[indexPath.section].expenses[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let expense = groups[indexPath.section].expenses[indexPath.row]
        let drop = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.remove(expense)
            completion(true)
        }
        drop.backgroundColor = ATTheme.Palette.danger
        return UISwipeActionsConfiguration(actions: [drop])
    }
}

// MARK: - Expense row

private final class ATExpenseCell: UITableViewCell {

    static let reuseIdentifier = "ATExpenseCell"

    private let dot = UIView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = ATTheme.Palette.paper

        dot.layer.cornerRadius = 5
        contentView.addSubview(dot)

        titleLabel.font = ATTheme.Typeface.sans(15.5)
        titleLabel.textColor = ATTheme.Palette.ink
        titleLabel.numberOfLines = 2
        contentView.addSubview(titleLabel)

        metaLabel.font = ATTheme.Typeface.caption
        metaLabel.textColor = ATTheme.Palette.inkFaint
        metaLabel.numberOfLines = 1
        contentView.addSubview(metaLabel)

        amountLabel.font = ATTheme.Typeface.mono(15, .semibold)
        amountLabel.textColor = ATTheme.Palette.ink
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)

        dot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(10)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(ATTheme.Space.sm)
            make.top.equalToSuperview().offset(ATTheme.Space.xs)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-ATTheme.Space.sm)
        }

        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-ATTheme.Space.sm)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
        }

        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.lastBaseline.equalTo(titleLabel)
            make.width.greaterThanOrEqualTo(60)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with expense: ATExpense) {
        dot.backgroundColor = expense.category.tint
        titleLabel.text = expense.note.isEmpty ? expense.category.title : expense.note

        var parts = [ATTime.long(expense.spentAt), expense.category.title]
        if expense.isSplit {
            parts.append("split \(expense.people) ways")
        }
        metaLabel.text = parts.joined(separator: " · ")

        amountLabel.text = ATMoney.format(expense.amount)
    }
}

// MARK: - Split bar

private final class ATSplitBar: UIView {

    private var segments: [(color: UIColor, ratio: CGFloat)] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ATTheme.Palette.paperDeep
        layer.cornerRadius = 5
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isOpaque = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with byCategory: [(category: ATExpenseCategory, total: Decimal, count: Int)]) {
        let sum = byCategory.reduce(Decimal.zero) { $0 + $1.total }
        guard sum > 0 else {
            segments = []
            setNeedsDisplay()
            return
        }

        segments = byCategory.map { entry in
            let ratio = CGFloat(Double(truncating: (entry.total / sum) as NSDecimalNumber))
            return (entry.category.tint, ratio)
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setFillColor(ATTheme.Palette.paperDeep.cgColor)
        context.fill(rect)

        var x: CGFloat = 0
        for segment in segments {
            let width = rect.width * segment.ratio
            context.setFillColor(segment.color.cgColor)
            context.fill(CGRect(x: x, y: 0, width: width, height: rect.height))
            x += width
        }
    }
}

// MARK: - Header

private final class ATLedgerHeaderView: UIView {

    private let totalCaption = UILabel()
    private let totalLabel = UILabel()
    private let shareLabel = UILabel()
    private let countLabel = UILabel()
    private let bar = ATSplitBar()
    private let legend = UIStackView()
    private let byPlace = UILabel()
    private let rule = ATRule()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paper

        totalCaption.attributedText = ATTheme.sectionLabel("Total spent", color: ATTheme.Palette.mist)
        addSubview(totalCaption)

        totalLabel.font = ATTheme.Typeface.serif(34, .semibold)
        totalLabel.textColor = ATTheme.Palette.ink
        totalLabel.adjustsFontSizeToFitWidth = true
        totalLabel.minimumScaleFactor = 0.6
        addSubview(totalLabel)

        shareLabel.font = ATTheme.Typeface.mono(15, .semibold)
        shareLabel.textColor = ATTheme.Palette.mist
        shareLabel.textAlignment = .right
        addSubview(shareLabel)

        countLabel.font = ATTheme.Typeface.caption
        countLabel.textColor = ATTheme.Palette.inkFaint
        addSubview(countLabel)

        addSubview(bar)

        legend.axis = .vertical
        legend.alignment = .fill
        legend.spacing = ATTheme.Space.xxs
        addSubview(legend)

        byPlace.attributedText = ATTheme.sectionLabel("By place", color: ATTheme.Palette.mist)
        addSubview(byPlace)

        addSubview(rule)

        totalCaption.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalCaption.snp.bottom).offset(ATTheme.Space.xxs)
            make.leading.equalToSuperview().inset(ATTheme.Space.gutter)
            make.trailing.lessThanOrEqualTo(shareLabel.snp.leading).offset(-ATTheme.Space.sm)
        }

        shareLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.lastBaseline.equalTo(totalLabel)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(ATTheme.Space.xxs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        bar.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.height.equalTo(10)
        }

        legend.snp.makeConstraints { make in
            make.top.equalTo(bar.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        byPlace.snp.makeConstraints { make in
            make.top.equalTo(legend.snp.bottom).offset(ATTheme.Space.lg)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(byPlace.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func height(forWidth width: CGFloat) -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    func configure(with ledger: ATExpenseLedger) {
        totalLabel.text = ATMoney.format(ledger.total)

        let entries = "\(ledger.entryCount) \(ledger.entryCount == 1 ? "entry" : "entries")"
        let places = "\(ledger.placeCount) \(ledger.placeCount == 1 ? "place" : "places")"
        countLabel.text = "\(entries) across \(places)"

        shareLabel.text = ledger.hasSplit ? "Your share \(ATMoney.format(ledger.share))" : ""
        shareLabel.isHidden = !ledger.hasSplit

        bar.configure(with: ledger.byCategory)

        legend.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for entry in ledger.byCategory {
            legend.addArrangedSubview(legendRow(entry, total: ledger.total))
        }

        setNeedsLayout()
    }

    private func legendRow(
        _ entry: (category: ATExpenseCategory, total: Decimal, count: Int),
        total: Decimal
    ) -> UIView {
        let container = UIView()

        let dot = UIView()
        dot.backgroundColor = entry.category.tint
        dot.layer.cornerRadius = 4
        container.addSubview(dot)

        let name = UILabel()
        name.attributedText = ATTheme.sectionLabel(entry.category.title, color: entry.category.tint)
        container.addSubview(name)

        let amount = UILabel()
        amount.text = ATMoney.format(entry.total)
        amount.font = ATTheme.Typeface.mono(12, .medium)
        amount.textColor = ATTheme.Palette.inkSoft
        amount.textAlignment = .right
        container.addSubview(amount)

        let percent = UILabel()
        let ratio = total > 0 ? Double(truncating: (entry.total / total) as NSDecimalNumber) : 0
        percent.text = "\(Int((ratio * 100).rounded()))%"
        percent.font = ATTheme.Typeface.caption
        percent.textColor = ATTheme.Palette.inkFaint
        percent.textAlignment = .right
        container.addSubview(percent)

        dot.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(name)
            make.width.height.equalTo(8)
        }

        name.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(ATTheme.Space.xs)
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(-2)
        }

        percent.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(name)
            make.width.equalTo(42)
        }

        amount.snp.makeConstraints { make in
            make.trailing.equalTo(percent.snp.leading).offset(-ATTheme.Space.xs)
            make.centerY.equalTo(name)
            make.leading.greaterThanOrEqualTo(name.snp.trailing).offset(ATTheme.Space.xs)
        }

        return container
    }
}
