import Foundation

struct RemoteCatalog: Codable {
    var version: Int
    var packs: [RemotePack]
}

struct RemotePack: Codable, Identifiable {
    var id: String
    var name: String
    var blurb: String?
    var cards: [RemoteCard]
}

struct RemoteCard: Codable, Identifiable {
    var id: String
    var text: String
    var mood: String
    var roundType: String
    var intensity: String
}

struct Card: Identifiable {
    var id: String
    var packId: String
    var packName: String
    var text: String
    var mood: String
    var roundType: String
    var intensity: String
    var source: String
}

enum Mode: String, CaseIterable, Identifiable {
    case romantic = "Romantic"
    case challenge = "Challenge"
    case mix = "Mix"
    var id: String { rawValue }
}

struct PlayCard: Identifiable {
    var id: String { card.id }
    var card: Card
    var holderIsA: Bool
}

struct CustomCard: Codable, Identifiable {
    var id: String
    var packId: String
    var text: String
    var mood: String
    var roundType: String
    var intensity: String
}

enum Screen {
    case splash, onboarding, home, settings, privacy, terms, packDetail, create, setup, play, recap
}
