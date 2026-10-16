//
//  ATSeed.swift
//  ATrimp
//
//
import Foundation
import GRDB
import UIKit

enum ATSeed {

    static let accountUsername = "trip"
    static let accountPassword = "123456"

    private static let accountUserID = "u-trip"

    static func assetSlug(_ text: String) -> String {
        text.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    static func populateIfNeeded(in queue: DatabaseQueue) throws {
        let existing = try queue.read { try ATUser.fetchCount($0) }
        guard existing == 0 else { return }
        try queue.write { db in
            try insertEverything(into: db)
        }
    }

    static var roster: [ATSeedContent.SeedUser] {
        let withPortraits = ATSeedContent.users.filter { person in
            ATArt.bundled("Avatar-\(assetSlug(person.displayName))") != nil
        }
        return withPortraits.isEmpty ? ATSeedContent.users : withPortraits
    }

    // MARK: - Population

    private static func insertEverything(into db: Database) throws {
        var drift = Drift(seed: 0x5EED_1075)
        let now = Date()


        let correspondents = Set(ATSeedContent.threads.map(\.peerUsername))

        var users: [ATUser] = []
        for (index, person) in roster.enumerated() {
            let isFriend = index % 7 == 3 || correspondents.contains(person.username)

            users.append(ATUser(
                id: "u-\(person.username)",
                username: person.username,
                displayName: person.displayName,
                bio: person.bio,
                homeCity: person.city,
                avatarSeed: "Avatar-\(assetSlug(person.displayName))",
                followingCount: drift.int(38...412),
                followerCount: drift.int(24...1860),
                postCount: drift.int(4...71),
                friendStateRaw: (isFriend ? ATFriendState.friends : ATFriendState.none).rawValue,
                isCurrentUser: false,
                appleUserID: nil,
                createdAt: now.addingTimeInterval(-Double(drift.int(240...1500)) * 86_400)
            ))
        }

        let account = ATUser(
            id: accountUserID,
            username: accountUsername,
            displayName: "Avery Lin",
            bio: "Keeping a record of the parts that did not go to plan.",
            homeCity: "Rotterdam",
            avatarSeed: "Avatar-AveryLin",
            followingCount: 0,
            followerCount: 0,
            postCount: 0,
            friendStateRaw: ATFriendState.none.rawValue,
            isCurrentUser: false,
            appleUserID: nil,
            createdAt: now.addingTimeInterval(-620 * 86_400)
        )

        for user in users { try user.insert(db) }
        try account.insert(db)


        var posts: [ATPost] = []
        var media: [ATPostMedia] = []

        for (index, seed) in ATSeedContent.posts.enumerated() {
            let authorID = users[(index * 11) % users.count].id

            let postID = "p-\(index)"
            let daysAgo = Double(index) * 2.1 + drift.double(0...1.6)

            let redemptionOffsets: [Int: Double] = [3: 4, 24: 30, 33: 21, 40: 46]

            var post = ATPost(
                id: postID,
                authorID: authorID,
                body: seed.body,
                themeRaw: seed.theme.rawValue,
                locationName: seed.location,
                country: seed.country,
                createdAt: now.addingTimeInterval(-daysAgo * 86_400),
                likeCount: drift.int(6...940),
                commentCount: 0,
                giftCount: 0,
                isLiked: false,
                redeemedAt: redemptionOffsets[index].map { days in
                    min(
                        now.addingTimeInterval(-(daysAgo - days) * 86_400),
                        now.addingTimeInterval(-86_400)
                    )
                },
                intensity: index % 3 == 2 ? nil : (index % 5) + 1,
                sameCount: index % 5 == 4 ? 0 : (index * 13) % 37,
                isSameHere: false,
                answersPostID: nil
            )

            for slot in 0..<seed.mediaCount {
                let isVideo = seed.hasVideo && slot == seed.mediaCount - 1
                let prefix = isVideo ? "Clip" : "Photo"
                media.append(ATPostMedia(
                    id: "m-\(postID)-\(slot)",
                    postID: postID,
                    kind: isVideo ? .video : .image,
                    reference: "\(prefix)-\(assetSlug(seed.location))-\(slot + 1)",
                    sortIndex: slot,
                    aspect: drift.pick([1.0, 1.5, 1.333, 0.8, 1.25, 0.75])
                ))
            }

            let pool = ATSeedContent.commentsByTheme[seed.theme] ?? []
            let commentTotal = drift.int(1...3)

            for slot in 0..<commentTotal {
                let usingPool = slot < pool.count
                let body = usingPool
                    ? pool[(index + slot * 3) % pool.count]
                    : ATSeedContent.genericComments[(index + slot) % ATSeedContent.genericComments.count]

                let commentedAt = min(
                    post.createdAt.addingTimeInterval(Double(drift.int(600...90_000))),
                    now.addingTimeInterval(-Double(drift.int(900...86_400)))
                )

                let comment = ATComment(
                    id: "c-\(postID)-\(slot)",
                    postID: postID,
                    authorID: users[drift.int(0...(users.count - 1))].id,
                    body: body,
                    createdAt: commentedAt,
                    isMine: false,
                    isSeeded: true
                )
                try comment.insert(db)
            }
            post.commentCount = commentTotal

            if index % 5 == 2 {
                let giftTotal = drift.int(1...3)
                for slot in 0..<giftTotal {
                    let tier = drift.int(0...7)
                    let gift = ATGiftRecord(
                        id: "g-\(postID)-\(slot)",
                        postID: postID,
                        fromUserID: users[drift.int(0...(users.count - 1))].id,
                        sku: ATGiftCatalog.tiers[tier].sku,
                        tierIndex: tier,
                        createdAt: post.createdAt.addingTimeInterval(Double(drift.int(300...50_000)))
                    )
                    try gift.insert(db)
                }
                post.giftCount = giftTotal
            }

            posts.append(post)
        }

        for post in posts { try post.insert(db) }
        for item in media { try item.insert(db) }


        for (index, thread) in ATSeedContent.threads.enumerated() {
            guard let peer = users.first(where: { $0.username == thread.peerUsername }) else { continue }

            let conversationID = "conv-\(peer.id)"

            let span = drift.double(4...32) * 86_400
            let endsAt = now.addingTimeInterval(-(Double(index) * 5_400 + drift.double(1_200...40_000)))
            let startsAt = endsAt.addingTimeInterval(-span)
            let step = span / Double(max(1, thread.messages.count - 1))

            var lastSentAt = startsAt

            for (position, line) in thread.messages.enumerated() {
                let fromPeer = (position % 2 == 0) == thread.firstSpeakerIsPeer
                let sentAt = startsAt.addingTimeInterval(step * Double(position))
                lastSentAt = sentAt

                let message = ATMessage(
                    id: "msg-\(conversationID)-\(position)",
                    conversationID: conversationID,
                    senderID: fromPeer ? peer.id : accountUserID,
                    kindRaw: ATMessageKind.text.rawValue,
                    body: line,
                    createdAt: sentAt,
                    isRead: true
                )
                try message.insert(db)
            }

            let unread = index % 4 == 1 ? drift.int(1...3) : 0
            let conversation = ATConversation(
                id: conversationID,
                peerUserID: peer.id,
                lastMessageAt: lastSentAt,
                unreadCount: unread
            )
            try conversation.insert(db)
        }

        let returns: [(original: Int, daysLater: Double, theme: ATPostTheme, body: String, photos: Int)] = [
            (
                3, 4, .surprise,
                "Went back in March and said yes to every glass of tea I was offered, including two I did not want. Ended up sitting with a shopkeeper for an hour arguing about nothing at all. The medina is the same size. I had just been walking through it wrong.",
                2
            ),
            (
                40, 46, .surprise,
                "Second visit, up at half six, no camera out until eight. The blue is exactly the same blue. What changed was the queue — at that hour there is no queue, only a man hosing down his step and a cat that owns the alley.",
                2
            ),
        ]

        for entry in returns {
            let original = posts[entry.original]
            let answerID = "p-answer-\(entry.original)"
            let answer = ATPost(
                id: answerID,
                authorID: original.authorID,
                body: entry.body,
                themeRaw: entry.theme.rawValue,
                locationName: original.locationName,
                country: original.country,
                createdAt: original.createdAt.addingTimeInterval(entry.daysLater * 86_400),
                likeCount: 60 + entry.original * 3,
                commentCount: 0,
                giftCount: 0,
                isLiked: false,
                redeemedAt: nil,
                intensity: nil,
                sameCount: entry.original % 11,
                isSameHere: false,
                answersPostID: original.id
            )
            try answer.insert(db)

            for slot in 0..<entry.photos {
                let item = ATPostMedia(
                    id: "m-\(answerID)-\(slot)",
                    postID: answerID,
                    kind: .image,
                    reference: "Photo-\(assetSlug(original.locationName))-\(slot + 1)",
                    sortIndex: slot,
                    aspect: 1.5
                )
                try item.insert(db)
            }
        }


        let salt = ATPassword.makeSalt()
        let credential = ATCredential(
            username: accountUsername,
            userID: accountUserID,
            salt: salt,
            passwordHash: ATPassword.hash(accountPassword, salt: salt)
        )
        try credential.insert(db)
    }
}

// MARK: - Deterministic sequence

private struct Drift {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    mutating func double(_ range: ClosedRange<Double>) -> Double {
        let unit = Double(next() % 10_000) / 10_000
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }

    mutating func pick<T>(_ options: [T]) -> T {
        options[int(0...(options.count - 1))]
    }
}
