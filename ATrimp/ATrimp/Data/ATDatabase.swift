//
//  ATDatabase.swift
//  ATrimp
//
//
import Foundation
import GRDB

final class ATDatabase {

    static let shared = ATDatabase()

    let writer: DatabaseQueue

    private static var directoryURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ATrimp", isDirectory: true)
    }

    private static var fileURL: URL {
        directoryURL.appendingPathComponent("store.sqlite")
    }

    private init() {
        var configuration = Configuration()
        configuration.prepareDatabase { database in
            try database.execute(sql: "PRAGMA foreign_keys = ON")
        }

        var queue = Self.open(configuration: configuration)
        do {
            try Self.migrator.migrate(queue)
        } catch {
            #if DEBUG
            assertionFailure("ATrimp migration failed, the store is about to be erased: \(error)")
            #endif
            try? FileManager.default.removeItem(at: Self.fileURL)
            queue = Self.open(configuration: configuration)
            do {
                try Self.migrator.migrate(queue)
            } catch {
                #if DEBUG
                assertionFailure("ATrimp migration failed again after erasing the store: \(error)")
                #endif
            }
        }
        writer = queue
        try? ATSeed.populateIfNeeded(in: queue)
    }

    private static func open(configuration: Configuration) -> DatabaseQueue {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        if let queue = try? DatabaseQueue(path: fileURL.path, configuration: configuration) {
            return queue
        }
        return try! DatabaseQueue(configuration: configuration)
    }

    // MARK: - Schema

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in

            try db.create(table: "user") { table in
                table.column("id", .text).primaryKey()
                table.column("username", .text).notNull().unique()
                table.column("displayName", .text).notNull()
                table.column("bio", .text).notNull().defaults(to: "")
                table.column("homeCity", .text).notNull().defaults(to: "")
                table.column("avatarSeed", .text).notNull()
                table.column("followingCount", .integer).notNull().defaults(to: 0)
                table.column("followerCount", .integer).notNull().defaults(to: 0)
                table.column("postCount", .integer).notNull().defaults(to: 0)
                table.column("isFollowing", .boolean).notNull().defaults(to: false)
                table.column("followsUs", .boolean).notNull().defaults(to: false)
                table.column("friendStateRaw", .text).notNull().defaults(to: "none")
                table.column("isCurrentUser", .boolean).notNull().defaults(to: false)
                table.column("appleUserID", .text)
                table.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "credential") { table in
                table.column("username", .text).primaryKey()
                table.column("userID", .text).notNull()
                table.column("salt", .text).notNull()
                table.column("passwordHash", .text).notNull()
            }

            try db.create(table: "post") { table in
                table.column("id", .text).primaryKey()
                table.column("authorID", .text).notNull().indexed()
                table.column("body", .text).notNull()
                table.column("themeRaw", .text).notNull().indexed()
                table.column("locationName", .text).notNull()
                table.column("country", .text).notNull()
                table.column("createdAt", .datetime).notNull().indexed()
                table.column("likeCount", .integer).notNull().defaults(to: 0)
                table.column("commentCount", .integer).notNull().defaults(to: 0)
                table.column("giftCount", .integer).notNull().defaults(to: 0)
                table.column("isLiked", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "postMedia") { table in
                table.column("id", .text).primaryKey()
                table.column("postID", .text).notNull().indexed()
                table.column("kindRaw", .text).notNull()
                table.column("reference", .text).notNull()
                table.column("sortIndex", .integer).notNull()
                table.column("aspect", .double).notNull().defaults(to: 1)
            }

            try db.create(table: "comment") { table in
                table.column("id", .text).primaryKey()
                table.column("postID", .text).notNull().indexed()
                table.column("authorID", .text).notNull()
                table.column("body", .text).notNull()
                table.column("createdAt", .datetime).notNull()
                table.column("isMine", .boolean).notNull().defaults(to: false)
                table.column("isSeeded", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "giftRecord") { table in
                table.column("id", .text).primaryKey()
                table.column("postID", .text).notNull().indexed()
                table.column("fromUserID", .text).notNull()
                table.column("sku", .text).notNull()
                table.column("tierIndex", .integer).notNull()
                table.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "conversation") { table in
                table.column("id", .text).primaryKey()
                table.column("peerUserID", .text).notNull().unique()
                table.column("lastMessageAt", .datetime).notNull().indexed()
                table.column("unreadCount", .integer).notNull().defaults(to: 0)
            }

            try db.create(table: "message") { table in
                table.column("id", .text).primaryKey()
                table.column("conversationID", .text).notNull().indexed()
                table.column("senderID", .text).notNull()
                table.column("kindRaw", .text).notNull()
                table.column("body", .text).notNull()
                table.column("createdAt", .datetime).notNull().indexed()
                table.column("isRead", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "purchase") { table in
                table.column("id", .text).primaryKey()
                table.column("sku", .text).notNull()
                table.column("transactionID", .text).notNull()
                table.column("purchasedAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v2") { db in
            try db.create(table: "follow") { table in
                table.column("followerID", .text).notNull().indexed()
                table.column("followeeID", .text).notNull().indexed()
                table.column("createdAt", .datetime).notNull()
                table.primaryKey(["followerID", "followeeID"])
            }

            try db.alter(table: "user") { table in
                table.drop(column: "isFollowing")
                table.drop(column: "followsUs")
            }
        }

        migrator.registerMigration("v3") { db in
            try db.create(table: "note") { table in
                table.column("id", .text).primaryKey()
                table.column("userID", .text).notNull().indexed()
                table.column("placeKey", .text).notNull().indexed()
                table.column("placeName", .text).notNull()
                table.column("country", .text).notNull().defaults(to: "")
                table.column("body", .text).notNull()
                table.column("sourcePostID", .text)
                table.column("createdAt", .datetime).notNull()
                table.column("resolvedAt", .datetime)
            }

            try db.alter(table: "post") { table in
                table.add(column: "redeemedAt", .datetime)
            }
        }

        migrator.registerMigration("v4") { db in
            try db.alter(table: "post") { table in
                table.add(column: "intensity", .integer)
            }
        }

        migrator.registerMigration("v5") { db in
            try db.alter(table: "post") { table in
                table.add(column: "sameCount", .integer).notNull().defaults(to: 0)
                table.add(column: "isSameHere", .boolean).notNull().defaults(to: false)
                table.add(column: "answersPostID", .text)
            }
        }

        migrator.registerMigration("v6") { db in
            try db.create(table: "expense") { table in
                table.column("id", .text).primaryKey()
                table.column("userID", .text).notNull().indexed()
                table.column("placeKey", .text).notNull()
                table.column("placeName", .text).notNull()
                table.column("country", .text).notNull().defaults(to: "")
                table.column("categoryRaw", .text).notNull()
                table.column("amount", .text).notNull()
                table.column("people", .integer).notNull().defaults(to: 1)
                table.column("note", .text).notNull().defaults(to: "")
                table.column("spentAt", .datetime).notNull()
                table.column("createdAt", .datetime).notNull()
            }
        }

        return migrator
    }
}
