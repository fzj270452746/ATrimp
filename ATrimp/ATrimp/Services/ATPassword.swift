//
//  ATPassword.swift
//  ATrimp
//
//
import Foundation
import CryptoKit

enum ATPassword {

    static func makeSalt() -> String {
        var generator = SystemRandomNumberGenerator()
        return (0..<4)
            .map { _ in String(UInt64.random(in: .min ... .max, using: &generator), radix: 16) }
            .joined()
    }

    static func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data("\(salt):\(password)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func matches(_ password: String, salt: String, hash expected: String) -> Bool {
        hash(password, salt: salt) == expected
    }
}
