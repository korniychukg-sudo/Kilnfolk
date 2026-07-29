import SwiftUI

// MARK: - Geometry of a lathe-turned pot

/// Maps a normalized wall profile (bottom → rim) into pixel space and
/// produces "front slice" paths between two heights, with elliptical caps.
struct PotGeometry {
    let rect: CGRect
    let profile: [Double]
    let heightScale: Double
    let ellipseK: CGFloat = 0.16

    var cx: CGFloat { rect.midX }
    var baseY: CGFloat { rect.maxY }
    var potH: CGFloat { rect.height * CGFloat(max(0.2, heightScale)) }
    var maxHalfW: CGFloat { rect.width * 0.5 * 0.94 }

    func radiusPx(at t: Double) -> CGFloat {
        let n = profile.count
        guard n > 1 else { return maxHalfW * 0.5 }
        let clamped = min(1, max(0, t))
        let fi = clamped * Double(n - 1)
        let i = min(n - 2, Int(fi))
        let frac = fi - Double(i)
        let r = profile[i] * (1 - frac) + profile[i + 1] * frac
        return CGFloat(r) * maxHalfW
    }

    func yPx(at t: Double) -> CGFloat { baseY - potH * CGFloat(min(1, max(0, t))) }

    func tAt(y: CGFloat) -> Double { Double((baseY - y) / potH) }

    /// Front-facing surface between heights t0..t1 (elliptical caps bow downward).
    func slicePath(_ t0: Double, _ t1: Double, rows: Int = 44) -> Path {
        var p = Path()
        let lo = min(t0, t1), hi = max(t0, t1)
        guard hi - lo > 0.001 else { return p }
        let r0 = radiusPx(at: lo), r1 = radiusPx(at: hi)
        let y0 = yPx(at: lo), y1 = yPx(at: hi)

        p.move(to: CGPoint(x: cx - r0, y: y0))
        // left edge upward
        for j in 1...rows {
            let t = lo + (hi - lo) * Double(j) / Double(rows)
            p.addLine(to: CGPoint(x: cx - radiusPx(at: t), y: yPx(at: t)))
        }
        // top cap, bowing toward the viewer
        p.addQuadCurve(to: CGPoint(x: cx + r1, y: y1),
                       control: CGPoint(x: cx, y: y1 + 2 * ellipseK * r1))
        // right edge downward
        for j in stride(from: rows - 1, through: 0, by: -1) {
            let t = lo + (hi - lo) * Double(j) / Double(rows)
            p.addLine(to: CGPoint(x: cx + radiusPx(at: t), y: yPx(at: t)))
        }
        // bottom cap
        p.addQuadCurve(to: CGPoint(x: cx - r0, y: y0),
                       control: CGPoint(x: cx, y: y0 + 2 * ellipseK * r0))
        p.closeSubpath()
        return p
    }
}

// MARK: - Deterministic pseudo-random

struct FolkRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B9 : seed }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0x7FFFFFFF) / Double(0x7FFFFFFF)
    }
    mutating func range(_ lo: Double, _ hi: Double) -> Double { lo + next() * (hi - lo) }
}

// MARK: - Painter

enum PotPainter {

    /// The tone visible on the wall at height t, given the coat and firing state.
    static func surfaceTone(pot: PotDesign, t: Double, fired: Bool) -> GlazeTone {
        let clayTone = fired ? pot.clay.firedTone : pot.clay.wetTone
        if let rim = GlazeCatalog.recipe(pot.coat.rimDipGlazeID), t >= 0.86 {
            return fired ? rim.fired : rim.wet
        }
        for band in pot.coat.bands where abs(t - band.center) <= band.width / 2 {
            if let g = GlazeCatalog.recipe(band.glazeID) { return fired ? g.fired : g.wet }
        }
        if t >= 0.045, let base = GlazeCatalog.recipe(pot.coat.baseGlazeID) {
            return fired ? base.fired : base.wet
        }
        return clayTone
    }

    static func effectiveGloss(pot: PotDesign) -> Double {
        var g = 0.0
        if let base = GlazeCatalog.recipe(pot.coat.baseGlazeID) { g = max(g, base.gloss) }
        for band in pot.coat.bands {
            if let r = GlazeCatalog.recipe(band.glazeID) { g = max(g, r.gloss * 0.7) }
        }
        if let rim = GlazeCatalog.recipe(pot.coat.rimDipGlazeID) { g = max(g, rim.gloss * 0.6) }
        return g
    }

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, pot: PotDesign,
                     phase: Double, wet: Bool, showShadow: Bool = true) {
        let inset = size.width * 0.03
        let rect = CGRect(x: inset, y: size.height * 0.06,
                          width: size.width - inset * 2, height: size.height * 0.90)
        drawInRect(&ctx, rect: rect, pot: pot, phase: phase, wet: wet, showShadow: showShadow)
    }

    static func drawInRect(_ ctx: inout GraphicsContext, rect: CGRect, pot: PotDesign,
                           phase: Double, wet: Bool, showShadow: Bool = true) {
        let geo = PotGeometry(rect: rect, profile: pot.profile, heightScale: pot.heightScale)
        let fired = pot.stage == .fired
        let clayTone = wet ? pot.clay.wetTone : (fired ? pot.clay.firedTone : pot.clay.wetTone.lighter(0.08))

        // Ground shadow
        if showShadow {
            let r0 = geo.radiusPx(at: 0)
            let sh = Path(ellipseIn: CGRect(x: geo.cx - r0 * 1.18, y: geo.baseY - r0 * 0.10,
                                            width: r0 * 2.36, height: r0 * 0.42))
            ctx.fill(sh, with: .color(Color.black.opacity(0.10)))
        }

        // Clay body
        let bodyPath = geo.slicePath(0, 1)
        fillShaded(&ctx, path: bodyPath, tone: clayTone, geo: geo)

        // Base coat (leaves the foot bare, like a real dipped pot)
        if let base = GlazeCatalog.recipe(pot.coat.baseGlazeID) {
            let tone = fired ? base.fired : base.wet
            fillShaded(&ctx, path: geo.slicePath(0.045, 1), tone: tone, geo: geo)
        }

        // Bands
        for band in pot.coat.bands {
            guard let g = GlazeCatalog.recipe(band.glazeID) else { continue }
            let tone = fired ? g.fired : g.wet
            let lo = max(0.03, band.center - band.width / 2)
            let hi = min(1.0, band.center + band.width / 2)
            fillShaded(&ctx, path: geo.slicePath(lo, hi), tone: tone, geo: geo)
        }

        // Rim dip
        if let rim = GlazeCatalog.recipe(pot.coat.rimDipGlazeID) {
            let tone = fired ? rim.fired : rim.wet
            fillShaded(&ctx, path: geo.slicePath(0.86, 1), tone: tone, geo: geo)
        }

        // Throwing rings — faint horizontal grooves left by fingers
        var ringT = 0.14
        while ringT < 0.94 {
            let r = geo.radiusPx(at: ringT)
            let y = geo.yPx(at: ringT)
            var ring = Path()
            ring.move(to: CGPoint(x: geo.cx - r, y: y))
            ring.addQuadCurve(to: CGPoint(x: geo.cx + r, y: y),
                              control: CGPoint(x: geo.cx, y: y + 2 * geo.ellipseK * r))
            ctx.stroke(ring, with: .color(Color.black.opacity(wet ? 0.075 : 0.05)), lineWidth: 1)
            ringT += 0.16
        }

        // Speckles: iron flecks in the clay, or speckled glaze — they spin with the wheel
        drawSpeckles(&ctx, geo: geo, pot: pot, phase: phase, fired: fired, bodyPath: bodyPath)

        // Spin streaks — small moving glints that sell the rotation
        if wet {
            drawSpinGlints(&ctx, geo: geo, phase: phase)
        }

        // Crackle web
        if pot.crackle && fired {
            drawCrackle(&ctx, geo: geo, pot: pot, bodyPath: bodyPath)
        }

        // Vertical sheen
        let gloss = wet ? 0.14 : (fired ? 0.10 + 0.14 * effectiveGloss(pot: pot) : 0.06)
        drawSheen(&ctx, geo: geo, alpha: gloss)

        // Mouth (top opening)
        let rTop = geo.radiusPx(at: 1)
        let yTop = geo.yPx(at: 1)
        let topTone = surfaceTone(pot: pot, t: 0.995, fired: fired)
        let mouthRect = CGRect(x: geo.cx - rTop, y: yTop - geo.ellipseK * rTop,
                               width: rTop * 2, height: geo.ellipseK * rTop * 2)
        ctx.fill(Path(ellipseIn: mouthRect), with: .color(topTone.darker(0.42).color))
        let innerRect = mouthRect.insetBy(dx: rTop * 0.12, dy: geo.ellipseK * rTop * 0.30)
        ctx.fill(Path(ellipseIn: innerRect), with: .color(topTone.darker(0.58).color))
        ctx.stroke(Path(ellipseIn: mouthRect), with: .color(topTone.lighter(0.22).color), lineWidth: 1.4)
    }

    private static func fillShaded(_ ctx: inout GraphicsContext, path: Path, tone: GlazeTone, geo: PotGeometry) {
        let gradient = Gradient(stops: [
            .init(color: tone.darker(0.30).color, location: 0.0),
            .init(color: tone.lighter(0.16).color, location: 0.38),
            .init(color: tone.color, location: 0.62),
            .init(color: tone.darker(0.26).color, location: 1.0),
        ])
        ctx.fill(path, with: .linearGradient(gradient,
                                             startPoint: CGPoint(x: geo.cx - geo.maxHalfW, y: 0),
                                             endPoint: CGPoint(x: geo.cx + geo.maxHalfW, y: 0)))
    }

    private static func drawSpeckles(_ ctx: inout GraphicsContext, geo: PotGeometry, pot: PotDesign,
                                     phase: Double, fired: Bool, bodyPath: Path) {
        var wantsGlazeSpeckle = pot.coat.speckle
        if let base = GlazeCatalog.recipe(pot.coat.baseGlazeID), base.speckled { wantsGlazeSpeckle = true }
        let clayFlecks = pot.clay.speckled && pot.coat.baseGlazeID == nil
        guard wantsGlazeSpeckle || clayFlecks else { return }

        var rng = FolkRandom(seed: pot.artSeed)
        let count = 46
        var layer = ctx
        layer.clip(to: bodyPath)
        for _ in 0..<count {
            let t = rng.range(0.06, 0.97)
            let theta0 = rng.range(0, .pi * 2)
            let dotSize = rng.range(1.2, 2.6)
            let theta = theta0 + phase
            let s = sin(theta), c = cos(theta)
            guard c > -0.15 else { continue }
            let r = geo.radiusPx(at: t)
            let x = geo.cx + CGFloat(s) * r * 0.92
            let y = geo.yPx(at: t) + CGFloat(c) * geo.ellipseK * r * 0.3
            let tone = surfaceTone(pot: pot, t: t, fired: fired)
            let bright = tone.r + tone.g + tone.b > 1.9
            let dotColor = bright ? tone.darker(0.5).color : tone.lighter(0.55).color
            let alpha = 0.16 + 0.30 * max(0, c)
            layer.fill(Path(ellipseIn: CGRect(x: x - dotSize / 2, y: y - dotSize / 2,
                                              width: dotSize, height: dotSize * 0.8)),
                       with: .color(dotColor.opacity(alpha)))
        }
    }

    private static func drawSpinGlints(_ ctx: inout GraphicsContext, geo: PotGeometry, phase: Double) {
        for i in 0..<3 {
            let t = 0.22 + Double(i) * 0.26
            let theta = phase * 1.15 + Double(i) * 2.3
            let s = sin(theta), c = cos(theta)
            guard c > 0.1 else { continue }
            let r = geo.radiusPx(at: t)
            let x = geo.cx + CGFloat(s) * r * 0.85
            let y = geo.yPx(at: t)
            let w: CGFloat = 9, h: CGFloat = 2.4
            let glint = Path(ellipseIn: CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h))
            ctx.fill(glint, with: .color(Color.white.opacity(0.16 * max(0.2, c))))
        }
    }

    private static func drawCrackle(_ ctx: inout GraphicsContext, geo: PotGeometry, pot: PotDesign, bodyPath: Path) {
        var rng = FolkRandom(seed: pot.artSeed ^ 0xC0FFEE)
        var layer = ctx
        layer.clip(to: bodyPath)
        for _ in 0..<13 {
            var p = Path()
            let t0 = rng.range(0.15, 0.95)
            var x = geo.cx + CGFloat(rng.range(-0.8, 0.8)) * geo.radiusPx(at: t0)
            var y = geo.yPx(at: t0)
            p.move(to: CGPoint(x: x, y: y))
            let segs = 3 + Int(rng.next() * 3)
            for _ in 0..<segs {
                x += CGFloat(rng.range(-14, 14))
                y += CGFloat(rng.range(-10, 14))
                p.addLine(to: CGPoint(x: x, y: y))
            }
            layer.stroke(p, with: .color(Color.black.opacity(0.12)), lineWidth: 0.8)
        }
    }

    private static func drawSheen(_ ctx: inout GraphicsContext, geo: PotGeometry, alpha: Double) {
        guard alpha > 0.01 else { return }
        let x = geo.cx - geo.maxHalfW * 0.42
        let topY = geo.yPx(at: 0.94)
        let botY = geo.yPx(at: 0.06)
        let w = geo.maxHalfW * 0.16
        let sheen = Path(roundedRect: CGRect(x: x - w / 2, y: topY, width: w, height: botY - topY),
                         cornerRadius: w / 2)
        let gradient = Gradient(stops: [
            .init(color: Color.white.opacity(0), location: 0),
            .init(color: Color.white.opacity(alpha), location: 0.3),
            .init(color: Color.white.opacity(alpha * 0.85), location: 0.7),
            .init(color: Color.white.opacity(0), location: 1),
        ])
        ctx.fill(sheen, with: .linearGradient(gradient,
                                              startPoint: CGPoint(x: x, y: topY),
                                              endPoint: CGPoint(x: x, y: botY)))
    }
}

// MARK: - Views

/// Static render of a pot at a given spin phase.
struct PotFigure: View {
    let pot: PotDesign
    var phase: Double = 0
    var wet: Bool = false
    var showShadow: Bool = true

    var body: some View {
        Canvas { ctx, size in
            PotPainter.draw(&ctx, size: size, pot: pot, phase: phase, wet: wet, showShadow: showShadow)
        }
    }
}

/// Continuously spinning render (gallery preview, glaze studio).
struct SpinningPotFigure: View {
    let pot: PotDesign
    var speed: Double = 0.9
    var wet: Bool = false
    var showShadow: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            PotFigure(pot: pot,
                      phase: timeline.date.timeIntervalSinceReferenceDate * speed,
                      wet: wet, showShadow: showShadow)
        }
    }
}
