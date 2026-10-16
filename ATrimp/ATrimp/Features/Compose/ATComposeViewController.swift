//
//  ATComposeViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATComposeViewController: ATViewController {

    private let scrollView = UIScrollView()
    private let content = UIStackView()

    private let themePicker = ATThemePicker()
    private let placeField = ATFieldRow(caption: "Place", placeholder: "Kyoto")
    private let countryField = ATFieldRow(caption: "Country", placeholder: "Japan")
    private let storyLabel = UILabel()
    private let storyView = UITextView()
    private let storyPlaceholder = UILabel()

    private let mediaStrip = UIStackView()
    private let addPhotosButton = ATGhostButton(title: "Add photos")
    private let addVideoButton = ATGhostButton(title: "Add a video")
    private let mediaHint = UILabel()

    private let eulaCheckbox = ATCheckbox(text: "")
    private let eulaLink = UIButton(type: .system)
    private let publishButton = ATPrimaryButton(title: "Publish")

    private let guidance = UIStackView()
    private let questionStack = UIStackView()
    private let scaffoldButton = ATGhostButton(title: "Start from this shape")
    private let intensityCaption = UILabel()
    private let intensityPicker = ATIntensityPicker()

    private var images: [UIImage] = []
    private var videoURL: URL?
    private let picker = ATMediaPicker()

    private let maximumImages = 6

    override func viewDidLoad() {
        super.viewDidLoad()

        buildScroll()
        buildContent()
        refreshMedia()
        refreshPublishState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.contentInset.bottom = ATTheme.Space.xl
        scrollView.verticalScrollIndicatorInsets.bottom = ATTheme.Space.xl
    }

    // MARK: - Layout

    private func buildScroll() {
        let bar = installNavBar(title: "File a trip")

        view.addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.addSubview(content)

        content.axis = .vertical
        content.spacing = ATTheme.Space.lg
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: ATTheme.Space.lg,
            leading: ATTheme.Space.gutter,
            bottom: ATTheme.Space.lg,
            trailing: ATTheme.Space.gutter
        )

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(bar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }
    }

    private func buildContent() {
        let standfirst = UILabel()
        standfirst.text = "What actually happened, rather than what you planned."
        standfirst.font = ATTheme.Typeface.sans(14)
        standfirst.textColor = ATTheme.Palette.inkFaint
        standfirst.numberOfLines = 0
        content.addArrangedSubview(standfirst)
        content.setCustomSpacing(ATTheme.Space.lg, after: standfirst)

        themePicker.onSelect = { [weak self] _ in
            self?.refreshGuidance()
            self?.refreshPublishState()
        }

        content.addArrangedSubview(sectionLabel("Lens"))
        content.addArrangedSubview(themePicker)

        buildGuidance()
        content.addArrangedSubview(guidance)
        content.setCustomSpacing(ATTheme.Space.xl, after: guidance)

        content.addArrangedSubview(sectionLabel("Where"))
        content.addArrangedSubview(placeField)
        content.addArrangedSubview(countryField)
        content.setCustomSpacing(ATTheme.Space.xl, after: countryField)

        content.addArrangedSubview(sectionLabel("What happened"))
        content.addArrangedSubview(storyContainer())
        content.setCustomSpacing(ATTheme.Space.xl, after: content.arrangedSubviews.last!)

        content.addArrangedSubview(sectionLabel("Media"))
        content.addArrangedSubview(mediaContainer())
        content.setCustomSpacing(ATTheme.Space.xl, after: content.arrangedSubviews.last!)

        content.addArrangedSubview(sectionLabel("Before you publish"))
        content.addArrangedSubview(eulaContainer())
        content.setCustomSpacing(ATTheme.Space.lg, after: content.arrangedSubviews.last!)

        publishButton.addTarget(self, action: #selector(handlePublish), for: .touchUpInside)
        content.addArrangedSubview(publishButton)

        let note = UILabel()
        note.text = "Filed trips appear on your profile and in the feed. You can remove one at any time from your works."
        note.font = ATTheme.Typeface.sans(11.5)
        note.textColor = ATTheme.Palette.inkFaint
        note.numberOfLines = 0
        content.addArrangedSubview(note)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(text)
        return label
    }

    private func buildGuidance() {
        guidance.axis = .vertical
        guidance.spacing = ATTheme.Space.sm
        guidance.isHidden = true

        questionStack.axis = .vertical
        questionStack.spacing = ATTheme.Space.xxs
        guidance.addArrangedSubview(questionStack)

        intensityCaption.font = ATTheme.Typeface.caption
        intensityCaption.textColor = ATTheme.Palette.inkSoft
        intensityCaption.numberOfLines = 0
        guidance.setCustomSpacing(ATTheme.Space.md, after: questionStack)
        guidance.addArrangedSubview(intensityCaption)
        guidance.setCustomSpacing(ATTheme.Space.xs, after: intensityCaption)
        guidance.addArrangedSubview(intensityPicker)

        scaffoldButton.addTarget(self, action: #selector(useScaffold), for: .touchUpInside)
        guidance.setCustomSpacing(ATTheme.Space.md, after: intensityPicker)
        guidance.addArrangedSubview(scaffoldButton)
    }

    private func refreshGuidance() {
        guard let theme = themePicker.selected else {
            guidance.isHidden = true
            return
        }
        guidance.isHidden = false

        questionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for question in theme.guidingQuestions {
            questionStack.addArrangedSubview(questionRow(question, tint: theme.tint))
        }

        intensityPicker.accent = theme.tint
        intensityCaption.text = theme.intensityPrompt
    }

    private func questionRow(_ text: String, tint: UIColor) -> UIView {
        let container = UIView()

        let configuration = UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        let bullet = UIImageView(image: UIImage(systemName: "circle", withConfiguration: configuration))
        bullet.tintColor = tint
        container.addSubview(bullet)

        let label = UILabel()
        label.text = text
        label.font = ATTheme.Typeface.sans(14)
        label.textColor = ATTheme.Palette.inkSoft
        label.numberOfLines = 0
        container.addSubview(label)

        bullet.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(5)
            make.width.height.equalTo(10)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(bullet.snp.trailing).offset(ATTheme.Space.xs)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        return container
    }

    @objc private func useScaffold() {
        guard let theme = themePicker.selected else { return }
        guard storyView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showToast("You have already started writing.")
            return
        }
        storyView.text = theme.scaffold
        storyPlaceholder.isHidden = true
        storyView.becomeFirstResponder()
        refreshPublishState()
    }

    private func storyContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paperRaised
        container.layer.cornerRadius = ATTheme.Radius.small
        container.layer.borderWidth = ATTheme.hairline
        container.layer.borderColor = ATTheme.Palette.rule.cgColor

        storyView.font = ATTheme.Typeface.sans(15.5)
        storyView.textColor = ATTheme.Palette.ink
        storyView.backgroundColor = .clear
        storyView.tintColor = ATTheme.Palette.accent
        storyView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        storyView.delegate = self
        storyView.isScrollEnabled = false
        container.addSubview(storyView)

        storyPlaceholder.text = "The detour, the queue, the place nobody mentioned."
        storyPlaceholder.font = ATTheme.Typeface.sans(15.5)
        storyPlaceholder.textColor = ATTheme.Palette.inkFaint
        storyPlaceholder.numberOfLines = 0
        container.addSubview(storyPlaceholder)

        storyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(128)
        }

        storyPlaceholder.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }

        return container
    }

    private func mediaContainer() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = ATTheme.Space.sm

        mediaStrip.axis = .horizontal
        mediaStrip.spacing = ATTheme.Space.xs
        mediaStrip.alignment = .leading
        container.addArrangedSubview(mediaStrip)

        let buttons = UIStackView(arrangedSubviews: [addPhotosButton, addVideoButton])
        buttons.axis = .horizontal
        buttons.spacing = ATTheme.Space.xs
        container.addArrangedSubview(buttons)

        addPhotosButton.addTarget(self, action: #selector(handleAddPhotos), for: .touchUpInside)
        addVideoButton.addTarget(self, action: #selector(handleAddVideo), for: .touchUpInside)

        mediaHint.font = ATTheme.Typeface.sans(11.5)
        mediaHint.textColor = ATTheme.Palette.inkFaint
        mediaHint.numberOfLines = 0
        container.addArrangedSubview(mediaHint)

        return container
    }

    private func eulaContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = ATTheme.Palette.accentSoft.withAlphaComponent(0.45)
        container.layer.cornerRadius = ATTheme.Radius.small
        container.layer.borderWidth = 1
        container.layer.borderColor = ATTheme.Palette.accent.withAlphaComponent(0.4).cgColor

        let text = NSMutableAttributedString(
            string: "I hold the rights to everything I am publishing and I accept the ",
            attributes: [
                .font: ATTheme.Typeface.sans(13),
                .foregroundColor: ATTheme.Palette.ink,
            ]
        )
        text.append(NSAttributedString(
            string: "End User Licence Agreement",
            attributes: [
                .font: ATTheme.Typeface.sans(13, .semibold),
                .foregroundColor: ATTheme.Palette.accent,
            ]
        ))
        text.append(NSAttributedString(
            string: ".",
            attributes: [
                .font: ATTheme.Typeface.sans(13),
                .foregroundColor: ATTheme.Palette.ink,
            ]
        ))

        eulaCheckbox.setAttributedText(text)
        eulaCheckbox.addTarget(self, action: #selector(handleEulaToggled), for: .valueChanged)
        container.addSubview(eulaCheckbox)

        eulaLink.setAttributedTitle(
            ATTheme.sectionLabel("Read the EULA", color: ATTheme.Palette.accent),
            for: .normal
        )
        eulaLink.addTarget(self, action: #selector(handleOpenEula), for: .touchUpInside)
        container.addSubview(eulaLink)

        eulaCheckbox.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(ATTheme.Space.md)
        }

        eulaLink.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.top.equalTo(eulaCheckbox.snp.bottom).offset(ATTheme.Space.xs)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        return container
    }

    // MARK: - State

    private func refreshPublishState() {
        let hasStory = !(storyView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPlace = !(placeField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCountry = !(countryField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasTheme = themePicker.selected != nil

        publishButton.isEnabled = hasStory && hasPlace && hasCountry && hasTheme && eulaCheckbox.isSelected
    }

    private func refreshMedia() {
        mediaStrip.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, image) in images.enumerated() {
            mediaStrip.addArrangedSubview(makeThumbnail(image: image, index: index))
        }

        if videoURL != nil {
            mediaStrip.addArrangedSubview(makeVideoThumbnail())
        }

        addPhotosButton.isHidden = videoURL != nil || images.count >= maximumImages
        addVideoButton.isHidden = videoURL != nil || !images.isEmpty
        mediaHint.text = videoURL == nil
            ? "Up to \(maximumImages) photographs, or a single video."
            : "One video attached. Remove it to add photographs instead."
    }

    private func makeThumbnail(image: UIImage, index: Int) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = ATTheme.Radius.small
        container.clipsToBounds = true

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        container.addSubview(imageView)

        let remove = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        remove.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        remove.tintColor = ATTheme.Palette.paper
        remove.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.65)
        remove.layer.cornerRadius = 10
        remove.tag = index
        remove.addTarget(self, action: #selector(handleRemoveImage(_:)), for: .touchUpInside)
        container.addSubview(remove)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        remove.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().offset(4)
            make.width.height.equalTo(20)
        }

        container.snp.makeConstraints { make in
            make.width.height.equalTo(76)
        }

        return container
    }

    private func makeVideoThumbnail() -> UIView {
        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paperDeep
        container.layer.cornerRadius = ATTheme.Radius.small
        container.clipsToBounds = true

        let glyph = UIImageView()
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        glyph.image = UIImage(systemName: "play.circle", withConfiguration: configuration)
        glyph.tintColor = ATTheme.Palette.inkSoft
        container.addSubview(glyph)

        let remove = UIButton(type: .system)
        let smallConfiguration = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        remove.setImage(UIImage(systemName: "xmark", withConfiguration: smallConfiguration), for: .normal)
        remove.tintColor = ATTheme.Palette.paper
        remove.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.65)
        remove.layer.cornerRadius = 10
        remove.addTarget(self, action: #selector(handleRemoveVideo), for: .touchUpInside)
        container.addSubview(remove)

        glyph.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        remove.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().offset(4)
            make.width.height.equalTo(20)
        }

        container.snp.makeConstraints { make in
            make.width.height.equalTo(76)
        }

        return container
    }

    // MARK: - Actions

    @objc private func handleAddPhotos() {
        let remaining = maximumImages - images.count
        guard remaining > 0 else {
            showToast("Six photographs is the limit for one post.")
            return
        }

        picker.present(from: self, mode: .images(limit: remaining)) { [weak self] picked in
            guard let self else { return }
            let newImages = picked.compactMap(\.image)
            guard !newImages.isEmpty else { return }

            self.images.append(contentsOf: newImages.prefix(remaining))
            if picked.count > remaining {
                self.showToast("Only the first \(remaining) were added.")
            }
            self.refreshMedia()
        }
    }

    @objc private func handleAddVideo() {
        picker.present(from: self, mode: .video) { [weak self] picked in
            guard let self, let first = picked.first, let url = first.videoURL else { return }
            self.videoURL = url
            self.refreshMedia()
        }
    }

    @objc private func handleRemoveImage(_ sender: UIButton) {
        guard images.indices.contains(sender.tag) else { return }
        images.remove(at: sender.tag)
        refreshMedia()
    }

    @objc private func handleRemoveVideo() {
        videoURL = nil
        refreshMedia()
    }

    @objc private func handleEulaToggled() {
        refreshPublishState()
    }

    @objc private func handleOpenEula() {
        present(ATLegalViewController(document: .eula), animated: true)
    }

    @objc private func handlePublish() {
        view.endEditing(true)

        guard !requireSignIn(message: "Sign in to publish a trip.") else { return }
        guard let userID = ATSession.shared.userID else { return }

        let story = (storyView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let place = (placeField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let country = (countryField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let theme = themePicker.selected else {
            showToast("Choose a lens for this trip.")
            return
        }

        guard eulaCheckbox.isSelected else {
            showToast("Accept the licence agreement to publish.")
            return
        }

        var media: [(kind: ATMediaKind, reference: String, aspect: Double)] = []

        if let videoURL {
            if let reference = ATMediaLibrary.importVideo(at: videoURL) {
                media.append((.video, reference, 0.75))
            } else {
                showToast("That video could not be attached.")
                return
            }
        } else {
            for image in images {
                guard let reference = ATMediaLibrary.importImage(image) else { continue }
                let aspect = image.size.height > 0 ? Double(image.size.width / image.size.height) : 1
                media.append((.image, reference, aspect))
            }
        }

        _ = ATStore.insertPost(
            authorID: userID,
            body: story,
            theme: theme,
            locationName: place,
            country: country,
            intensity: intensityPicker.value,
            media: media
        )

        ATSession.shared.refresh()
        resetForm()

        ATToast.show("Published. It is on your profile now.")
        ATRootViewController.current?.finishCompose()
    }

    private func resetForm() {
        storyView.text = nil
        storyPlaceholder.isHidden = false
        placeField.textField.text = nil
        countryField.textField.text = nil
        themePicker.select(nil)
        intensityPicker.value = nil
        images = []
        videoURL = nil
        eulaCheckbox.isSelected = false
        refreshGuidance()
        refreshMedia()
        refreshPublishState()
        scrollView.setContentOffset(.zero, animated: true)
    }
}

// MARK: - Text view

extension ATComposeViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        storyPlaceholder.isHidden = !textView.text.isEmpty
        refreshPublishState()
    }
}

// MARK: - Theme picker

private final class ATThemePicker: UIView {

    private(set) var selected: ATPostTheme?
    var onSelect: ((ATPostTheme?) -> Void)?
    private var buttons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = ATTheme.Space.xs
        addSubview(rows)

        let themes = ATPostTheme.allCases
        for start in stride(from: 0, to: themes.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = ATTheme.Space.xs
            row.distribution = .fillEqually

            for offset in 0..<2 {
                let index = start + offset
                guard index < themes.count else {
                    row.addArrangedSubview(UIView())
                    continue
                }
                let theme = themes[index]
                let button = makeButton(theme: theme)
                buttons.append(button)
                row.addArrangedSubview(button)
            }
            rows.addArrangedSubview(row)
        }

        rows.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func makeButton(theme: ATPostTheme) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = theme.title
        configuration.subtitle = theme.blurb
        configuration.image = UIImage(
            systemName: theme.symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        configuration.imagePadding = 6
        configuration.titleAlignment = .leading
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = ATTheme.Typeface.sans(13.5, .semibold)
        button.layer.cornerRadius = ATTheme.Radius.small
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.tag = ATPostTheme.allCases.firstIndex(of: theme) ?? 0
        button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        apply(theme: theme, to: button, isSelected: false)
        return button
    }

    private func apply(theme: ATPostTheme, to button: UIButton, isSelected: Bool) {
        button.backgroundColor = isSelected ? theme.tint.withAlphaComponent(0.16) : .clear
        button.layer.borderColor = (isSelected ? theme.tint : ATTheme.Palette.rule).cgColor

        var configuration = button.configuration
        configuration?.baseForegroundColor = isSelected ? theme.tint : ATTheme.Palette.ink
        configuration?.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ATTheme.Typeface.sans(10.5, .regular)
            outgoing.foregroundColor = isSelected ? theme.tint.withAlphaComponent(0.75) : ATTheme.Palette.inkFaint
            return outgoing
        }
        button.configuration = configuration
    }

    func select(_ theme: ATPostTheme?) {
        selected = theme
        for button in buttons {
            let buttonTheme = ATPostTheme.allCases[button.tag]
            apply(theme: buttonTheme, to: button, isSelected: buttonTheme == theme)
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        let theme = ATPostTheme.allCases[sender.tag]
        select(theme == selected ? nil : theme)
        onSelect?(selected)
    }
}

// MARK: - Intensity

private final class ATIntensityPicker: UIView {

    var value: Int? {
        didSet { refresh() }
    }

    var accent: UIColor = ATTheme.Palette.ink {
        didSet { refresh() }
    }

    private var bars: [UIControl] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .bottom
        addSubview(row)

        for step in 1...5 {
            let bar = UIControl()
            bar.tag = step
            bar.layer.cornerRadius = 3
            bar.layer.cornerCurve = .continuous
            bar.layer.borderWidth = 1
            bar.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            bar.snp.makeConstraints { make in
                make.width.equalTo(26)
                make.height.equalTo(8 + CGFloat(step - 1) * 4)
            }
            row.addArrangedSubview(bar)
            bars.append(bar)
        }

        row.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func handleTap(_ sender: UIControl) {
        value = (value == sender.tag) ? nil : sender.tag
    }

    private func refresh() {
        for bar in bars {
            let filled = (value ?? 0) >= bar.tag
            bar.backgroundColor = filled ? accent : .clear
            bar.layer.borderColor = (filled ? accent : ATTheme.Palette.ruleStrong).cgColor
        }
    }
}
