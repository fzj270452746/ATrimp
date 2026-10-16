//
//  ATToolbox.swift
//  ATrimp
//
//

import UIKit

struct ATPlaceBrief {

    let place: ATPlace
    let dossier: ATPlaceDossier
    let pitfalls: [ATPost]
    let rewards: [ATPost]
    let notes: [ATNote]
    let headline: String

    var isEmpty: Bool { dossier.postCount == 0 && notes.isEmpty }
}

struct ATPlaceComparison {

    let left: ATPlaceDossier
    let right: ATPlaceDossier
    let leftIntensity: Double?
    let rightIntensity: Double?
    let verdict: String

    var isEmpty: Bool { left.postCount == 0 && right.postCount == 0 }
}

struct ATDrawCandidate {

    enum Origin {
        case note(ATNote)
        case library(ATPlaceDossier)
    }

    let place: ATPlace
    let origin: Origin
    let headline: String
    let noteBody: String?
    let dominantTheme: ATPostTheme?
    let postCount: Int
}

struct ATPlacePickerEntry {

    let place: ATPlace
    let detail: String
    let tint: UIColor
    let weight: Int
    let noteCount: Int
}

enum ATToolbox {

    static let caution: Set<ATPostTheme> = [.pitfall, .wrongTurn, .overrated]

    static let reward: Set<ATPostTheme> = [.surprise, .hiddenGem, .luckyFind]

    static let warning: Set<ATPostTheme> = ATStore.ATStanding.regretted.lenses

    // MARK: - Brief

    static func brief(for place: ATPlace) -> ATPlaceBrief {
        let dossier = ATStore.dossier(for: place)
        let notes = ATStore.notes(forPlaceKey: place.key)

        let pitfalls = dossier.posts
            .filter { caution.contains($0.theme) }
            .sorted { $0.createdAt > $1.createdAt }

        let rewards = dossier.posts
            .filter { reward.contains($0.theme) }
            .sorted { $0.createdAt > $1.createdAt }

        let ordered = notes.sorted {
            $0.isResolved == $1.isResolved ? $0.createdAt > $1.createdAt : !$0.isResolved
        }

        return ATPlaceBrief(
            place: place,
            dossier: dossier,
            pitfalls: pitfalls,
            rewards: rewards,
            notes: ordered,
            headline: headline(for: dossier, notes: notes)
        )
    }

    private static func headline(for dossier: ATPlaceDossier, notes: [ATNote]) -> String {
        let filings = dossier.postCount
        guard filings > 0 else {
            return notes.isEmpty
                ? "Nobody has filed here yet."
                : "Nobody has filed here yet — all of this comes from your own note."
        }

        let warnings = count(of: caution, in: dossier)
        let filed = "\(filings) \(filings == 1 ? "filing" : "filings")"

        switch warnings {
        case 0:
            return "\(filed) and no warnings at all."
        case 1:
            return "\(filed) and one warning worth reading."
        default:
            return "\(filings) filings, and \(warnings) of them are warnings. Read those first."
        }
    }

    // MARK: - Comparison

    static func compare(_ left: ATPlace, _ right: ATPlace) -> ATPlaceComparison {
        let leftDossier = ATStore.dossier(for: left)
        let rightDossier = ATStore.dossier(for: right)
        let leftIntensity = intensity(leftDossier.posts)
        let rightIntensity = intensity(rightDossier.posts)

        return ATPlaceComparison(
            left: leftDossier,
            right: rightDossier,
            leftIntensity: leftIntensity,
            rightIntensity: rightIntensity,
            verdict: verdict(
                leftDossier,
                rightDossier,
                leftIntensity: leftIntensity,
                rightIntensity: rightIntensity
            )
        )
    }

    private static func intensity(_ posts: [ATPost]) -> Double? {
        let values = posts.compactMap(\.intensity)
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private static func verdict(
        _ left: ATPlaceDossier,
        _ right: ATPlaceDossier,
        leftIntensity: Double?,
        rightIntensity: Double?
    ) -> String {
        let leftCount = left.postCount
        let rightCount = right.postCount

        if leftCount == 0 && rightCount == 0 {
            return "Nobody has filed on either place yet — there is nothing to weigh."
        }

        if leftCount == 0 || rightCount == 0 {
            let blank = leftCount == 0 ? left.place.name : right.place.name
            let full = leftCount == 0 ? right : left
            return "\(blank) has no filings at all; \(full.place.name) has \(full.postCount). One side of this is a blank page."
        }

        let leftWarn = share(of: warning, in: left)
        let rightWarn = share(of: warning, in: right)
        if abs(leftWarn - rightWarn) >= 0.20 {
            let hotter = leftWarn > rightWarn ? left : right
            let cooler = leftWarn > rightWarn ? right : left
            return "People warn about \(hotter.place.name) far more often — \(count(of: warning, in: hotter)) of \(hotter.postCount) filings against \(count(of: warning, in: cooler)) of \(cooler.postCount)."
        }

        let leftReward = share(of: reward, in: left)
        let rightReward = share(of: reward, in: right)
        if abs(leftReward - rightReward) >= 0.20 {
            let better = leftReward > rightReward ? left : right
            let worse = leftReward > rightReward ? right : left
            return "\(better.place.name) is the one people are glad they went to — \(count(of: reward, in: better)) of \(better.postCount) filings against \(count(of: reward, in: worse)) of \(worse.postCount)."
        }

        if let leftIntensity, let rightIntensity, abs(leftIntensity - rightIntensity) >= 1.0 {
            let hotter = leftIntensity > rightIntensity ? left : right
            let high = max(leftIntensity, rightIntensity)
            let low = min(leftIntensity, rightIntensity)
            let scores = "\(String(format: "%.1f", high))/5 against \(String(format: "%.1f", low))/5"

            if let leftTheme = left.dominantTheme, let rightTheme = right.dominantTheme,
               leftTheme == rightTheme {
                return "Both read mostly as \(leftTheme.title), but it runs hotter in \(hotter.place.name) — \(scores)."
            }
            return "Filing for filing, \(hotter.place.name) lands harder — \(scores)."
        }

        if Double(max(leftCount, rightCount)) / Double(min(leftCount, rightCount)) >= 2 {
            let more = leftCount > rightCount ? left : right
            let less = leftCount > rightCount ? right : left
            return "\(more.place.name) carries \(more.postCount) filings to \(less.place.name)'s \(less.postCount), so take its reading as the settled one."
        }

        if let leftTheme = left.dominantTheme, let rightTheme = right.dominantTheme, leftTheme == rightTheme {
            return "Both come out as \(leftTheme.title) more than anything else; the difference is only in how often people bother to say so."
        }

        return "The two read much the same: \(leftCount) filings against \(rightCount), and no lens leads either one."
    }

    // MARK: - Picker

    static func pickerEntries(allowsNotes: Bool) -> [ATPlacePickerEntry] {
        var noteCounts: [String: Int] = [:]
        var notesByKey: [String: ATNote] = [:]

        if allowsNotes {
            for note in ATStore.notes() {
                noteCounts[note.placeKey, default: 0] += 1
                if notesByKey[note.placeKey] == nil { notesByKey[note.placeKey] = note }
            }
        }

        var entries: [ATPlacePickerEntry] = []
        var seen = Set<String>()

        for dossier in ATStore.placeSummaries() {
            let key = dossier.place.key
            seen.insert(key)
            let notes = noteCounts[key] ?? 0
            entries.append(
                ATPlacePickerEntry(
                    place: dossier.place,
                    detail: detail(filings: dossier.postCount, notes: notes),
                    tint: dossier.dominantTheme?.tint ?? ATTheme.Palette.ruleStrong,
                    weight: (notes > 0 ? 10_000 : 0) + dossier.postCount,
                    noteCount: notes
                )
            )
        }

        for (key, note) in notesByKey where !seen.contains(key) {
            let count = noteCounts[key] ?? 0
            entries.append(
                ATPlacePickerEntry(
                    place: ATPlace.resolve(locationName: note.placeName, country: note.country),
                    detail: detail(filings: 0, notes: count),
                    tint: ATTheme.Palette.ruleStrong,
                    weight: 10_000 + count,
                    noteCount: count
                )
            )
        }

        return entries.sorted {
            $0.weight == $1.weight ? $0.place.name < $1.place.name : $0.weight > $1.weight
        }
    }

    private static func detail(filings: Int, notes: Int) -> String {
        let filingText = filings == 1 ? "1 filing" : "\(filings) filings"
        let noteText = notes == 1 ? "1 note" : "\(notes) notes"
        guard notes > 0 else { return filingText }
        return "\(filingText) · \(noteText)"
    }

    // MARK: - Draw

    static func drawPool() -> [ATDrawCandidate] {
        var byKey: [String: ATPlaceDossier] = [:]
        for dossier in ATStore.placeSummaries() {
            byKey[dossier.place.key] = dossier
        }

        var latestNote: [String: ATNote] = [:]
        for note in ATStore.notes() where !note.isResolved {
            if let existing = latestNote[note.placeKey] {
                if note.createdAt > existing.createdAt { latestNote[note.placeKey] = note }
            } else {
                latestNote[note.placeKey] = note
            }
        }

        var candidates: [ATDrawCandidate] = []
        var used = Set<String>()

        for note in latestNote.values {
            let place = ATPlace.resolve(locationName: note.placeName, country: note.country)
            let dossier = byKey[place.key] ?? ATPlaceDossier(place: place, posts: [])
            used.insert(place.key)
            candidates.append(
                ATDrawCandidate(
                    place: place,
                    origin: .note(note),
                    headline: "You kept a note for this one.",
                    noteBody: note.body,
                    dominantTheme: dossier.dominantTheme,
                    postCount: dossier.postCount
                )
            )
        }

        for dossier in byKey.values where !used.contains(dossier.place.key) {
            used.insert(dossier.place.key)
            candidates.append(
                ATDrawCandidate(
                    place: dossier.place,
                    origin: .library(dossier),
                    headline: libraryHeadline(dossier),
                    noteBody: nil,
                    dominantTheme: dossier.dominantTheme,
                    postCount: dossier.postCount
                )
            )
        }

        return candidates.sorted { $0.place.name < $1.place.name }
    }

    private static func libraryHeadline(_ dossier: ATPlaceDossier) -> String {
        let filings = dossier.postCount == 1 ? "1 filing" : "\(dossier.postCount) filings"
        guard let dominant = dossier.dominantTheme else {
            return "\(filings) in the library."
        }
        return "\(filings), reading mostly as \(dominant.title)."
    }

    static func draw(from pool: [ATDrawCandidate]) -> ATDrawCandidate? {
        pool.randomElement()
    }

    // MARK: - Helpers

    private static func count(of lenses: Set<ATPostTheme>, in dossier: ATPlaceDossier) -> Int {
        dossier.posts.filter { lenses.contains($0.theme) }.count
    }

    private static func share(of lenses: Set<ATPostTheme>, in dossier: ATPlaceDossier) -> Double {
        guard dossier.postCount > 0 else { return 0 }
        return Double(count(of: lenses, in: dossier)) / Double(dossier.postCount)
    }
}
