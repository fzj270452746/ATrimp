//
//  ATWrappedViewController.swift
//  ATrimp
//
//
//
import SnapKit
import UIKit

final class ATWrappedViewController: ATViewController {

    private let scroller = UIScrollView()
    private let pages = UIStackView()
    private let dots = UIStackView()

    private var wrapped = ATDigest.wrapped()
    private var pageViews: [ATWrappedPage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let bar = installNavBar(title: "The year")
        bar.addTrailing(symbol: "square.and.arrow.up", action: #selector(handleShare), target: self)

        wrapped = ATDigest.wrapped()

        buildScroller()
        buildPages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let latest = ATDigest.wrapped()
        if latest.filings != wrapped.filings || latest.readerFiled != wrapped.readerFiled {
            wrapped = latest
            buildPages()
        }
    }

    // MARK: - Layout

    private func buildScroller() {
        scroller.isPagingEnabled = true
        scroller.showsHorizontalScrollIndicator = false
        scroller.showsVerticalScrollIndicator = false
        scroller.contentInsetAdjustmentBehavior = .never
        scroller.delegate = self
        view.addSubview(scroller)

        pages.axis = .horizontal
        pages.alignment = .fill
        pages.distribution = .fillEqually
        scroller.addSubview(pages)

        dots.axis = .horizontal
        dots.spacing = 6
        dots.alignment = .center
        view.addSubview(dots)

        scroller.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(dots.snp.top).offset(-ATTheme.Space.sm)
        }

        pages.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(CGFloat(max(1, pageCount)))
        }

        dots.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.md)
            make.height.equalTo(8)
        }
    }

    private var pageCount: Int { pageViews.count }

    // MARK: - Pages

    private func buildPages() {
        pages.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()

        for page in makePages() {
            pageViews.append(page)
            pages.addArrangedSubview(page)
        }

        rebuildDots()
        updateDots()

        pages.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(CGFloat(max(1, pageViews.count)))
        }
    }

    private func makePages() -> [ATWrappedPage] {

        var result: [ATWrappedPage] = []

        result.append(ATWrappedPage(
            caption: "ATrimp · \(wrapped.periodPhrase)",
            headline: "The year in\nsecond thoughts",
            detail: "\(wrapped.filings) filings from \(wrapped.travellers) travellers, across \(wrapped.places) places.",
            foot: "Swipe",
            tint: ATTheme.Palette.accent,
            dark: true
        ))

        result.append(ATWrappedPage(
            caption: "Reach",
            headline: "\(wrapped.countries)",
            headlineSuffix: wrapped.countries == 1 ? "country" : "countries",
            detail: "Spread over \(wrapped.places) places. The library is small and far-flung rather than deep — most places carry one filing and no more.",
            foot: nil,
            tint: ATTheme.Palette.mist,
            dark: false
        ))

        let dominant = wrapped.dominantLens
        let lensPage = ATWrappedPage(
            caption: "The shape of it",
            headline: dominant?.title ?? "Nothing yet",
            detail: dominant.map {
                "\(wrapped.lenses.first?.count ?? 0) of \(wrapped.filings) filings read as \($0.title.lowercased()). The eight lenses are most of what this library has to say, so the mixture is the point."
            } ?? "Nothing has been filed yet.",
            foot: nil,
            tint: dominant?.tint ?? ATTheme.Palette.inkSoft,
            dark: false
        )
        lensPage.attachLensBar(wrapped.lenses)
        result.append(lensPage)

        if let busiest = wrapped.busiest {
            let page = ATWrappedPage(
                caption: "Most filed",
                headline: busiest.dossier.place.name,
                headlineSuffix: busiest.dossier.place.country,
                detail: "\(busiest.score) filings from \(busiest.dossier.authorCount) travellers. Somewhere enough people have been, and disagreed about, to be worth reading before you go.",
                foot: nil,
                tint: busiest.dossier.dominantTheme?.tint ?? ATTheme.Palette.inkSoft,
                dark: true
            )
            page.attachStripe(busiest.dossier.themesByWeight)
            result.append(page)
        }

        if let regretted = wrapped.mostRegretted {
            let page = ATWrappedPage(
                caption: "Most regretted",
                headline: regretted.dossier.place.name,
                headlineSuffix: regretted.dossier.place.country,
                detail: "\(regretted.score) filings land on the lenses that went badly. The most useful page in the library, and the one nobody writes before they leave.",
                foot: nil,
                tint: ATPostTheme.regret.tint,
                dark: false
            )
            page.attachStripe(regretted.dossier.themesByWeight)
            result.append(page)
        }

        result.append(ATWrappedPage(
            caption: "Answered",
            headline: "\(wrapped.answered)",
            headlineSuffix: wrapped.answered == 1 ? "filing went back" : "filings went back",
            detail: "A regret stops being the last word on a place the moment somebody returns and writes what changed. That is the whole idea, and this is how often it happened.",
            foot: nil,
            tint: ATPostTheme.surprise.tint,
            dark: true
        ))

        result.append(ATWrappedPage(
            caption: "Your part",
            headline: wrapped.hasReaderPart ? "\(wrapped.readerFiled)" : "Nothing yet",
            headlineSuffix: wrapped.hasReaderPart
                ? (wrapped.readerFiled == 1 ? "filing of yours" : "filings of yours")
                : nil,
            detail: readerDetail(),
            foot: nil,
            tint: ATTheme.Palette.accent,
            dark: false
        ))

        return result
    }

    private func readerDetail() -> String {
        guard wrapped.hasReaderPart else {
            return "The library is not yours to begin with, and this screen will not pretend otherwise. File a trip, keep a note, or mark something “same here”, and your part appears here."
        }

        var lines = [
            "\(wrapped.readerFiled) filed",
            "\(wrapped.readerLiked) liked",
            "\(wrapped.readerRecognised) marked same here",
        ]
        if wrapped.readerNotes > 0 {
            lines.append("\(wrapped.readerNotesDone) of \(wrapped.readerNotes) notes done")
        }
        if wrapped.readerRevisits > 0 {
            lines.append("\(wrapped.readerRevisits) returns written")
        }
        return lines.joined(separator: " · ") + ". Everything here is counted from what you did, not from a score."
    }

    // MARK: - Dots

    private func rebuildDots() {
        dots.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for _ in pageViews {
            let dot = UIView()
            dot.layer.cornerRadius = 3
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(6)
            }
            dots.addArrangedSubview(dot)
        }
    }

    private func updateDots() {
        let width = max(1, scroller.bounds.width)
        let current = Int((scroller.contentOffset.x / width).rounded())

        for (index, dot) in dots.arrangedSubviews.enumerated() {
            let active = index == current
            dot.backgroundColor = active
                ? ATTheme.Palette.ink
                : ATTheme.Palette.ruleStrong
        }
    }

    // MARK: - Actions

    @objc private func handleShare() {
        share(card: ATCardRenderer.card(for: wrapped), from: navBar?.trailingView)
    }
}

// MARK: - Pages

extension ATWrappedViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDots()
    }
}

// MARK: - One panel

private final class ATWrappedPage: UIView {

    private let captionLabel = UILabel()
    private let headlineLabel = UILabel()
    private let suffixLabel = UILabel()
    private let detailLabel = UILabel()
    private let footLabel = UILabel()

    private var accessory: UIView?

    init(
        caption: String,
        headline: String,
        headlineSuffix: String? = nil,
        detail: String,
        foot: String?,
        tint: UIColor,
        dark: Bool
    ) {
        super.init(frame: .zero)

        backgroundColor = dark ? ATTheme.Palette.ink : ATTheme.Palette.paper
        let foreground = dark ? ATTheme.Palette.paper : ATTheme.Palette.ink

        captionLabel.attributedText = ATTheme.sectionLabel(caption, color: tint)
        captionLabel.numberOfLines = 2
        addSubview(captionLabel)

        headlineLabel.text = headline
        headlineLabel.font = ATTheme.Typeface.serif(46, .semibold)
        headlineLabel.textColor = foreground
        headlineLabel.numberOfLines = 4
        headlineLabel.adjustsFontSizeToFitWidth = true
        headlineLabel.minimumScaleFactor = 0.6
        addSubview(headlineLabel)

        suffixLabel.text = headlineSuffix
        suffixLabel.font = ATTheme.Typeface.serif(20, .semibold)
        suffixLabel.textColor = dark ? ATTheme.Palette.paper.withAlphaComponent(0.6) : ATTheme.Palette.inkFaint
        suffixLabel.numberOfLines = 2
        addSubview(suffixLabel)

        detailLabel.text = detail
        detailLabel.font = ATTheme.Typeface.sans(15)
        detailLabel.textColor = dark
            ? ATTheme.Palette.paper.withAlphaComponent(0.78)
            : ATTheme.Palette.inkSoft
        detailLabel.numberOfLines = 0
        addSubview(detailLabel)

        footLabel.attributedText = foot.map { ATTheme.sectionLabel($0, color: tint) }
        footLabel.numberOfLines = 1
        addSubview(footLabel)

        captionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(56)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
        }

        footLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.xxl)
        }

        layOutContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func layOutContent() {
        headlineLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
            make.centerY.equalToSuperview().offset(-30)
        }

        var previous: ConstraintItem = headlineLabel.snp.bottom

        if let accessory {
            accessory.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
                make.top.equalTo(previous).offset(ATTheme.Space.lg)
            }
            previous = accessory.snp.bottom
        }

        if suffixLabel.text?.isEmpty == false {
            suffixLabel.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
                make.top.equalTo(previous).offset(ATTheme.Space.xs)
            }
            previous = suffixLabel.snp.bottom
        }

        detailLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
            make.top.greaterThanOrEqualTo(previous).offset(ATTheme.Space.md)
            make.bottom.equalTo(footLabel.snp.top).offset(-ATTheme.Space.lg)
        }
    }

    func attachLensBar(_ entries: [(theme: ATPostTheme, count: Int)]) {
        let bar = ATLensBar()
        bar.configure(with: entries)
        addSubview(bar)
        accessory = bar
        layOutContent()
    }

    func attachStripe(_ entries: [(theme: ATPostTheme, count: Int)]) {
        let stripe = ATLensStripe()
        stripe.configure(with: entries)
        addSubview(stripe)
        accessory = stripe
        layOutContent()
    }
}
