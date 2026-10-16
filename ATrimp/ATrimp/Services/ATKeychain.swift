//
//  ATKeychain.swift
//  ATrimp
//
//
import Foundation
import KeychainAccess

enum ATKeychain {

    enum Key: String {
        case signedInUserID = "atrimp.signedInUserID"
        case appleUserID = "atrimp.appleUserID"
    }

    private static let store = Keychain(service: "com.atrim.ATrimp")

    static func set(_ value: String?, for key: Key) {
        if let value {
            try? store.set(value, key: key.rawValue)
        } else {
            try? store.remove(key.rawValue)
        }
    }

    static func string(for key: Key) -> String? {
        try? store.get(key.rawValue)
    }
}
