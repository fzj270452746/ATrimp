//
//  ATPostTheme.swift
//  ATrimp
//
//
import UIKit

enum ATPostTheme: String, CaseIterable, Codable {
    case regret
    case surprise
    case hiddenGem
    case pitfall
    case wrongTurn
    case overrated
    case luckyFind
    case longHaul

    var title: String {
        switch self {
        case .regret: return "Regret"
        case .surprise: return "Surprise"
        case .hiddenGem: return "Hidden Gem"
        case .pitfall: return "Pitfall"
        case .wrongTurn: return "Wrong Turn"
        case .overrated: return "Overrated"
        case .luckyFind: return "Lucky Find"
        case .longHaul: return "Long Haul"
        }
    }

    var blurb: String {
        switch self {
        case .regret: return "What you would do differently"
        case .surprise: return "Better than anyone told you"
        case .hiddenGem: return "Empty, cheap and worth the detour"
        case .pitfall: return "Cost you money, time or both"
        case .wrongTurn: return "The route that went nowhere"
        case .overrated: return "Everyone raves, you do not"
        case .luckyFind: return "Stumbled into it by accident"
        case .longHaul: return "The journey was the ordeal"
        }
    }

    var symbol: String {
        switch self {
        case .regret: return "arrow.uturn.backward"
        case .surprise: return "sparkles"
        case .hiddenGem: return "mappin.and.ellipse"
        case .pitfall: return "exclamationmark.triangle"
        case .wrongTurn: return "arrow.triangle.turn.up.right.diamond"
        case .overrated: return "hand.thumbsdown"
        case .luckyFind: return "clover"
        case .longHaul: return "tortoise"
        }
    }

    var guidingQuestions: [String] {
        switch self {
        case .regret:
            return ["What you expected", "What actually happened", "What you would do instead"]
        case .surprise:
            return ["What you had been told", "What it was really like", "Who it is for"]
        case .hiddenGem:
            return ["How you found it", "What it cost", "Why nobody goes"]
        case .pitfall:
            return ["What it cost you", "The warning you missed", "How to avoid it"]
        case .wrongTurn:
            return ["Where the route went wrong", "How long before you knew", "The way back"]
        case .overrated:
            return ["What everyone says", "What you actually got", "What to do instead"]
        case .luckyFind:
            return ["How you stumbled into it", "What made it work", "Whether it would again"]
        case .longHaul:
            return ["The leg that broke you", "What you would pay to skip", "What made it bearable"]
        }
    }

    var scaffold: String {
        guidingQuestions.map { "\($0): " }.joined(separator: "\n") + "\n"
    }

    var intensityPrompt: String {
        switch self {
        case .regret: return "How much do you regret it?"
        case .surprise: return "How far past your expectations?"
        case .hiddenGem: return "How glad you found it?"
        case .pitfall: return "How much did it cost you?"
        case .wrongTurn: return "How badly did it go?"
        case .overrated: return "How much did it let you down?"
        case .luckyFind: return "How lucky was it, really?"
        case .longHaul: return "How hard was the journey?"
        }
    }

    var tint: UIColor {
        switch self {
        case .regret: return UIColor(hex: 0x9B4A57)
        case .surprise: return UIColor(hex: 0xC98A2B)
        case .hiddenGem: return UIColor(hex: 0x2F6D62)
        case .pitfall: return UIColor(hex: 0xB5541F)
        case .wrongTurn: return UIColor(hex: 0x4A5578)
        case .overrated: return UIColor(hex: 0x6B7043)
        case .luckyFind: return UIColor(hex: 0x7A5CA8)
        case .longHaul: return UIColor(hex: 0x3E6E9E)
        }
    }
}
