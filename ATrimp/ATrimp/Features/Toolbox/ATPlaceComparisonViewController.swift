//
//  ATPlaceComparisonViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATPlaceComparisonViewController: ATViewController {

    private let labelColumn: CGFloat = 84

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private var left: ATPlace?
    private var right: ATPlace?
    private var lastSignature = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: "Compare")
        buildScroll()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
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
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        column.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ATTheme.Space.gutter)
            make.width.equalToSuperview().offset(-ATTheme.Space.gutter * 2)
        }
    }

    // MARK: - Data

    @objc private func reload() {
        let signature = "\(left?.key ?? "-")|\(right?.key ?? "-")"
        guard signature != lastSignature else { return }
        lastSignature = signature

        let comparison: ATPlaceComparison? = {
            guard let left, let right else { return nil }
            return ATToolbox.compare(left, right)
        }()

        let leftDossier = comparison?.left ?? left.map { ATStore.dossier(for: $0) }
        let rightDossier = comparison?.right ?? right.map { ATStore.dossier(for: $0) }

        rebuild(leftDossier, rightDossier, comparison)
    }

    private func rebuild(
        _ leftDossier: ATPlaceDossier?,
        _ rightDossier: ATPlaceDossier?,
        _ comparison: ATPlaceComparison?
    ) {
        column.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let slots = slotRow(leftDossier, rightDossier)
        column.addArrangedSubview(slots)
        column.setCustomSpacing(ATTheme.Space.sm, after: slots)

        let changes = changeRow(leftDossier != nil, rightDossier != nil)
        column.addArrangedSubview(changes)
        column.setCustomSpacing(ATTheme.Space.lg, after: changes)

        guard let comparison else {
            let hint = mutedLine("Pick both places and the reading appears here.")
            column.addArrangedSubview(hint)
            column.setCustomSpacing(ATTheme.Space.xl, after: hint)
            column.addArrangedSubview(tail())
            return
        }

        let metrics = [
            ("Filings", "\(comparison.left.postCount)", "\(comparison.right.postCount)"),
            ("Travellers", "\(comparison.left.authorCount)", "\(comparison.right.authorCount)"),
            ("Latest", latest(comparison.left), latest(comparison.right)),
            ("Intensity", intensity(comparison.leftIntensity), intensity(comparison.rightIntensity)),
        ]

        var last: UIView?
        for metric in metrics {
            let row = metricRow(metric.0, metric.1, metric.2)
            column.addArrangedSubview(row)
            column.setCustomSpacing(ATTheme.Space.sm, after: row)
            last = row
        }
        if let last {
            column.setCustomSpacing(ATTheme.Space.xl, after: last)
        }

        let header = sectionHeader("How they read")
        column.addArrangedSubview(header)
        column.setCustomSpacing(ATTheme.Space.sm, after: header)

        let leftLens = lensBlock(comparison.left)
        column.addArrangedSubview(leftLens)
        column.setCustomSpacing(ATTheme.Space.md, after: leftLens)

        let rightLens = lensBlock(comparison.right)
        column.addArrangedSubview(rightLens)
        column.setCustomSpacing(ATTheme.Space.xl, after: rightLens)

        let verdict = verdictCard(comparison)
        column.addArrangedSubview(verdict)
        column.setCustomSpacing(ATTheme.Space.lg, after: verdict)

        column.addArrangedSubview(tail())
    }

    // MARK: - Pieces

    private func slotRow(_ leftDossier: ATPlaceDossier?, _ rightDossier: ATPlaceDossier?) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.sm
        row.alignment = .fill

        let spacer = UIView()
        spacer.snp.makeConstraints { make in
            make.width.equalTo(labelColumn)
        }
        row.addArrangedSubview(spacer)

        let pair = UIStackView()
        pair.axis = .horizontal
        pair.spacing = ATTheme.Space.sm
        pair.distribution = .fillEqually
        pair.alignment = .fill
        pair.addArrangedSubview(slot(leftDossier, side: 0))
        pair.addArrangedSubview(slot(rightDossier, side: 1))
        row.addArrangedSubview(pair)

        pair.snp.makeConstraints { make in
            make.height.equalTo(132)
        }

        return row
    }

    private func slot(_ dossier: ATPlaceDossier?, side: Int) -> UIView {
        let control = UIControl()
        control.backgroundColor = ATTheme.Palette.paperDeep
        control.layer.cornerRadius = ATTheme.Radius.small
        control.layer.cornerCurve = .continuous

        guard let dossier else {
            let icon = UIImageView(
                image: UIImage(
                    systemName: "mappin.and.ellipse",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
                )
            )
            icon.tintColor = ATTheme.Palette.inkFaint
            icon.contentMode = .center
            control.addSubview(icon)

            let label = UILabel()
            label.text = "Pick a place"
            label.font = ATTheme.Typeface.sans(14, .semibold)
            label.textColor = ATTheme.Palette.inkSoft
            label.textAlignment = .center
            control.addSubview(label)

            icon.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-12)
            }

            label.snp.makeConstraints { make in
                make.top.equalTo(icon.snp.bottom).offset(ATTheme.Space.xs)
                make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xs)
            }

            control.addAction(
                UIAction { [weak self] _ in self?.choose(side: side) },
                for: .touchUpInside
            )

            return control
        }

        let name = UILabel()
        name.text = dossier.place.name
        name.font = ATTheme.Typeface.serif(18, .semibold)
        name.textColor = ATTheme.Palette.ink
        name.numberOfLines = 2
        control.addSubview(name)

        let country = UILabel()
        country.text = dossier.place.country
        country.font = ATTheme.Typeface.caption
        country.textColor = ATTheme.Palette.inkFaint
        country.numberOfLines = 1
        control.addSubview(country)

        let tally = UILabel()
        tally.text = "\(dossier.postCount) \(dossier.postCount == 1 ? "filing" : "filings")"
        tally.font = ATTheme.Typeface.mono(12, .semibold)
        tally.textColor = ATTheme.Palette.inkSoft
        control.addSubview(tally)

        let stripe = ATLensStripe()
        stripe.configure(with: dossier.themesByWeight)
        control.addSubview(stripe)

        name.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        country.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(1)
            make.leading.trailing.equalTo(name)
        }

        tally.snp.makeConstraints { make in
            make.top.equalTo(country.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalTo(name)
        }

        stripe.snp.makeConstraints { make in
            make.leading.trailing.equalTo(name)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        control.addAction(
            UIAction { [weak self] _ in
                self?.push(ATPlaceViewController(place: dossier.place))
            },
            for: .touchUpInside
        )

        return control
    }

    private func changeRow(_ hasLeft: Bool, _ hasRight: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.sm
        row.alignment = .fill

        let spacer = UIView()
        spacer.snp.makeConstraints { make in
            make.width.equalTo(labelColumn)
        }
        row.addArrangedSubview(spacer)

        let pair = UIStackView()
        pair.axis = .horizontal
        pair.spacing = ATTheme.Space.sm
        pair.distribution = .fillEqually
        pair.alignment = .fill

        let leftButton = ATGhostButton(title: hasLeft ? "Change" : "Choose")
        leftButton.addTarget(self, action: #selector(changeLeft), for: .touchUpInside)
        pair.addArrangedSubview(leftButton)

        let rightButton = ATGhostButton(title: hasRight ? "Change" : "Choose")
        rightButton.addTarget(self, action: #selector(changeRight), for: .touchUpInside)
        pair.addArrangedSubview(rightButton)

        row.addArrangedSubview(pair)
        return row
    }

    private func metricRow(_ caption: String, _ leftText: String, _ rightText: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.sm
        row.alignment = .firstBaseline

        let label = UILabel()
        label.text = caption
        label.font = ATTheme.Typeface.caption
        label.textColor = ATTheme.Palette.inkFaint
        label.snp.makeConstraints { make in
            make.width.equalTo(labelColumn)
        }
        row.addArrangedSubview(label)

        let pair = UIStackView()
        pair.axis = .horizontal
        pair.spacing = ATTheme.Space.sm
        pair.distribution = .fillEqually
        pair.alignment = .firstBaseline
        pair.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pair.addArrangedSubview(value(leftText))
        pair.addArrangedSubview(value(rightText))
        row.addArrangedSubview(pair)

        return row
    }

    private func value(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ATTheme.Typeface.mono(15, .semibold)
        label.textColor = ATTheme.Palette.ink
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }

    private func lensBlock(_ dossier: ATPlaceDossier) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ATTheme.Space.xs

        let caption = UILabel()
        caption.attributedText = ATTheme.sectionLabel(dossier.place.name, color: ATTheme.Palette.inkSoft)
        stack.addArrangedSubview(caption)

        let bar = ATLensBar()
        bar.configure(with: dossier.themesByWeight, averages: dossier.averageIntensity)
        stack.addArrangedSubview(bar)

        return stack
    }

    private func verdictCard(_ comparison: ATPlaceComparison) -> UIView {
        let card = UIView()
        card.backgroundColor = ATTheme.Palette.ink
        card.layer.cornerRadius = ATTheme.Radius.medium
        card.layer.cornerCurve = .continuous

        let caption = UILabel()
        caption.attributedText = ATTheme.sectionLabel("The reading", color: ATTheme.Palette.accent)
        card.addSubview(caption)

        let body = UILabel()
        body.text = comparison.verdict
        body.font = ATTheme.Typeface.serif(17, .semibold)
        body.textColor = ATTheme.Palette.paper
        body.numberOfLines = 0
        card.addSubview(body)

        let source = UILabel()
        let total = comparison.left.postCount + comparison.right.postCount
        source.text = "Counted from \(total) \(total == 1 ? "filing" : "filings") across the two places."
        source.font = ATTheme.Typeface.caption
        source.textColor = ATTheme.Palette.paper.withAlphaComponent(0.62)
        source.numberOfLines = 0
        card.addSubview(source)

        caption.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
        }

        body.snp.makeConstraints { make in
            make.top.equalTo(caption.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
        }

        source.snp.makeConstraints { make in
            make.top.equalTo(body.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.bottom.equalToSuperview().inset(ATTheme.Space.md)
        }

        return card
    }

    private func sectionHeader(_ title: String) -> UIView {
        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(title, color: ATTheme.Palette.mist)
        return label
    }

    private func mutedLine(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ATTheme.Typeface.sans(14.5)
        label.textColor = ATTheme.Palette.inkFaint
        label.numberOfLines = 0
        return label
    }

    private func tail() -> UIView {
        let view = UIView()
        view.snp.makeConstraints { make in
            make.height.equalTo(ATTheme.Space.xl)
        }
        return view
    }

    private func latest(_ dossier: ATPlaceDossier) -> String {
        guard let date = dossier.latestFiledAt else { return "—" }
        return ATTime.long(date)
    }

    private func intensity(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f/5", value)
    }

    // MARK: - Actions

    @objc private func changeLeft() { choose(side: 0) }

    @objc private func changeRight() { choose(side: 1) }

    private func choose(side: Int) {
        let excluding = Set([left?.key, right?.key].compactMap { $0 })
        let picker = ATPlacePickerViewController(
            title: side == 0 ? "First place" : "Second place",
            standfirst: "Pick from everywhere the library has an opinion about.",
            entries: ATToolbox.pickerEntries(allowsNotes: false),
            excluding: excluding
        ) { [weak self] place in
            guard let self else { return }
            if side == 0 {
                self.left = place
            } else {
                self.right = place
            }
            self.reload()
            self.navigationController?.popViewController(animated: true)
        }
        push(picker)
    }
}
