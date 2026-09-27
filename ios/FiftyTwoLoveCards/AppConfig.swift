import Foundation

enum AppConfig {
    static func value(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }

    static var packsURL: String { value("PACKS_URL") }
    static var termsURL: String { value("TERMS_URL") }
    static var privacyURL: String { value("PRIVACY_URL") }
    static var supportEmail: String { value("SUPPORT_EMAIL") }
    static var productIds: [String] {
        ["IAP_PRODUCT_7DAY", "IAP_PRODUCT_MONTHLY", "IAP_PRODUCT_YEARLY"].map(value).filter { !$0.isEmpty }
    }
    static var labels: [(id: String, label: String)] {
        [
            (value("IAP_PRODUCT_7DAY"), "Weekly"),
            (value("IAP_PRODUCT_MONTHLY"), "Monthly"),
            (value("IAP_PRODUCT_YEARLY"), "Yearly"),
        ]
    }
}
