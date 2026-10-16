//
//  ATDrawViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATDrawViewController: ATViewController {

    private let tileWidth: CGFloat = 200
    private let tileSpacing: CGFloat = 12
    private let landingIndex = 24
    private let reelCount = 26

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private let standfirst = UILabel()
    private let window = UIView()
    private let reel = UIStackView()
    private let drawButton = ATPrimaryButton(title: "Draw a place")
    private let resultCard = UIView()
    private let resultName = UILabel()
    private let resultCountry = UILabel()
    private let resultHeadline = UILabel()
    private let resultNote = UILabel()
    private let actions = UIStackView()

    private var pool: [ATDrawCandidate] = []
    private var pendingNote: ATNote?
    private var lastWinner: ATDrawCandidate?
    private var isDrawing = false

    private var pitch: CGFloat { tileWidth + tileSpacing }

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: "Next stop")
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

        standfirst.font = ATTheme.Typeface.body
        standfirst.textColor = ATTheme.Palette.inkSoft
        standfirst.numberOfLines = 0

        column.addArrangedSubview(standfirst)
        column.setCustomSpacing(ATTheme.Space.lg, after: standfirst)

        buildWindow()
        column.addArrangedSubview(window)
        column.setCustomSpacing(ATTheme.Space.lg, after: window)

        drawButton.addTarget(self, action: #selector(handleDraw), for: .touchUpInside)
        column.addArrangedSubview(drawButton)
        column.setCustomSpacing(ATTheme.Space.lg, after: drawButton)

        buildResultCard()
        column.addArrangedSubview(resultCard)
        column.setCustomSpacing(ATTheme.Space.sm, after: resultCard)

        actions.axis = .vertical
        actions.alignment = .fill
        actions.spacing = ATTheme.Space.xs
        column.addArrangedSubview(actions)

        let tail = UIView()
        tail.snp.makeConstraints { make in
            make.height.equalTo(ATTheme.Space.xxl)
        }
        column.addArrangedSubview(tail)
    }

    private func buildWindow() {
        window.backgroundColor = ATTheme.Palette.paperDeep
        window.layer.cornerRadius = ATTheme.Radius.medium
        window.layer.cornerCurve = .continuous
        window.clipsToBounds = true

        reel.axis = .horizontal
        reel.spacing = tileSpacing
        reel.alignment = .fill
        window.addSubview(reel)

        let left = ATFadeView(fadesToRight: false)
        window.addSubview(left)

        let right = ATFadeView(fadesToRight: true)
        window.addSubview(right)

        window.snp.makeConstraints { make in
            make.height.equalTo(120)
        }

        reel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(96)
        }

        left.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(24)
        }

        right.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalTo(24)
        }
    }

    private func buildResultCard() {
        resultCard.backgroundColor = ATTheme.Palette.paperRaised
        resultCard.layer.cornerRadius = ATTheme.Radius.medium
        resultCard.layer.cornerCurve = .continuous
        resultCard.alpha = 0
        ATTheme.Elevation.apply(to: resultCard, level: 1)

        resultName.font = ATTheme.Typeface.serif(26, .semibold)
        resultName.textColor = ATTheme.Palette.ink
        resultName.numberOfLines = 2
        resultCard.addSubview(resultName)

        resultCountry.font = ATTheme.Typeface.sans(13, .medium)
        resultCountry.textColor = ATTheme.Palette.inkFaint
        resultCard.addSubview(resultCountry)

        resultHeadline.font = ATTheme.Typeface.caption
        resultHeadline.textColor = ATTheme.Palette.inkSoft
        resultHeadline.numberOfLines = 0
        resultCard.addSubview(resultHeadline)

        resultNote.font = ATTheme.Typeface.serif(15.5)
        resultNote.textColor = ATTheme.Palette.ink
        resultNote.numberOfLines = 0
        resultCard.addSubview(resultNote)

        resultName.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
        }

        resultCountry.snp.makeConstraints { make in
            make.top.equalTo(resultName.snp.bottom).offset(2)
            make.leading.trailing.equalTo(resultName)
        }

        resultHeadline.snp.makeConstraints { make in
            make.top.equalTo(resultCountry.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalTo(resultName)
        }

        resultNote.snp.makeConstraints { make in
            make.top.equalTo(resultHeadline.snp.bottom).offset(ATTheme.Space.sm)
            make.leading.trailing.equalTo(resultName)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.md)
        }
    }

    // MARK: - Data

    @objc private func reload() {
        guard !isDrawing else { return }

        pool = ATToolbox.drawPool()

        let hasNotes = pool.contains {
            if case .note = $0.origin { return true }
            return false
        }
        standfirst.text = hasNotes
            ? "Somewhere you said you would go — or somewhere else in the library. You do not get to argue."
            : "Nothing kept yet, so this is the whole library. You do not get to argue."

        drawButton.isEnabled = !pool.isEmpty
        buildReel(landingOn: lastWinner)
    }

    private func buildReel(landingOn winner: ATDrawCandidate?) {
        reel.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !pool.isEmpty else { return }

        let start = winner.flatMap { candidate in
            pool.firstIndex { $0.place.key == candidate.place.key }
        } ?? 0

        for index in 0..<reelCount {
            let candidate: ATDrawCandidate
            if let winner, index == landingIndex {
                candidate = winner
            } else {
                candidate = pool[(start + index) % pool.count]
            }
            let tile = ATDrawTile(candidate: candidate)
            reel.addArrangedSubview(tile)
            tile.snp.makeConstraints { make in
                make.width.equalTo(tileWidth)
            }
        }

        reel.transform = .identity
    }

    // MARK: - Actions

    @objc private func handleDraw() {
        guard !isDrawing, let winner = ATToolbox.draw(from: pool) else { return }

        isDrawing = true
        lastWinner = winner
        drawButton.isEnabled = false
        resultCard.alpha = 0
        actions.arrangedSubviews.forEach { $0.removeFromSuperview() }

        buildReel(landingOn: winner)
        window.layoutIfNeeded()

        let offset = window.bounds.width / 2 - (CGFloat(landingIndex) * pitch + tileWidth / 2)

        UIView.animate(withDuration: 1.25, delay: 0, options: [.curveEaseOut]) {
            self.reel.transform = CGAffineTransform(translationX: offset, y: 0)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.isDrawing = false
            self.drawButton.isEnabled = true
            self.drawButton.setTitle("Draw again", for: .normal)
            self.settle(winner)
        }
    }

    private func settle(_ candidate: ATDrawCandidate) {
        resultName.text = candidate.place.name
        resultCountry.text = candidate.place.country
        resultHeadline.text = candidate.headline

        if let body = candidate.noteBody, !body.isEmpty {
            resultNote.text = "You wrote: \(body)"
            resultNote.isHidden = false
        } else {
            resultNote.text = nil
            resultNote.isHidden = true
        }

        rebuildActions(candidate)

        UIView.animate(withDuration: 0.28) {
            self.resultCard.alpha = 1
        }
    }

    private func rebuildActions(_ candidate: ATDrawCandidate) {
        actions.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pendingNote = nil

        let open = ATGhostButton(title: "Open the dossier")
        open.addTarget(self, action: #selector(openDossier), for: .touchUpInside)
        actions.addArrangedSubview(open)

        if case let .note(note) = candidate.origin {
            pendingNote = note
            let done = ATGhostButton(title: "Mark that note done")
            done.addTarget(self, action: #selector(markNoteDone), for: .touchUpInside)
            actions.addArrangedSubview(done)
        }
    }

    @objc private func openDossier() {
        guard let place = landedPlace else { return }
        push(ATPlaceViewController(place: place))
    }

    @objc private func markNoteDone() {
        guard let note = pendingNote else { return }
        ATStore.setNoteResolved(true, id: note.id)
        pendingNote = nil
        actions.arrangedSubviews.forEach { $0.removeFromSuperview() }
        showToast("Done.")
        reload()
    }

    private var landedPlace: ATPlace? {
        guard reel.arrangedSubviews.indices.contains(landingIndex),
              let tile = reel.arrangedSubviews[landingIndex] as? ATDrawTile
        else { return nil }
        return tile.place
    }
}

// MARK: - Tile

private final class ATDrawTile: UIView {

    let place: ATPlace

    init(candidate: ATDrawCandidate) {
        self.place = candidate.place
        super.init(frame: .zero)

        backgroundColor = ATTheme.Palette.paperRaised
        layer.cornerRadius = ATTheme.Radius.small
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let name = UILabel()
        name.text = candidate.place.name
        name.font = ATTheme.Typeface.serif(19, .semibold)
        name.textColor = ATTheme.Palette.ink
        name.numberOfLines = 2
        addSubview(name)

        let country = UILabel()
        country.text = candidate.place.country
        country.font = ATTheme.Typeface.caption
        country.textColor = ATTheme.Palette.inkFaint
        country.numberOfLines = 1
        addSubview(country)

        name.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ATTheme.Space.sm)
        }

        country.snp.makeConstraints { make in
            make.top.equalTo(name.snp.bottom).offset(2)
            make.leading.trailing.equalTo(name)
        }

        if let theme = candidate.dominantTheme {
            let chip = ATThemeChip(theme: theme, compact: true)
            addSubview(chip)

            chip.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(ATTheme.Space.sm)
                make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

// MARK: - Fade

private final class ATFadeView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    init(fadesToRight: Bool) {
        super.init(frame: .zero)

        isUserInteractionEnabled = false

        guard let gradient = layer as? CAGradientLayer else { return }
        let opaque = ATTheme.Palette.paper.withAlphaComponent(1).cgColor
        let clear = ATTheme.Palette.paper.withAlphaComponent(0).cgColor
        gradient.colors = fadesToRight ? [opaque, clear] : [clear, opaque]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}
