//
//  ATDigest.swift
//  ATrimp
//
//
import Foundation

struct ATWrapped {

    let startsAt: Date?
    let endsAt: Date?

    let filings: Int
    let countries: Int
    let places: Int
    let travellers: Int
    let lenses: [(theme: ATPostTheme, count: Int)]
    let busiest: ATStore.ATPlaceStanding?
    let mostRegretted: ATStore.ATPlaceStanding?
    let rewarded: ATStore.ATPlaceStanding?
    let answered: Int

    let readerFiled: Int
    let readerLiked: Int
    let readerRecognised: Int
    let readerNotes: Int
    let readerNotesDone: Int
    let readerRevisits: Int

    var dominantLens: ATPostTheme? { lenses.first?.theme }

    var isEmpty: Bool { filings == 0 }

    var hasReaderPart: Bool {
        readerFiled + readerLiked + readerRecognised + readerNotes > 0
    }

    var periodPhrase: String {
        guard let startsAt, let endsAt else { return "So far" }

        let calendar = Calendar.current
        let month = DateFormatter()
        month.dateFormat = "MMMM"

        let startMonth = month.string(from: startsAt)
        let endMonth = month.string(from: endsAt)

        let startYear = calendar.component(.year, from: startsAt)
        let endYear = calendar.component(.year, from: endsAt)

        if startMonth == endMonth, startYear == endYear {
            return "\(startMonth) \(startYear)"
        }
        if startYear == endYear {
            return "\(startMonth) — \(endMonth) \(endYear)"
        }
        return "\(startMonth) \(startYear) — \(endMonth) \(endYear)"
    }
}

enum ATDigest {

    static func wrapped() -> ATWrapped {
        let posts = ATStore.allPosts()
        let dossiers = ATStore.placeSummaries()

        let countries = Set(posts.map { $0.country }.filter { !$0.isEmpty })
        let places = Set(posts.map {
            ATPlace.resolve(locationName: $0.locationName, country: $0.country).key
        })

        var lensCounts: [ATPostTheme: Int] = [:]
        for post in posts { lensCounts[post.theme, default: 0] += 1 }

        let tallied: [(theme: ATPostTheme, count: Int)] = ATPostTheme.allCases.map {
            (theme: $0, count: lensCounts[$0] ?? 0)
        }
        let lenses: [(theme: ATPostTheme, count: Int)] = tallied
            .filter { $0.count > 0 }
            .sorted { left, right in
                if left.count != right.count { return left.count > right.count }
                return left.theme.title < right.theme.title
            }

        let readerID = ATStore.currentUser()?.id
        let mine = readerID.map { ATStore.posts(byAuthor: $0) } ?? []
        let notes = ATStore.notes()

        return ATWrapped(
            startsAt: posts.map(\.createdAt).min(),
            endsAt: posts.map(\.createdAt).max(),
            filings: posts.count,
            countries: countries.count,
            places: places.count,
            travellers: Set(posts.map(\.authorID)).count,
            lenses: lenses,
            busiest: ATStore.standings(.busiest, limit: 1).first,
            mostRegretted: ATStore.standings(.regretted, limit: 1).first,
            rewarded: ATStore.standings(.rewarded, limit: 1).first,
            answered: dossiers.reduce(0) { $0 + $1.posts.filter(\.isRedeemed).count },
            readerFiled: mine.count,
            readerLiked: ATStore.likedPosts().count,
            readerRecognised: ATStore.resonatedPosts().count,
            readerNotes: notes.count,
            readerNotesDone: notes.filter(\.isResolved).count,
            readerRevisits: readerID.map { ATStore.revisitCount(authorID: $0) } ?? 0
        )
    }
}
