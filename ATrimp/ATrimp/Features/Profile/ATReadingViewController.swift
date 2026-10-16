//
//  ATReadingViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATReadingViewController: ATViewController {

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private let headline = UILabel()
    private let standfirst = UILabel()
    private let countsLabel = UILabel()
    private let readerCaption = UILabel()
    private let readerBar = ATLensBar()
    private let readerEmpty = UILabel()

    private let libraryCaption = UILabel()
    private let libraryBar = ATLensBar()
    private let libraryNote = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: "How you read")
        buildLayout()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Layout

    private func buildLayout() {
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        view.addSubview(scroll)

        column.axis = .vertical
        column.alignment = .fill
        scroll.addSubview(column)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        column.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ATTheme.Space.gutter)
            make.width.equalToSuperview().offset(-ATTheme.Space.gutter * 2)
        }

        headline.font = ATTheme.Typeface.serif(30, .semibold)
        headline.textColor = ATTheme.Palette.ink
        headline.numberOfLines = 2

        standfirst.font = ATTheme.Typeface.body
        standfirst.textColor = ATTheme.Palette.inkSoft
        standfirst.numberOfLines = 0

        countsLabel.font = ATTheme.Typeface.mono(14, .semibold)
        countsLabel.textColor = ATTheme.Palette.inkSoft
        countsLabel.numberOfLines = 0

        readerEmpty.font = ATTheme.Typeface.body
        readerEmpty.textColor = ATTheme.Palette.inkSoft
        readerEmpty.numberOfLines = 0

        libraryNote.font = ATTheme.Typeface.caption
        libraryNote.textColor = ATTheme.Palette.inkFaint
        libraryNote.numberOfLines = 0

        column.addArrangedSubview(headline)
        column.setCustomSpacing(ATTheme.Space.sm, after: headline)
        column.addArrangedSubview(standfirst)
        column.setCustomSpacing(ATTheme.Space.md, after: standfirst)
        column.addArrangedSubview(countsLabel)
        column.setCustomSpacing(ATTheme.Space.lg, after: countsLabel)

        column.addArrangedSubview(rule())
        column.setCustomSpacing(ATTheme.Space.lg, after: column.arrangedSubviews.last!)

        column.addArrangedSubview(readerCaption)
        column.setCustomSpacing(ATTheme.Space.sm, after: readerCaption)
        column.addArrangedSubview(readerBar)
        column.addArrangedSubview(readerEmpty)
        column.setCustomSpacing(ATTheme.Space.xl, after: readerEmpty)

        column.addArrangedSubview(rule())
        column.setCustomSpacing(ATTheme.Space.lg, after: column.arrangedSubviews.last!)

        column.addArrangedSubview(libraryCaption)
        column.setCustomSpacing(ATTheme.Space.sm, after: libraryCaption)
        column.addArrangedSubview(libraryBar)
        column.setCustomSpacing(ATTheme.Space.sm, after: libraryBar)
        column.addArrangedSubview(libraryNote)
        column.setCustomSpacing(ATTheme.Space.xxl, after: libraryNote)
    }

    private func rule() -> UIView {
        let rule = ATRule()
        rule.snp.makeConstraints { make in
            make.height.equalTo(ATTheme.hairline)
        }
        return rule
    }

    // MARK: - Data

    private func reload() {
        let reading = ATStore.readerReading()
        let library = ATStore.libraryThemeCounts()

        readerCaption.attributedText = ATTheme.sectionLabel("Your record", color: ATTheme.Palette.mist)
        libraryCaption.attributedText = ATTheme.sectionLabel("The library", color: ATTheme.Palette.inkSoft)

        libraryBar.configure(with: library)
        let libraryTotal = library.reduce(0) { $0 + $1.count }
        libraryNote.text = "\(libraryTotal) filings across the eight lenses. This half is the whole library, not you."

        guard !reading.isEmpty else {
            headline.text = "Nothing read yet"
            standfirst.text = "This screen is built from what you have actually done. Like a few filings, leave a comment, or publish a trip, and the shape of your reading appears here."
            countsLabel.text = "0 filed · 0 liked · 0 discussed"
            readerBar.configure(with: [])
            readerBar.isHidden = true
            readerEmpty.isHidden = false
            readerEmpty.text = "No record to read yet."
            return
        }

        let persona = ATReadingPersona.of(reading.byWeight.first?.theme)
        headline.text = persona.title
        standfirst.text = persona.blurb
        countsLabel.text = "\(reading.filedTotal) filed · \(reading.likedTotal) liked · \(reading.discussedTotal) discussed"

        readerBar.isHidden = false
        readerBar.configure(with: reading.byWeight)
        readerEmpty.isHidden = true
    }
}

// MARK: - Persona

private enum ATReadingPersona {

    struct Line {
        let title: String
        let blurb: String
    }

    static func of(_ theme: ATPostTheme?) -> Line {
        guard let theme else {
            return Line(title: "Still deciding", blurb: "Your record has no clear lean yet.")
        }
        switch theme {
        case .regret:
            return Line(
                title: "The second-draft traveller",
                blurb: "You read for what to do differently. Most of what you keep is somebody's hindsight, which is the cheapest kind of experience there is."
            )
        case .surprise:
            return Line(
                title: "The easy enthusiast",
                blurb: "You lean towards the filings where a place beat expectations. Worth remembering on the days a trip is not going well."
            )
        case .hiddenGem:
            return Line(
                title: "The quiet-route reader",
                blurb: "You look for the empty, cheap and slightly out of the way. Most of your list is places nobody has heard of yet."
            )
        case .pitfall:
            return Line(
                title: "The cost accountant",
                blurb: "You want to know what it took — money, hours, or both. You will not be the one caught out at the ticket desk."
            )
        case .wrongTurn:
            return Line(
                title: "The route planner",
                blurb: "You read for the ways a journey goes sideways. Half of your record is other people's detours."
            )
        case .overrated:
            return Line(
                title: "The sceptic",
                blurb: "You want the case against. You will still go, but you will go knowing what you are paying for."
            )
        case .luckyFind:
            return Line(
                title: "The drifter",
                blurb: "You like the accidents — the thing nobody planned. Your record reads like somebody who leaves the afternoon free."
            )
        case .longHaul:
            return Line(
                title: "The long-way-rounder",
                blurb: "You read the journeys, not the arrivals. Twelve hours in transit is part of the trip, not a gap between two of them."
            )
        }
    }
}
