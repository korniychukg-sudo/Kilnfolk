import SwiftUI

// MARK: - Codable color tone

struct GlazeTone: Codable, Equatable {
    var r: Double
    var g: Double
    var b: Double

    var color: Color { Color(red: r, green: g, blue: b) }
    var uiColor: UIColor { UIColor(red: r, green: g, blue: b, alpha: 1) }

    func darker(_ amount: Double) -> GlazeTone {
        GlazeTone(r: max(0, r * (1 - amount)), g: max(0, g * (1 - amount)), b: max(0, b * (1 - amount)))
    }

    func lighter(_ amount: Double) -> GlazeTone {
        GlazeTone(r: min(1, r + (1 - r) * amount), g: min(1, g + (1 - g) * amount), b: min(1, b + (1 - b) * amount))
    }
}

// MARK: - Clay bodies

enum ClayBodyKind: String, Codable, CaseIterable, Identifiable {
    case terracotta
    case speckledBuff
    case porcelain
    case midnight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .terracotta: return "Terracotta"
        case .speckledBuff: return "Speckled Buff"
        case .porcelain: return "Porcelain"
        case .midnight: return "Midnight Clay"
        }
    }

    var blurb: String {
        switch self {
        case .terracotta: return "Warm iron-rich earthenware. The classic flowerpot orange with a soft, rustic surface."
        case .speckledBuff: return "A sandy stoneware peppered with dark iron flecks that bloom in the kiln."
        case .porcelain: return "Fine, bright and smooth. Glazes look their clearest over this pale body."
        case .midnight: return "A deep charcoal stoneware. Bold silhouettes and moody contrast under any glaze."
        }
    }

    /// Color of the moist clay while it spins on the wheel.
    var wetTone: GlazeTone {
        switch self {
        case .terracotta: return GlazeTone(r: 0.62, g: 0.36, b: 0.24)
        case .speckledBuff: return GlazeTone(r: 0.66, g: 0.55, b: 0.42)
        case .porcelain: return GlazeTone(r: 0.80, g: 0.77, b: 0.72)
        case .midnight: return GlazeTone(r: 0.30, g: 0.28, b: 0.29)
        }
    }

    /// Color after the bisque fire (unglazed areas of a finished pot).
    var firedTone: GlazeTone {
        switch self {
        case .terracotta: return GlazeTone(r: 0.78, g: 0.45, b: 0.28)
        case .speckledBuff: return GlazeTone(r: 0.82, g: 0.71, b: 0.55)
        case .porcelain: return GlazeTone(r: 0.94, g: 0.92, b: 0.88)
        case .midnight: return GlazeTone(r: 0.36, g: 0.33, b: 0.35)
        }
    }

    var speckled: Bool { self == .speckledBuff }
}

// MARK: - Glazes

struct GlazeRecipe: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let wet: GlazeTone
    let fired: GlazeTone
    let gloss: Double
    let speckled: Bool
}

enum GlazeCatalog {
    static let all: [GlazeRecipe] = [
        GlazeRecipe(id: "celadon", name: "Celadon Mist",
                    blurb: "A pale green-blue born in ancient China. Pools darker where the walls curve.",
                    wet: GlazeTone(r: 0.72, g: 0.78, b: 0.72), fired: GlazeTone(r: 0.63, g: 0.78, b: 0.70),
                    gloss: 0.85, speckled: false),
        GlazeRecipe(id: "oceantide", name: "Ocean Tide",
                    blurb: "Deep harbor blue with a glassy shine, like sea glass rolled by waves.",
                    wet: GlazeTone(r: 0.52, g: 0.60, b: 0.70), fired: GlazeTone(r: 0.23, g: 0.42, b: 0.60),
                    gloss: 0.9, speckled: false),
        GlazeRecipe(id: "honeyamber", name: "Honey Amber",
                    blurb: "Warm translucent amber that glows like late-afternoon light in a jar.",
                    wet: GlazeTone(r: 0.80, g: 0.68, b: 0.46), fired: GlazeTone(r: 0.83, g: 0.58, b: 0.24),
                    gloss: 0.8, speckled: false),
        GlazeRecipe(id: "oatmilk", name: "Oat Milk",
                    blurb: "A soft creamy white that keeps things calm and lets the shape speak.",
                    wet: GlazeTone(r: 0.88, g: 0.85, b: 0.78), fired: GlazeTone(r: 0.95, g: 0.92, b: 0.85),
                    gloss: 0.55, speckled: false),
        GlazeRecipe(id: "mosshollow", name: "Moss Hollow",
                    blurb: "Muted forest green with a satin surface, like moss on a shaded stone.",
                    wet: GlazeTone(r: 0.55, g: 0.60, b: 0.47), fired: GlazeTone(r: 0.40, g: 0.51, b: 0.33),
                    gloss: 0.45, speckled: false),
        GlazeRecipe(id: "lavenderash", name: "Lavender Ash",
                    blurb: "Dusty violet-grey drifting toward smoke at the edges.",
                    wet: GlazeTone(r: 0.68, g: 0.63, b: 0.72), fired: GlazeTone(r: 0.58, g: 0.50, b: 0.66),
                    gloss: 0.5, speckled: false),
        GlazeRecipe(id: "tomatoember", name: "Tomato Ember",
                    blurb: "A bold orange-red that fires bright and joyful, never shy.",
                    wet: GlazeTone(r: 0.80, g: 0.52, b: 0.42), fired: GlazeTone(r: 0.83, g: 0.29, b: 0.19),
                    gloss: 0.7, speckled: false),
        GlazeRecipe(id: "midnighttide", name: "Midnight Pool",
                    blurb: "Near-black indigo with tiny starry flecks caught in the melt.",
                    wet: GlazeTone(r: 0.36, g: 0.38, b: 0.48), fired: GlazeTone(r: 0.13, g: 0.17, b: 0.31),
                    gloss: 0.85, speckled: true),
        GlazeRecipe(id: "rosequartz", name: "Rose Quartz",
                    blurb: "A blushing pink with a gentle satin finish. Sweet but grown-up.",
                    wet: GlazeTone(r: 0.85, g: 0.71, b: 0.70), fired: GlazeTone(r: 0.89, g: 0.60, b: 0.60),
                    gloss: 0.55, speckled: false),
        GlazeRecipe(id: "sagefield", name: "Sage Field",
                    blurb: "Grey-green herbs dried in a summer kitchen. Quiet and easy to love.",
                    wet: GlazeTone(r: 0.66, g: 0.70, b: 0.60), fired: GlazeTone(r: 0.62, g: 0.69, b: 0.54),
                    gloss: 0.4, speckled: false),
        GlazeRecipe(id: "charcoalsatin", name: "Charcoal Satin",
                    blurb: "Smooth matte near-black. Makes every silhouette look sculptural.",
                    wet: GlazeTone(r: 0.38, g: 0.36, b: 0.36), fired: GlazeTone(r: 0.22, g: 0.21, b: 0.22),
                    gloss: 0.25, speckled: false),
        GlazeRecipe(id: "buttercream", name: "Butter Cream",
                    blurb: "Pale yellow sunshine with soft speckles, like vanilla cake crumb.",
                    wet: GlazeTone(r: 0.90, g: 0.84, b: 0.62), fired: GlazeTone(r: 0.96, g: 0.86, b: 0.55),
                    gloss: 0.6, speckled: true),
    ]

    static func recipe(_ id: String?) -> GlazeRecipe? {
        guard let id = id else { return nil }
        return all.first { $0.id == id }
    }
}

// MARK: - Pot design

struct GlazeBand: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var center: Double
    var width: Double
    var glazeID: String
}

struct GlazeCoat: Codable, Equatable {
    var baseGlazeID: String? = nil
    var bands: [GlazeBand] = []
    var rimDipGlazeID: String? = nil
    var speckle: Bool = false

    var isBare: Bool { baseGlazeID == nil && bands.isEmpty && rimDipGlazeID == nil && !speckle }
}

enum PotStage: String, Codable {
    case queued
    case firing
    case fired
}

struct PotDesign: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String = ""
    var createdAt = Date()
    var clay: ClayBodyKind = .terracotta
    var profile: [Double]
    var heightScale: Double = 0.8
    var coat = GlazeCoat()
    var stage: PotStage = .queued
    var firedAt: Date? = nil
    var crackle: Bool = false
    var favorite: Bool = false
    // v2 (optionals — v1 saves decode unchanged)
    var formID: String? = nil
    var formStars: Int? = nil

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Piece" : name
    }

    /// Stable per-pot seed for speckles and crackle patterns.
    var artSeed: UInt64 {
        var h: UInt64 = 5381
        for byte in id.uuidString.utf8 { h = (h << 5) &+ h &+ UInt64(byte) }
        return h
    }
}

enum PotShapes {
    static let sampleCount = 28

    /// A fresh centered lump of clay: a low dome, ready for opening.
    static func freshLump() -> [Double] {
        (0..<sampleCount).map { i in
            let t = Double(i) / Double(sampleCount - 1)
            return 0.30 + 0.42 * exp(-t * 2.0) * (1.0 - t * 0.4)
        }
    }

    /// Rough measure of how far the walls moved from the starting lump.
    static func shapingAmount(_ profile: [Double]) -> Double {
        let lump = freshLump()
        guard profile.count == lump.count else { return 1 }
        var sum = 0.0
        for i in 0..<lump.count { sum += abs(profile[i] - lump[i]) }
        return sum / Double(lump.count)
    }
}

// MARK: - Kiln & drafts

struct KilnJob: Codable, Equatable {
    var potID: UUID
    var startedAt: Date
    var duration: TimeInterval = 30

    func progress(at date: Date) -> Double {
        min(1, max(0, date.timeIntervalSince(startedAt) / duration))
    }

    func isDone(at date: Date) -> Bool {
        date.timeIntervalSince(startedAt) >= duration
    }
}

struct WheelDraft: Codable, Equatable {
    var profile: [Double]
    var heightScale: Double
    var clay: ClayBodyKind
}

struct FolkStats: Codable, Equatable {
    var thrown = 0
    var fired = 0
}
