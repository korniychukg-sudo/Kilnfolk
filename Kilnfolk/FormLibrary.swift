import SwiftUI

// MARK: - Classic forms

struct PotForm: Identifiable {
    let id: String
    let name: String
    let tier: Int
    let story: String
    let controls: [Double]
    let targetHeight: Double

    /// Control points interpolated to the wheel's 28-sample profile.
    var targetProfile: [Double] {
        let n = PotShapes.sampleCount
        let m = controls.count
        guard m > 1 else { return Array(repeating: 0.5, count: n) }
        return (0..<n).map { i in
            let t = Double(i) / Double(n - 1) * Double(m - 1)
            let j = min(m - 2, Int(t))
            let f = t - Double(j)
            return controls[j] * (1 - f) + controls[j + 1] * f
        }
    }
}

enum FormLibrary {
    static let all: [PotForm] = [
        // Tier 1 — Apprentice
        PotForm(id: "teabowl", name: "Tea Bowl", tier: 1,
                story: "The chawan of the Japanese tea ceremony. Humble, wide and open — masters spend a lifetime on this 'simple' bowl.",
                controls: [0.40, 0.60, 0.78, 0.90, 0.97, 1.0], targetHeight: 0.60),
        PotForm(id: "budvase", name: "Bud Vase", tier: 1,
                story: "A little vase for a single stem. Round belly, narrow neck — the first shape every potter gives as a gift.",
                controls: [0.42, 0.68, 0.88, 0.97, 0.88, 0.62, 0.40, 0.32, 0.36], targetHeight: 0.74),
        PotForm(id: "honeypot", name: "Honey Pot", tier: 1,
                story: "A squat kitchen jar with a friendly belly. Made in every village pottery since pots were invented.",
                controls: [0.50, 0.78, 0.95, 1.0, 0.96, 0.82, 0.66, 0.60], targetHeight: 0.62),
        // Tier 2 — Journeyman
        PotForm(id: "moonjar", name: "Moon Jar", tier: 2,
                story: "Korea's beloved 'dal-hangari' — a near-perfect sphere, thrown in two halves and joined. Ours asks for one honest ball.",
                controls: [0.38, 0.68, 0.90, 1.0, 1.0, 0.90, 0.68, 0.44], targetHeight: 0.80),
        PotForm(id: "mug", name: "Straight Mug", tier: 2,
                story: "The rib's exam: dead-straight walls, no waves, no bulges. Harder than it looks, satisfying beyond reason.",
                controls: [0.72, 0.73, 0.74, 0.74, 0.74, 0.74, 0.74, 0.75], targetHeight: 0.72),
        PotForm(id: "milkjug", name: "Milk Jug", tier: 2,
                story: "A generous belly that narrows to pour. The curve has to swell low, or the jug looks like it skipped breakfast.",
                controls: [0.48, 0.80, 0.98, 1.0, 0.90, 0.70, 0.52, 0.44, 0.48], targetHeight: 0.78),
        // Tier 3 — Artisan
        PotForm(id: "amphora", name: "Amphora", tier: 3,
                story: "The freight container of the ancient world — wine, oil and grain crossed the sea in these high-shouldered giants.",
                controls: [0.32, 0.48, 0.72, 0.94, 1.0, 0.92, 0.74, 0.54, 0.40, 0.36, 0.44], targetHeight: 0.95),
        PotForm(id: "gingerjar", name: "Ginger Jar", tier: 3,
                story: "A Chinese storage classic: round shoulders, short straight neck. Once held spices on ships; now holds pride of place.",
                controls: [0.46, 0.72, 0.92, 1.0, 0.98, 0.86, 0.62, 0.46, 0.46], targetHeight: 0.76),
        PotForm(id: "bottlevase", name: "Bottle Vase", tier: 3,
                story: "All the drama lives in the neck: a full body drawn up into a long, even stem. Keep your hand steady near the top.",
                controls: [0.50, 0.80, 0.97, 1.0, 0.88, 0.60, 0.34, 0.22, 0.19, 0.19, 0.22], targetHeight: 0.96),
        // Tier 4 — Master
        PotForm(id: "trumpetvase", name: "Trumpet Vase", tier: 4,
                story: "A slender waist that flares wide open at the rim, like a lily. Flare too fast and the wall collapses — potters call it 'losing the flower'.",
                controls: [0.52, 0.60, 0.52, 0.40, 0.34, 0.32, 0.38, 0.55, 0.78, 1.0], targetHeight: 0.90),
        PotForm(id: "meiping", name: "Meiping", tier: 4,
                story: "The Chinese 'plum vase': broad proud shoulders right at the top, tapering to a daringly small foot. Balance made visible.",
                controls: [0.34, 0.44, 0.58, 0.72, 0.86, 0.96, 1.0, 0.94, 0.70, 0.46], targetHeight: 0.92),
        PotForm(id: "doublegourd", name: "Double Gourd", tier: 4,
                story: "Two stacked bellies pinched at a waist — the gourd of long life in Chinese art. The waist is where dreams go to wobble.",
                controls: [0.44, 0.76, 0.94, 1.0, 0.88, 0.58, 0.42, 0.56, 0.76, 0.80, 0.62, 0.36, 0.28], targetHeight: 0.94),
    ]

    static func form(_ id: String?) -> PotForm? {
        guard let id = id else { return nil }
        return all.first { $0.id == id }
    }

    static func forms(inTier tier: Int) -> [PotForm] {
        all.filter { $0.tier == tier }
    }

    static func tierName(_ tier: Int) -> String {
        switch tier {
        case 1: return "Apprentice"
        case 2: return "Journeyman"
        case 3: return "Artisan"
        default: return "Master"
        }
    }

    static func starsNeeded(forTier tier: Int) -> Int {
        switch tier {
        case 2: return 4
        case 3: return 10
        case 4: return 18
        default: return 0
        }
    }

    static func tierUnlocked(_ tier: Int, totalStars: Int) -> Bool {
        totalStars >= starsNeeded(forTier: tier)
    }
}

// MARK: - Fit scoring

enum FormScoring {
    static func fit(profile: [Double], heightScale: Double, form: PotForm) -> Double {
        let target = form.targetProfile
        guard profile.count == target.count, !target.isEmpty else { return 0 }
        var sum = 0.0
        for i in 0..<target.count { sum += abs(profile[i] - target[i]) }
        let meanDiff = sum / Double(target.count)
        let hsDiff = abs(heightScale - form.targetHeight)
        return max(0, min(1, 1 - meanDiff * 4.2 - hsDiff * 1.1))
    }

    static func stars(fit: Double) -> Int {
        if fit >= 0.90 { return 3 }
        if fit >= 0.78 { return 2 }
        if fit >= 0.62 { return 1 }
        return 0
    }
}

// MARK: - Real-world dimensions (for the HUD and detail sheet)

enum PotMeasure {
    static let maxHeightCM = 30.0
    static let maxWidthCM = 22.0

    static func heightCM(_ heightScale: Double) -> Int {
        max(3, Int((heightScale * maxHeightCM).rounded()))
    }

    static func widthCM(_ profile: [Double]) -> Int {
        let maxR = profile.max() ?? 0.5
        return max(3, Int((maxR * maxWidthCM).rounded()))
    }
}
