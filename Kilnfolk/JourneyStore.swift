import SwiftUI

// MARK: - State

struct JourneyState: Codable {
    var xp: Int = 0
    var formStars: [String: Int] = [:]
    var formBestFit: [String: Double] = [:]
    var glazesUsed: [String] = []
    var claysUsed: [String] = []
    var badges: [String: Date] = [:]
    var dailyStreak: Int = 0
    var lastDailyDoneKey: String = ""

    // Tolerant decode: any missing field falls back to its default.
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        xp = (try? c.decodeIfPresent(Int.self, forKey: .xp)).flatMap { $0 } ?? 0
        formStars = (try? c.decodeIfPresent([String: Int].self, forKey: .formStars)).flatMap { $0 } ?? [:]
        formBestFit = (try? c.decodeIfPresent([String: Double].self, forKey: .formBestFit)).flatMap { $0 } ?? [:]
        glazesUsed = (try? c.decodeIfPresent([String].self, forKey: .glazesUsed)).flatMap { $0 } ?? []
        claysUsed = (try? c.decodeIfPresent([String].self, forKey: .claysUsed)).flatMap { $0 } ?? []
        badges = (try? c.decodeIfPresent([String: Date].self, forKey: .badges)).flatMap { $0 } ?? [:]
        dailyStreak = (try? c.decodeIfPresent(Int.self, forKey: .dailyStreak)).flatMap { $0 } ?? 0
        lastDailyDoneKey = (try? c.decodeIfPresent(String.self, forKey: .lastDailyDoneKey)).flatMap { $0 } ?? ""
    }
}

// MARK: - Ranks

struct PotterRank {
    let level: Int
    let name: String
    let xp: Int
}

// MARK: - Badges

struct JourneyBadge: Identifiable {
    let id: String
    let title: String
    let hint: String
}

// MARK: - Reveal summary

struct RevealSummary {
    var xpLines: [(label: String, xp: Int)] = []
    var totalXP: Int { xpLines.reduce(0) { $0 + $1.xp } }
    var oldLevel: Int = 1
    var newLevel: Int = 1
    var unlockedGlazes: [GlazeRecipe] = []
    var unlockedClays: [ClayBodyKind] = []
    var newBadges: [JourneyBadge] = []
    var stars: Int = 0
    var fit: Double = 0
    var formName: String? = nil
    var dailyDone: Bool = false
    var dailyStreak: Int = 0
}

// MARK: - Store

final class JourneyStore: ObservableObject {
    @Published private(set) var state = JourneyState()
    @Published var activeFormID: String? = nil

    private let key = "kilnfolk.journey.v1"

    static let ranks: [PotterRank] = [
        PotterRank(level: 1, name: "New Hands", xp: 0),
        PotterRank(level: 2, name: "Clay Curious", xp: 40),
        PotterRank(level: 3, name: "Steady Fingers", xp: 90),
        PotterRank(level: 4, name: "Wheel Friend", xp: 150),
        PotterRank(level: 5, name: "Glaze Mixer", xp: 220),
        PotterRank(level: 6, name: "Kiln Keeper", xp: 300),
        PotterRank(level: 7, name: "Form Finder", xp: 400),
        PotterRank(level: 8, name: "Studio Regular", xp: 520),
        PotterRank(level: 9, name: "Curve Master", xp: 660),
        PotterRank(level: 10, name: "Glaze Alchemist", xp: 820),
        PotterRank(level: 11, name: "Kiln Sage", xp: 1000),
        PotterRank(level: 12, name: "Master Potter", xp: 1200),
    ]

    static let glazeUnlockLevel: [String: Int] = [
        "celadon": 1, "oatmilk": 1, "honeyamber": 1, "tomatoember": 1, "mosshollow": 1,
        "rosequartz": 2, "oceantide": 4, "sagefield": 5, "lavenderash": 5,
        "buttercream": 7, "charcoalsatin": 8, "midnighttide": 10,
    ]

    static let clayUnlockLevel: [ClayBodyKind: Int] = [
        .terracotta: 1, .speckledBuff: 1, .porcelain: 3, .midnight: 6,
    ]

    static let badgeDefs: [JourneyBadge] = [
        JourneyBadge(id: "first_fire", title: "First Fire", hint: "Fire your first piece"),
        JourneyBadge(id: "fired_5", title: "Shelf Starter", hint: "Fire 5 pieces"),
        JourneyBadge(id: "fired_15", title: "Prolific Potter", hint: "Fire 15 pieces"),
        JourneyBadge(id: "fired_40", title: "Kiln Veteran", hint: "Fire 40 pieces"),
        JourneyBadge(id: "all_clays", title: "Four Bodies", hint: "Throw with all 4 clays"),
        JourneyBadge(id: "all_glazes", title: "Full Palette", hint: "Use all 12 glazes"),
        JourneyBadge(id: "crackle_3", title: "Crackle Collector", hint: "Get 3 crackle surprises"),
        JourneyBadge(id: "star3_first", title: "Perfect Form", hint: "Earn 3 stars on any form"),
        JourneyBadge(id: "star3_5", title: "Five Perfections", hint: "Earn 3 stars on 5 forms"),
        JourneyBadge(id: "tier2_clear", title: "Journeyman", hint: "Star every Journeyman form"),
        JourneyBadge(id: "tier3_clear", title: "Artisan", hint: "Star every Artisan form"),
        JourneyBadge(id: "tier4_clear", title: "True Master", hint: "Star every Master form"),
        JourneyBadge(id: "streak_3", title: "Three Mornings", hint: "3-day daily form streak"),
        JourneyBadge(id: "streak_7", title: "A Week at the Wheel", hint: "7-day daily form streak"),
        JourneyBadge(id: "tall_pot", title: "Sky Reacher", hint: "Fire a pot 29 cm tall"),
        JourneyBadge(id: "wide_bowl", title: "Open Arms", hint: "Fire a wide-open low bowl"),
        JourneyBadge(id: "master_rank", title: "Master Potter", hint: "Reach the highest rank"),
    ]

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(JourneyState.self, from: data) {
            state = decoded
        }
    }

    // MARK: Derived

    var level: Int {
        Self.ranks.last(where: { state.xp >= $0.xp })?.level ?? 1
    }

    var rankName: String {
        Self.ranks.first(where: { $0.level == level })?.name ?? "New Hands"
    }

    var nextRank: PotterRank? {
        Self.ranks.first(where: { $0.level == level + 1 })
    }

    /// 0..1 progress from the current rank threshold to the next.
    var rankProgress: Double {
        guard let next = nextRank else { return 1 }
        let current = Self.ranks.first(where: { $0.level == level })?.xp ?? 0
        guard next.xp > current else { return 1 }
        return Double(state.xp - current) / Double(next.xp - current)
    }

    var totalStars: Int {
        state.formStars.values.reduce(0, +)
    }

    func stars(for formID: String) -> Int {
        state.formStars[formID] ?? 0
    }

    func bestFit(for formID: String) -> Double? {
        state.formBestFit[formID]
    }

    func isGlazeUnlocked(_ id: String) -> Bool {
        (Self.glazeUnlockLevel[id] ?? 1) <= level
    }

    func isClayUnlocked(_ kind: ClayBodyKind) -> Bool {
        (Self.clayUnlockLevel[kind] ?? 1) <= level
    }

    func glazeUnlockLevel(_ id: String) -> Int {
        Self.glazeUnlockLevel[id] ?? 1
    }

    func clayUnlockLevel(_ kind: ClayBodyKind) -> Int {
        Self.clayUnlockLevel[kind] ?? 1
    }

    func isTierUnlocked(_ tier: Int) -> Bool {
        FormLibrary.tierUnlocked(tier, totalStars: totalStars)
    }

    func hasBadge(_ id: String) -> Bool {
        state.badges[id] != nil
    }

    func badgeDate(_ id: String) -> Date? {
        state.badges[id]
    }

    // MARK: Daily form

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dateKey(_ date: Date = Date()) -> String {
        dayFormatter.string(from: date)
    }

    /// Deterministic pick for the day, drawn from tiers the potter has unlocked.
    /// Pure — safe to call from view bodies.
    func formOfTheDay(now: Date = Date()) -> PotForm {
        let today = Self.dateKey(now)
        let available = FormLibrary.all.filter { isTierUnlocked($0.tier) }
        let pool = available.isEmpty ? FormLibrary.forms(inTier: 1) : available
        var h: UInt64 = 1469598103934665603
        for b in today.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return pool[Int(h % UInt64(pool.count))]
    }

    func dailyDone(now: Date = Date()) -> Bool {
        state.lastDailyDoneKey == Self.dateKey(now)
    }

    // MARK: The single mutation point

    func registerFiredPot(_ pot: PotDesign, firedTotal: Int, crackleTotal: Int) -> RevealSummary {
        var summary = RevealSummary()
        summary.oldLevel = level
        summary.xpLines.append(("Fired piece", 20))

        // Challenge result
        if let formID = pot.formID, let form = FormLibrary.form(formID) {
            let stars = pot.formStars ?? 0
            let fit = FormScoring.fit(profile: pot.profile, heightScale: pot.heightScale, form: form)
            summary.stars = stars
            summary.fit = fit
            summary.formName = form.name
            if stars > 0 {
                summary.xpLines.append(("\(form.name) · \(stars)-star form", 15 * stars))
                state.formStars[formID] = max(state.formStars[formID] ?? 0, stars)
            }
            state.formBestFit[formID] = max(state.formBestFit[formID] ?? 0, fit)

            // Daily form
            let today = Self.dateKey()
            if formID == formOfTheDay().id,
               stars > 0, state.lastDailyDoneKey != today {
                let yesterday = Self.dateKey(Date(timeIntervalSinceNow: -86400))
                state.dailyStreak = state.lastDailyDoneKey == yesterday ? state.dailyStreak + 1 : 1
                state.lastDailyDoneKey = today
                summary.xpLines.append(("Form of the day", 15))
                summary.dailyDone = true
                summary.dailyStreak = state.dailyStreak
            }
        }

        // First-use bonuses
        var coatGlazes: [String] = []
        if let g = pot.coat.baseGlazeID { coatGlazes.append(g) }
        coatGlazes.append(contentsOf: pot.coat.bands.map { $0.glazeID })
        if let g = pot.coat.rimDipGlazeID { coatGlazes.append(g) }
        for g in Array(Set(coatGlazes)).sorted() where !state.glazesUsed.contains(g) {
            state.glazesUsed.append(g)
            if let recipe = GlazeCatalog.recipe(g) {
                summary.xpLines.append(("New glaze: \(recipe.name)", 10))
            }
        }
        if !state.claysUsed.contains(pot.clay.rawValue) {
            state.claysUsed.append(pot.clay.rawValue)
            summary.xpLines.append(("New clay: \(pot.clay.displayName)", 10))
        }

        state.xp += summary.totalXP
        summary.newLevel = level

        // Unlocks crossing the boundary
        if summary.newLevel > summary.oldLevel {
            summary.unlockedGlazes = GlazeCatalog.all.filter {
                let lvl = Self.glazeUnlockLevel[$0.id] ?? 1
                return lvl > summary.oldLevel && lvl <= summary.newLevel
            }
            summary.unlockedClays = ClayBodyKind.allCases.filter {
                let lvl = Self.clayUnlockLevel[$0] ?? 1
                return lvl > summary.oldLevel && lvl <= summary.newLevel
            }
        }

        // Badges
        summary.newBadges = evaluateBadges(pot: pot, firedTotal: firedTotal, crackleTotal: crackleTotal)

        save()
        return summary
    }

    private func evaluateBadges(pot: PotDesign, firedTotal: Int, crackleTotal: Int) -> [JourneyBadge] {
        var earned: [String] = []
        func check(_ id: String, _ condition: Bool) {
            if condition && state.badges[id] == nil { earned.append(id) }
        }
        check("first_fire", firedTotal >= 1)
        check("fired_5", firedTotal >= 5)
        check("fired_15", firedTotal >= 15)
        check("fired_40", firedTotal >= 40)
        check("all_clays", state.claysUsed.count >= ClayBodyKind.allCases.count)
        check("all_glazes", state.glazesUsed.count >= GlazeCatalog.all.count)
        check("crackle_3", crackleTotal >= 3)
        let threeStars = state.formStars.values.filter { $0 >= 3 }.count
        check("star3_first", threeStars >= 1)
        check("star3_5", threeStars >= 5)
        for tier in 2...4 {
            let cleared = FormLibrary.forms(inTier: tier).allSatisfy { (state.formStars[$0.id] ?? 0) >= 1 }
            check("tier\(tier)_clear", cleared)
        }
        check("streak_3", state.dailyStreak >= 3)
        check("streak_7", state.dailyStreak >= 7)
        check("tall_pot", pot.heightScale >= 0.97)
        check("wide_bowl", (pot.profile.suffix(3).max() ?? 0) >= 0.9 && pot.heightScale <= 0.65)
        check("master_rank", level >= 12)

        let now = Date()
        for id in earned { state.badges[id] = now }
        return Self.badgeDefs.filter { earned.contains($0.id) }
    }

    // MARK: Reset & persistence

    func resetAll() {
        state = JourneyState()
        activeFormID = nil
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
