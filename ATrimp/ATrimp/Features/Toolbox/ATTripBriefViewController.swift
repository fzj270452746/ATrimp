//
//  ATTripBriefViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATTripBriefViewController: ATViewController {

    private let place: ATPlace

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private var lastSignature = ""

    init(place: ATPlace) {
        self.place = place
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: place.name)
        bar.addTrailing(symbol: "square.and.arrow.up", action: #selector(handleShare), target: self)

        buildScroll()

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
        let brief = ATToolbox.brief(for: place)
        let signature = [
            place.key,
            "\(brief.dossier.postCount)",
            "\(brief.notes.count)",
            "\(brief.notes.filter(\.isResolved).count)",
        ].joined(separator: "|")

        guard signature != lastSignature else { return }
        lastSignature = signature

        rebuild(brief)
    }

    private func rebuild(_ brief: ATPlaceBrief) {
        let offset = scroll.contentOffset

        column.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let authors = ATStore.users(
            ids: Array(Set((brief.pitfalls + brief.rewards).map(\.authorID)))
        )

        let head = buildHead(brief.dossier)
        column.addArrangedSubview(head)
        column.setCustomSpacing(ATTheme.Space.lg, after: head)

        let headline = buildHeadline(brief.headline)
        column.addArrangedSubview(headline)
        column.setCustomSpacing(ATTheme.Space.xl, after: headline)

        let costHeader = sectionHeader("What it cost people", tally: brief.pitfalls.count)
        column.addArrangedSubview(costHeader)
        column.setCustomSpacing(ATTheme.Space.xs, after: costHeader)
        if brief.pitfalls.isEmpty {
            let muted = mutedLine("Nobody has warned about this place yet.")
            column.addArrangedSubview(muted)
            column.setCustomSpacing(ATTheme.Space.xl, after: muted)
        } else {
            for (index, post) in brief.pitfalls.enumerated() {
                let row = framedPost(post, author: authors[post.authorID])
                column.addArrangedSubview(row)
                column.setCustomSpacing(
                    index == brief.pitfalls.count - 1 ? ATTheme.Space.xl : ATTheme.Space.md,
                    after: row
                )
            }
        }

        let detourHeader = sectionHeader("Worth the detour", tally: brief.rewards.count)
        column.addArrangedSubview(detourHeader)
        column.setCustomSpacing(ATTheme.Space.xs, after: detourHeader)
        if brief.rewards.isEmpty {
            let muted = mutedLine("Nobody has called this one out yet.")
            column.addArrangedSubview(muted)
            column.setCustomSpacing(ATTheme.Space.xl, after: muted)
        } else {
            for (index, post) in brief.rewards.enumerated() {
                let row = framedPost(post, author: authors[post.authorID])
                column.addArrangedSubview(row)
                column.setCustomSpacing(
                    index == brief.rewards.count - 1 ? ATTheme.Space.xl : ATTheme.Space.md,
                    after: row
                )
            }
        }

        let notesHeader = sectionHeader("What you told yourself", tally: brief.notes.isEmpty ? nil : brief.notes.count)
        column.addArrangedSubview(notesHeader)
        column.setCustomSpacing(ATTheme.Space.xs, after: notesHeader)
        column.addArrangedSubview(buildNotes(brief.notes))

        let tail = UIView()
        tail.snp.makeConstraints { make in
            make.height.equalTo(ATTheme.Space.xxl)
        }
        column.addArrangedSubview(tail)

        scroll.layoutIfNeeded()
        let limit = max(0, scroll.contentSize.height - scroll.bounds.height)
        scroll.setContentOffset(CGPoint(x: 0, y: min(offset.y, limit)), animated: false)
    }

    // MARK: - Pieces

    private func buildHead(_ dossier: ATPlaceDossier) -> UIView {
        let container = UIView()

        let name = UILabel()
        name.text = dossier.place.name
        name.font = ATTheme.Typeface.serif(30, .semibold)
        name.textColor = ATTheme.Palette.ink
        name.numberOfLines = 2
        container.addSubview(name)

        let country = UILabel()
        country.text = dossier.place.country
        country.font = ATTheme.Typeface.sans(13, .medium)
        country.textColor = ATTheme.Palette.inkFaint
        country.isHidden = dossier.place.country.isEmpty
        container.addSubview(country)

        let metrics = UIStackView()
        metrics.axis = .horizontal
        metrics.spacing = ATTheme.Space.md
        metrics.alignment = .center
        metrics.addArrangedSubview(
            ATMetricLabel(
                symbol: "doc.text",
                text: "\(dossier.postCount) \(dossier.postCount == 1 ? "filing" : "filings")"
            )
        )
        metrics.addArrangedSubview(
            ATMetricLabel(
                symbol: "person.2",
                text: "\(dossier.authorCount) \(dossier.authorCount == 1 ? "traveller" : "travellers")"
            )
        )
        if let first = dossier.firstFiledAt {
            let year = Calendar.current.component(.year, from: first)
            metrics.addArrangedSubview(ATMetricLabel(symbol: "calendar", text: "since \(year)"))
        }
        container.addSubview(metrics)

        let rule = ATRule()
        container.addSubview(rule)

        name.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        country.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }

        metrics.snp.makeConstraints { make in
            make.top.equalTo(country.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.lessThanOrEqualToSuperview()
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(metrics.snp.bottom).offset(ATTheme.Space.md)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return container
    }

    private func buildHeadline(_ text: String) -> UIView {
        let container = UIView()

        let caption = UILabel()
        caption.attributedText = ATTheme.sectionLabel("The short version", color: ATTheme.Palette.accent)
        container.addSubview(caption)

        let body = UILabel()
        body.text = text
        body.font = ATTheme.Typeface.serif(17, .semibold)
        body.textColor = ATTheme.Palette.ink
        body.numberOfLines = 0
        container.addSubview(body)

        caption.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        body.snp.makeConstraints { make in
            make.top.equalTo(caption.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.bottom.equalToSuperview()
        }

        return container
    }

    private func buildNotes(_ notes: [ATNote]) -> UIView {
        guard ATSession.shared.isSignedIn else { return signInRow() }
        guard !notes.isEmpty else {
            return mutedLine("Nothing kept for this place yet. Open a filing and press “Keep a note”.")
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = ATTheme.Space.md
        for note in notes {
            stack.addArrangedSubview(noteRow(note))
        }
        return stack
    }

    private func sectionHeader(_ title: String, tally: Int?) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(title, color: ATTheme.Palette.mist)
        container.addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        if let tally {
            let count = UILabel()
            count.text = "\(tally)"
            count.font = ATTheme.Typeface.mono(13, .semibold)
            count.textColor = ATTheme.Palette.inkFaint
            container.addSubview(count)

            count.snp.makeConstraints { make in
                make.trailing.centerY.equalToSuperview()
                make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(ATTheme.Space.xs)
            }
        }

        return container
    }

    private func mutedLine(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = ATTheme.Typeface.sans(14.5)
        label.textColor = ATTheme.Palette.inkFaint
        label.numberOfLines = 0
        return label
    }

    private func framedPost(_ post: ATPost, author: ATUser?) -> UIView {
        let control = UIControl()

        let top = UIStackView()
        top.axis = .horizontal
        top.spacing = ATTheme.Space.xs
        top.alignment = .center
        top.addArrangedSubview(ATThemeChip(theme: post.theme, compact: true))

        let mark = ATIntensityMark()
        mark.configure(value: post.intensity, tint: post.theme.tint)
        top.addArrangedSubview(mark)

        let slack = UIView()
        slack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        top.addArrangedSubview(slack)
        control.addSubview(top)

        let body = UILabel()
        body.text = post.body
        body.font = ATTheme.Typeface.sans(14.5)
        body.textColor = ATTheme.Palette.ink
        body.numberOfLines = 3
        control.addSubview(body)

        let meta = UILabel()
        meta.text = [ATTime.compact(post.createdAt), author?.displayName ?? "Someone"]
            .joined(separator: " · ")
        meta.font = ATTheme.Typeface.caption
        meta.textColor = ATTheme.Palette.inkFaint
        control.addSubview(meta)

        let rule = ATRule()
        control.addSubview(rule)

        top.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        body.snp.makeConstraints { make in
            make.top.equalTo(top.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
        }

        meta.snp.makeConstraints { make in
            make.top.equalTo(body.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview()
        }

        rule.snp.makeConstraints { make in
            make.top.equalTo(meta.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.bottom.equalToSuperview()
        }

        control.addAction(
            UIAction { [weak self] _ in
                self?.push(ATPostDetailViewController(postID: post.id))
            },
            for: .touchUpInside
        )

        return control
    }

    private func noteRow(_ note: ATNote) -> UIView {
        let container = UIView()
        let done = note.isResolved

        let tick = UIControl()
        tick.layer.borderWidth = 1
        tick.layer.cornerRadius = 11
        tick.backgroundColor = done ? ATTheme.Palette.mist : .clear
        tick.layer.borderColor = (done ? ATTheme.Palette.mist : ATTheme.Palette.inkSoft).cgColor
        tick.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                ATStore.setNoteResolved(!done, id: note.id)
                self.reload()
            },
            for: .touchUpInside
        )
        container.addSubview(tick)

        let mark = UIImageView(
            image: UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
            )
        )
        mark.tintColor = ATTheme.Palette.paper
        mark.contentMode = .center
        mark.alpha = done ? 1 : 0
        tick.addSubview(mark)

        let body = UILabel()
        body.numberOfLines = 0
        body.attributedText = NSAttributedString(
            string: note.body,
            attributes: [
                .font: ATTheme.Typeface.sans(15),
                .foregroundColor: done ? ATTheme.Palette.inkFaint : ATTheme.Palette.ink,
                .strikethroughStyle: done ? NSUnderlineStyle.single.rawValue : 0,
                .strikethroughColor: ATTheme.Palette.inkFaint,
            ]
        )
        container.addSubview(body)

        tick.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(1)
            make.width.height.equalTo(22)
        }

        mark.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        body.snp.makeConstraints { make in
            make.leading.equalTo(tick.snp.trailing).offset(ATTheme.Space.sm)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        return container
    }

    private func signInRow() -> UIView {
        let control = UIControl()
        control.backgroundColor = ATTheme.Palette.paperDeep
        control.layer.cornerRadius = ATTheme.Radius.small
        control.layer.cornerCurve = .continuous

        let label = UILabel()
        label.text = "Sign in to see anything you kept here."
        label.font = ATTheme.Typeface.sans(14.5)
        label.textColor = ATTheme.Palette.accent
        label.numberOfLines = 0
        control.addSubview(label)

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ATTheme.Space.md)
        }

        control.addAction(
            UIAction { [weak self] _ in
                guard let self, !self.requireSignIn(message: "Sign in to keep notes about a place.") else { return }
                self.reload()
            },
            for: .touchUpInside
        )

        return control
    }

    // MARK: - Actions

    @objc private func handleShare() {
        share(cardFor: ATStore.dossier(for: place), from: navBar?.trailingView)
    }
}
