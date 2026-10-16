//
//  ATTime.swift
//  ATrimp
//
//
import Foundation

enum ATTime {

    private static let english = Locale(identifier: "en_US")

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = english
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private static let longFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = english
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = english
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = english
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = english
        formatter.unitsStyle = .full
        return formatter
    }()

    static func compact(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3_600 { return "\(Int(seconds / 60))m" }
        if seconds < 86_400 { return "\(Int(seconds / 3_600))h" }
        if seconds < 604_800 { return "\(Int(seconds / 86_400))d" }
        if seconds < 2_419_200 { return "\(Int(seconds / 604_800))w" }
        return dayFormatter.string(from: date)
    }

    static func relative(_ date: Date, now: Date = Date()) -> String {
        if abs(now.timeIntervalSince(date)) < 60 { return "just now" }
        return relativeFormatter.localizedString(for: date, relativeTo: now)
    }

    static func long(_ date: Date) -> String {
        longFormatter.string(from: date)
    }

    static func clock(_ date: Date) -> String {
        clockFormatter.string(from: date)
    }

    static func monthYear(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    static func dayHeading(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return longFormatter.string(from: date)
    }

    static func isSameDay(_ first: Date, _ second: Date) -> Bool {
        Calendar.current.isDate(first, inSameDayAs: second)
    }
}
