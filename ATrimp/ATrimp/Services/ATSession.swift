//
//  ATSession.swift
//  ATrimp
//
//
import Foundation

enum ATAuthError: LocalizedError {
    case emptyField(String)
    case unknownAccount
    case wrongPassword
    case usernameTaken
    case usernameTooShort
    case passwordTooShort
    case passwordsDoNotMatch

    var errorDescription: String? {
        switch self {
        case .emptyField(let name): return "Please enter your \(name)."
        case .unknownAccount: return "No account found with that username."
        case .wrongPassword: return "That password does not match."
        case .usernameTaken: return "That username is already taken."
        case .usernameTooShort: return "Usernames need at least 3 characters."
        case .passwordTooShort: return "Passwords need at least 6 characters."
        case .passwordsDoNotMatch: return "The two passwords do not match."
        }
    }
}

final class ATSession {

    static let shared = ATSession()

    static let didChange = Notification.Name("ATSessionDidChange")

    private(set) var currentUser: ATUser?

    var isSignedIn: Bool { currentUser != nil }
    var userID: String? { currentUser?.id }

    private init() {
        restore()
    }

    // MARK: - Restoring

    private func restore() {
        guard
            let storedID = ATKeychain.string(for: .signedInUserID),
            let user = ATStore.user(id: storedID)
        else {
            ATStore.clearCurrentUser()
            return
        }

        ATStore.setCurrentUser(id: user.id)
        currentUser = user
    }

    // MARK: - Credentials

    @discardableResult
    func signIn(username: String, password: String) throws -> ATUser {
        let handle = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !handle.isEmpty else { throw ATAuthError.emptyField("username") }
        guard !password.isEmpty else { throw ATAuthError.emptyField("password") }

        guard let credential = ATStore.credential(username: handle) else {
            throw ATAuthError.unknownAccount
        }
        guard ATPassword.matches(password, salt: credential.salt, hash: credential.passwordHash) else {
            throw ATAuthError.wrongPassword
        }
        guard let user = ATStore.user(id: credential.userID) else {
            throw ATAuthError.unknownAccount
        }

        adopt(user)
        return user
    }

    @discardableResult
    func register(username: String, displayName: String, password: String, confirmation: String) throws -> ATUser {
        let handle = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !handle.isEmpty else { throw ATAuthError.emptyField("username") }
        guard !name.isEmpty else { throw ATAuthError.emptyField("display name") }
        guard !password.isEmpty else { throw ATAuthError.emptyField("password") }
        guard handle.count >= 3 else { throw ATAuthError.usernameTooShort }
        guard password.count >= 6 else { throw ATAuthError.passwordTooShort }
        guard password == confirmation else { throw ATAuthError.passwordsDoNotMatch }
        guard !ATStore.isUsernameTaken(handle) else { throw ATAuthError.usernameTaken }

        guard let user = ATStore.createAccount(username: handle, displayName: name, password: password) else {
            throw ATAuthError.usernameTaken
        }

        adopt(user)
        return user
    }

    // MARK: - Apple

    @discardableResult
    func signInWithApple(appleUserID: String, displayName: String?, email: String?) -> ATUser? {
        if let existing = ATStore.appleAccount(appleUserID: appleUserID) {
            adopt(existing)
            return existing
        }

        let handle = Self.availableUsername(basedOn: email ?? displayName ?? "traveller")
        let name = displayName.flatMap { $0.isEmpty ? nil : $0 } ?? handle.capitalized

        guard let user = ATStore.createAccount(
            username: handle,
            displayName: name,
            password: UUID().uuidString,
            appleUserID: appleUserID
        ) else {
            return nil
        }

        ATKeychain.set(appleUserID, for: .appleUserID)
        adopt(user)
        return user
    }

    private static func availableUsername(basedOn source: String) -> String {
        let cleaned = source
            .split(separator: "@").first
            .map(String.init)?
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" } ?? "traveller"
        let base = cleaned.isEmpty ? "traveller" : String(cleaned.prefix(18))

        var candidate = base
        var suffix = 1
        while ATStore.isUsernameTaken(candidate) {
            suffix += 1
            candidate = "\(base)\(suffix)"
        }
        return candidate
    }

    // MARK: - Leaving

    func signOut() {
        ATStore.clearCurrentUser()
        ATKeychain.set(nil, for: .signedInUserID)
        currentUser = nil
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }

    func deleteAccount() {
        guard let user = currentUser else { return }
        ATStore.deleteAccount(id: user.id, username: user.username)
        ATKeychain.set(nil, for: .signedInUserID)
        ATKeychain.set(nil, for: .appleUserID)
        currentUser = nil
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }

    // MARK: - Refreshing

    func refresh() {
        guard let id = currentUser?.id else { return }
        currentUser = ATStore.user(id: id)
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }

    private func adopt(_ user: ATUser) {
        ATStore.setCurrentUser(id: user.id)
        ATKeychain.set(user.id, for: .signedInUserID)
        currentUser = ATStore.user(id: user.id) ?? user
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }
}
