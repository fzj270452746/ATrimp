//
//  ATNotifications.swift
//  ATrimp
//
//
import Foundation
import UserNotifications

enum ATNotifications {

    private static let enabledKey = "ATrimp.notifications.enabled"
    private static let seenKey = "ATrimp.notifications.seenAt"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static func enable(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    isEnabled = granted
                    if granted { markSeen() }
                    completion(granted)
                }
            }
    }

    static func disable() {
        isEnabled = false
    }

    static func checkForFilingsAtNotedPlaces() {
        guard isEnabled else { return }

        let notes = ATStore.notes().filter { !$0.isResolved }
        guard !notes.isEmpty else { return }

        let since = UserDefaults.standard.object(forKey: seenKey) as? Date ?? Date()
        let keys = Set(notes.map(\.placeKey))

        let arrivals = ATStore.placeSummaries()
            .filter { keys.contains($0.place.key) }
            .compactMap { dossier -> (name: String, count: Int)? in
                let fresh = dossier.posts.filter { $0.createdAt > since }.count
                return fresh > 0 ? (dossier.place.name, fresh) : nil
            }

        markSeen()
        guard !arrivals.isEmpty else { return }

        let total = arrivals.reduce(0) { $0 + $1.count }
        let places = arrivals.prefix(3).map(\.name).joined(separator: ", ")
        post(
            title: total == 1 ? "One new filing where you have a note" : "\(total) new filings where you have notes",
            body: "\(places). Open \(arrivals.count == 1 ? "it" : "them") before you go."
        )
    }

    private static func markSeen() {
        UserDefaults.standard.set(Date(), forKey: seenKey)
    }

    private static func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
