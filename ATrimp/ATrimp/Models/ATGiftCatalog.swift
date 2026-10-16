//
//  ATGiftCatalog.swift
//  ATrimp
//
//
import Foundation

struct ATGift: Hashable {
    let sku: String
    let name: String
    let artwork: String?
    let symbol: String
    let price: Decimal
    let blurb: String
    let presence: Int
}

extension ATGift {
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
}

enum ATGiftCatalog {

    static let tiers: [ATGift] = [
        ATGift(sku: "lenxywkgfxfapppp", name: "Postcard", artwork: "Gift-Postcard", symbol: "envelope",
               price: 0.99, blurb: "A note from the road", presence: 1),
        ATGift(sku: "sfvchfreqqvylbsq", name: "Stamp", artwork: "Stamp", symbol: "seal",
               price: 1.99, blurb: "Make it official", presence: 1),
        ATGift(sku: "com.atrim.gift.compass", name: "Compass", artwork: "Compass", symbol: "safari",
               price: 2.99, blurb: "For the next wrong turn", presence: 2),
        ATGift(sku: "uqolhbwnthilopmj", name: "Pocket Map", artwork: "Map", symbol: "map",
               price: 4.99, blurb: "Folded, torn, loved", presence: 2),
        ATGift(sku: "hfwagmrmjavoovhr", name: "Thermos", artwork: "Thermos", symbol: "cup.and.saucer",
               price: 9.99, blurb: "For the long wait", presence: 3),
        ATGift(sku: "hruextnukwkqbiax", name: "Field Notebook", artwork: "Notebook", symbol: "book.closed",
               price: 19.99, blurb: "Write it down properly", presence: 3),
        ATGift(sku: "ygccqcprsndkwhqd", name: "Cabin Bag", artwork: "CabinBag", symbol: "bag",
               price: 49.99, blurb: "Carry-on sized gratitude", presence: 4),
        ATGift(sku: "vlhydxmeamgmqanv", name: "Round Trip", artwork: "RoundTrip", symbol: "airplane",
               price: 99.99, blurb: "The whole journey", presence: 4),
    ]

    static func gift(forSKU sku: String) -> ATGift? {
        tiers.first { $0.sku == sku }
    }

    static func gift(atTier index: Int) -> ATGift? {
        guard tiers.indices.contains(index) else { return nil }
        return tiers[index]
    }

    static var allSKUs: [String] {
        tiers.map(\.sku)
    }
}
