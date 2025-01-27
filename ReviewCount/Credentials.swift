import Foundation

struct Credentials {
    private static let label = "WaniKani API Token"
    private static let service = Bundle.main.bundleIdentifier!
    private static let accountName = "\(service).apiToken"

    static var hasToken: Bool {
        return get() != nil
    }

    static func get() -> String? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: accountName,
            kSecClass: kSecClassGenericPassword,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        guard status == errSecSuccess else {
            return nil
        }

        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    static func set(_ token: String) {
        let data = Data(token.utf8)

        let query = [
            kSecValueData: data,
            kSecAttrLabel: label,
            kSecAttrService: service,
            kSecAttrAccount: accountName,
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary

        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: accountName,
                kSecClass: kSecClassGenericPassword
            ] as CFDictionary

            let attributesToUpdate = [
                kSecValueData: data
            ] as CFDictionary

            SecItemUpdate(query, attributesToUpdate)
        }
    }

    static func remove() {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: accountName,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary

        SecItemDelete(query)
    }
}
