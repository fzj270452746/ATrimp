//
//  ATPlace.swift
//  ATrimp
//
//
import Foundation

struct ATPlace: Hashable {

    let key: String
    let name: String
    let country: String

    let latitude: Double?
    let longitude: Double?

    var hasCoordinate: Bool { latitude != nil && longitude != nil }

    var title: String {
        country.isEmpty ? name : "\(name), \(country)"
    }
}

// MARK: - Gazetteer

extension ATPlace {

    static let all: [ATPlace] = [
        ATPlace(key: "amsterdam", name: "Amsterdam", country: "Netherlands", latitude: 52.3676, longitude: 4.9041),
        ATPlace(key: "anso", name: "Ansoo", country: "Spain", latitude: 42.7503, longitude: -0.8300),
        ATPlace(key: "atacama", name: "Atacama", country: "Chile", latitude: -22.9098, longitude: -68.1997),
        ATPlace(key: "bali", name: "Bali", country: "Indonesia", latitude: -8.4095, longitude: 115.1889),
        ATPlace(key: "bangkok", name: "Bangkok", country: "Thailand", latitude: 13.7563, longitude: 100.5018),
        ATPlace(key: "bergamo", name: "Bergamo", country: "Italy", latitude: 45.6983, longitude: 9.6773),
        ATPlace(key: "bergen", name: "Bergen", country: "Norway", latitude: 60.3913, longitude: 5.3221),
        ATPlace(key: "bogota", name: "Bogotá", country: "Colombia", latitude: 4.7110, longitude: -74.0721),
        ATPlace(key: "bratislava", name: "Bratislava", country: "Slovakia", latitude: 48.1486, longitude: 17.1077),
        ATPlace(key: "cairo", name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357),
        ATPlace(key: "chefchaouen", name: "Chefchaouen", country: "Morocco", latitude: 35.1688, longitude: -5.2636),
        ATPlace(key: "chisinau", name: "Chișinău", country: "Moldova", latitude: 47.0105, longitude: 28.8638),
        ATPlace(key: "dubrovnik", name: "Dubrovnik", country: "Croatia", latitude: 42.6507, longitude: 18.0944),
        ATPlace(key: "edinburgh", name: "Edinburgh", country: "Scotland", latitude: 55.9533, longitude: -3.1883),
        ATPlace(key: "elchalten", name: "El Chaltén", country: "Argentina", latitude: -49.3315, longitude: -72.8863),
        ATPlace(key: "ghent", name: "Ghent", country: "Belgium", latitude: 51.0543, longitude: 3.7174),
        ATPlace(key: "hanoi", name: "Hanoi", country: "Vietnam", latitude: 21.0278, longitude: 105.8342),
        ATPlace(key: "hobart", name: "Hobart", country: "Australia", latitude: -42.8821, longitude: 147.3272),
        ATPlace(key: "hollywood", name: "Hollywood", country: "United States", latitude: 34.0928, longitude: -118.3287),
        ATPlace(key: "isfahan", name: "Isfahan", country: "Iran", latitude: 32.6546, longitude: 51.6680),
        ATPlace(key: "jaipur", name: "Jaipur", country: "India", latitude: 26.9124, longitude: 75.7873),
        ATPlace(key: "kanazawa", name: "Kanazawa", country: "Japan", latitude: 36.5613, longitude: 136.6562),
        ATPlace(key: "kerala", name: "Kerala", country: "India", latitude: 10.8505, longitude: 76.2711),
        ATPlace(key: "kotor", name: "Kotor", country: "Montenegro", latitude: 42.4247, longitude: 18.7712),
        ATPlace(key: "kuta", name: "Kuta", country: "Indonesia", latitude: -8.7210, longitude: 115.1690),
        ATPlace(key: "kyoto", name: "Kyoto", country: "Japan", latitude: 35.0116, longitude: 135.7681),
        ATPlace(key: "ladakh", name: "Ladakh", country: "India", latitude: 34.1526, longitude: 77.5771),
        ATPlace(key: "lisbon", name: "Lisbon", country: "Portugal", latitude: 38.7223, longitude: -9.1393),
        ATPlace(key: "ljubljana", name: "Ljubljana", country: "Slovenia", latitude: 46.0569, longitude: 14.5058),
        ATPlace(key: "lofoten", name: "Lofoten", country: "Norway", latitude: 68.1520, longitude: 13.6350),
        ATPlace(key: "marrakesh", name: "Marrakesh", country: "Morocco", latitude: 31.6295, longitude: -7.9811),
        ATPlace(key: "matera", name: "Matera", country: "Italy", latitude: 40.6664, longitude: 16.6043),
        ATPlace(key: "mexicocity", name: "Mexico City", country: "Mexico", latitude: 19.4326, longitude: -99.1332),
        ATPlace(key: "paris", name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522),
        ATPlace(key: "porto", name: "Porto", country: "Portugal", latitude: 41.1579, longitude: -8.6291),
        ATPlace(key: "positano", name: "Positano", country: "Italy", latitude: 40.6281, longitude: 14.4850),
        ATPlace(key: "prague", name: "Prague", country: "Czechia", latitude: 50.0755, longitude: 14.4378),
        ATPlace(key: "rarotonga", name: "Rarotonga", country: "Cook Islands", latitude: -21.2367, longitude: -159.7777),
        ATPlace(key: "reykjavik", name: "Reykjavík", country: "Iceland", latitude: 64.1466, longitude: -21.9426),
        ATPlace(key: "santorini", name: "Santorini", country: "Greece", latitude: 36.3932, longitude: 25.4615),
        ATPlace(key: "seoul", name: "Seoul", country: "South Korea", latitude: 37.5665, longitude: 126.9780),
        ATPlace(key: "sighisoara", name: "Sighișoara", country: "Romania", latitude: 46.2197, longitude: 24.7917),
        ATPlace(key: "tbilisi", name: "Tbilisi", country: "Georgia", latitude: 41.7151, longitude: 44.8271),
        ATPlace(key: "timessquare", name: "Times Square", country: "United States", latitude: 40.7580, longitude: -73.9855),
        ATPlace(key: "tirana", name: "Tirana", country: "Albania", latitude: 41.3275, longitude: 19.8187),
        ATPlace(key: "transsiberian", name: "Trans-Siberian", country: "Russia", latitude: 55.0084, longitude: 82.9357),
        ATPlace(key: "tromso", name: "Tromsø", country: "Norway", latitude: 69.6492, longitude: 18.9553),
        ATPlace(key: "trsteno", name: "Trsteno", country: "Croatia", latitude: 42.7100, longitude: 18.0400),
        ATPlace(key: "ushuaia", name: "Ushuaia", country: "Argentina", latitude: -54.8019, longitude: -68.3030),
        ATPlace(key: "valparaiso", name: "Valparaíso", country: "Chile", latitude: -33.0472, longitude: -71.6127),
        ATPlace(key: "venice", name: "Venice", country: "Italy", latitude: 45.4408, longitude: 12.3155),
        ATPlace(key: "wroclaw", name: "Wrocław", country: "Poland", latitude: 51.1079, longitude: 17.0385),
        ATPlace(key: "zermatt", name: "Zermatt", country: "Switzerland", latitude: 46.0207, longitude: 7.7491),
    ]

    private static let aliases: [String: String] = [
        "marrakech": "marrakesh",
        "mexico city": "mexicocity",
        "trans siberian": "transsiberian",
        "new york": "timessquare",
        "nyc": "timessquare",
    ]

    private static let index: [String: ATPlace] = {
        var map: [String: ATPlace] = [:]
        for place in all {
            map[normalize(place.key)] = place
            map[normalize(place.name)] = place
            map[normalize("\(place.name) \(place.country)")] = place
        }
        for (alias, key) in aliases {
            if let place = all.first(where: { $0.key == key }) {
                map[normalize(alias)] = place
            }
        }
        return map
    }()

    static func resolve(locationName: String, country: String = "") -> ATPlace {
        let name = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let region = country.trimmingCharacters(in: .whitespacesAndNewlines)

        if !name.isEmpty {
            if let known = index[normalize("\(name) \(region)")] ?? index[normalize(name)] {
                return known
            }
        }
        return ATPlace(
            key: "x-" + normalize("\(name)\(region)"),
            name: name.isEmpty ? "Somewhere" : name,
            country: region,
            latitude: nil,
            longitude: nil
        )
    }

    static func normalize(_ text: String) -> String {
        let folded = text.folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        return folded
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

// MARK: - Dossier

struct ATPlaceDossier {

    let place: ATPlace
    let posts: [ATPost]

    var postCount: Int { posts.count }

    var authorCount: Int { Set(posts.map(\.authorID)).count }

    var themeCounts: [ATPostTheme: Int] {
        Dictionary(grouping: posts, by: \.theme).mapValues(\.count)
    }

    var themesByWeight: [(theme: ATPostTheme, count: Int)] {
        themeCounts
            .map { (theme: $0.key, count: $0.value) }
            .sorted {
                $0.count == $1.count
                    ? $0.theme.title < $1.theme.title
                    : $0.count > $1.count
            }
    }

    var dominantTheme: ATPostTheme? { themesByWeight.first?.theme }

    var averageIntensity: [ATPostTheme: Double] {
        var totals: [ATPostTheme: (sum: Int, answers: Int)] = [:]
        for post in posts {
            guard let value = post.intensity else { continue }
            let running = totals[post.theme] ?? (0, 0)
            totals[post.theme] = (running.sum + value, running.answers + 1)
        }
        return totals.mapValues { Double($0.sum) / Double($0.answers) }
    }

    var firstFiledAt: Date? { posts.map(\.createdAt).min() }
    var latestFiledAt: Date? { posts.map(\.createdAt).max() }
}
