//
//  ATStore.swift
//  ATrimp
//
//
import Foundation
import GRDB

enum ATStore {

    static var db: DatabaseQueue { ATDatabase.shared.writer }

    // MARK: - Feed

    static func posts(
        theme: ATPostTheme? = nil,
        offset: Int = 0,
        limit: Int,
        carryingVideo: Bool? = nil,
        includingRevisits: Bool = true
    ) -> [ATPost] {
        (try? db.read { database in
            var request = ATPost.all()
            if let theme {
                request = request.filter(Column("themeRaw") == theme.rawValue)
            }
            if !includingRevisits {
                request = request.filter(Column("answersPostID") == nil)
            }
            if let carryingVideo {
                let holdsVideo = """
                    EXISTS (SELECT 1 FROM postMedia \
                    WHERE postMedia.postID = post.id AND postMedia.kindRaw = ?)
                    """
                request = request.filter(
                    sql: carryingVideo ? holdsVideo : "NOT \(holdsVideo)",
                    arguments: [ATMediaKind.video.rawValue]
                )
            }
            return try request
                .order(Column("createdAt").desc)
                .limit(limit, offset: offset)
                .fetchAll(database)
        }) ?? []
    }

    static func post(id: String) -> ATPost? {
        try? db.read { try ATPost.fetchOne($0, key: id) }
    }

    static func postCount(theme: ATPostTheme? = nil) -> Int {
        (try? db.read { database in
            var request = ATPost.all()
            if let theme {
                request = request.filter(Column("themeRaw") == theme.rawValue)
            }
            return try request.fetchCount(database)
        }) ?? 0
    }

    static func posts(byAuthor authorID: String) -> [ATPost] {
        (try? db.read {
            try ATPost
                .filter(Column("authorID") == authorID)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    static func likedPosts() -> [ATPost] {
        (try? db.read {
            try ATPost
                .filter(Column("isLiked") == true)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    static func setLiked(_ liked: Bool, postID: String) {
        try? db.write { database in
            guard let post = try ATPost.fetchOne(database, key: postID), post.isLiked != liked else { return }
            try ATPost
                .filter(Column("id") == postID)
                .updateAll(
                    database,
                    Column("isLiked").set(to: liked),
                    Column("likeCount").set(to: max(0, post.likeCount + (liked ? 1 : -1)))
                )
        }
    }

    static func insertPost(
        authorID: String,
        body: String,
        theme: ATPostTheme,
        locationName: String,
        country: String,
        intensity: Int? = nil,
        answersPostID: String? = nil,
        media: [(kind: ATMediaKind, reference: String, aspect: Double)]
    ) -> ATPost {
        let postID = UUID().uuidString
        let post = ATPost(
            id: postID,
            authorID: authorID,
            body: body,
            themeRaw: theme.rawValue,
            locationName: locationName,
            country: country,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            giftCount: 0,
            isLiked: false,
            redeemedAt: nil,
            intensity: intensity,
            sameCount: 0,
            isSameHere: false,
            answersPostID: answersPostID
        )

        try? db.write { database in
            try post.insert(database)
            for (slot, item) in media.enumerated() {
                let record = ATPostMedia(
                    id: UUID().uuidString,
                    postID: postID,
                    kind: item.kind,
                    reference: item.reference,
                    sortIndex: slot,
                    aspect: item.aspect
                )
                try record.insert(database)
            }
            if let answersPostID {
                try ATPost
                    .filter(Column("id") == answersPostID)
                    .updateAll(database, Column("redeemedAt").set(to: Date()))
            }
            try ATUser
                .filter(Column("id") == authorID)
                .updateAll(database, Column("postCount").set(to: Column("postCount") + 1))
        }

        return post
    }

    static func deletePost(id: String) {
        try? db.write { database in
            guard let post = try ATPost.fetchOne(database, key: id) else { return }
            try ATPostMedia.filter(Column("postID") == id).deleteAll(database)
            try ATComment.filter(Column("postID") == id).deleteAll(database)
            try ATGiftRecord.filter(Column("postID") == id).deleteAll(database)
            try ATPost.filter(Column("id") == id).deleteAll(database)
            try ATUser
                .filter(Column("id") == post.authorID)
                .updateAll(database, Column("postCount").set(to: Column("postCount") - 1))
        }
    }

    // MARK: - Places

    static func allPosts() -> [ATPost] {
        (try? db.read { try ATPost.order(Column("createdAt").desc).fetchAll($0) }) ?? []
    }

    private static func placeGroups() -> [String: [ATPost]] {
        Dictionary(grouping: allPosts()) {
            ATPlace.resolve(locationName: $0.locationName, country: $0.country).key
        }
    }

    static func placeSummaries() -> [ATPlaceDossier] {
        placeGroups().compactMap { _, posts in
            guard let first = posts.first else { return nil }
            let place = ATPlace.resolve(locationName: first.locationName, country: first.country)
            return ATPlaceDossier(place: place, posts: posts)
        }
        .sorted { ($0.latestFiledAt ?? .distantPast) > ($1.latestFiledAt ?? .distantPast) }
    }

    static func dossier(for place: ATPlace) -> ATPlaceDossier {
        ATPlaceDossier(place: place, posts: placeGroups()[place.key] ?? [])
    }

    static func pinnedPlaceSummaries() -> [ATPlaceDossier] {
        placeSummaries()
            .filter { $0.place.hasCoordinate }
            .sorted { $0.postCount > $1.postCount }
    }

    struct ATReaderReading {
        var filed: [ATPostTheme: Int] = [:]
        var liked: [ATPostTheme: Int] = [:]
        var discussed: [ATPostTheme: Int] = [:]

        var filedTotal: Int { filed.values.reduce(0, +) }
        var likedTotal: Int { liked.values.reduce(0, +) }
        var discussedTotal: Int { discussed.values.reduce(0, +) }
        var total: Int { filedTotal + likedTotal + discussedTotal }
        var isEmpty: Bool { total == 0 }

        var byWeight: [(theme: ATPostTheme, count: Int)] {
            var merged: [ATPostTheme: Int] = [:]
            for counts in [filed, liked, discussed] {
                for (theme, count) in counts { merged[theme, default: 0] += count }
            }
            return merged
                .map { (theme: $0.key, count: $0.value) }
                .sorted { $0.count == $1.count ? $0.theme.title < $1.theme.title : $0.count > $1.count }
        }
    }

    static func readerReading() -> ATReaderReading {
        guard let readerID = currentUser()?.id else { return ATReaderReading() }

        var reading = ATReaderReading()
        for post in posts(byAuthor: readerID) {
            reading.filed[post.theme, default: 0] += 1
        }
        for post in likedPosts() {
            reading.liked[post.theme, default: 0] += 1
        }

        let own = comments(byAuthor: readerID, limit: 400)
        let onPosts = posts(ids: Array(Set(own.map(\.postID))))
        for comment in own {
            guard let theme = onPosts[comment.postID]?.theme else { continue }
            reading.discussed[theme, default: 0] += 1
        }
        return reading
    }

    static func posts(ids: [String]) -> [String: ATPost] {
        guard !ids.isEmpty else { return [:] }
        let rows = (try? db.read {
            try ATPost.filter(ids.contains(Column("id"))).fetchAll($0)
        }) ?? []
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    }

    static func libraryThemeCounts() -> [(theme: ATPostTheme, count: Int)] {
        ATPostTheme.allCases
            .map { (theme: $0, count: postCount(theme: $0)) }
            .filter { $0.count > 0 }
    }

    // MARK: - Search

    struct ATSearchResults {
        var places: [ATPlaceDossier] = []
        var people: [ATUser] = []
        var posts: [ATPost] = []

        var isEmpty: Bool { places.isEmpty && people.isEmpty && posts.isEmpty }
    }

    static func search(_ text: String) -> ATSearchResults {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 1 else { return ATSearchResults() }

        let pattern = "%\(needle.lowercased())%"
        var results = ATSearchResults()

        results.places = placeSummaries().filter {
            $0.place.name.lowercased().contains(needle.lowercased())
                || $0.place.country.lowercased().contains(needle.lowercased())
        }

        results.people = (try? db.read {
            try ATUser
                .filter(Column("isCurrentUser") == false)
                .filter(sql: """
                    LOWER(displayName) LIKE ? OR LOWER(username) LIKE ? \
                    OR LOWER(homeCity) LIKE ? OR LOWER(bio) LIKE ?
                    """, arguments: [pattern, pattern, pattern, pattern])
                .order(Column("displayName"))
                .limit(24)
                .fetchAll($0)
        }) ?? []

        results.posts = (try? db.read {
            try ATPost
                .filter(sql: """
                    LOWER(body) LIKE ? OR LOWER(locationName) LIKE ? OR LOWER(country) LIKE ?
                    """, arguments: [pattern, pattern, pattern])
                .order(Column("createdAt").desc)
                .limit(40)
                .fetchAll($0)
        }) ?? []

        return results
    }

    // MARK: - Notes

    static func notes() -> [ATNote] {
        guard let readerID = currentUser()?.id else { return [] }
        return (try? db.read {
            try ATNote
                .filter(Column("userID") == readerID)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    static func notes(forPlaceKey key: String) -> [ATNote] {
        guard let readerID = currentUser()?.id else { return [] }
        return (try? db.read {
            try ATNote
                .filter(Column("userID") == readerID)
                .filter(Column("placeKey") == key)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    static func noteCount(forPlaceKey key: String) -> Int {
        notes(forPlaceKey: key).count
    }

    @discardableResult
    static func addNote(place: ATPlace, body: String, sourcePostID: String?) -> ATNote? {
        guard let readerID = currentUser()?.id else { return nil }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let note = ATNote(
            id: UUID().uuidString,
            userID: readerID,
            placeKey: place.key,
            placeName: place.name,
            country: place.country,
            body: trimmed,
            sourcePostID: sourcePostID,
            createdAt: Date(),
            resolvedAt: nil
        )
        try? db.write { try note.insert($0) }
        return note
    }

    static func setNoteResolved(_ resolved: Bool, id: String) {
        try? db.write { database in
            try ATNote
                .filter(Column("id") == id)
                .updateAll(database, Column("resolvedAt").set(to: resolved ? Date() : nil))
        }
    }

    static func deleteNote(id: String) {
        try? db.write { try ATNote.filter(Column("id") == id).deleteAll($0) }
    }

    // MARK: - Expenses

    static func expenses() -> [ATExpense] {
        guard let readerID = currentUser()?.id else { return [] }
        return (try? db.read {
            try ATExpense
                .filter(Column("userID") == readerID)
                .order(Column("spentAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    static func expense(id: String) -> ATExpense? {
        try? db.read { try ATExpense.fetchOne($0, key: id) }
    }

    static func expenses(forPlaceKey key: String) -> [ATExpense] {
        guard let readerID = currentUser()?.id else { return [] }
        return (try? db.read {
            try ATExpense
                .filter(Column("userID") == readerID)
                .filter(Column("placeKey") == key)
                .order(Column("spentAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    @discardableResult
    static func addExpense(
        place: ATPlace,
        category: ATExpenseCategory,
        amount: Decimal,
        people: Int,
        note: String,
        spentAt: Date
    ) -> ATExpense? {
        guard let readerID = currentUser()?.id else { return nil }
        guard amount > 0, people >= 1 else { return nil }

        let record = ATExpense(
            id: UUID().uuidString,
            userID: readerID,
            placeKey: place.key,
            placeName: place.name,
            country: place.country,
            categoryRaw: category.rawValue,
            amount: amount,
            people: people,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            spentAt: spentAt,
            createdAt: Date()
        )
        try? db.write { try record.insert($0) }
        return record
    }

    static func updateExpense(
        id: String,
        place: ATPlace,
        category: ATExpenseCategory,
        amount: Decimal,
        people: Int,
        note: String,
        spentAt: Date
    ) {
        guard let readerID = currentUser()?.id else { return }
        guard amount > 0, people >= 1 else { return }

        try? db.write { database in
            try ATExpense
                .filter(Column("id") == id)
                .filter(Column("userID") == readerID)
                .updateAll(
                    database,
                    Column("placeKey").set(to: place.key),
                    Column("placeName").set(to: place.name),
                    Column("country").set(to: place.country),
                    Column("categoryRaw").set(to: category.rawValue),
                    Column("amount").set(to: amount),
                    Column("people").set(to: people),
                    Column("note").set(to: note.trimmingCharacters(in: .whitespacesAndNewlines)),
                    Column("spentAt").set(to: spentAt)
                )
        }
    }

    static func deleteExpense(id: String) {
        try? db.write { try ATExpense.filter(Column("id") == id).deleteAll($0) }
    }

    // MARK: - Redemption

    static func setRedeemed(_ redeemed: Bool, postID: String) {
        try? db.write { database in
            try ATPost
                .filter(Column("id") == postID)
                .updateAll(database, Column("redeemedAt").set(to: redeemed ? Date() : nil))
        }
    }

    // MARK: - Resonance

    static func setSameHere(_ same: Bool, postID: String) {
        try? db.write { database in
            guard let post = try ATPost.fetchOne(database, key: postID), post.isSameHere != same else { return }
            try ATPost
                .filter(Column("id") == postID)
                .updateAll(
                    database,
                    Column("isSameHere").set(to: same),
                    Column("sameCount").set(to: max(0, post.sameCount + (same ? 1 : -1)))
                )
        }
    }

    static func resonatedThemes() -> [(theme: ATPostTheme, count: Int)] {
        let marked = (try? db.read {
            try ATPost.filter(Column("isSameHere") == true).fetchAll($0)
        }) ?? []
        return Dictionary(grouping: marked, by: \.theme)
            .map { (theme: $0.key, count: $0.value.count) }
            .sorted { $0.count == $1.count ? $0.theme.title < $1.theme.title : $0.count > $1.count }
    }

    static func resonatedPosts() -> [ATPost] {
        (try? db.read {
            try ATPost
                .filter(Column("isSameHere") == true)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    static func readerThemes() -> Set<ATPostTheme> {
        guard let readerID = currentUser()?.id else { return [] }
        var themes = Set(posts(byAuthor: readerID).map(\.theme))
        themes.formUnion(likedPosts().map(\.theme))
        themes.formUnion(resonatedPosts().map(\.theme))
        return themes
    }

    static func peopleWhoFile(_ theme: ATPostTheme, limit: Int, excluding excluded: Set<String> = []) -> [ATUser] {
        let rows = (try? db.read {
            try ATPost
                .filter(Column("themeRaw") == theme.rawValue)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []

        var counts: [String: Int] = [:]
        for post in rows where !excluded.contains(post.authorID) {
            counts[post.authorID, default: 0] += 1
        }

        let ranked = counts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .prefix(limit)
            .map(\.key)

        let people = users(ids: Array(ranked))
        return ranked.compactMap { people[$0] }
    }

    static func sharedThemes(withUser userID: String) -> [ATPostTheme] {
        let mine = readerThemes()
        guard !mine.isEmpty else { return [] }
        let theirs = Set(posts(byAuthor: userID).map(\.theme))
        return ATPostTheme.allCases.filter { mine.contains($0) && theirs.contains($0) }
    }

    // MARK: - Revisits

    static func answer(toPost postID: String) -> ATPost? {
        try? db.read {
            try ATPost.filter(Column("answersPostID") == postID).fetchOne($0)
        }
    }

    static func answeredPost(ofRevisit post: ATPost) -> ATPost? {
        guard let id = post.answersPostID else { return nil }
        return self.post(id: id)
    }

    static func revisitCount(authorID: String) -> Int {
        (try? db.read {
            try ATPost
                .filter(Column("authorID") == authorID)
                .filter(Column("answersPostID") != nil)
                .fetchCount($0)
        }) ?? 0
    }

    static func answeredCount(authorID: String) -> Int {
        (try? db.read {
            try ATPost
                .filter(Column("authorID") == authorID)
                .filter(Column("redeemedAt") != nil)
                .fetchCount($0)
        }) ?? 0
    }

    // MARK: - The ledger

    enum ATStanding: String, CaseIterable {
        case busiest
        case regretted
        case rewarded

        var title: String {
            switch self {
            case .busiest: return "Most filed"
            case .regretted: return "Most regretted"
            case .rewarded: return "Best surprises"
            }
        }

        var blurb: String {
            switch self {
            case .busiest: return "Where the library has the most to say."
            case .regretted: return "The places people would do differently."
            case .rewarded: return "Where the trip beat the expectation."
            }
        }

        var lenses: Set<ATPostTheme> {
            switch self {
            case .busiest: return Set(ATPostTheme.allCases)
            case .regretted: return [.regret, .pitfall, .wrongTurn, .overrated]
            case .rewarded: return [.surprise, .hiddenGem, .luckyFind]
            }
        }

        func score(of dossier: ATPlaceDossier) -> Int {
            self == .busiest
                ? dossier.postCount
                : dossier.posts.filter { lenses.contains($0.theme) }.count
        }
    }

    struct ATPlaceStanding {
        let dossier: ATPlaceDossier
        let score: Int
    }

    static func standings(_ kind: ATStanding, limit: Int) -> [ATPlaceStanding] {
        let rows: [ATPlaceStanding] = placeSummaries().map {
            ATPlaceStanding(dossier: $0, score: kind.score(of: $0))
        }
        let ranked: [ATPlaceStanding] = rows.filter { $0.score > 0 }.sorted { left, right in
            if left.score != right.score { return left.score > right.score }
            let leftDate = left.dossier.latestFiledAt ?? .distantPast
            let rightDate = right.dossier.latestFiledAt ?? .distantPast
            return leftDate > rightDate
        }
        return Array(ranked.prefix(limit))
    }

    struct ATMonth {
        let start: Date
        let posts: [ATPost]

        var count: Int { posts.count }
        var placeCount: Int {
            Set(posts.map { ATPlace.resolve(locationName: $0.locationName, country: $0.country).key }).count
        }
        var authorCount: Int { Set(posts.map(\.authorID)).count }

        var themesByWeight: [(theme: ATPostTheme, count: Int)] {
            Dictionary(grouping: posts, by: \.theme)
                .map { (theme: $0.key, count: $0.value.count) }
                .sorted {
                    $0.count == $1.count ? $0.theme.title < $1.theme.title : $0.count > $1.count
                }
        }

        var dominantTheme: ATPostTheme? { themesByWeight.first?.theme }
    }

    static func months(limit: Int = 12) -> [ATMonth] {
        let calendar = Calendar.current
        var buckets: [Date: [ATPost]] = [:]
        for post in allPosts() {
            let parts = calendar.dateComponents([.year, .month], from: post.createdAt)
            guard let start = calendar.date(from: parts) else { continue }
            buckets[start, default: []].append(post)
        }
        return buckets
            .map { ATMonth(start: $0.key, posts: $0.value) }
            .sorted { $0.start > $1.start }
            .prefix(limit)
            .map { $0 }
    }

    static func posts(inMonthStarting start: Date) -> [ATPost] {
        let calendar = Calendar.current
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
        return (try? db.read {
            try ATPost
                .filter(Column("createdAt") >= start && Column("createdAt") < end)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    // MARK: - Media

    static func media(forPost postID: String) -> [ATPostMedia] {
        (try? db.read {
            try ATPostMedia
                .filter(Column("postID") == postID)
                .order(Column("sortIndex"))
                .fetchAll($0)
        }) ?? []
    }

    static func media(forPostIDs ids: [String]) -> [String: [ATPostMedia]] {
        guard !ids.isEmpty else { return [:] }
        let rows = (try? db.read {
            try ATPostMedia
                .filter(ids.contains(Column("postID")))
                .order(Column("sortIndex"))
                .fetchAll($0)
        }) ?? []
        return Dictionary(grouping: rows, by: \.postID)
    }

    // MARK: - Comments

    static func comments(forPost postID: String) -> [ATComment] {
        (try? db.read {
            try ATComment
                .filter(Column("postID") == postID)
                .order(Column("createdAt"))
                .fetchAll($0)
        }) ?? []
    }

    @discardableResult
    static func addComment(postID: String, authorID: String, body: String) -> ATComment {
        let comment = ATComment(
            id: UUID().uuidString,
            postID: postID,
            authorID: authorID,
            body: body,
            createdAt: Date(),
            isMine: true,
            isSeeded: false
        )

        try? db.write { database in
            try comment.insert(database)
            try ATPost
                .filter(Column("id") == postID)
                .updateAll(database, Column("commentCount").set(to: Column("commentCount") + 1))
        }

        return comment
    }

    static func deleteComment(id: String) {
        try? db.write { database in
            guard let comment = try ATComment.fetchOne(database, key: id) else { return }
            try ATComment.filter(Column("id") == id).deleteAll(database)
            try ATPost
                .filter(Column("id") == comment.postID)
                .updateAll(database, Column("commentCount").set(to: Column("commentCount") - 1))
        }
    }

    static func comments(byAuthor authorID: String, limit: Int = 40) -> [ATComment] {
        (try? db.read {
            try ATComment
                .filter(Column("authorID") == authorID)
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll($0)
        }) ?? []
    }

    static func commentCount(forPost postID: String) -> Int {
        (try? db.read {
            try ATComment.filter(Column("postID") == postID).fetchCount($0)
        }) ?? 0
    }

    // MARK: - People

    static func currentUser() -> ATUser? {
        try? db.read {
            try ATUser.filter(Column("isCurrentUser") == true).fetchOne($0)
        }
    }

    static func user(id: String) -> ATUser? {
        try? db.read { try ATUser.fetchOne($0, key: id) }
    }

    static func users(ids: [String]) -> [String: ATUser] {
        guard !ids.isEmpty else { return [:] }
        let rows = (try? db.read {
            try ATUser.filter(ids.contains(Column("id"))).fetchAll($0)
        }) ?? []
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
    }

    static func suggestedPeople(limit: Int) -> [ATUser] {
        (try? db.read {
            try ATUser
                .filter(Column("isCurrentUser") == false)
                .filter(Column("friendStateRaw") != ATFriendState.friends.rawValue)
                .order(Column("followerCount").desc)
                .limit(limit)
                .fetchAll($0)
        }) ?? []
    }

    // MARK: - Following

    static func following() -> [ATUser] {
        guard let readerID = currentUser()?.id else { return [] }
        return (try? db.read { database in
            try ATUser
                .filter(Column("isCurrentUser") == false)
                .filter(sql: "id IN (SELECT followeeID FROM follow WHERE followerID = ?)", arguments: [readerID])
                .order(Column("displayName"))
                .fetchAll(database)
        }) ?? []
    }

    static func followers() -> [ATUser] {
        guard let readerID = currentUser()?.id else { return [] }
        return (try? db.read { database in
            try ATUser
                .filter(Column("isCurrentUser") == false)
                .filter(sql: "id IN (SELECT followerID FROM follow WHERE followeeID = ?)", arguments: [readerID])
                .order(Column("displayName"))
                .fetchAll(database)
        }) ?? []
    }

    static func followingCount() -> Int { following().count }
    static func followerCount() -> Int { followers().count }

    static func isFollowing(_ userID: String) -> Bool {
        guard let readerID = currentUser()?.id else { return false }
        return follows(from: readerID, to: userID)
    }

    static func followsUs(_ userID: String) -> Bool {
        guard let readerID = currentUser()?.id else { return false }
        return follows(from: userID, to: readerID)
    }

    private static func follows(from followerID: String, to followeeID: String) -> Bool {
        (try? db.read { database in
            try ATFollow
                .filter(Column("followerID") == followerID)
                .filter(Column("followeeID") == followeeID)
                .fetchCount(database) > 0
        }) ?? false
    }

    static func friends() -> [ATUser] {
        (try? db.read {
            try ATUser
                .filter(Column("isCurrentUser") == false)
                .filter(Column("friendStateRaw") == ATFriendState.friends.rawValue)
                .order(Column("displayName"))
                .fetchAll($0)
        }) ?? []
    }

    static func setFollowing(_ following: Bool, userID: String) {
        guard let readerID = currentUser()?.id, readerID != userID else { return }

        try? db.write { database in
            guard let user = try ATUser.fetchOne(database, key: userID) else { return }
            let alreadyFollowing = try ATFollow
                .filter(Column("followerID") == readerID)
                .filter(Column("followeeID") == userID)
                .fetchCount(database) > 0
            guard alreadyFollowing != following else { return }

            if following {
                try ATFollow(followerID: readerID, followeeID: userID, createdAt: Date()).insert(database)
            } else {
                try ATFollow
                    .filter(Column("followerID") == readerID)
                    .filter(Column("followeeID") == userID)
                    .deleteAll(database)
            }

            try ATUser
                .filter(Column("id") == userID)
                .updateAll(
                    database,
                    Column("followerCount").set(to: max(0, user.followerCount + (following ? 1 : -1)))
                )
        }
    }

    static func setFriendState(_ state: ATFriendState, userID: String) {
        try? db.write { database in
            try ATUser
                .filter(Column("id") == userID)
                .updateAll(database, Column("friendStateRaw").set(to: state.rawValue))
        }
    }

    static func updateProfile(
        userID: String,
        displayName: String,
        bio: String,
        homeCity: String,
        avatarSeed: String?
    ) {
        try? db.write { database in
            var assignments: [ColumnAssignment] = [
                Column("displayName").set(to: displayName),
                Column("bio").set(to: bio),
                Column("homeCity").set(to: homeCity),
            ]
            if let avatarSeed {
                assignments.append(Column("avatarSeed").set(to: avatarSeed))
            }
            try ATUser.filter(Column("id") == userID).updateAll(database, assignments)
        }
    }

    static func deleteUser(id: String) {
        try? db.write { database in
            let postIDs = try String.fetchAll(
                database,
                sql: "SELECT id FROM post WHERE authorID = ?",
                arguments: [id]
            )
            for postID in postIDs {
                try ATPostMedia.filter(Column("postID") == postID).deleteAll(database)
                try ATComment.filter(Column("postID") == postID).deleteAll(database)
                try ATGiftRecord.filter(Column("postID") == postID).deleteAll(database)
            }
            try ATPost.filter(Column("authorID") == id).deleteAll(database)
            try ATComment.filter(Column("authorID") == id).deleteAll(database)
            try ATGiftRecord.filter(Column("fromUserID") == id).deleteAll(database)
            try ATFollow
                .filter(Column("followerID") == id || Column("followeeID") == id)
                .deleteAll(database)
            try ATExpense.filter(Column("userID") == id).deleteAll(database)

            let conversationIDs = try String.fetchAll(
                database,
                sql: "SELECT id FROM conversation WHERE peerUserID = ?",
                arguments: [id]
            )
            for conversationID in conversationIDs {
                try ATMessage.filter(Column("conversationID") == conversationID).deleteAll(database)
            }
            try ATConversation.filter(Column("peerUserID") == id).deleteAll(database)
            try ATUser.filter(Column("id") == id).deleteAll(database)
        }
    }

    // MARK: - Gifts

    @discardableResult
    static func addGift(postID: String, fromUserID: String, gift: ATGift, tierIndex: Int) -> ATGiftRecord {
        let record = ATGiftRecord(
            id: UUID().uuidString,
            postID: postID,
            fromUserID: fromUserID,
            sku: gift.sku,
            tierIndex: tierIndex,
            createdAt: Date()
        )

        try? db.write { database in
            try record.insert(database)
            try ATPost
                .filter(Column("id") == postID)
                .updateAll(database, Column("giftCount").set(to: Column("giftCount") + 1))
        }

        return record
    }

    static func giftCount(forPost postID: String) -> Int {
        (try? db.read {
            try ATGiftRecord.filter(Column("postID") == postID).fetchCount($0)
        }) ?? 0
    }

    static func gifts(forPost postID: String) -> [ATGiftRecord] {
        (try? db.read {
            try ATGiftRecord
                .filter(Column("postID") == postID)
                .order(Column("createdAt").desc)
                .fetchAll($0)
        }) ?? []
    }

    // MARK: - Chat

    static func conversations() -> [ATConversation] {
        (try? db.read {
            try ATConversation.order(Column("lastMessageAt").desc).fetchAll($0)
        }) ?? []
    }

    static func conversation(withUser userID: String) -> ATConversation? {
        try? db.read {
            try ATConversation.filter(Column("peerUserID") == userID).fetchOne($0)
        }
    }

    @discardableResult
    static func ensureConversation(withUser userID: String) -> ATConversation {
        if let existing = conversation(withUser: userID) { return existing }

        let conversation = ATConversation(
            id: "conv-\(userID)",
            peerUserID: userID,
            lastMessageAt: Date(),
            unreadCount: 0
        )
        try? db.write { try conversation.insert($0) }
        return conversation
    }

    static func messages(inConversation conversationID: String, limit: Int = 400) -> [ATMessage] {
        (try? db.read {
            try ATMessage
                .filter(Column("conversationID") == conversationID)
                .order(Column("createdAt").asc)
                .limit(limit)
                .fetchAll($0)
        }) ?? []
    }

    static func lastMessage(inConversation conversationID: String) -> ATMessage? {
        try? db.read {
            try ATMessage
                .filter(Column("conversationID") == conversationID)
                .order(Column("createdAt").desc)
                .fetchOne($0)
        }
    }

    @discardableResult
    static func sendMessage(
        conversationID: String,
        senderID: String,
        kind: ATMessageKind,
        body: String
    ) -> ATMessage {
        let message = ATMessage(
            id: UUID().uuidString,
            conversationID: conversationID,
            senderID: senderID,
            kindRaw: kind.rawValue,
            body: body,
            createdAt: Date(),
            isRead: true
        )

        try? db.write { database in
            try message.insert(database)
            try ATConversation
                .filter(Column("id") == conversationID)
                .updateAll(database, Column("lastMessageAt").set(to: message.createdAt))
        }

        return message
    }

    static func markRead(conversationID: String) {
        try? db.write { database in
            try ATConversation
                .filter(Column("id") == conversationID)
                .updateAll(database, Column("unreadCount").set(to: 0))
            try ATMessage
                .filter(Column("conversationID") == conversationID)
                .updateAll(database, Column("isRead").set(to: true))
        }
    }

    static func deleteConversation(id: String) {
        try? db.write { database in
            try ATMessage.filter(Column("conversationID") == id).deleteAll(database)
            try ATConversation.filter(Column("id") == id).deleteAll(database)
        }
    }

    static func unreadTotal() -> Int {
        (try? db.read { database in
            try Int.fetchOne(
                database,
                sql: "SELECT COALESCE(SUM(unreadCount), 0) FROM conversation"
            ) ?? 0
        }) ?? 0
    }

    // MARK: - Accounts

    static func credential(username: String) -> ATCredential? {
        try? db.read {
            try ATCredential.fetchOne($0, key: username.lowercased())
        }
    }

    static func isUsernameTaken(_ username: String) -> Bool {
        credential(username: username) != nil
    }

    static func appleAccount(appleUserID: String) -> ATUser? {
        try? db.read {
            try ATUser.filter(Column("appleUserID") == appleUserID).fetchOne($0)
        }
    }

    @discardableResult
    static func createAccount(
        username: String,
        displayName: String,
        password: String,
        appleUserID: String? = nil
    ) -> ATUser? {
        let handle = username.lowercased()
        guard !isUsernameTaken(handle) else { return nil }

        let user = ATUser(
            id: "u-\(handle)",
            username: handle,
            displayName: displayName,
            bio: "",
            homeCity: "",
            avatarSeed: "Avatar-\(handle)",
            followingCount: 0,
            followerCount: 0,
            postCount: 0,
            friendStateRaw: ATFriendState.none.rawValue,
            isCurrentUser: true,
            appleUserID: appleUserID,
            createdAt: Date()
        )

        let salt = ATPassword.makeSalt()
        let credential = ATCredential(
            username: handle,
            userID: user.id,
            salt: salt,
            passwordHash: ATPassword.hash(password, salt: salt)
        )

        var created = false
        try? db.write { database in
            try ATUser.filter(Column("isCurrentUser") == true).updateAll(database, Column("isCurrentUser").set(to: false))
            try user.insert(database)
            try credential.insert(database)
            created = true
        }

        return created ? user : nil
    }

    static func setCurrentUser(id: String) {
        try? db.write { database in
            try ATUser
                .filter(Column("isCurrentUser") == true)
                .updateAll(database, Column("isCurrentUser").set(to: false))
            try ATUser
                .filter(Column("id") == id)
                .updateAll(database, Column("isCurrentUser").set(to: true))
        }
    }

    static func clearCurrentUser() {
        try? db.write { database in
            try ATUser
                .filter(Column("isCurrentUser") == true)
                .updateAll(database, Column("isCurrentUser").set(to: false))
        }
    }

    static func deleteAccount(id: String, username: String) {
        try? db.write { database in
            try ATCredential.filter(Column("username") == username.lowercased()).deleteAll(database)
            let postIDs = try String.fetchAll(
                database,
                sql: "SELECT id FROM post WHERE authorID = ?",
                arguments: [id]
            )
            for postID in postIDs {
                try ATPostMedia.filter(Column("postID") == postID).deleteAll(database)
                try ATComment.filter(Column("postID") == postID).deleteAll(database)
                try ATGiftRecord.filter(Column("postID") == postID).deleteAll(database)
            }
            try ATPost.filter(Column("authorID") == id).deleteAll(database)
            try ATComment.filter(Column("authorID") == id).deleteAll(database)
            try ATFollow
                .filter(Column("followerID") == id || Column("followeeID") == id)
                .deleteAll(database)
            try ATExpense.filter(Column("userID") == id).deleteAll(database)
            try ATUser.filter(Column("id") == id).deleteAll(database)
        }
    }

    // MARK: - Purchases

    static func recordPurchase(sku: String, transactionID: String) {
        let purchase = ATPurchase(
            id: UUID().uuidString,
            sku: sku,
            transactionID: transactionID,
            purchasedAt: Date()
        )
        try? db.write { try purchase.insert($0) }
    }

    static func purchaseCount(sku: String) -> Int {
        (try? db.read {
            try ATPurchase.filter(Column("sku") == sku).fetchCount($0)
        }) ?? 0
    }
}
