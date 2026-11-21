import Foundation
import UIKit

// MARK: - Models

struct VGGift: Codable {
    var id: String
    var name: String
    var emoji: String
    var value: Int
    var date: Date
    var isUpgraded: Bool
    var uniqueNumber: Int?
    var model: String?
    var backdrop: String?
    var symbol: String?
    var availability: Int
    var totalAvailability: Int
    var isNFT: Bool
    var slugOrLink: String?
    
    var displayName: String {
        if let num = uniqueNumber {
            return "\(name) #\(num)"
        }
        return name
    }
}

struct VGProfile: Codable {
    var id: String
    var name: String
    var hasPremium: Bool = false
    var hasTelegramBadge: Bool = false
    var verificationType: VGVerificationType = .none
    var nftUsername: String? = nil
    var collectibleNumber: String? = nil
    var collectibleNumberPrice: Double? = nil
    var collectibleNumberDate: Date? = nil
    var level: Int? = nil
    var levelProgress: Int = 0
    var levelMax: Int = 1000
    var usernames: [String] = []
    var profileColor: String? = nil
    var profileBackground: String? = nil
    var workHours: String? = nil
    var address: String? = nil
    var starsBalance: Int = 0
    var gramBalance: Double = 0
    var gifts: [VGGift] = []
    var gramCardBackground: String = "blue"
    var gramCardSticker: String? = nil
}

enum VGVerificationType: String, Codable {
    case none = "none"
    case major = "major"
    case hold = "hold"
}

struct VGTransaction: Codable {
    var id: String
    var type: VGTransactionType
    var giftName: String
    var giftEmoji: String
    var date: Date
    var fromProfile: String?
    var toProfile: String?
    var amount: Int?
    var currency: String?
}

enum VGTransactionType: String, Codable {
    case received = "received"
    case sent = "sent"
    case upgraded = "upgraded"
    case purchased = "purchased"
}

// MARK: - Gift Catalog

struct VGGiftCatalogItem {
    var id: String
    var name: String
    var emoji: String
    var value: Int
    var totalAvailability: Int
    var availableLeft: Int
    var isResale: Bool
    var firstSale: Date?
    var lastSale: Date?
}

// MARK: - Manager

class VisualGramManager {
    static let shared = VisualGramManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private let keyActivated = "vg_activated"
    private let keyTrialStart = "vg_trial_start"
    private let keyProfiles = "vg_profiles"
    private let keyCurrentProfile = "vg_current_profile"
    private let keyTransactions = "vg_transactions"
    private let keyActivationKey = "vg_activation_key"
    
    private init() {
        if getProfiles().isEmpty {
            let defaultProfile = VGProfile(id: "main", name: "Мой профиль")
            saveProfile(defaultProfile)
            setCurrentProfileId("main")
        }
    }
    
    // MARK: - Trial & Activation
    
    var isActivated: Bool {
        return defaults.bool(forKey: keyActivated)
    }
    
    var trialStartDate: Date? {
        return defaults.object(forKey: keyTrialStart) as? Date
    }
    
    var isTrialActive: Bool {
        guard !isActivated else { return true }
        guard let start = trialStartDate else {
            // First launch — start trial
            defaults.set(Date(), forKey: keyTrialStart)
            return true
        }
        return Date().timeIntervalSince(start) < 86400 // 24 hours
    }
    
    var trialTimeLeft: TimeInterval {
        guard let start = trialStartDate else { return 86400 }
        return max(0, 86400 - Date().timeIntervalSince(start))
    }
    
    func activateWithKey(_ key: String) -> Bool {
        // Validate key format XXXX-XXXX-XXXX-XXXX-XXXX
        let components = key.uppercased().components(separatedBy: "-")
        guard components.count == 5,
              components.allSatisfy({ $0.count == 4 }) else {
            return false
        }
        // Here you'd normally validate against server
        // For now save locally
        defaults.set(true, forKey: keyActivated)
        defaults.set(key, forKey: keyActivationKey)
        return true
    }
    
    func checkAccess() -> Bool {
        return isActivated || isTrialActive
    }
    
    // MARK: - Profiles
    
    func getProfiles() -> [VGProfile] {
        guard let data = defaults.data(forKey: keyProfiles),
              let profiles = try? JSONDecoder().decode([VGProfile].self, from: data) else {
            return []
        }
        return profiles
    }
    
    func saveProfile(_ profile: VGProfile) {
        var profiles = getProfiles()
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
        } else {
            profiles.append(profile)
        }
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: keyProfiles)
        }
    }
    
    func getCurrentProfileId() -> String {
        return defaults.string(forKey: keyCurrentProfile) ?? "main"
    }
    
    func setCurrentProfileId(_ id: String) {
        defaults.set(id, forKey: keyCurrentProfile)
    }
    
    func getCurrentProfile() -> VGProfile {
        let id = getCurrentProfileId()
        return getProfiles().first(where: { $0.id == id }) ?? VGProfile(id: "main", name: "Мой профиль")
    }
    
    func updateCurrentProfile(_ update: (inout VGProfile) -> Void) {
        var profile = getCurrentProfile()
        update(&profile)
        saveProfile(profile)
    }
    
    // MARK: - Gifts
    
    func addGift(_ gift: VGGift) {
        updateCurrentProfile { profile in
            profile.gifts.append(gift)
        }
        addTransaction(VGTransaction(
            id: UUID().uuidString,
            type: .received,
            giftName: gift.name,
            giftEmoji: gift.emoji,
            date: Date(),
            fromProfile: nil,
            toProfile: getCurrentProfileId(),
            amount: gift.value,
            currency: "stars"
        ))
    }
    
    func upgradeGift(id: String) {
        updateCurrentProfile { profile in
            if let idx = profile.gifts.firstIndex(where: { $0.id == id }) {
                profile.gifts[idx].isUpgraded = true
                profile.gifts[idx].uniqueNumber = Int.random(in: 1...350000)
                profile.gifts[idx].model = ["Citrus", "Ruby", "Whisker", "Golden"].randomElement()
                profile.gifts[idx].backdrop = ["Fandango", "Indigo Dye", "Crimson"].randomElement()
                profile.gifts[idx].symbol = ["Ring", "Dollar Graffiti", "Tiki Mask"].randomElement()
            }
        }
        if let gift = getCurrentProfile().gifts.first(where: { $0.id == id }) {
            addTransaction(VGTransaction(
                id: UUID().uuidString,
                type: .upgraded,
                giftName: gift.displayName,
                giftEmoji: gift.emoji,
                date: Date(),
                fromProfile: nil,
                toProfile: nil,
                amount: nil,
                currency: nil
            ))
        }
    }
    
    // MARK: - Transactions
    
    func getTransactions() -> [VGTransaction] {
        guard let data = defaults.data(forKey: keyTransactions),
              let txs = try? JSONDecoder().decode([VGTransaction].self, from: data) else {
            return []
        }
        return txs.sorted { $0.date > $1.date }
    }
    
    func addTransaction(_ tx: VGTransaction) {
        var txs = getTransactions()
        txs.insert(tx, at: 0)
        if let data = try? JSONEncoder().encode(txs) {
            defaults.set(data, forKey: keyTransactions)
        }
    }
    
    // MARK: - Gift Catalog
    
    func getGiftCatalog() -> [VGGiftCatalogItem] {
        return [
            VGGiftCatalogItem(id: "heart", name: "Heart", emoji: "❤️", value: 15, totalAvailability: 1000000, availableLeft: 999000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "bear", name: "Teddy Bear", emoji: "🧸", value: 15, totalAvailability: 1000000, availableLeft: 998000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "gift", name: "Gift Box", emoji: "🎁", value: 25, totalAvailability: 1000000, availableLeft: 997000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "rose", name: "Rose", emoji: "🌹", value: 25, totalAvailability: 500000, availableLeft: 490000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "cake", name: "Birthday Cake", emoji: "🎂", value: 50, totalAvailability: 500000, availableLeft: 489000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "flowers", name: "Flowers", emoji: "💐", value: 50, totalAvailability: 500000, availableLeft: 488000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "rocket", name: "Rocket", emoji: "🚀", value: 50, totalAvailability: 350000, availableLeft: 349000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "trophy", name: "Trophy", emoji: "🏆", value: 100, totalAvailability: 350000, availableLeft: 348000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "ring", name: "Ring", emoji: "💍", value: 100, totalAvailability: 350000, availableLeft: 347000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "diamond", name: "Diamond", emoji: "💎", value: 100, totalAvailability: 350000, availableLeft: 346000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "champagne", name: "Champagne", emoji: "🍾", value: 50, totalAvailability: 350000, availableLeft: 345000, isResale: false, firstSale: nil, lastSale: nil),
            VGGiftCatalogItem(id: "icecream", name: "Ice Cream", emoji: "🍫", value: 100, totalAvailability: 350000, availableLeft: 0, isResale: true, firstSale: Date(), lastSale: Date()),
        ]
    }
    
    // MARK: - TON Rate
    
    func fetchTONRate(completion: @escaping (Double?) -> Void) {
        let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=the-open-network&vs_currencies=usd")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ton = json["the-open-network"] as? [String: Any],
                  let usd = ton["usd"] as? Double else {
                completion(nil)
                return
            }
            completion(usd)
        }.resume()
    }
}
