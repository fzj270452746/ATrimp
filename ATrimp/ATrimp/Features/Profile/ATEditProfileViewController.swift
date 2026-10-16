//
//  ATEditProfileViewController.swift
//  ATrimp
//
import SnapKit
import UIKit

final class ATEditProfileViewController: ATViewController {

    private let scrollView = UIScrollView()
    private let content = UIStackView()

    private let avatar = ATAvatarView(size: 96)
    private let changePhotoButton = UIButton(type: .system)
    private let nameField = ATFieldRow(caption: "Display name", placeholder: "Avery Lin")
    private let cityField = ATFieldRow(caption: "Home city", placeholder: "Rotterdam")
    private let bioLabel = UILabel()
    private let bioView = UITextView()
    private let bioPlaceholder = UILabel()
    private let saveButton = ATPrimaryButton(title: "Save changes")

    private let picker = ATMediaPicker()
    private let camera = ATCameraPicker()
    private var pendingAvatarReference: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: "Edit profile")
        buildLayout()
        populate()
    }

    // MARK: - Layout

    private func buildLayout() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.addSubview(content)

        content.axis = .vertical
        content.spacing = ATTheme.Space.lg
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: ATTheme.Space.lg,
            leading: ATTheme.Space.gutter,
            bottom: ATTheme.Space.xxl,
            trailing: ATTheme.Space.gutter
        )

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }

        let photoBlock = UIStackView()
        photoBlock.axis = .vertical
        photoBlock.alignment = .center
        photoBlock.spacing = ATTheme.Space.sm

        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangePhoto)))

        changePhotoButton.setAttributedTitle(
            ATTheme.sectionLabel("Change photograph", color: ATTheme.Palette.accent),
            for: .normal
        )
        changePhotoButton.addTarget(self, action: #selector(handleChangePhoto), for: .touchUpInside)

        photoBlock.addArrangedSubview(avatar)
        photoBlock.addArrangedSubview(changePhotoButton)
        content.addArrangedSubview(photoBlock)
        content.setCustomSpacing(ATTheme.Space.xl, after: photoBlock)

        content.addArrangedSubview(label("Name and place"))
        content.addArrangedSubview(nameField)
        content.addArrangedSubview(cityField)

        content.addArrangedSubview(label("About you"))
        content.addArrangedSubview(bioContainer())

        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        content.addArrangedSubview(saveButton)

        let note = UILabel()
        note.text = "Your photograph and description are visible to anyone who opens your profile."
        note.font = ATTheme.Typeface.sans(11.5)
        note.textColor = ATTheme.Palette.inkFaint
        note.numberOfLines = 0
        content.addArrangedSubview(note)
    }

    private func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(text)
        return label
    }

    private func bioContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = ATTheme.Palette.paperRaised
        container.layer.cornerRadius = ATTheme.Radius.small
        container.layer.borderWidth = ATTheme.hairline
        container.layer.borderColor = ATTheme.Palette.rule.cgColor

        bioView.font = ATTheme.Typeface.sans(15.5)
        bioView.textColor = ATTheme.Palette.ink
        bioView.backgroundColor = .clear
        bioView.tintColor = ATTheme.Palette.accent
        bioView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        bioView.isScrollEnabled = false
        bioView.delegate = self
        container.addSubview(bioView)

        bioPlaceholder.text = "A line or two about how you travel."
        bioPlaceholder.font = ATTheme.Typeface.sans(15.5)
        bioPlaceholder.textColor = ATTheme.Palette.inkFaint
        container.addSubview(bioPlaceholder)

        bioView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(110)
        }

        bioPlaceholder.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().offset(-15)
        }

        return container
    }

    private func populate() {
        guard let user = ATSession.shared.currentUser else { return }
        avatar.set(user: user)
        nameField.textField.text = user.displayName
        cityField.textField.text = user.homeCity
        bioView.text = user.bio
        bioPlaceholder.isHidden = !user.bio.isEmpty
    }

    // MARK: - Actions

    @objc private func handleChangePhoto() {
        let sheet = UIAlertController(
            title: "Profile photograph",
            message: nil,
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: "Take photo", style: .default) { [weak self] _ in
            self?.takePhoto()
        })
        sheet.addAction(UIAlertAction(title: "Choose from library", style: .default) { [weak self] _ in
            self?.chooseFromLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = avatar
            popover.sourceRect = avatar.bounds
            popover.permittedArrowDirections = [.up, .down]
        }
        present(sheet, animated: true)
    }

    private func takePhoto() {
        camera.present(from: self) { [weak self] picked in
            self?.adopt(picked?.image)
        }
    }

    private func chooseFromLibrary() {
        picker.present(from: self, mode: .images(limit: 1)) { [weak self] picked in
            self?.adopt(picked.first?.image)
        }
    }

    private func adopt(_ image: UIImage?) {
        guard let image else { return }

        guard let reference = ATMediaLibrary.importAvatar(image) else {
            showToast("That photograph could not be used.")
            return
        }

        pendingAvatarReference = reference
        avatar.set(seed: reference, initials: "")
    }

    @objc private func handleSave() {
        view.endEditing(true)

        guard let user = ATSession.shared.currentUser else { return }

        let name = (nameField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showToast("Your display name cannot be empty.")
            return
        }

        ATStore.updateProfile(
            userID: user.id,
            displayName: name,
            bio: (bioView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            homeCity: (cityField.textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            avatarSeed: pendingAvatarReference
        )

        ATSession.shared.refresh()
        showToast("Profile updated.")
        goBack()
    }
}

extension ATEditProfileViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        bioPlaceholder.isHidden = !textView.text.isEmpty
    }
}
