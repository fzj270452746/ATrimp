//
//  ATSeedContent.swift
//  ATrimp
//
//
import Foundation

enum ATSeedContent {

    // MARK: - People

    struct SeedUser {
        let username: String
        let displayName: String
        let city: String
        let bio: String
    }

    static let users: [SeedUser] = [
        SeedUser(username: "marisolv", displayName: "Marisol Vega", city: "Lisbon", bio: "Shoulder-season light and a notebook that is always open."),
        SeedUser(username: "tomash", displayName: "Tom Ashworth", city: "Manchester", bio: "Three trains a day and one camera that still works."),
        SeedUser(username: "ingridh", displayName: "Ingrid Halvorsen", city: "Bergen", bio: "I plan the route, then ignore it somewhere around day two."),
        SeedUser(username: "ravi_n", displayName: "Ravi Nair", city: "Toronto", bio: "Street food first, museums when it rains."),
        SeedUser(username: "claireb", displayName: "Claire Beaumont", city: "Lyon", bio: "Will detour four hours for a bakery somebody mentioned once."),
        SeedUser(username: "dkowa", displayName: "Daniel Kowalski", city: "Kraków", bio: "Night buses, window seats, terrible coffee."),
        SeedUser(username: "aisha_r", displayName: "Aisha Rahman", city: "London", bio: "Collecting small towns nobody has heard of."),
        SeedUser(username: "lucasm", displayName: "Lucas Moreau", city: "Montréal", bio: "Two weeks off a year and I use all of it badly."),
        SeedUser(username: "sofiap", displayName: "Sofia Petrova", city: "Sofia", bio: "Mountains over cities, every single time."),
        SeedUser(username: "ben_c", displayName: "Ben Carter", city: "Melbourne", bio: "Long haul veteran. Window seat, no exceptions."),
        SeedUser(username: "noorh", displayName: "Noor Haddad", city: "Amman", bio: "I photograph doorways. That is the whole hobby."),
        SeedUser(username: "erik_l", displayName: "Erik Lindqvist", city: "Stockholm", bio: "Cold water swims in as many countries as possible."),
        SeedUser(username: "maya_t", displayName: "Maya Thompson", city: "Chicago", bio: "Architecture, diners and long walks at dusk."),
        SeedUser(username: "jprend", displayName: "Jean-Pierre Rendu", city: "Marseille", bio: "Sailor's eye for a good harbour and a bad one."),
        SeedUser(username: "hana_k", displayName: "Hana Kobayashi", city: "Osaka", bio: "Backstreets, second-hand bookshops, late trains."),
        SeedUser(username: "ollyb", displayName: "Olly Bennett", city: "Bristol", bio: "Bad at planning, excellent at improvising."),
        SeedUser(username: "priya_s", displayName: "Priya Shah", city: "Nairobi", bio: "Wildlife guide in another life. Now I just take notes."),
        SeedUser(username: "matt_d", displayName: "Matt Doyle", city: "Dublin", bio: "Will walk twenty kilometres for a view and regret nothing."),
        SeedUser(username: "zoe_w", displayName: "Zoe Whitfield", city: "Vancouver", bio: "Ferries, fog and very early starts."),
        SeedUser(username: "carlos_r", displayName: "Carlos Rivera", city: "Mexico City", bio: "Market cook. I travel to eat."),
        SeedUser(username: "annikav", displayName: "Annika Virtanen", city: "Helsinki", bio: "Design museums and long silences."),
        SeedUser(username: "sam_k", displayName: "Sam Okafor", city: "Lagos", bio: "Music first. Everything else is logistics."),
        SeedUser(username: "lena_m", displayName: "Lena Müller", city: "Berlin", bio: "Cycling between cities until my legs file a complaint."),
        SeedUser(username: "hugo_s", displayName: "Hugo Santos", city: "São Paulo", bio: "Twelve hours of daylight, twelve hours of walking."),
        SeedUser(username: "fionam", displayName: "Fiona MacLeod", city: "Edinburgh", bio: "Rain is not a reason to stay in."),
        SeedUser(username: "yusuf_a", displayName: "Yusuf Aslan", city: "Istanbul", bio: "Two continents, one commuter pass."),
        SeedUser(username: "gretchen", displayName: "Greta Lindberg", city: "Copenhagen", bio: "I keep a list of places that were worth the detour."),
        SeedUser(username: "pablor", displayName: "Pablo Ruiz", city: "Madrid", bio: "Late dinners, early trains, no complaints."),
        SeedUser(username: "jennyl", displayName: "Jenny Lim", city: "Singapore", bio: "Airport lounges are my second home."),
        SeedUser(username: "aron_v", displayName: "Aron Van Dijk", city: "Rotterdam", bio: "Harbours, cranes and industrial sunsets."),
        SeedUser(username: "tessab", displayName: "Tessa Bright", city: "Auckland", bio: "Four hours from anywhere and I like it that way."),
        SeedUser(username: "milos_p", displayName: "Miloš Pavlović", city: "Belgrade", bio: "River towns and long lunches."),
        SeedUser(username: "amberw", displayName: "Amber Wallace", city: "Portland", bio: "Trail maps, thermos, out the door by five."),
        SeedUser(username: "giovanni", displayName: "Giovanni Ricci", city: "Naples", bio: "I know every ferry schedule on this coast."),
        SeedUser(username: "kirsten", displayName: "Kirsten Dahl", city: "Oslo", bio: "Winter light is the whole point."),
        SeedUser(username: "rault", displayName: "Raúl Torres", city: "Buenos Aires", bio: "Steak, football and a very slow bus."),
    ]

    // MARK: - Posts

    struct SeedPost {
        let theme: ATPostTheme
        let location: String
        let country: String
        let mediaCount: Int
        let hasVideo: Bool
        let body: String
    }

    static let posts: [SeedPost] = [

        // MARK: Regret

        SeedPost(theme: .regret, location: "Kyoto", country: "Japan", mediaCount: 3, hasVideo: false, body: "Four days in Kyoto and I never once left the temple circuit. What I actually remember is twenty minutes on a curb in Gion eating a convenience-store onigiri while a delivery van idled beside me. Next time I book nothing at all and just walk."),
        SeedPost(theme: .regret, location: "Positano", country: "Italy", mediaCount: 2, hasVideo: false, body: "We skipped the ferry because the queue looked endless. The queue was twenty minutes. The road alternative took three hours and I saw the whole coast through a bus window with someone's backpack in my face."),
        SeedPost(theme: .regret, location: "Reykjavík", country: "Iceland", mediaCount: 4, hasVideo: true, body: "I packed six stops into a single day and can now recall none of them. Iceland rewards standing still, and I had booked every hour down to the petrol stops."),
        SeedPost(theme: .regret, location: "Marrakesh", country: "Morocco", mediaCount: 2, hasVideo: false, body: "I turned down mint tea three separate times because I assumed it was a sales tactic. It was not a sales tactic. It was tea, and turning it down was the rudest thing I did all week."),
        SeedPost(theme: .regret, location: "Lisbon", country: "Portugal", mediaCount: 3, hasVideo: false, body: "Brought the wrong shoes and paid for it on every one of those hills. Nobody warns you properly that Lisbon is a staircase with a city attached to it."),
        SeedPost(theme: .regret, location: "Hanoi", country: "Vietnam", mediaCount: 2, hasVideo: false, body: "Left after two nights because the noise got under my skin. Everyone who stayed a week says it flips around day three and becomes the best place in the country. I will never know."),
        SeedPost(theme: .regret, location: "Mexico City", country: "Mexico", mediaCount: 3, hasVideo: false, body: "Skipped the anthropology museum because it looked like homework. Spent that afternoon in a shopping centre buying a phone charger. I think about this more often than is reasonable."),

        // MARK: Surprise

        SeedPost(theme: .surprise, location: "Tbilisi", country: "Georgia", mediaCount: 4, hasVideo: true, body: "Booked three nights as a stopover and stayed nine. The old town at 7am, before the shutters go up, is one of the quietest beautiful places I have stood in. Nobody I know has been."),
        SeedPost(theme: .surprise, location: "Bratislava", country: "Slovakia", mediaCount: 3, hasVideo: false, body: "Went in expecting a half-day city between better-known neighbours. Left four days later having eaten extremely well for the price of a London sandwich."),
        SeedPost(theme: .surprise, location: "Valparaíso", country: "Chile", mediaCount: 5, hasVideo: false, body: "Every wall is painted by someone with something to say and the funiculars still run. I had budgeted an afternoon and gave it three days."),
        SeedPost(theme: .surprise, location: "Ghent", country: "Belgium", mediaCount: 3, hasVideo: false, body: "Went for one canal photograph and stayed for the fact that it is a real working city rather than a preserved one. Students everywhere, bikes everywhere, no ticket queues anywhere."),
        SeedPost(theme: .surprise, location: "Wrocław", country: "Poland", mediaCount: 4, hasVideo: false, body: "I had no expectations whatsoever and it turned out to be the most pleasant surprise of the whole trip. The little bronze dwarfs hidden around the city kept me walking for hours."),
        SeedPost(theme: .surprise, location: "Kotor", country: "Montenegro", mediaCount: 3, hasVideo: true, body: "The bay looks photoshopped and the climb above the town takes about an hour if you are honest about your fitness. I was not honest. It was still worth it."),
        SeedPost(theme: .surprise, location: "Kanazawa", country: "Japan", mediaCount: 4, hasVideo: false, body: "Went specifically to avoid Kyoto and accidentally found the garden I had been hoping Kyoto would be. Sat there for two hours doing absolutely nothing."),

        // MARK: Hidden Gem

        SeedPost(theme: .hiddenGem, location: "Sighișoara", country: "Romania", mediaCount: 3, hasVideo: false, body: "A walled town on a hill that costs almost nothing to wander. Go on a weekday in October and you will have the clock tower square largely to yourself."),
        SeedPost(theme: .hiddenGem, location: "Matera", country: "Italy", mediaCount: 5, hasVideo: false, body: "Everyone does the famous viewpoint and leaves. Stay overnight, walk down into the sassi at dusk, and the whole place changes character completely."),
        SeedPost(theme: .hiddenGem, location: "Ansoo", country: "Spain", mediaCount: 2, hasVideo: false, body: "A village in the Pyrenees with one bar, one bakery and a river you can hear from bed. The bakery opens at eight and sells out by nine. Plan accordingly."),
        SeedPost(theme: .hiddenGem, location: "Trsteno", country: "Croatia", mediaCount: 3, hasVideo: false, body: "Twenty minutes up the coast from the crowds, an old arboretum with a fountain and about six other people in it. Cheapest good hour of the whole trip."),
        SeedPost(theme: .hiddenGem, location: "El Chaltén", country: "Argentina", mediaCount: 6, hasVideo: true, body: "A town that exists purely as a trailhead and does that job perfectly. Trails start from the main street. You can be at a glacier by lunch without a single vehicle."),
        SeedPost(theme: .hiddenGem, location: "Isfahan", country: "Iran", mediaCount: 4, hasVideo: false, body: "The bridges at night, when families sit out on the stone with tea, are the memory I kept. Go late, not at sunset with the tour groups."),
        SeedPost(theme: .hiddenGem, location: "Lofoten", country: "Norway", mediaCount: 5, hasVideo: true, body: "Everyone photographs the same three viewpoints. Rent a bike instead and ride between the fishing villages — you get the same mountains with nobody standing in front of them."),

        // MARK: Pitfall

        SeedPost(theme: .pitfall, location: "Venice", country: "Italy", mediaCount: 2, hasVideo: false, body: "Bought a waterbus pass I did not need, at a price I am embarrassed to type, and then walked everywhere anyway because walking is faster. Check the map before you buy the ticket."),
        SeedPost(theme: .pitfall, location: "Bangkok", country: "Thailand", mediaCount: 2, hasVideo: false, body: "Agreed a fare at the airport without asking about the tolls. The tolls were not included. It cost more than the flight's baggage fee and I paid it with a smile because I had no choice."),
        SeedPost(theme: .pitfall, location: "Paris", country: "France", mediaCount: 3, hasVideo: false, body: "Bought a museum pass on a Monday. Two of the four museums I wanted were shut on Mondays. Read the opening days before you commit to the pass, not after."),
        SeedPost(theme: .pitfall, location: "Dubrovnik", country: "Croatia", mediaCount: 2, hasVideo: false, body: "Walked the walls at eleven in the morning in August with no water and no hat. There is no shade up there at all. Do it at eight or at six, never in between."),
        SeedPost(theme: .pitfall, location: "Cairo", country: "Egypt", mediaCount: 3, hasVideo: false, body: "Hired a guide at the gate who was not a guide. He was a very confident man with a lanyard. Book through your hotel or not at all."),
        SeedPost(theme: .pitfall, location: "Amsterdam", country: "Netherlands", mediaCount: 2, hasVideo: false, body: "Rented a bike without checking the brakes, on cobbles, in the rain. I have never been closer to a canal. Test the brakes in the shop doorway before you ride away."),
        SeedPost(theme: .pitfall, location: "Zermatt", country: "Switzerland", mediaCount: 3, hasVideo: true, body: "Assumed the mountain railway ran late. It does not. The last train left while I was still admiring the view and the walk back down took three hours in fading light."),

        // MARK: Wrong Turn

        SeedPost(theme: .wrongTurn, location: "Santorini", country: "Greece", mediaCount: 2, hasVideo: false, body: "Took a shortcut down to the water that turned into a goat path and then into a cliff. Retrieved my dignity about forty minutes later, further along the coast than intended."),
        SeedPost(theme: .wrongTurn, location: "Edinburgh", country: "Scotland", mediaCount: 2, hasVideo: false, body: "Followed a sign for the castle that pointed the wrong way for two streets, then gave up and followed the crowd instead. The crowd was right. The sign was decorative."),
        SeedPost(theme: .wrongTurn, location: "Bogotá", country: "Colombia", mediaCount: 2, hasVideo: false, body: "Got on the bus going the correct direction on the wrong road. Ninety minutes later I was at the end of the line being helped by a driver who found the whole thing hilarious."),
        SeedPost(theme: .wrongTurn, location: "Marrakech", country: "Morocco", mediaCount: 3, hasVideo: false, body: "Trusted my own sense of direction in the medina. The medina does not recognise my sense of direction as a valid concept. A boy on a moped walked me home for the equivalent of a coffee."),
        SeedPost(theme: .wrongTurn, location: "Bergen", country: "Norway", mediaCount: 3, hasVideo: true, body: "Set off on a marked trail that was marked considerably better at the start than at the end. Came down a different mountain to the one I went up. Views were excellent throughout."),
        SeedPost(theme: .wrongTurn, location: "Jaipur", country: "India", mediaCount: 2, hasVideo: false, body: "Asked for the fort and was pointed at a different fort. Went anyway. It was smaller, emptier and better, and I have never been able to work out which one I actually saw."),
        SeedPost(theme: .wrongTurn, location: "Porto", country: "Portugal", mediaCount: 3, hasVideo: false, body: "Crossed the wrong bridge, walked up the wrong hill, ended up in a residential street where a woman was watering plants and told me I was lost before I said anything."),

        // MARK: Overrated

        SeedPost(theme: .overrated, location: "Santorini", country: "Greece", mediaCount: 3, hasVideo: false, body: "The famous sunset is a crowd of several hundred people holding phones above their heads. The same sun sets over the quieter side of the island with nobody watching at all."),
        SeedPost(theme: .overrated, location: "Times Square", country: "United States", mediaCount: 2, hasVideo: false, body: "Went once, at night, as instructed. Fifteen minutes was enough and I spent most of it being gently shuffled along by people who were also not enjoying it."),
        SeedPost(theme: .overrated, location: "Bali", country: "Indonesia", mediaCount: 4, hasVideo: false, body: "The island is genuinely beautiful and the specific places everybody posts are the least pleasant parts of it. Two hours inland and it becomes the trip people think they had."),
        SeedPost(theme: .overrated, location: "Prague", country: "Czechia", mediaCount: 3, hasVideo: false, body: "The old town square at noon is a scrum. Cross the river, walk twenty minutes in any direction, and you get the same architecture with room to look at it."),
        SeedPost(theme: .overrated, location: "Hollywood", country: "United States", mediaCount: 2, hasVideo: false, body: "A pavement with names on it and a queue for a photograph of some letters on a hill. I had a very good taco nearby, which redeemed the afternoon entirely."),
        SeedPost(theme: .overrated, location: "Chefchaouen", country: "Morocco", mediaCount: 3, hasVideo: false, body: "The blue is real and so is the queue for every blue doorway. Go at seven in the morning — the photographs are better and the shopkeepers are still having breakfast."),
        SeedPost(theme: .overrated, location: "Kuta", country: "Indonesia", mediaCount: 2, hasVideo: false, body: "Busy, hot, and full of people selling the same four things. Twenty minutes down the coast is the same beach with a tenth of the noise."),

        // MARK: Lucky Find

        SeedPost(theme: .luckyFind, location: "Ljubljana", country: "Slovenia", mediaCount: 3, hasVideo: false, body: "Missed a connection and got four unexpected hours here. Sat by the river with a coffee and watched the whole city go past on bicycles. Best delay of my life."),
        SeedPost(theme: .luckyFind, location: "Chișinău", country: "Moldova", mediaCount: 3, hasVideo: false, body: "Ended up here because a flight was cheaper. The wine cellars under the city go on for kilometres and I had them almost entirely to myself on a Tuesday."),
        SeedPost(theme: .luckyFind, location: "Bergen", country: "Norway", mediaCount: 4, hasVideo: true, body: "Walked out of the hotel to buy a toothbrush and found a street market setting up with fish, bread and about nine kinds of jam. Ate standing up. Perfect morning, entirely unplanned."),
        SeedPost(theme: .luckyFind, location: "Seoul", country: "South Korea", mediaCount: 3, hasVideo: false, body: "Took a wrong exit from the subway and came up in a food alley that I then ate my way down for two hours. I have never been able to find it again."),
        SeedPost(theme: .luckyFind, location: "Tirana", country: "Albania", mediaCount: 3, hasVideo: false, body: "Booked one night to break up a bus journey. Stayed four. The coffee culture here is serious, the prices are not, and the light in the afternoon is extraordinary."),
        SeedPost(theme: .luckyFind, location: "Bergamo", country: "Italy", mediaCount: 3, hasVideo: false, body: "Landing at the budget airport turned into a day in the upper town, which is walled, quiet and has a funicular. Cheaper and calmer than the city everyone flies here to reach."),
        SeedPost(theme: .luckyFind, location: "Hobart", country: "Australia", mediaCount: 4, hasVideo: false, body: "Came for a wedding, stayed an extra week. The Saturday market alone justifies the flight, and the mountain behind the city had snow on it in the middle of summer."),

        // MARK: Long Haul

        SeedPost(theme: .longHaul, location: "Trans-Siberian", country: "Russia", mediaCount: 4, hasVideo: true, body: "Six days on a train and the first two were genuinely hard. By day three the rhythm takes over and you start resenting the stops for interrupting it. Bring more food than you think you need."),
        SeedPost(theme: .longHaul, location: "Atacama", country: "Chile", mediaCount: 4, hasVideo: false, body: "Twenty-two hours of buses to reach a place with no water and no shade. Worth it once. I would not do the buses again — I would fly to Calama and sleep for a day first."),
        SeedPost(theme: .longHaul, location: "Kerala", country: "India", mediaCount: 3, hasVideo: false, body: "An overnight train, a bus, and a boat to get to a guesthouse with three rooms. The journey is the story. The destination is a nice place to recover from the journey."),
        SeedPost(theme: .longHaul, location: "Ushuaia", country: "Argentina", mediaCount: 4, hasVideo: true, body: "Flew to the end of the world in three legs and arrived with no luggage. Bought a coat locally, which the airline later reimbursed, and had the best three days of the trip."),
        SeedPost(theme: .longHaul, location: "Ladakh", country: "India", mediaCount: 5, hasVideo: true, body: "Two days of mountain roads at altitude with a driver who was completely unbothered. Take the acclimatisation seriously — I did not, and lost a day to a headache."),
        SeedPost(theme: .longHaul, location: "Rarotonga", country: "Cook Islands", mediaCount: 3, hasVideo: false, body: "Twenty-six hours of travel each way, including a night in a transit hotel, for five days on the island. Would I do it again? Yes, but for ten days, not five."),
        SeedPost(theme: .longHaul, location: "Tromsø", country: "Norway", mediaCount: 3, hasVideo: true, body: "Three flights and a bus in the dark to get above the Arctic Circle in January. Saw the lights on the second night and understood immediately why people do this journey repeatedly."),
    ]

    // MARK: - Comments

    static let commentsByTheme: [ATPostTheme: [String]] = [
        .regret: [
            "This is the most honest thing I have read on here.",
            "The thing you skipped is always the thing you remember.",
            "I did almost exactly this and I still think about it.",
            "Adding this to the list of places to do properly next time.",
            "Nobody warns you that over-scheduling is its own kind of loss.",
            "Twenty minutes on a curb beats four hours of queueing. Always.",
        ],
        .surprise: [
            "Went in with no expectations and it is now a favourite. Same experience.",
            "Booked two nights, stayed six. I understand completely.",
            "This place never makes anyone's list and it should.",
            "The morning version of a place is always the real one.",
            "How did you find out about this? Genuinely asking.",
            "Saving this. I had written it off entirely.",
        ],
        .hiddenGem: [
            "Please stop telling people about this.",
            "Weekday in the off-season is the entire trick.",
            "Staying overnight instead of day-tripping changes everything.",
            "The bakery detail is the most useful thing in this post.",
            "Been nearby twice and never stopped. That was a mistake.",
            "Renting a bike instead of driving is the right call here.",
        ],
        .pitfall: [
            "I paid this exact price for this exact mistake.",
            "Adding this to the list of things to check before booking.",
            "Nobody reads the opening days until it is too late.",
            "The last train is always earlier than you think it is.",
            "Thank you for the warning, sincerely.",
            "Water and a hat. Every time. Every single time.",
        ],
        .wrongTurn: [
            "The best parts of my trips are always the wrong turns.",
            "Ended up somewhere similar and stayed for hours.",
            "This is exactly how I found my favourite place last year.",
            "Getting lost in a medina is basically compulsory.",
            "Genuinely funny and also deeply relatable.",
            "The locals always know you are lost before you do.",
        ],
        .overrated: [
            "Genuinely refreshing to see someone say this.",
            "Went once, will not go again, and I feel seen.",
            "The quieter side of the island is the whole answer.",
            "Twenty minutes' walk from the crowds and it is a different place.",
            "Agreed, though the food nearby usually saves it.",
            "Go early or do not go. This is the rule.",
        ],
        .luckyFind: [
            "Missed connection turned into the best part of the trip. Same.",
            "Accidental finds are always better than planned ones.",
            "This is why I stopped booking everything in advance.",
            "How have I never heard of this place?",
            "The unplanned morning is always the one I remember.",
            "Saving this for the next time a flight gets moved.",
        ],
        .longHaul: [
            "The journey is the trip. Took me years to accept this.",
            "Six days on a train sounds terrifying and also perfect.",
            "Acclimatisation is not optional, learned the hard way.",
            "Worth it once is exactly the right verdict.",
            "Doing the same route next year. Noted on the food.",
            "Would you do it again? Genuine question.",
        ],
    ]

    static let genericComments: [String] = [
        "Which month did you go?",
        "Saving this for later, thank you.",
        "Great write-up. The detail about the light is lovely.",
        "Adding it to the list.",
        "This is the kind of post I come here for.",
        "How long would you give it if you went back?",
        "Beautifully put.",
        "Taking notes. Heading there in spring.",
    ]

    // MARK: - Conversations

    struct SeedThread {
        let peerUsername: String
        let firstSpeakerIsPeer: Bool
        let messages: [String]
    }

    static let threads: [SeedThread] = [
        SeedThread(peerUsername: "marisolv", firstSpeakerIsPeer: true, messages: [
            "Your Kyoto post is doing numbers, by the way.",
            "Ha, it is mostly complaining.",
            "It is the useful kind of complaining. People need it.",
            "That is the hope. Are you still going in April?",
            "April, yes. Should I do the same route as you?",
            "Only if you want to spend four days queuing.",
            "Noted. What would you do instead?",
            "Book one thing, then walk in a different direction each morning.",
            "That is going in the notes app right now.",
            "Send me your list when you have it and I will mark it up.",
            "You will regret offering that.",
            "I have regretted worse. Do it.",
        ]),
        SeedThread(peerUsername: "tomash", firstSpeakerIsPeer: false, messages: [
            "That hidden gem post has convinced me.",
            "Which one, I have written about four.",
            "The walled town in Romania.",
            "Go on a weekday. I mean that literally, it is a different place.",
            "Tuesday it is. Is two nights too many?",
            "Two is right. Three and you will have run out of things to do.",
            "Perfect. Anything I should book ahead?",
            "Just the train. Everything else you can decide when you get there.",
            "Refreshing after the itinerary I built for Italy.",
            "You built an itinerary?",
            "Do not. I am still recovering.",
        ]),
        SeedThread(peerUsername: "aisha_r", firstSpeakerIsPeer: false, messages: [
            "Did you make it to the market in the end?",
            "I did. Ate standing up, twice, no regrets.",
            "The jam place?",
            "Nine kinds of jam. I bought four.",
            "Which was the best one?",
            "The one I cannot remember the name of, naturally.",
            "Send a photo of the jar and I will work it out.",
            "I ate the label. Give me until tomorrow.",
            "Unbelievable.",
        ]),
        SeedThread(peerUsername: "ben_c", firstSpeakerIsPeer: true, messages: [
            "Quick one — flights or trains for the coast?",
            "Trains, and book the window side.",
            "Even with the change at the second stop?",
            "Especially with the change. That stretch is the whole point.",
            "How long is the change?",
            "Forty minutes, enough for a coffee if you walk fast.",
            "Booked. Window seat, second stop, coffee.",
        ]),
    ]
}
