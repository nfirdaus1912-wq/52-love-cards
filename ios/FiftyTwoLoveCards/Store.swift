import Foundation
import StoreKit

@MainActor
final class Store: ObservableObject {
    struct Item: Identifiable {
        var id: String
        var label: String
        var price: String
        var product: Product?
    }

    @Published var items: [Item] = []
    @Published var subscribed = LocalStore.subscribed

    func start() async {
        subscribed = LocalStore.subscribed
        await loadProducts()
        await refresh()
        Task { await listen() }
    }

    func loadProducts() async {
        let ids = Set(AppConfig.productIds)
        guard !ids.isEmpty else {
            items = AppConfig.labels.map { Item(id: $0.id, label: $0.label, price: "Set in App Store Connect", product: nil) }
            return
        }
        do {
            let products = try await Product.products(for: ids)
            items = AppConfig.labels.map { pair in
                let p = products.first { $0.id == pair.id }
                return Item(id: pair.id, label: pair.label, price: p?.displayPrice ?? "—", product: p)
            }
        } catch {
            items = AppConfig.labels.map { Item(id: $0.id, label: $0.label, price: "—", product: nil) }
        }
    }

    func buy(_ item: Item) async {
        guard let product = item.product else { return }
        do {
            let result = try await product.purchase()
            if case .success(let ver) = result {
                if case .verified = ver {
                    await refresh()
                }
            }
        } catch {}
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    func refresh() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified = result { active = true }
        }
        LocalStore.subscribed = active
        subscribed = active
    }

    private func listen() async {
        for await _ in Transaction.updates {
            await refresh()
        }
    }
}
