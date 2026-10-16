//
//  ATModels.swift
//  ATrimp
//
//
import Foundation
import GRDB

// MARK: - Relationship

enum ATFriendState: String, Codable {
    case none
    case requested
    case incoming
    case friends
}

// MARK: - User

struct ATUser: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var username: String
    var displayName: String
    var bio: String
    var homeCity: String
    var avatarSeed: String
    var followingCount: Int
    var followerCount: Int
    var postCount: Int
    var friendStateRaw: String
    var isCurrentUser: Bool
    var appleUserID: String?
    var createdAt: Date

    static let databaseTableName = "user"

    var friendState: ATFriendState {
        get { ATFriendState(rawValue: friendStateRaw) ?? .none }
        set { friendStateRaw = newValue.rawValue }
    }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }
}

// MARK: - Follow

struct ATFollow: Codable, FetchableRecord, PersistableRecord, Hashable {
    var followerID: String
    var followeeID: String
    var createdAt: Date

    static let databaseTableName = "follow"
}

// MARK: - Post

struct ATPost: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var authorID: String
    var body: String
    var themeRaw: String
    var locationName: String
    var country: String
    var createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var giftCount: Int
    var isLiked: Bool
    var redeemedAt: Date?
    var intensity: Int?
    var sameCount: Int
    var isSameHere: Bool
    var answersPostID: String?

    static let databaseTableName = "post"

    var theme: ATPostTheme {
        ATPostTheme(rawValue: themeRaw) ?? .surprise
    }

    var isRedeemed: Bool { redeemedAt != nil }

    var isRevisit: Bool { answersPostID != nil }
}

// MARK: - Note

struct ATNote: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var userID: String
    var placeKey: String
    var placeName: String
    var country: String
    var body: String
    var sourcePostID: String?
    var createdAt: Date
    var resolvedAt: Date?

    static let databaseTableName = "note"

    var isResolved: Bool { resolvedAt != nil }
}

// MARK: - Media

enum ATMediaKind: String, Codable {
    case image
    case video
}

struct ATPostMedia: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var postID: String
    var kindRaw: String
    var reference: String
    var sortIndex: Int
    var aspect: Double

    static let databaseTableName = "postMedia"

    init(
        id: String = UUID().uuidString,
        postID: String,
        kind: ATMediaKind,
        reference: String,
        sortIndex: Int,
        aspect: Double = 1
    ) {
        self.id = id
        self.postID = postID
        self.kindRaw = kind.rawValue
        self.reference = reference
        self.sortIndex = sortIndex
        self.aspect = aspect
    }

    var kind: ATMediaKind { ATMediaKind(rawValue: kindRaw) ?? .image }

    var localFileName: String? {
        reference.hasPrefix("file:") ? String(reference.dropFirst(5)) : nil
    }
}

// MARK: - Comment

struct ATComment: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var postID: String
    var authorID: String
    var body: String
    var createdAt: Date
    var isMine: Bool
    var isSeeded: Bool

    static let databaseTableName = "comment"
}

// MARK: - Gift

struct ATGiftRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var postID: String
    var fromUserID: String
    var sku: String
    var tierIndex: Int
    var createdAt: Date

    static let databaseTableName = "giftRecord"
}

// MARK: - Conversation

struct ATConversation: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var peerUserID: String
    var lastMessageAt: Date
    var unreadCount: Int

    static let databaseTableName = "conversation"
}

// MARK: - Message

enum ATMessageKind: String, Codable {
    case text
    case image
    case gift
    case callLog
}

struct ATMessage: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var conversationID: String
    var senderID: String
    var kindRaw: String
    var body: String
    var createdAt: Date
    var isRead: Bool

    static let databaseTableName = "message"

    var kind: ATMessageKind { ATMessageKind(rawValue: kindRaw) ?? .text }
}

// MARK: - Credential

struct ATCredential: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var username: String
    var userID: String
    var salt: String
    var passwordHash: String

    var id: String { username }

    static let databaseTableName = "credential"
}

// MARK: - Purchase

struct ATPurchase: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var sku: String
    var transactionID: String
    var purchasedAt: Date

    static let databaseTableName = "purchase"
}
