//
//  ATStoreKit.swift
//  ATrimp
//
//
import Foundation
import StoreKit

enum ATPurchaseError: LocalizedError {
    case productUnavailable
    case cancelled
    case pending
    case verificationFailed
    case failed

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "That gift is not available right now."
        case .cancelled:
            return nil
        case .pending:
            return "Your purchase is waiting for approval."
        case .verificationFailed:
            return "The App Store could not confirm that purchase."
        case .failed:
            return "The purchase did not go through. Please try again."
        }
    }
}

final class ATStoreKit {

    static let shared = ATStoreKit()

    private(set) var products: [String: Product] = [:]
    private(set) var lastLoadFailed = false

    var hasProducts: Bool { !products.isEmpty }

    private init() {}

    @discardableResult
    func loadProducts() async -> [Product] {
        do {
            let fetched = try await Product.products(for: ATGiftCatalog.allSKUs)
            products = Dictionary(fetched.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            lastLoadFailed = fetched.isEmpty
            return fetched
        } catch {
            lastLoadFailed = true
            return []
        }
    }

    func price(for gift: ATGift) -> String {
        products[gift.sku]?.displayPrice ?? gift.displayPrice
    }

    func purchase(gift: ATGift) async throws -> String {
        var product = products[gift.sku]
        if product == nil {
            product = try? await Product.products(for: [gift.sku]).first
            if let product { products[gift.sku] = product }
        }
        guard let product else { throw ATPurchaseError.productUnavailable }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw ATPurchaseError.failed
        }

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw ATPurchaseError.verificationFailed
            }
            await transaction.finish()
            return String(transaction.id)

        case .userCancelled:
            throw ATPurchaseError.cancelled

        case .pending:
            throw ATPurchaseError.pending

        @unknown default:
            throw ATPurchaseError.failed
        }
    }
}
