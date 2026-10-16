//
//  ATLoginViewController.swift
//  ATrimp
//
import AuthenticationServices
import SnapKit
import UIKit

final class ATLoginViewController: ATAuthViewController {

    private let usernameField = ATFieldRow(caption: "Username", placeholder: "Your username")
    private let passwordField = ATFieldRow(caption: "Password", placeholder: "Your password", secure: true)

    init() {
        super.init(
            headline: "Welcome back.",
            standfirst: "Sign in to publish your own notes, keep up with the people you follow, and send gifts."
        )
    }

    override func buildContent() {
        usernameField.textField.textContentType = .username
        usernameField.textField.returnKeyType = .next
        usernameField.textField.delegate = self

        passwordField.textField.textContentType = .password
        passwordField.textField.returnKeyType = .go
        passwordField.textField.delegate = self

        fieldStack.addArrangedSubview(usernameField)
        fieldStack.addArrangedSubview(passwordField)

        let signIn = ATPrimaryButton(title: "Sign in")
        signIn.addTarget(self, action: #selector(handleSignIn), for: .touchUpInside)
        actionStack.addArrangedSubview(signIn)

        let apple = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        apple.cornerRadius = ATTheme.Radius.small
        apple.addTarget(self, action: #selector(handleApple), for: .touchUpInside)
        apple.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        let divider = makeDivider("or")
        divider.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        actionStack.addArrangedSubview(divider)
        actionStack.addArrangedSubview(apple)

        let createAccount = ATGhostButton(title: "Create an account")
        createAccount.addTarget(self, action: #selector(handleCreateAccount), for: .touchUpInside)
        actionStack.addArrangedSubview(createAccount)
    }

    // MARK: - Actions

    @objc private func handleSignIn() {
        view.endEditing(true)

        let username = usernameField.textField.text ?? ""
        let password = passwordField.textField.text ?? ""

        do {
            _ = try ATSession.shared.signIn(username: username, password: password)
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

    @objc private func handleCreateAccount() {
        view.endEditing(true)
        present(ATRegisterViewController(), animated: true)
    }

    private func finish() {
        view.window?.rootViewController?.dismiss(animated: true)
    }
}

extension ATLoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === usernameField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            handleSignIn()
        }
        return true
    }
}
