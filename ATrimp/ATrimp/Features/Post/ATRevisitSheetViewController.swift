//
//  ATRevisitSheetViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATRevisitSheetViewController: UIViewController {

    private let original: ATPost
    private let onFiled: (ATPost) -> Void

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private let standfirst = UILabel()
    private let lensCaption = UILabel()
    private let lensScroller = UIScrollView()
    private let lensRow = UIStackView()
    private let storyHolder = UIView()
    private let storyView = UITextView()
    private let storyPlaceholder = UILabel()
    private let photoButton = ATGhostButton(title: "Add a photograph")
    private let photoStrip = UIStackView()
    private let publishButton = ATPrimaryButton(title: "File the return trip")
    private let stampButton = ATGhostButton(title: "Just mark it, without writing")

    private var lens: ATPostTheme = .surprise
    private var lensButtons: [ATPostTheme: ATPillButton] = [:]
    private var photo: UIImage?

    private let picker = ATMediaPicker()

    init(post: ATPost, onFiled: @escaping (ATPost) -> Void) {
        self.original = post
        self.onFiled = onFiled
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        buildLayout()
        refreshPublishState()
    }

    // MARK: - Layout

    private func buildLayout() {
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        view.addSubview(scroll)

        column.axis = .vertical
        column.alignment = .fill
        scroll.addSubview(column)

        scroll.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }

        column.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(ATTheme.Space.gutter)
            make.width.equalToSuperview().offset(-ATTheme.Space.gutter * 2)
        }

        let title = UILabel()
        title.text = "What changed?"
        title.font = ATTheme.Typeface.serif(26, .semibold)
        title.textColor = ATTheme.Palette.ink
        title.numberOfLines = 2

        standfirst.font = ATTheme.Typeface.body
        standfirst.textColor = ATTheme.Palette.inkSoft
        standfirst.numberOfLines = 0
        standfirst.text = "You filed \(original.locationName) \(ATTime.relative(original.createdAt)). Going back is how one of these stops being the last word on a place."

        lensCaption.attributedText = ATTheme.sectionLabel("How it read this time")

        lensScroller.showsHorizontalScrollIndicator = false
        lensScroller.clipsToBounds = false
        lensScroller.addSubview(lensRow)

        lensRow.axis = .horizontal
        lensRow.spacing = ATTheme.Space.xs
        lensRow.alignment = .fill
        for theme in ATPostTheme.allCases {
            let button = ATPillButton(title: theme.title)
            button.addTarget(self, action: #selector(chooseLens(_:)), for: .touchUpInside)
            lensRow.addArrangedSubview(button)
            lensButtons[theme] = button
        }

        storyHolder.backgroundColor = ATTheme.Palette.paperDeep
        storyHolder.layer.cornerRadius = ATTheme.Radius.small
        storyHolder.layer.cornerCurve = .continuous

        storyView.backgroundColor = .clear
        storyView.font = ATTheme.Typeface.sans(16)
        storyView.textColor = ATTheme.Palette.ink
        storyView.tintColor = ATTheme.Palette.accent
        storyView.delegate = self
        storyView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        storyHolder.addSubview(storyView)

        storyPlaceholder.text = "The queue was twenty minutes. I took the ferry and the coast looked nothing like the bus window."
        storyPlaceholder.font = ATTheme.Typeface.sans(16)
        storyPlaceholder.textColor = ATTheme.Palette.inkFaint
        storyPlaceholder.numberOfLines = 0
        storyPlaceholder.isUserInteractionEnabled = false
        storyHolder.addSubview(storyPlaceholder)

        photoButton.addTarget(self, action: #selector(addPhoto), for: .touchUpInside)

        photoStrip.axis = .horizontal
        photoStrip.spacing = ATTheme.Space.xs
        photoStrip.alignment = .fill

        publishButton.addTarget(self, action: #selector(publish), for: .touchUpInside)
        stampButton.addTarget(self, action: #selector(stampOnly), for: .touchUpInside)

        column.addArrangedSubview(title)
        column.setCustomSpacing(ATTheme.Space.sm, after: title)
        column.addArrangedSubview(standfirst)
        column.setCustomSpacing(ATTheme.Space.lg, after: standfirst)
        column.addArrangedSubview(lensCaption)
        column.setCustomSpacing(ATTheme.Space.sm, after: lensCaption)
        column.addArrangedSubview(lensScroller)
        column.setCustomSpacing(ATTheme.Space.lg, after: lensScroller)
        column.addArrangedSubview(storyHolder)
        column.setCustomSpacing(ATTheme.Space.sm, after: storyHolder)
        column.addArrangedSubview(photoButton)
        column.setCustomSpacing(ATTheme.Space.xs, after: photoButton)
        column.addArrangedSubview(photoStrip)
        column.setCustomSpacing(ATTheme.Space.lg, after: photoStrip)
        column.addArrangedSubview(publishButton)
        column.setCustomSpacing(ATTheme.Space.sm, after: publishButton)
        column.addArrangedSubview(stampButton)
        column.setCustomSpacing(ATTheme.Space.xxl, after: stampButton)

        lensRow.snp.makeConstraints { make in
            make.edges.equalTo(lensScroller.contentLayoutGuide)
            make.height.equalTo(38)
        }

        lensScroller.snp.makeConstraints { make in
            make.height.equalTo(38)
        }

        storyHolder.snp.makeConstraints { make in
            make.height.equalTo(132)
        }

        storyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        storyPlaceholder.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.sm)
        }

        markLens()
    }

    // MARK: - Actions

    @objc private func chooseLens(_ sender: ATPillButton) {
        guard let theme = lensButtons.first(where: { $0.value === sender })?.key else { return }
        lens = theme
        markLens()
    }

    private func markLens() {
        for (theme, button) in lensButtons {
            button.apply(title: theme.title, filled: theme == lens, tint: ATTheme.Palette.ink)
        }
    }

    @objc private func addPhoto() {
        picker.present(from: self, mode: .images(limit: 1)) { [weak self] picked in
            guard let self, let first = picked.first, let image = first.image else { return }
            self.photo = image
            self.refreshPhoto()
            self.refreshPublishState()
        }
    }

    private func refreshPhoto() {
        photoStrip.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let photo else { return }

        let preview = UIImageView(image: photo)
        preview.contentMode = .scaleAspectFill
        preview.clipsToBounds = true
        preview.layer.cornerRadius = ATTheme.Radius.small
        preview.layer.cornerCurve = .continuous
        preview.snp.makeConstraints { make in
            make.width.height.equalTo(84)
        }
        photoStrip.addArrangedSubview(preview)

        let remove = ATGhostButton(title: "Remove")
        remove.addTarget(self, action: #selector(clearPhoto), for: .touchUpInside)
        photoStrip.addArrangedSubview(remove)
    }

    @objc private func clearPhoto() {
        photo = nil
        refreshPhoto()
        refreshPublishState()
    }

    private func refreshPublishState() {
        publishButton.isEnabled = !story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var story: String { storyView.text ?? "" }

    @objc private func publish() {
        let body = story.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        guard let userID = ATSession.shared.userID else {
            ATToast.show("Sign in to file this.", in: view)
            return
        }

        var media: [(kind: ATMediaKind, reference: String, aspect: Double)] = []
        if let photo, let reference = ATMediaLibrary.importImage(photo) {
            let aspect = photo.size.height > 0 ? Double(photo.size.width / photo.size.height) : 1
            media.append((.image, reference, aspect))
        }

        let answer = ATStore.insertPost(
            authorID: userID,
            body: body,
            theme: lens,
            locationName: original.locationName,
            country: original.country,
            answersPostID: original.id,
            media: media
        )

        ATSession.shared.refresh()
        onFiled(answer)
        dismiss(animated: true)
    }

    @objc private func stampOnly() {
        ATStore.setRedeemed(true, postID: original.id)
        onFiled(original)
        dismiss(animated: true)
    }
}

// MARK: - Text view

extension ATRevisitSheetViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        storyPlaceholder.isHidden = !story.isEmpty
        refreshPublishState()
    }
}
