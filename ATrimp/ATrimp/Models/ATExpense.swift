//
//  ATExpense.swift
//  ATrimp
//
//

import GRDB
import UIKit

enum ATExpenseCategory: String, CaseIterable, Codable {
    case flights
    case stays
    case food
    case ground
    case tickets
    case shopping
    case other

    var title: String {
        switch self {
        case .flights: return "Flights"
        case .stays: return "Stays"
        case .food: return "Food"
        case .ground: return "Ground"
        case .tickets: return "Tickets"
        case .shopping: return "Shopping"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .flights: return "airplane"
        case .stays: return "bed.double"
        case .food: return "fork.knife"
        case .ground: return "tram"
        case .tickets: return "ticket"
        case .shopping: return "bag"
        case .other: return "ellipsis.circle"
        }
    }

    var tint: UIColor {
        switch self {
        case .flights: return UIColor(hex: 0x3E6E9E)
        case .stays: return UIColor(hex: 0x7A5CA8)
        case .food: return UIColor(hex: 0xB5541F)
        case .ground: return UIColor(hex: 0x2F6D62)
        case .tickets: return UIColor(hex: 0xC98A2B)
        case .shopping: return UIColor(hex: 0x9B4A57)
        case .other: return UIColor(hex: 0x6B7043)
        }
    }
}

struct ATExpense: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {

    var id: String
    var userID: String
    var placeKey: String
    var placeName: String
    var country: String
    var categoryRaw: String
    var amount: Decimal
    var people: Int
    var note: String
    var spentAt: Date
    var createdAt: Date

    static let databaseTableName = "expense"

    var category: ATExpenseCategory { ATExpenseCategory(rawValue: categoryRaw) ?? .other }

    var share: Decimal { people > 0 ? amount / Decimal(people) : amount }

    var place: ATPlace { ATPlace.resolve(locationName: placeName, country: country) }

    var isSplit: Bool { people > 1 }
}

enum ATMoney {

    private static let parserLocale = Locale(identifier: "en_US_POSIX")

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = parserLocale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static func parse(_ text: String) -> Decimal? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: ",", with: "")
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }
        guard let amount = Decimal(string: cleaned, locale: parserLocale) else { return nil }
        guard amount > 0 else { return nil }
        return amount
    }

    static func format(_ amount: Decimal) -> String {
        formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

struct ATExpenseLedger {

    let expenses: [ATExpense]

    init(_ expenses: [ATExpense]) {
        self.expenses = expenses
    }

    var isEmpty: Bool { expenses.isEmpty }

    var entryCount: Int { expenses.count }

    var placeCount: Int { Set(expenses.map(\.placeKey)).count }

    var total: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var share: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.share }
    }

    var hasSplit: Bool { expenses.contains(where: \.isSplit) }

    var byCategory: [(category: ATExpenseCategory, total: Decimal, count: Int)] {
        var totals: [ATExpenseCategory: (sum: Decimal, count: Int)] = [:]
        for expense in expenses {
            let running = totals[expense.category] ?? (Decimal.zero, 0)
            totals[expense.category] = (running.sum + expense.amount, running.count + 1)
        }
        return totals
            .map { (category: $0.key, total: $0.value.sum, count: $0.value.count) }
            .sorted {
                $0.total == $1.total
                    ? $0.category.title < $1.category.title
                    : $0.total > $1.total
            }
    }

    var byPlace: [(place: ATPlace, expenses: [ATExpense], total: Decimal)] {
        var groups: [String: (place: ATPlace, expenses: [ATExpense])] = [:]
        for expense in expenses {
            let place = expense.place
            var running = groups[place.key] ?? (place, [])
            running.expenses.append(expense)
            groups[place.key] = running
        }
        return groups
            .map { (place: $0.value.place, expenses: $0.value.expenses, total: $0.value.expenses.reduce(Decimal.zero) { $0 + $1.amount }) }
            .sorted {
                $0.total == $1.total
                    ? $0.place.name < $1.place.name
                    : $0.total > $1.total
            }
    }
}
