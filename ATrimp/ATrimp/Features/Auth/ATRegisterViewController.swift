//
//  ATRegisterViewController.swift
//  ATrimp
//
import AuthenticationServices
import SnapKit
import UIKit

final class ATRegisterViewController: ATAuthViewController {

    private let usernameField = ATFieldRow(caption: "Username", placeholder: "Letters, numbers, underscore")
    private let displayNameField = ATFieldRow(caption: "Display name", placeholder: "How you appear to others")
    private let passwordField = ATFieldRow(caption: "Password", placeholder: "At least 6 characters", secure: true)
    private let confirmField = ATFieldRow(caption: "Confirm password", placeholder: "Repeat your password", secure: true)

    init() {
        super.init(
            headline: "Make an account.",
            standfirst: "Keep a record of your trips, follow the people whose notes you trust, and join the discussion."
        )
    }

    override func buildContent() {
        usernameField.textField.textContentType = .username
        usernameField.textField.autocapitalizationType = .none
        usernameField.textField.returnKeyType = .next
        usernameField.textField.delegate = self

        displayNameField.textField.textContentType = .name
        displayNameField.textField.returnKeyType = .next
        displayNameField.textField.delegate = self

        passwordField.textField.textContentType = .newPassword
        passwordField.textField.returnKeyType = .next
        passwordField.textField.delegate = self

        confirmField.textField.textContentType = .newPassword
        confirmField.textField.returnKeyType = .go
        confirmField.textField.delegate = self

        [usernameField, displayNameField, passwordField, confirmField].forEach {
            fieldStack.addArrangedSubview($0)
        }

        let create = ATPrimaryButton(title: "Create account")
        create.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        actionStack.addArrangedSubview(create)

        let apple = ASAuthorizationAppleIDButton(type: .signUp, style: .black)
        apple.cornerRadius = ATTheme.Radius.small
        apple.addTarget(self, action: #selector(handleApple), for: .touchUpInside)
        apple.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        actionStack.addArrangedSubview(apple)

        let back = ATGhostButton(title: "I already have an account")
        back.addTarget(self, action: #selector(handleBackToSignIn), for: .touchUpInside)
        actionStack.addArrangedSubview(back)
    }

    // MARK: - Actions

    @objc private func handleRegister() {
        view.endEditing(true)

        do {
            _ = try ATSession.shared.register(
                username: usernameField.textField.text ?? "",
                displayName: displayNameField.textField.text ?? "",
                password: passwordField.textField.text ?? "",
                confirmation: confirmField.textField.text ?? ""
            )
        } catch {
            showError(error)
            return
        }

        ATLoadingOverlay.run(duration: 1.2) { [weak self] in
            self?.finish()
        }
    }

    @objc private func handleApple() {
        view.endEditing(true)

        ATAppleSignIn.shared.start { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let identity):
                guard ATSession.shared.signInWithApple(
                    appleUserID: identity.userID,
                    displayName: identity.displayName,
                    email: identity.email
                ) != nil else {
                    ATToast.show("We could not set up an account for that Apple ID.", in: self.view)
                    return
                }
                ATLoadingOverlay.run(duration: 1.2) { [weak self] in
                    self?.finish()
                }

            case .failure(let error):
                if let authError = error as? ATAppleSignInError, authError.errorDescription == nil {
                    return
                }
                ATToast.show(error.localizedDescription, in: self.view)
            }
        }
    }

    @objc private func handleBackToSignIn() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    private func finish() {
        view.window?.rootViewController?.dismiss(animated: true)
    }
}

extension ATRegisterViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let order = [usernameField, displayNameField, passwordField, confirmField]

        guard let index = order.firstIndex(where: { $0.textField === textField }) else { return true }
        if index < order.count - 1 {
            order[index + 1].textField.becomeFirstResponder()
        } else {
            handleRegister()
        }
        return true
    }
}
