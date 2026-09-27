import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: Screen = .splash
    @Published var onboardPage = 0
    @Published var catalog = RemoteCatalog(version: 1, packs: [])
    @Published var cards: [Card] = []
    @Published var custom: [CustomCard] = []
    @Published var tab: Mode = .mix
    @Published var cardCount = 8
    @Published var nameA = LocalStore.nameA
    @Published var nameB = LocalStore.nameB
    @Published var selectedPackId: String?
    @Published var packIndex = 0
    @Published var deck: [PlayCard] = []
    @Published var index = 0
    @Published var scoreA = 0
    @Published var scoreB = 0
    @Published var skips = 0
    @Published var playAnswer = ""
    @Published var createText = ""
    @Published var createMood = "romantic"
    @Published var createRound = "know_me"
    @Published var catalogLive = false
    @Published var loading = false
    @Published var error: String?

    let ourPack = RemotePack(id: "our_cards", name: "Our cards", blurb: "Cards you wrote together.", cards: [])

    func bootstrap() async {
        let started = Date()
        custom = LocalStore.custom
        catalog = PackRepository.localCatalog()
        cards = PackRepository.flatten(catalog, custom: custom)
        let remote = await PackRepository.fetchRemote()
        let best = PackRepository.bestOf(catalog, remote)
        catalog = best
        cards = PackRepository.flatten(best, custom: custom)
        catalogLive = remote != nil && remote!.version >= best.version
        let wait = 1 - Date().timeIntervalSince(started)
        if wait > 0 { try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
        screen = LocalStore.seenOnboarding ? .home : .onboarding
    }

    func refreshCatalog() async {
        loading = true
        let remote = await PackRepository.fetchRemote()
        let best = PackRepository.bestOf(PackRepository.localCatalog(), remote)
        catalog = best
        cards = PackRepository.flatten(best, custom: custom)
        catalogLive = remote != nil && remote!.version >= best.version
        loading = false
    }

    func goHome() {
        screen = .home
        error = nil
        playAnswer = ""
    }

    func backFromSettings() {
        if screen == .privacy || screen == .terms { go(.settings) } else { goHome() }
    }

    func displayPacks() -> [RemotePack] {
        custom.isEmpty ? catalog.packs : catalog.packs + [ourPack]
    }

    func cardsInPack(_ id: String?) -> [Card] {
        guard let id else { return cards }
        if id == "our_cards" { return cards.filter { $0.packId == "our_cards" || $0.source == "custom" } }
        return cards.filter { $0.packId == id }
    }

    func packName(_ id: String?) -> String {
        switch id {
        case nil: return "Mix"
        case "our_cards": return "Our cards"
        default: return catalog.packs.first { $0.id == id }?.name ?? "Pack"
        }
    }

    func setTab(_ mode: Mode) { tab = mode }
    func go(_ s: Screen) { screen = s; error = nil }

    func backFromPack() {
        if packIndex > 0 { prevPackCard() } else { goHome() }
    }

    func nextOnboard() {
        if onboardPage >= 2 { finishOnboard() } else { onboardPage += 1 }
    }

    func skipOnboard() { finishOnboard() }

    private func finishOnboard() {
        LocalStore.seenOnboarding = true
        screen = .home
        onboardPage = 0
    }

    func startGame() { screen = .setup }

    func openPack(_ id: String) {
        selectedPackId = id
        packIndex = 0
        screen = .packDetail
    }

    func nextPackCard() {
        let n = cardsInPack(selectedPackId).count
        guard n > 0 else { return }
        packIndex = min(packIndex + 1, n - 1)
    }

    func prevPackCard() {
        packIndex = max(packIndex - 1, 0)
    }

    func setPlayAnswer(_ raw: String) {
        let digits = String(raw.filter(\.isNumber).prefix(2))
        if digits.isEmpty { playAnswer = ""; return }
        if let n = Int(digits), (1...10).contains(n) { playAnswer = String(n); return }
        if digits == "1" { playAnswer = "1" }
    }

    var currentMark: Int? {
        guard let n = Int(playAnswer), (1...10).contains(n) else { return nil }
        return n
    }

    func submitMark() {
        guard let mark = currentMark else { return }
        settle(mark)
    }

    func skipCard() { settle(0) }

    func beginSession() {
        LocalStore.nameA = nameA.isEmpty ? "You" : nameA
        LocalStore.nameB = nameB.isEmpty ? "Them" : nameB
        nameA = LocalStore.nameA
        nameB = LocalStore.nameB
        deck = DeckBuilder.session(all: cards, packId: selectedPackId, mode: tab, count: cardCount, used: LocalStore.used)
        index = 0
        scoreA = 0
        scoreB = 0
        skips = 0
        playAnswer = ""
        screen = .play
    }

    private func settle(_ mark: Int) {
        guard deck.indices.contains(index) else { return }
        let current = deck[index]
        LocalStore.addUsed(current.card.id)
        if (1...10).contains(mark) {
            if current.holderIsA { scoreA += mark } else { scoreB += mark }
        } else {
            skips += 1
        }
        playAnswer = ""
        let next = index + 1
        if next >= deck.count {
            screen = .recap
        } else {
            index = next
        }
    }

    func backCard() {
        if index > 0 { index -= 1; playAnswer = "" }
    }

    func saveCustom() {
        let text = createText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if cards.contains(where: { $0.text.caseInsensitiveCompare(text) == .orderedSame }) {
            error = "That question already exists"
            return
        }
        let card = CustomCard(id: "custom-\(UUID().uuidString)", packId: "our_cards", text: text, mood: createMood, roundType: createRound, intensity: "light")
        LocalStore.custom = LocalStore.custom + [card]
        custom = LocalStore.custom
        cards = PackRepository.flatten(catalog, custom: custom)
        createText = ""
        error = nil
        selectedPackId = "our_cards"
        packIndex = 0
        screen = .packDetail
    }
}
