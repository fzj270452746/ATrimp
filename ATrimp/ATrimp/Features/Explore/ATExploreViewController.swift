//
//  ATExploreViewController.swift
//  ATrimp
//
//
//
import SnapKit
import UIKit

final class ATExploreViewController: ATViewController {

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private let masthead = UILabel()
    private let standfirst = UILabel()

    private let standingsStack = UIStackView()
    private let standingsBlurb = UILabel()
    private var standingButtons: [ATStore.ATStanding: ATPillButton] = [:]
    private var standing: ATStore.ATStanding = .busiest

    private let monthStrip = UIStackView()
    private let libraryBar = ATLensBar()
    private let libraryNote = UILabel()
    private let sameRoadStack = UIStackView()
    private let sameRoadNote = UILabel()
    private let mapNote = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        buildHeader()
        buildScroll()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Header

    private func buildHeader() {
        masthead.text = "Explore"
        masthead.font = ATTheme.Typeface.serif(34, .semibold)
        masthead.textColor = ATTheme.Palette.ink
        view.addSubview(masthead)

        let rule = ATRule(color: ATTheme.Palette.accent)
        view.addSubview(rule)

        standfirst.text = "Every place the library has an opinion about."
        standfirst.font = ATTheme.Typeface.caption
        standfirst.textColor = ATTheme.Palette.inkFaint
        standfirst.numberOfLines = 1
        view.addSubview(standfirst)

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

        standfirst.snp.makeConstraints { make in
            make.top.equalTo(rule.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }
    }

    // MARK: - Layout

    private func buildScroll() {
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        view.addSubview(scroll)

        column.axis = .vertical
        column.alignment = .fill
        column.spacing = 0
        scroll.addSubview(column)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(standfirst.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.bottom.equalToSuperview()
        }

        column.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ATTheme.Space.gutter)
            make.width.equalToSuperview().offset(-ATTheme.Space.gutter * 2)
        }

        buildSearchRow()
        buildYearCard()
        buildToolbox()
        buildLedger()
        buildMonths()
        buildLibrary()
        buildSameRoad()
        buildMapRow()

        column.addArrangedSubview(spacer(90))
    }

    // MARK: - Toolbox

    private func buildToolbox() {
        let header = sectionHeader("Toolbox", note: "Four things to do with a place")
        column.addArrangedSubview(header)
        column.setCustomSpacing(ATTheme.Space.sm, after: header)

        let top = toolRow([
            (
                symbol: "list.bullet",
                title: "Trip brief",
                detail: "Pitfalls, highlights and your own notes, on one page",
                action: { [weak self] in self?.openBrief() }
            ),
            (
                symbol: "arrow.left.arrow.right",
                title: "Compare",
                detail: "Two places, side by side",
                action: { [weak self] in self?.push(ATPlaceComparisonViewController()) }
            ),
        ])
        column.addArrangedSubview(top)
        column.setCustomSpacing(ATTheme.Space.xs, after: top)

        let bottom = toolRow([
            (
                symbol: "shuffle",
                title: "Draw",
                detail: "Let the library pick the next stop",
                action: { [weak self] in self?.push(ATDrawViewController()) }
            ),
            (
                symbol: "creditcard",
                title: "Ledger",
                detail: "What the trip cost, and where it went",
                action: { [weak self] in self?.push(ATLedgerViewController()) }
            ),
        ])
        column.addArrangedSubview(bottom)
        column.setCustomSpacing(ATTheme.Space.xl, after: bottom)
    }

    private func openBrief() {
        let picker = ATPlacePickerViewController(
            title: "Trip brief",
            standfirst: "Pick a place to read before you go.",
            entries: ATToolbox.pickerEntries(allowsNotes: true)
        ) { [weak self] place in
            self?.push(ATTripBriefViewController(place: place))
        }
        push(picker)
    }

    private func toolRow(
        _ tools: [(symbol: String, title: String, detail: String, action: () -> Void)]
    ) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.sm
        row.distribution = .fillEqually
        row.alignment = .fill

        for tool in tools {
            row.addArrangedSubview(toolCard(tool.symbol, tool.title, tool.detail, tool.action))
        }

        return row
    }

    private func toolCard(
        _ symbol: String,
        _ title: String,
        _ detail: String,
        _ action: @escaping () -> Void
    ) -> UIView {
        let control = UIControl()
        control.backgroundColor = ATTheme.Palette.paperDeep
        control.layer.cornerRadius = ATTheme.Radius.small
        control.layer.cornerCurve = .continuous

        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            )
        )
        icon.tintColor = ATTheme.Palette.accent
        icon.contentMode = .center
        control.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ATTheme.Typeface.sans(14.5, .semibold)
        titleLabel.textColor = ATTheme.Palette.ink
        titleLabel.numberOfLines = 1
        control.addSubview(titleLabel)

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = ATTheme.Typeface.caption
        detailLabel.textColor = ATTheme.Palette.inkSoft
        detailLabel.numberOfLines = 3
        control.addSubview(detailLabel)

        control.snp.makeConstraints { make in
            make.height.equalTo(112)
        }

        icon.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(ATTheme.Space.md)
            make.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
            make.top.equalTo(icon.snp.bottom).offset(ATTheme.Space.xs)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.lessThanOrEqualToSuperview().offset(-ATTheme.Space.md)
        }

        control.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return control
    }

    // MARK: - Search

    private func buildSearchRow() {
        let row = makeRow(
            symbol: "magnifyingglass",
            title: "Search the library",
            detail: "Places, people and writing, in one box"
        ) { [weak self] in self?.push(ATSearchViewController()) }

        column.addArrangedSubview(row)
        column.setCustomSpacing(ATTheme.Space.md, after: row)
    }

    // MARK: - The year

    private func buildYearCard() {
        let card = UIControl()
        card.backgroundColor = ATTheme.Palette.ink
        card.layer.cornerRadius = ATTheme.Radius.medium
        card.layer.cornerCurve = .continuous
        card.addTarget(self, action: #selector(openWrapped), for: .touchUpInside)

        let caption = UILabel()
        caption.attributedText = ATTheme.sectionLabel(
            "The year in second thoughts",
            color: ATTheme.Palette.accent
        )
        card.addSubview(caption)

        let headline = UILabel()
        headline.text = "Your record, read back to you"
        headline.font = ATTheme.Typeface.serif(22, .semibold)
        headline.textColor = ATTheme.Palette.paper
        headline.numberOfLines = 2
        card.addSubview(headline)

        let detail = UILabel()
        detail.text = "Swipe through what the last months add up to — where the library went, how it read, and how much of it was yours."
        detail.font = ATTheme.Typeface.sans(13.5)
        detail.textColor = ATTheme.Palette.paper.withAlphaComponent(0.72)
        detail.numberOfLines = 0
        card.addSubview(detail)

        let chevron = UIImageView(
            image: UIImage(
                systemName: "arrow.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            )
        )
        chevron.tintColor = ATTheme.Palette.accent
        card.addSubview(chevron)

        caption.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
        }

        headline.snp.makeConstraints { make in
            make.top.equalTo(caption.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.xl)
        }

        detail.snp.makeConstraints { make in
            make.top.equalTo(headline.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.md)
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
            make.centerY.equalTo(headline)
        }

        column.addArrangedSubview(card)
        column.setCustomSpacing(ATTheme.Space.lg, after: card)
    }

    @objc private func openWrapped() {
        push(ATWrappedViewController())
    }

    // MARK: - The ledger

    private func buildLedger() {
        let header = sectionHeader("The ledger", note: nil)
        column.addArrangedSubview(header)
        column.setCustomSpacing(ATTheme.Space.sm, after: header)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.xs
        row.distribution = .fillEqually
        for kind in ATStore.ATStanding.allCases {
            let button = ATPillButton(title: kind.title)
            button.addTarget(self, action: #selector(chooseStanding(_:)), for: .touchUpInside)
            row.addArrangedSubview(button)
            standingButtons[kind] = button
        }
        column.addArrangedSubview(row)
        column.setCustomSpacing(ATTheme.Space.sm, after: row)

        standingsBlurb.font = ATTheme.Typeface.caption
        standingsBlurb.textColor = ATTheme.Palette.inkFaint
        standingsBlurb.numberOfLines = 0
        column.addArrangedSubview(standingsBlurb)
        column.setCustomSpacing(ATTheme.Space.sm, after: standingsBlurb)

        standingsStack.axis = .vertical
        standingsStack.spacing = 0
        column.addArrangedSubview(standingsStack)
        column.setCustomSpacing(ATTheme.Space.xl, after: standingsStack)
    }

    @objc private func chooseStanding(_ sender: ATPillButton) {
        guard let kind = standingButtons.first(where: { $0.value === sender })?.key else { return }
        standing = kind
        reloadStandings()
    }

    private func reloadStandings() {
        for (kind, button) in standingButtons {
            let active = kind == standing
            button.apply(
                title: kind.title,
                filled: active,
                tint: ATTheme.Palette.ink
            )
        }
        standingsBlurb.text = standing.blurb

        standingsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let standings = ATStore.standings(standing, limit: 5)
        guard !standings.isEmpty else {
            let label = UILabel()
            label.text = "Nothing has been filed under this yet."
            label.font = ATTheme.Typeface.body
            label.textColor = ATTheme.Palette.inkSoft
            standingsStack.addArrangedSubview(label)
            return
        }

        for (index, entry) in standings.enumerated() {
            standingsStack.addArrangedSubview(standingRow(rank: index + 1, entry: entry))
        }
    }

    private func standingRow(rank: Int, entry: ATStore.ATPlaceStanding) -> UIView {
        let dossier = entry.dossier
        let control = UIControl()

        let rankLabel = UILabel()
        rankLabel.text = "\(rank)"
        rankLabel.font = ATTheme.Typeface.mono(15, .semibold)
        rankLabel.textColor = ATTheme.Palette.inkFaint
        control.addSubview(rankLabel)

        let name = UILabel()
        name.text = dossier.place.name
        name.font = ATTheme.Typeface.serif(17, .semibold)
        name.textColor = ATTheme.Palette.ink
        name.numberOfLines = 1
        control.addSubview(name)

        let country = UILabel()
        country.text = dossier.place.country
        country.font = ATTheme.Typeface.caption
        country.textColor = ATTheme.Palette.inkFaint
        control.addSubview(country)

        let score = UILabel()
        score.text = "\(entry.score)"
        score.font = ATTheme.Typeface.mono(15, .semibold)
        score.textColor = ATTheme.Palette.ink
        control.addSubview(score)

        let stripe = ATLensStripe()
        stripe.configure(with: dossier.themesByWeight)
        control.addSubview(stripe)

        rankLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(11)
            make.width.equalTo(18)
        }

        name.snp.makeConstraints { make in
            make.leading.equalTo(rankLabel.snp.trailing).offset(ATTheme.Space.xs)
            make.trailing.lessThanOrEqualTo(score.snp.leading).offset(-ATTheme.Space.sm)
            make.top.equalToSuperview().offset(ATTheme.Space.xs)
        }

        country.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(1)
        }

        score.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(name)
        }

        stripe.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.trailing.equalToSuperview()
            make.top.equalTo(country.snp.bottom).offset(ATTheme.Space.xs)
            make.bottom.equalToSuperview()
        }

        control.addAction(
            UIAction { [weak self] _ in self?.push(ATPlaceViewController(place: dossier.place)) },
            for: .touchUpInside
        )
        return control
    }

    // MARK: - Months

    private func buildMonths() {
        let header = sectionHeader("By month", note: "Tap a month to read it")
        column.addArrangedSubview(header)
        column.setCustomSpacing(ATTheme.Space.sm, after: header)

        let scroller = UIScrollView()
        scroller.showsHorizontalScrollIndicator = false
        scroller.clipsToBounds = false

        monthStrip.axis = .horizontal
        monthStrip.spacing = ATTheme.Space.xs
        monthStrip.alignment = .fill
        scroller.addSubview(monthStrip)
        column.addArrangedSubview(scroller)
        column.setCustomSpacing(ATTheme.Space.xl, after: scroller)

        scroller.snp.makeConstraints { make in
            make.height.equalTo(Self.monthCardHeight)
        }

        monthStrip.snp.makeConstraints { make in
            make.edges.equalTo(scroller.contentLayoutGuide)
        }
    }

    private static let monthCardHeight: CGFloat = 88
    private static let monthCardWidth: CGFloat = 72

    private func reloadMonths() {
        monthStrip.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let months = ATStore.months(limit: 12)
        guard !months.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

        for month in months {
            let card = UIControl()
            card.backgroundColor = ATTheme.Palette.paperDeep
            card.layer.cornerRadius = ATTheme.Radius.small
            card.layer.cornerCurve = .continuous

            let caption = UILabel()
            caption.text = "\(formatter.string(from: month.start).uppercased()) \(yearFormatter.string(from: month.start))"
            caption.font = ATTheme.Typeface.sans(10, .semibold)
            caption.textColor = ATTheme.Palette.inkFaint
            caption.adjustsFontSizeToFitWidth = true
            caption.minimumScaleFactor = 0.8
            card.addSubview(caption)

            let count = UILabel()
            count.text = "\(month.count)"
            count.font = ATTheme.Typeface.mono(22, .semibold)
            count.textColor = ATTheme.Palette.ink
            card.addSubview(count)

            let stripe = ATLensStripe()
            stripe.configure(with: month.themesByWeight)
            card.addSubview(stripe)

            caption.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(ATTheme.Space.xs)
            }

            count.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xs)
                make.top.equalTo(caption.snp.bottom).offset(1)
            }

            stripe.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xs)
                make.top.equalTo(count.snp.bottom).offset(ATTheme.Space.xs)
                make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
            }

            let start = month.start
            card.addAction(
                UIAction { [weak self] _ in self?.push(ATMonthViewController(monthStart: start)) },
                for: .touchUpInside
            )
            monthStrip.addArrangedSubview(card)
            card.snp.makeConstraints { make in
                make.width.equalTo(Self.monthCardWidth)
                make.height.equalTo(Self.monthCardHeight)
            }
        }
    }

    // MARK: - The library

    private func buildLibrary() {
        let header = sectionHeader("How the library reads", note: nil)
        column.addArrangedSubview(header)
        column.setCustomSpacing(ATTheme.Space.sm, after: header)

        column.addArrangedSubview(libraryBar)
        column.setCustomSpacing(ATTheme.Space.sm, after: libraryBar)

        libraryNote.font = ATTheme.Typeface.caption
        libraryNote.textColor = ATTheme.Palette.inkFaint
        libraryNote.numberOfLines = 0
        column.addArrangedSubview(libraryNote)
        column.setCustomSpacing(ATTheme.Space.lg, after: libraryNote)
    }

    // MARK: - Same road

    private func buildSameRoad() {
        let header = sectionHeader("On the same road", note: nil)
        column.addArrangedSubview(header)
        column.setCustomSpacing(ATTheme.Space.sm, after: header)

        sameRoadStack.axis = .horizontal
        sameRoadStack.spacing = ATTheme.Space.md
        sameRoadStack.alignment = .top
        sameRoadStack.distribution = .fillEqually
        column.addArrangedSubview(sameRoadStack)
        column.setCustomSpacing(ATTheme.Space.xs, after: sameRoadStack)

        sameRoadNote.font = ATTheme.Typeface.caption
        sameRoadNote.textColor = ATTheme.Palette.inkFaint
        sameRoadNote.numberOfLines = 0
        column.addArrangedSubview(sameRoadNote)
        column.setCustomSpacing(ATTheme.Space.lg, after: sameRoadNote)
    }

    private func reloadSameRoad() {
        sameRoadStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let themes = ATStore.readerThemes()
        guard let lead = ATStore.readerReading().byWeight.first?.theme
                ?? ATStore.resonatedThemes().first?.theme
                ?? themes.sorted(by: { $0.title < $1.title }).first else {
            sameRoadNote.text = "Like a filing, leave a comment or mark one “same here”, and the people who read the way you do turn up here."
            sameRoadStack.isHidden = true
            return
        }

        let people = ATStore.peopleWhoFile(
            lead,
            limit: 4,
            excluding: Set([ATStore.currentUser()?.id].compactMap { $0 })
        )
        guard !people.isEmpty else {
            sameRoadNote.text = "Nobody else has filed under \(lead.title) yet."
            sameRoadStack.isHidden = true
            return
        }

        sameRoadStack.isHidden = false
        for person in people {
            sameRoadStack.addArrangedSubview(personCard(person, lens: lead))
        }
        sameRoadNote.text = "You keep reading \(lead.title.lowercased()). These four have filed under it most."
    }

    private func personCard(_ person: ATUser, lens: ATPostTheme) -> UIView {
        let control = UIControl()

        let avatar = UIImageView()
        avatar.image = ATArt.avatarImage(
            seed: person.avatarSeed,
            initials: person.initials,
            size: 52
        )
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 26
        avatar.clipsToBounds = true
        avatar.backgroundColor = ATTheme.Palette.paperDeep
        control.addSubview(avatar)

        let name = UILabel()
        name.text = person.displayName
        name.font = ATTheme.Typeface.sans(12, .semibold)
        name.textColor = ATTheme.Palette.ink
        name.numberOfLines = 2
        name.textAlignment = .center
        control.addSubview(name)

        let marker = UIView()
        marker.backgroundColor = lens.tint
        marker.layer.cornerRadius = 1.5
        control.addSubview(marker)

        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(52)
        }

        name.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xs)
        }

        marker.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(22)
            make.height.equalTo(3)
        }

        control.addAction(
            UIAction { [weak self] _ in self?.push(ATUserProfileViewController(userID: person.id)) },
            for: .touchUpInside
        )
        return control
    }

    // MARK: - Map

    private func buildMapRow() {
        let row = makeRow(
            symbol: "map",
            title: "The map",
            detail: "Every pinned place, coloured by how it reads"
        ) { [weak self] in self?.push(ATPlaceMapViewController()) }
        column.addArrangedSubview(row)
        column.setCustomSpacing(ATTheme.Space.lg, after: row)

        mapNote.font = ATTheme.Typeface.caption
        mapNote.textColor = ATTheme.Palette.inkFaint
        mapNote.numberOfLines = 0
        column.addArrangedSubview(mapNote)
    }

    // MARK: - Shared pieces

    private func reload() {
        let library = ATStore.libraryThemeCounts()
        let total = library.reduce(0) { $0 + $1.count }
        let places = ATStore.placeSummaries().count

        libraryBar.configure(with: library)
        libraryNote.text = "\(total) filings across \(places) places. This is the whole library, not you."

        mapNote.text = "\(ATStore.pinnedPlaceSummaries().count) of those places can be pinned. The rest are somewhere the writer typed by hand."

        reloadStandings()
        reloadMonths()
        reloadSameRoad()
    }

    private func sectionHeader(_ title: String, note: String?) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(title, color: ATTheme.Palette.mist)
        container.addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        if let note {
            let noteLabel = UILabel()
            noteLabel.text = note
            noteLabel.font = ATTheme.Typeface.caption
            noteLabel.textColor = ATTheme.Palette.inkFaint
            noteLabel.textAlignment = .right
            container.addSubview(noteLabel)

            noteLabel.snp.makeConstraints { make in
                make.trailing.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(ATTheme.Space.xs)
            }
        }

        return container
    }

    private func makeRow(
        symbol: String,
        title: String,
        detail: String,
        action: @escaping () -> Void
    ) -> UIView {
        let control = UIControl()
        control.backgroundColor = ATTheme.Palette.paperDeep
        control.layer.cornerRadius = ATTheme.Radius.small
        control.layer.cornerCurve = .continuous

        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            )
        )
        icon.tintColor = ATTheme.Palette.accent
        icon.contentMode = .center
        control.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ATTheme.Typeface.sans(15.5, .semibold)
        titleLabel.textColor = ATTheme.Palette.ink
        control.addSubview(titleLabel)

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = ATTheme.Typeface.caption
        detailLabel.textColor = ATTheme.Palette.inkSoft
        detailLabel.numberOfLines = 0
        control.addSubview(detailLabel)

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            )
        )
        chevron.tintColor = ATTheme.Palette.inkFaint
        control.addSubview(chevron)

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.top.equalToSuperview().offset(ATTheme.Space.md)
            make.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(ATTheme.Space.sm)
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-ATTheme.Space.xs)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
            make.centerY.equalTo(titleLabel)
        }

        control.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return control
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        return view
    }
}
