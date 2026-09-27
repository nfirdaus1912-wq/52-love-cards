import Foundation

enum LocalStore {
    private static let defaults = UserDefaults.standard

    static var nameA: String {
        get { defaults.string(forKey: "name_a") ?? "" }
        set { defaults.set(newValue, forKey: "name_a") }
    }
    static var nameB: String {
        get { defaults.string(forKey: "name_b") ?? "" }
        set { defaults.set(newValue, forKey: "name_b") }
    }
    static var used: Set<String> {
        get { Set(defaults.stringArray(forKey: "used_ids") ?? []) }
        set { defaults.set(Array(newValue), forKey: "used_ids") }
    }
    static func addUsed(_ id: String) {
        var s = used
        s.insert(id)
        used = s
    }
    static var subscribed: Bool {
        get { defaults.bool(forKey: "subscribed") }
        set { defaults.set(newValue, forKey: "subscribed") }
    }
    static var seenOnboarding: Bool {
        get { defaults.bool(forKey: "seen_onboard") }
        set { defaults.set(newValue, forKey: "seen_onboard") }
    }

    static var custom: [CustomCard] {
        get {
            guard let data = defaults.data(forKey: "custom_json") else { return [] }
            return (try? JSONDecoder().decode([CustomCard].self, from: data)) ?? []
        }
        set {
            defaults.set(try? JSONEncoder().encode(newValue), forKey: "custom_json")
        }
    }
}
