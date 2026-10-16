//
//  ATExpenseSheetViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATExpenseSheetViewController: UIViewController {

    private let existing: ATExpense?
    private let onSaved: () -> Void

    private let scroll = UIScrollView()
    private let column = UIStackView()

    private let titleLabel = UILabel()
    private let placeRow = UIControl()
    private let placeLabel = UILabel()
    private let amountField = ATFieldRow(caption: "Amount", placeholder: "0.00", keyboard: .decimalPad)
    private let categoryScroller = UIScrollView()
    private let categoryRow = UIStackView()
    private let datePicker = UIDatePicker()
    private let peopleRow = UIStackView()
    private let noteField = ATFieldRow(caption: "Note", placeholder: "Dinner at the night market")
    private let saveButton = ATPrimaryButton(title: "Add expense")
    private let deleteButton = ATGhostButton(title: "Delete", tint: ATTheme.Palette.danger)

    private var place: ATPlace?
    private var category: ATExpenseCategory = .other
    private var people = 1

    private var categoryButtons: [ATExpenseCategory: ATPillButton] = [:]
    private var peopleButtons: [Int: ATPillButton] = [:]

    init(editing expense: ATExpense?, defaultPlace: ATPlace?, onSaved: @escaping () -> Void) {
        self.existing = expense
        self.place = expense?.place ?? defaultPlace
        self.category = expense?.category ?? .other
        self.people = expense?.people ?? 1
        self.onSaved = onSaved
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        buildLayout()
        refreshPlaceRow()
        markCategory()
        markPeople()
        refreshSaveState()
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

        titleLabel.text = existing == nil ? "What did it cost?" : "Change this one"
        titleLabel.font = ATTheme.Typeface.serif(26, .semibold)
        titleLabel.textColor = ATTheme.Palette.ink
        titleLabel.numberOfLines = 2

        buildPlaceRow()

        if let existing {
            amountField.textField.text = ATMoney.format(existing.amount)
            noteField.textField.text = existing.note
            datePicker.date = existing.spentAt
        }
        amountField.textField.addTarget(self, action: #selector(refreshSaveState), for: .editingChanged)

        buildCategoryRow()
        buildPeopleRow()

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()
        datePicker.tintColor = ATTheme.Palette.accent

        saveButton.setTitle(existing == nil ? "Add expense" : "Save changes", for: .normal)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        deleteButton.addTarget(self, action: #selector(deleteThis), for: .touchUpInside)

        let categoryCaption = caption("Category")
        let dateCaption = caption("When")
        let peopleCaption = caption("Split between")
        let peopleNote = UILabel()
        peopleNote.text = "Your share is the total divided by this."
        peopleNote.font = ATTheme.Typeface.caption
        peopleNote.textColor = ATTheme.Palette.inkFaint
        peopleNote.numberOfLines = 0

        column.addArrangedSubview(titleLabel)
        column.setCustomSpacing(ATTheme.Space.md, after: titleLabel)
        column.addArrangedSubview(placeRow)
        column.setCustomSpacing(ATTheme.Space.lg, after: placeRow)

        column.addArrangedSubview(amountField)
        column.setCustomSpacing(ATTheme.Space.lg, after: amountField)

        column.addArrangedSubview(categoryCaption)
        column.setCustomSpacing(ATTheme.Space.xs, after: categoryCaption)
        column.addArrangedSubview(categoryScroller)
        column.setCustomSpacing(ATTheme.Space.lg, after: categoryScroller)

        column.addArrangedSubview(dateCaption)
        column.setCustomSpacing(ATTheme.Space.xs, after: dateCaption)
        column.addArrangedSubview(datePicker)
        column.setCustomSpacing(ATTheme.Space.lg, after: datePicker)

        column.addArrangedSubview(peopleCaption)
        column.setCustomSpacing(ATTheme.Space.xs, after: peopleCaption)
        column.addArrangedSubview(peopleRow)
        column.setCustomSpacing(ATTheme.Space.xxs, after: peopleRow)
        column.addArrangedSubview(peopleNote)
        column.setCustomSpacing(ATTheme.Space.lg, after: peopleNote)

        column.addArrangedSubview(noteField)
        column.setCustomSpacing(ATTheme.Space.lg, after: noteField)

        column.addArrangedSubview(saveButton)
        column.setCustomSpacing(ATTheme.Space.sm, after: saveButton)

        if existing != nil {
            column.addArrangedSubview(deleteButton)
            column.setCustomSpacing(ATTheme.Space.xl, after: deleteButton)
        } else {
            column.setCustomSpacing(ATTheme.Space.xl, after: saveButton)
        }

        categoryRow.snp.makeConstraints { make in
            make.edges.equalTo(categoryScroller.contentLayoutGuide)
            make.height.equalTo(38)
        }

        categoryScroller.snp.makeConstraints { make in
            make.height.equalTo(38)
        }

        peopleRow.snp.makeConstraints { make in
            make.height.equalTo(38)
        }
    }

    private func buildPlaceRow() {
        placeRow.backgroundColor = ATTheme.Palette.paperDeep
        placeRow.layer.cornerRadius = ATTheme.Radius.small
        placeRow.layer.cornerCurve = .continuous
        placeRow.addTarget(self, action: #selector(pickPlace), for: .touchUpInside)

        let icon = UIImageView(
            image: UIImage(
                systemName: "mappin.and.ellipse",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            )
        )
        icon.tintColor = ATTheme.Palette.accent
        icon.contentMode = .center
        placeRow.addSubview(icon)

        placeLabel.font = ATTheme.Typeface.sans(15.5, .semibold)
        placeRow.addSubview(placeLabel)

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            )
        )
        chevron.tintColor = ATTheme.Palette.inkFaint
        placeRow.addSubview(chevron)

        placeRow.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        placeLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(ATTheme.Space.sm)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-ATTheme.Space.xs)
        }

        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
            make.centerY.equalToSuperview()
        }
    }

    private func buildCategoryRow() {
        categoryScroller.showsHorizontalScrollIndicator = false
        categoryScroller.clipsToBounds = false
        categoryScroller.addSubview(categoryRow)

        categoryRow.axis = .horizontal
        categoryRow.spacing = ATTheme.Space.xs
        categoryRow.alignment = .fill

        for value in ATExpenseCategory.allCases {
            let button = ATPillButton(title: value.title)
            button.addTarget(self, action: #selector(chooseCategory(_:)), for: .touchUpInside)
            categoryRow.addArrangedSubview(button)
            categoryButtons[value] = button
        }
    }

    private func buildPeopleRow() {
        peopleRow.axis = .horizontal
        peopleRow.spacing = ATTheme.Space.xs
        peopleRow.distribution = .fillEqually
        peopleRow.alignment = .fill

        for value in 1...6 {
            let button = ATPillButton(title: "\(value)")
            button.addTarget(self, action: #selector(choosePeople(_:)), for: .touchUpInside)
            peopleRow.addArrangedSubview(button)
            peopleButtons[value] = button
        }
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(text)
        return label
    }

    // MARK: - State

    private func refreshPlaceRow() {
        placeLabel.text = place?.name ?? "Choose a place"
        placeLabel.textColor = place == nil ? ATTheme.Palette.inkFaint : ATTheme.Palette.ink
    }

    @objc private func refreshSaveState() {
        saveButton.isEnabled = place != nil && ATMoney.parse(amountField.textField.text ?? "") != nil
    }

    private func markCategory() {
        for (value, button) in categoryButtons {
            button.apply(title: value.title, filled: value == category, tint: value.tint)
        }
    }

    private func markPeople() {
        for (value, button) in peopleButtons {
            button.apply(title: "\(value)", filled: value == people, tint: ATTheme.Palette.ink)
        }
    }

    // MARK: - Actions

    @objc private func chooseCategory(_ sender: ATPillButton) {
        guard let value = categoryButtons.first(where: { $0.value === sender })?.key else { return }
        category = value
        markCategory()
    }

    @objc private func choosePeople(_ sender: ATPillButton) {
        guard let value = peopleButtons.first(where: { $0.value === sender })?.key else { return }
        people = value
        markPeople()
    }

    @objc private func pickPlace() {
        view.endEditing(true)

        let picker = ATPlacePickerViewController(
            title: "Where was it",
            standfirst: "Every place in the library — or type one of your own.",
            entries: ATToolbox.pickerEntries(allowsNotes: false),
            allowsTypedPlace: true,
            presentedModally: true
        ) { [weak self] place in
            guard let self else { return }
            self.place = place
            self.refreshPlaceRow()
            self.refreshSaveState()
            self.dismiss(animated: true)
        }

        picker.modalPresentationStyle = .pageSheet
        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = ATTheme.Radius.large
        }
        present(picker, animated: true)
    }

    @objc private func save() {
        guard let place, let amount = ATMoney.parse(amountField.textField.text ?? "") else { return }

        let note = noteField.textField.text ?? ""

        if let existing {
            ATStore.updateExpense(
                id: existing.id,
                place: place,
                category: category,
                amount: amount,
                people: people,
                note: note,
                spentAt: datePicker.date
            )
        } else {
            ATStore.addExpense(
                place: place,
                category: category,
                amount: amount,
                people: people,
                note: note,
                spentAt: datePicker.date
            )
        }

        view.endEditing(true)
        let completion = onSaved
        dismiss(animated: true) { completion() }
    }

    @objc private func deleteThis() {
        guard let existing else { return }
        ATStore.deleteExpense(id: existing.id)
        let completion = onSaved
        dismiss(animated: true) { completion() }
    }
}
