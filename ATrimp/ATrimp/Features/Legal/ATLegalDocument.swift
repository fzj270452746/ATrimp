//
//  ATLegalDocument.swift
//  ATrimp
//
//
import Foundation

enum ATLegalDocument {
    case terms
    case privacy
    case eula

    var title: String {
        switch self {
        case .terms: return "Terms of Service"
        case .privacy: return "Privacy Policy"
        case .eula: return "End User Licence Agreement"
        }
    }

    var shortTitle: String {
        switch self {
        case .terms: return "Terms of Service"
        case .privacy: return "Privacy Policy"
        case .eula: return "EULA"
        }
    }

    // The documents are held outside the app, so the page a reader opens is
    // always the published version. Terms of Service and the Privacy Policy
    // share a single page.

    var url: URL {
        switch self {
        case .terms, .privacy: return Self.termsURL
        case .eula: return Self.eulaURL
        }
    }

    private static let termsURL = URL(
        string: "https://www.privacypolicies.com/live/87f03a50-21ea-44be-9940-f5c073d0e4ad"
    )!

    private static let eulaURL = URL(
        string: "https://www.privacypolicies.com/live/a7628282-b013-46b1-86f7-0b5e5e5e6e3c"
    )!
}
