import Foundation

enum PackRepository {
    static func localCatalog() -> RemoteCatalog {
        bestOf(bundled(), loadCache())
    }

    static func bestOf(_ catalogs: RemoteCatalog?...) -> RemoteCatalog {
        catalogs.compactMap { cat -> RemoteCatalog? in
            guard let cat, !cat.packs.isEmpty else { return nil }
            return cat
        }
        .max { a, b in
            if a.version != b.version { return a.version < b.version }
            let ac = a.packs.reduce(0) { $0 + $1.cards.count }
            let bc = b.packs.reduce(0) { $0 + $1.cards.count }
            return ac < bc
        } ?? RemoteCatalog(version: 1, packs: [])
    }

    static func load() async -> RemoteCatalog {
        bestOf(localCatalog(), await fetchRemote())
    }

    static func fetchRemote() async -> RemoteCatalog? {
        let raw = AppConfig.packsURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        let sep = raw.contains("?") ? "&" : "?"
        guard let url = URL(string: "\(raw)\(sep)t=\(Int(Date().timeIntervalSince1970 * 1000))") else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let catalog = try JSONDecoder().decode(RemoteCatalog.self, from: data)
            guard !catalog.packs.isEmpty else { return nil }
            saveCache(catalog)
            return catalog
        } catch {
            return nil
        }
    }

    private static var cacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("packs-cache.json")
    }

    private static func saveCache(_ catalog: RemoteCatalog) {
        if let data = try? JSONEncoder().encode(catalog) {
            try? data.write(to: cacheURL)
        }
    }

    private static func loadCache() -> RemoteCatalog? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(RemoteCatalog.self, from: data)
    }

    private static func bundled() -> RemoteCatalog {
        guard let url = Bundle.main.url(forResource: "packs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(RemoteCatalog.self, from: data) else {
            return RemoteCatalog(version: 1, packs: [])
        }
        return catalog
    }

    static func flatten(_ catalog: RemoteCatalog, custom: [CustomCard]) -> [Card] {
        let remote = catalog.packs.flatMap { pack in
            pack.cards.map {
                Card(id: $0.id, packId: pack.id, packName: pack.name, text: $0.text, mood: $0.mood, roundType: $0.roundType, intensity: $0.intensity, source: "remote")
            }
        }
        let ours = custom.map { c in
            Card(id: c.id, packId: "our_cards", packName: "Our cards", text: c.text, mood: c.mood, roundType: c.roundType, intensity: c.intensity, source: "custom")
        }
        return remote + ours
    }
}

enum DeckBuilder {
    static func session(all: [Card], packId: String?, mode: Mode, count: Int, used: Set<String>) -> [PlayCard] {
        let n = min(max(count, 2), 20)
        let scoped = all.filter { packId == nil || $0.packId == packId }
        let pool: [Card]
        switch mode {
        case .romantic: pool = scoped.filter { $0.mood == "romantic" }
        case .challenge: pool = scoped.filter { $0.mood == "challenge" }
        case .mix: pool = scoped
        }
        let sourcePool = (pool.isEmpty ? scoped : pool).isEmpty ? all : (pool.isEmpty ? scoped : pool)
        let fresh = sourcePool.filter { !used.contains($0.id) }
        var source = (fresh.isEmpty ? sourcePool : fresh).shuffled()
        if source.isEmpty { return [] }
        var cards: [Card] = []
        while cards.count < n {
            cards.append(contentsOf: source)
        }
        cards = Array(cards.prefix(n))
        return cards.enumerated().map { PlayCard(card: $1, holderIsA: $0 % 2 == 0) }
    }
}
