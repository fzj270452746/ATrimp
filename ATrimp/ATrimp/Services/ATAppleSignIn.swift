//
//  ATAppleSignIn.swift
//  ATrimp
//
//
import AuthenticationServices
import UIKit

struct ATAppleIdentity {
    let userID: String
    let displayName: String?
    let email: String?
}

final class ATAppleSignIn: NSObject {

    static let shared = ATAppleSignIn()

    private var completion: ((Result<ATAppleIdentity, Error>) -> Void)?

    func start(completion: @escaping (Result<ATAppleIdentity, Error>) -> Void) {
        self.completion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func finish(with result: Result<ATAppleIdentity, Error>) {
        let handler = completion
        completion = nil
        handler?(result)
    }
}

extension ATAppleSignIn: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(ATAppleSignInError.unexpectedCredential))
            return
        }

        let name = credential.fullName.flatMap { components -> String? in
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components)
            return formatted.isEmpty ? nil : formatted
        }

        finish(with: .success(ATAppleIdentity(
            userID: credential.user,
            displayName: name,
            email: credential.email
        )))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authorizationError = error as? ASAuthorizationError,
           authorizationError.code == .canceled {
            finish(with: .failure(ATAppleSignInError.cancelled))
            return
        }
        finish(with: .failure(error))
    }
}

extension ATAppleSignIn: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}

enum ATAppleSignInError: LocalizedError {
    case cancelled
    case unexpectedCredential

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .unexpectedCredential:
            return "Apple did not return a usable account. Please try again."
        }
    }
}
