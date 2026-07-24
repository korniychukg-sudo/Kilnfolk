import Foundation
import CoreGraphics
import ImageIO

// MARK: - Output paths

let args = CommandLine.arguments
let artDir = args.count > 1 ? args[1] : "./Art"
let iconDir = args.count > 2 ? args[2] : "./Icon"
try? FileManager.default.createDirectory(atPath: artDir, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: iconDir, withIntermediateDirectories: true)

// MARK: - Core helpers

func makeCtx(_ w: Int, _ h: Int) -> CGContext {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    return CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                     space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

func savePNG(_ ctx: CGContext, _ path: String) {
    let img = ctx.makeImage()!
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(path)")
}

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(srgbRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
}

func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> CGColor {
    CGColor(srgbRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
}

var rngState: UInt64 = 88172645463325252
func rnd() -> Double {
    rngState ^= rngState << 13
    rngState ^= rngState >> 7
    rngState ^= rngState << 17
    return Double(rngState % 100000) / 100000.0
}
func rnd(_ lo: Double, _ hi: Double) -> Double { lo + rnd() * (hi - lo) }

/// Per-pixel film grain — gives the art its papery feel (and honest file weight).
func addNoise(_ ctx: CGContext, amount: Int) {
    guard let data = ctx.data else { return }
    let w = ctx.width, h = ctx.height, bpr = ctx.bytesPerRow
    let buf = data.bindMemory(to: UInt8.self, capacity: bpr * h)
    var s: UInt64 = 0x243F6A8885A308D3
    for y in 0..<h {
        let row = y * bpr
        for x in 0..<w {
            s ^= s << 13; s ^= s >> 7; s ^= s << 17
            let n = Int(s % UInt64(2 * amount + 1)) - amount
            let idx = row + x * 4
            for c in 0..<3 {
                let v = Int(buf[idx + c]) + n
                buf[idx + c] = UInt8(max(0, min(255, v)))
            }
        }
    }
}

func vignette(_ ctx: CGContext, _ w: Int, _ h: Int, strength: Double = 0.16) {
    let colors = [rgba(0.1, 0.05, 0.02, 0), rgba(0.1, 0.05, 0.02, strength)] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: colors, locations: [0, 1])!
    let c = CGPoint(x: Double(w) / 2, y: Double(h) / 2)
    ctx.drawRadialGradient(grad, startCenter: c, startRadius: CGFloat(min(w, h)) * 0.35,
                           endCenter: c, endRadius: CGFloat(max(w, h)) * 0.72, options: .drawsAfterEndLocation)
}

func fillVertical(_ ctx: CGContext, _ w: Int, _ h: Int, top: CGColor, bottom: CGColor) {
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                          colors: [top, bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])
}

func fillPathVertical(_ ctx: CGContext, _ path: CGPath, top: CGColor, bottom: CGColor) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let box = path.boundingBox
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                          colors: [top, bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: box.midX, y: box.maxY),
                           end: CGPoint(x: box.midX, y: box.minY), options: [])
    ctx.restoreGState()
}

// MARK: - Palette

let PCream = rgb(0.969, 0.941, 0.898)
let PLinen = rgb(0.941, 0.902, 0.839)
let PTerra = rgb(0.769, 0.412, 0.247)
let PTerraDeep = rgb(0.639, 0.310, 0.173)
let PInk = rgb(0.271, 0.208, 0.169)
let PSage = rgb(0.529, 0.612, 0.482)
let PDenim = rgb(0.353, 0.475, 0.573)
let PHoney = rgb(0.871, 0.665, 0.298)
let PWood = rgb(0.651, 0.506, 0.353)
let PWoodDark = rgb(0.510, 0.376, 0.247)
let PEmber = rgb(0.898, 0.443, 0.204)

// MARK: - Shape helpers (origin bottom-left, y grows up)

/// Symmetric pot silhouette from a profile (fractions of half-width), bottom to rim.
func potPath(cx: Double, baseY: Double, halfW: Double, height: Double, profile: [Double]) -> CGPath {
    let p = CGMutablePath()
    let n = profile.count
    func r(_ i: Int) -> Double { profile[i] * halfW }
    func y(_ i: Int) -> Double { baseY + height * Double(i) / Double(n - 1) }
    p.move(to: CGPoint(x: cx - r(0), y: y(0)))
    for i in 1..<n { p.addLine(to: CGPoint(x: cx - r(i), y: y(i))) }
    p.addLine(to: CGPoint(x: cx + r(n - 1), y: y(n - 1)))
    for i in stride(from: n - 2, through: 0, by: -1) { p.addLine(to: CGPoint(x: cx + r(i), y: y(i))) }
    p.closeSubpath()
    return p
}

let vaseProfile: [Double] = [0.42, 0.55, 0.72, 0.88, 0.97, 1.0, 0.95, 0.84, 0.68, 0.52, 0.42, 0.40, 0.46]
let bowlProfile: [Double] = [0.38, 0.62, 0.82, 0.94, 1.0, 1.0, 0.98]
let jugProfile: [Double] = [0.5, 0.72, 0.9, 1.0, 0.98, 0.86, 0.66, 0.46, 0.36, 0.34, 0.4]
let cupProfile: [Double] = [0.55, 0.68, 0.78, 0.86, 0.92, 0.97, 1.0]
let bottleProfile: [Double] = [0.55, 0.78, 0.95, 1.0, 0.96, 0.8, 0.55, 0.3, 0.2, 0.18, 0.22]

func drawPotShape(_ ctx: CGContext, cx: Double, baseY: Double, halfW: Double, height: Double,
                  profile: [Double], body: CGColor, dark: CGColor, mouth: Bool = true) {
    let path = potPath(cx: cx, baseY: baseY, halfW: halfW, height: height, profile: profile)
    fillPathVertical(ctx, path, top: body, bottom: dark)
    // side shading
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let sw = halfW * 0.45
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                          colors: [rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: cx + halfW, y: baseY),
                           end: CGPoint(x: cx + halfW - sw * 2, y: baseY), options: [])
    let grad2 = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                           colors: [rgba(1, 1, 1, 0.14), rgba(1, 1, 1, 0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad2, start: CGPoint(x: cx - halfW, y: baseY),
                           end: CGPoint(x: cx - halfW + sw * 1.6, y: baseY), options: [])
    ctx.restoreGState()
    if mouth {
        let rTop = profile[profile.count - 1] * halfW
        let mouthRect = CGRect(x: cx - rTop, y: baseY + height - rTop * 0.16,
                               width: rTop * 2, height: rTop * 0.32)
        ctx.setFillColor(rgba(0, 0, 0, 0.28))
        ctx.fillEllipse(in: mouthRect)
    }
}

func drawShadowEllipse(_ ctx: CGContext, cx: Double, y: Double, halfW: Double) {
    ctx.setFillColor(rgba(0.2, 0.1, 0.05, 0.14))
    ctx.fillEllipse(in: CGRect(x: cx - halfW, y: y - halfW * 0.13, width: halfW * 2, height: halfW * 0.26))
}

func drawWheel(_ ctx: CGContext, cx: Double, cy: Double, rx: Double) {
    let ry = rx * 0.26
    drawShadowEllipse(ctx, cx: cx, y: cy - ry * 1.4, halfW: rx * 1.15)
    ctx.setFillColor(rgb(0.24, 0.22, 0.23))
    ctx.fillEllipse(in: CGRect(x: cx - rx, y: cy - ry * 1.8, width: rx * 2, height: ry * 2))
    ctx.setFillColor(rgb(0.36, 0.34, 0.36))
    ctx.fillEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    ctx.setStrokeColor(rgba(1, 1, 1, 0.12))
    ctx.setLineWidth(rx * 0.02)
    ctx.strokeEllipse(in: CGRect(x: cx - rx * 0.7, y: cy - ry * 0.7, width: rx * 1.4, height: ry * 1.4))
}

func sparkle(_ ctx: CGContext, x: Double, y: Double, r: Double, color: CGColor) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x, y: y + r))
    p.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x + r * 0.18, y: y + r * 0.18))
    p.addQuadCurve(to: CGPoint(x: x, y: y - r), control: CGPoint(x: x + r * 0.18, y: y - r * 0.18))
    p.addQuadCurve(to: CGPoint(x: x - r, y: y), control: CGPoint(x: x - r * 0.18, y: y - r * 0.18))
    p.addQuadCurve(to: CGPoint(x: x, y: y + r), control: CGPoint(x: x - r * 0.18, y: y + r * 0.18))
    ctx.addPath(p)
    ctx.setFillColor(color)
    ctx.fillPath()
}

func woodPlank(_ ctx: CGContext, x: Double, y: Double, w: Double, h: Double) {
    let rect = CGRect(x: x, y: y, width: w, height: h)
    ctx.setFillColor(PWood)
    let rounded = CGPath(roundedRect: rect, cornerWidth: h * 0.12, cornerHeight: h * 0.12, transform: nil)
    ctx.addPath(rounded)
    ctx.fillPath()
    ctx.saveGState()
    ctx.addPath(rounded)
    ctx.clip()
    ctx.setStrokeColor(rgba(0.4, 0.28, 0.16, 0.35))
    for _ in 0..<Int(w / 40) {
        let gy = y + rnd(0.15, 0.85) * h
        let gx = x + rnd(0, 0.9) * w
        let len = rnd(30, 120)
        ctx.setLineWidth(rnd(1.5, 3.5))
        ctx.move(to: CGPoint(x: gx, y: gy))
        ctx.addQuadCurve(to: CGPoint(x: gx + len, y: gy + rnd(-4, 4)),
                         control: CGPoint(x: gx + len / 2, y: gy + rnd(-7, 7)))
        ctx.strokePath()
    }
    ctx.setFillColor(rgba(0, 0, 0, 0.2))
    ctx.fillEllipse(in: CGRect(x: x + w * 0.03, y: y + h / 2 - 4, width: 8, height: 8))
    ctx.fillEllipse(in: CGRect(x: x + w * 0.96, y: y + h / 2 - 4, width: 8, height: 8))
    ctx.restoreGState()
    ctx.setFillColor(rgba(0.2, 0.1, 0.05, 0.18))
    ctx.fill(CGRect(x: x, y: y - h * 0.22, width: w, height: h * 0.2))
}

// MARK: - Kiln shape

func drawKiln(_ ctx: CGContext, cx: Double, baseY: Double, w: Double, h: Double,
              bodyColor: CGColor, brickColor: CGColor, glow: Bool) {
    // dome body
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx - w / 2, y: baseY))
    p.addLine(to: CGPoint(x: cx - w / 2, y: baseY + h * 0.55))
    p.addQuadCurve(to: CGPoint(x: cx, y: baseY + h), control: CGPoint(x: cx - w / 2, y: baseY + h * 0.98))
    p.addQuadCurve(to: CGPoint(x: cx + w / 2, y: baseY + h * 0.55), control: CGPoint(x: cx + w / 2, y: baseY + h * 0.98))
    p.addLine(to: CGPoint(x: cx + w / 2, y: baseY))
    p.closeSubpath()
    fillPathVertical(ctx, p, top: bodyColor, bottom: brickColor)
    // brick joints
    ctx.saveGState()
    ctx.addPath(p)
    ctx.clip()
    ctx.setStrokeColor(rgba(0.15, 0.08, 0.05, 0.25))
    ctx.setLineWidth(3)
    var yy = baseY + h * 0.12
    var rowIdx = 0
    while yy < baseY + h {
        ctx.move(to: CGPoint(x: cx - w / 2, y: yy))
        ctx.addLine(to: CGPoint(x: cx + w / 2, y: yy))
        ctx.strokePath()
        var xx = cx - w / 2 + (rowIdx % 2 == 0 ? w * 0.08 : w * 0.16)
        while xx < cx + w / 2 {
            ctx.move(to: CGPoint(x: xx, y: yy))
            ctx.addLine(to: CGPoint(x: xx, y: yy + h * 0.12))
            ctx.strokePath()
            xx += w * 0.16
        }
        yy += h * 0.12
        rowIdx += 1
    }
    ctx.restoreGState()
    // mouth
    let mw = w * 0.34, mh = h * 0.42
    let mouth = CGMutablePath()
    mouth.move(to: CGPoint(x: cx - mw / 2, y: baseY))
    mouth.addLine(to: CGPoint(x: cx - mw / 2, y: baseY + mh * 0.6))
    mouth.addQuadCurve(to: CGPoint(x: cx + mw / 2, y: baseY + mh * 0.6),
                       control: CGPoint(x: cx, y: baseY + mh * 1.15))
    mouth.addLine(to: CGPoint(x: cx + mw / 2, y: baseY))
    mouth.closeSubpath()
    ctx.addPath(mouth)
    ctx.setFillColor(glow ? rgb(0.14, 0.06, 0.04) : rgb(0.12, 0.10, 0.11))
    ctx.fillPath()
    if glow {
        ctx.saveGState()
        ctx.addPath(mouth)
        ctx.clip()
        let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: [rgba(1.0, 0.72, 0.25, 0.95), rgba(0.9, 0.3, 0.1, 0.0)] as CFArray,
                              locations: [0, 1])!
        ctx.drawRadialGradient(grad, startCenter: CGPoint(x: cx, y: baseY + mh * 0.2), startRadius: 5,
                               endCenter: CGPoint(x: cx, y: baseY + mh * 0.25), endRadius: mw * 0.9, options: [])
        ctx.restoreGState()
    }
    // chimney
    ctx.setFillColor(brickColor)
    ctx.fill(CGRect(x: cx + w * 0.18, y: baseY + h * 0.8, width: w * 0.12, height: h * 0.4))
}

// MARK: - Scenes

func sceneOnboardingWheel() {
    let w = 1500, h = 1500
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: PCream, bottom: PLinen)
    ctx.setFillColor(rgba(0.871, 0.665, 0.298, 0.25))
    ctx.fillEllipse(in: CGRect(x: 330, y: 430, width: 840, height: 840))
    drawWheel(ctx, cx: 750, cy: 430, rx: 330)
    drawPotShape(ctx, cx: 750, baseY: 445, halfW: 200, height: 500, profile: vaseProfile,
                 body: rgb(0.72, 0.44, 0.30), dark: rgb(0.58, 0.32, 0.20))
    // finger dot touching wall
    ctx.setFillColor(rgba(0.98, 0.85, 0.72, 1))
    ctx.fillEllipse(in: CGRect(x: 920, y: 760, width: 84, height: 84))
    ctx.setStrokeColor(rgba(0.27, 0.21, 0.17, 0.5))
    ctx.setLineWidth(7)
    ctx.strokeEllipse(in: CGRect(x: 920, y: 760, width: 84, height: 84))
    // motion arcs
    ctx.setStrokeColor(rgba(0.27, 0.21, 0.17, 0.35))
    ctx.setLineWidth(9)
    for i in 0..<3 {
        let r = 430.0 + Double(i) * 55
        ctx.addArc(center: CGPoint(x: 750, y: 430), radius: r, startAngle: .pi * 1.15, endAngle: .pi * 1.45, clockwise: false)
        ctx.strokePath()
    }
    sparkle(ctx, x: 330, y: 1120, r: 34, color: rgba(0.871, 0.665, 0.298, 0.8))
    sparkle(ctx, x: 1190, y: 1180, r: 26, color: rgba(0.769, 0.412, 0.247, 0.6))
    sparkle(ctx, x: 1120, y: 380, r: 20, color: rgba(0.529, 0.612, 0.482, 0.7))
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h)
    savePNG(ctx, "\(artDir)/onboarding_wheel.png")
}

func sceneOnboardingGlaze() {
    let w = 1500, h = 1500
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.941, 0.925, 0.878), bottom: PLinen)
    ctx.setFillColor(rgba(0.353, 0.475, 0.573, 0.16))
    ctx.fillEllipse(in: CGRect(x: 300, y: 480, width: 900, height: 900))
    // table
    woodPlank(ctx, x: 120, y: 300, w: 1260, h: 60)
    // main pot half dipped
    drawShadowEllipse(ctx, cx: 700, y: 362, halfW: 250)
    drawPotShape(ctx, cx: 700, baseY: 366, halfW: 230, height: 620, profile: jugProfile,
                 body: rgb(0.82, 0.71, 0.55), dark: rgb(0.68, 0.55, 0.40))
    // dipped top: clip pot path above waterline
    let potP = potPath(cx: 700, baseY: 366, halfW: 230, height: 620, profile: jugProfile)
    ctx.saveGState()
    ctx.addPath(potP)
    ctx.clip()
    ctx.setFillColor(rgb(0.63, 0.78, 0.70))
    ctx.fill(CGRect(x: 380, y: 680, width: 640, height: 340))
    // drips
    for dx in [-140.0, -60, 30, 120] {
        let dripH = rnd(40, 130)
        let rect = CGRect(x: 700 + dx, y: 680 - dripH, width: 34, height: dripH + 8)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 17, cornerHeight: 17, transform: nil))
        ctx.setFillColor(rgb(0.63, 0.78, 0.70))
        ctx.fillPath()
    }
    ctx.restoreGState()
    // glaze jars
    let jarColors: [CGColor] = [rgb(0.23, 0.42, 0.60), rgb(0.83, 0.58, 0.24), rgb(0.89, 0.60, 0.60)]
    for (i, jc) in jarColors.enumerated() {
        let jx = 1080.0 + Double(i) * 120 - Double(i * i) * 8
        let jy = 360.0
        drawPotShape(ctx, cx: jx, baseY: jy, halfW: 52, height: 150, profile: cupProfile,
                     body: jc, dark: rgba(0, 0, 0, 1), mouth: true)
    }
    sparkle(ctx, x: 350, y: 1220, r: 30, color: rgba(0.353, 0.475, 0.573, 0.6))
    sparkle(ctx, x: 1200, y: 1150, r: 24, color: rgba(0.871, 0.665, 0.298, 0.8))
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h)
    savePNG(ctx, "\(artDir)/onboarding_glaze.png")
}

func sceneOnboardingShelf() {
    let w = 1500, h = 1500
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.957, 0.929, 0.874), bottom: PLinen)
    ctx.setFillColor(rgba(0.529, 0.612, 0.482, 0.15))
    ctx.fillEllipse(in: CGRect(x: 280, y: 400, width: 940, height: 940))
    // two shelves
    woodPlank(ctx, x: 210, y: 820, w: 1080, h: 52)
    woodPlank(ctx, x: 210, y: 380, w: 1080, h: 52)
    // top row pots
    drawPotShape(ctx, cx: 420, baseY: 874, halfW: 105, height: 300, profile: vaseProfile,
                 body: rgb(0.63, 0.78, 0.70), dark: rgb(0.48, 0.62, 0.55))
    drawPotShape(ctx, cx: 740, baseY: 874, halfW: 130, height: 210, profile: bowlProfile,
                 body: rgb(0.83, 0.58, 0.24), dark: rgb(0.66, 0.44, 0.16))
    drawPotShape(ctx, cx: 1060, baseY: 874, halfW: 95, height: 330, profile: bottleProfile,
                 body: rgb(0.23, 0.42, 0.60), dark: rgb(0.15, 0.30, 0.46))
    // bottom row pots
    drawPotShape(ctx, cx: 500, baseY: 434, halfW: 120, height: 260, profile: jugProfile,
                 body: rgb(0.89, 0.60, 0.60), dark: rgb(0.72, 0.45, 0.45))
    drawPotShape(ctx, cx: 900, baseY: 434, halfW: 110, height: 300, profile: vaseProfile,
                 body: rgb(0.22, 0.21, 0.22), dark: rgb(0.12, 0.11, 0.12))
    sparkle(ctx, x: 1210, y: 1260, r: 34, color: rgba(0.871, 0.665, 0.298, 0.9))
    sparkle(ctx, x: 300, y: 1180, r: 24, color: rgba(0.769, 0.412, 0.247, 0.6))
    sparkle(ctx, x: 1290, y: 700, r: 20, color: rgba(0.529, 0.612, 0.482, 0.7))
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h)
    savePNG(ctx, "\(artDir)/onboarding_shelf.png")
}

func sceneStudioBackdrop() {
    let w = 1400, h = 1800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.955, 0.922, 0.868), bottom: rgb(0.925, 0.878, 0.804))
    // window
    let wx = 180.0, wy = 1150.0, ww = 480.0, wh = 480.0
    ctx.setFillColor(rgb(0.85, 0.90, 0.92))
    ctx.addPath(CGPath(roundedRect: CGRect(x: wx, y: wy, width: ww, height: wh),
                       cornerWidth: 30, cornerHeight: 30, transform: nil))
    ctx.fillPath()
    ctx.setFillColor(rgba(0.99, 0.86, 0.45, 0.9))
    ctx.fillEllipse(in: CGRect(x: wx + 260, y: wy + 280, width: 130, height: 130))
    ctx.setFillColor(rgba(1, 1, 1, 0.75))
    ctx.fillEllipse(in: CGRect(x: wx + 40, y: wy + 180, width: 220, height: 80))
    ctx.fillEllipse(in: CGRect(x: wx + 140, y: wy + 140, width: 260, height: 90))
    ctx.setStrokeColor(rgb(0.60, 0.47, 0.33))
    ctx.setLineWidth(22)
    ctx.addPath(CGPath(roundedRect: CGRect(x: wx, y: wy, width: ww, height: wh),
                       cornerWidth: 30, cornerHeight: 30, transform: nil))
    ctx.move(to: CGPoint(x: wx + ww / 2, y: wy))
    ctx.addLine(to: CGPoint(x: wx + ww / 2, y: wy + wh))
    ctx.move(to: CGPoint(x: wx, y: wy + wh / 2))
    ctx.addLine(to: CGPoint(x: wx + ww, y: wy + wh / 2))
    ctx.strokePath()
    // hanging shelf with pot silhouettes
    woodPlank(ctx, x: 820, y: 1300, w: 460, h: 40)
    drawPotShape(ctx, cx: 910, baseY: 1342, halfW: 48, height: 130, profile: vaseProfile,
                 body: rgb(0.72, 0.44, 0.30), dark: rgb(0.58, 0.32, 0.20))
    drawPotShape(ctx, cx: 1050, baseY: 1342, halfW: 56, height: 90, profile: bowlProfile,
                 body: rgb(0.63, 0.78, 0.70), dark: rgb(0.48, 0.62, 0.55))
    drawPotShape(ctx, cx: 1180, baseY: 1342, halfW: 42, height: 150, profile: bottleProfile,
                 body: rgb(0.35, 0.47, 0.57), dark: rgb(0.24, 0.35, 0.44))
    // floor
    ctx.setFillColor(rgb(0.80, 0.68, 0.52))
    ctx.fill(CGRect(x: 0, y: 0, width: Double(w), height: 360))
    ctx.setStrokeColor(rgba(0.55, 0.42, 0.28, 0.4))
    ctx.setLineWidth(6)
    for i in 0..<6 {
        let fy = 60.0 + Double(i) * 52
        ctx.move(to: CGPoint(x: 0, y: fy))
        ctx.addLine(to: CGPoint(x: Double(w), y: fy))
        ctx.strokePath()
    }
    ctx.setFillColor(rgba(0.2, 0.1, 0.05, 0.12))
    ctx.fill(CGRect(x: 0, y: 350, width: Double(w), height: 14))
    addNoise(ctx, amount: 6)
    vignette(ctx, w, h, strength: 0.12)
    savePNG(ctx, "\(artDir)/studio_backdrop.png")
}

func sceneKilnBanner() {
    let w = 1600, h = 800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.30, 0.20, 0.30), bottom: rgb(0.85, 0.48, 0.25))
    // stars
    for _ in 0..<26 {
        let sx = rnd(30, Double(w) - 30), sy = rnd(Double(h) * 0.55, Double(h) - 20)
        ctx.setFillColor(rgba(1, 1, 1, rnd(0.2, 0.6)))
        let r = rnd(2, 5)
        ctx.fillEllipse(in: CGRect(x: sx, y: sy, width: r, height: r))
    }
    // ground
    ctx.setFillColor(rgb(0.32, 0.20, 0.16))
    ctx.fill(CGRect(x: 0, y: 0, width: Double(w), height: 130))
    drawKiln(ctx, cx: 800, baseY: 120, w: 560, h: 520,
             bodyColor: rgb(0.66, 0.38, 0.26), brickColor: rgb(0.48, 0.26, 0.18), glow: true)
    // sparks
    for _ in 0..<14 {
        let sx = 800 + rnd(-90, 90), sy = rnd(180, 420)
        ctx.setFillColor(rgba(1.0, rnd(0.5, 0.8), 0.2, rnd(0.4, 0.9)))
        let r = rnd(3, 9)
        ctx.fillEllipse(in: CGRect(x: sx, y: sy, width: r, height: r))
    }
    // side pots silhouettes
    drawPotShape(ctx, cx: 280, baseY: 128, halfW: 90, height: 240, profile: vaseProfile,
                 body: rgb(0.24, 0.15, 0.13), dark: rgb(0.16, 0.09, 0.08))
    drawPotShape(ctx, cx: 1330, baseY: 128, halfW: 110, height: 200, profile: jugProfile,
                 body: rgb(0.24, 0.15, 0.13), dark: rgb(0.16, 0.09, 0.08))
    addNoise(ctx, amount: 8)
    vignette(ctx, w, h, strength: 0.2)
    savePNG(ctx, "\(artDir)/kiln_banner.png")
}

func sceneKilnCold() {
    let w = 1400, h = 800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.78, 0.80, 0.84), bottom: rgb(0.88, 0.86, 0.82))
    ctx.setFillColor(rgba(1, 1, 1, 0.8))
    ctx.fillEllipse(in: CGRect(x: 1130, y: 620, width: 110, height: 110))
    ctx.setFillColor(rgb(0.72, 0.66, 0.60))
    ctx.fill(CGRect(x: 0, y: 0, width: Double(w), height: 120))
    drawKiln(ctx, cx: 700, baseY: 112, w: 500, h: 470,
             bodyColor: rgb(0.60, 0.54, 0.52), brickColor: rgb(0.45, 0.40, 0.39), glow: false)
    // little dust pile
    ctx.setFillColor(rgba(0.5, 0.45, 0.42, 0.7))
    ctx.fillEllipse(in: CGRect(x: 940, y: 96, width: 160, height: 46))
    addNoise(ctx, amount: 6)
    vignette(ctx, w, h, strength: 0.12)
    savePNG(ctx, "\(artDir)/kiln_cold.png")
}

func sceneGalleryBanner() {
    let w = 1600, h = 800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.945, 0.910, 0.850), bottom: rgb(0.90, 0.84, 0.75))
    let glazeColors: [(CGColor, CGColor)] = [
        (rgb(0.63, 0.78, 0.70), rgb(0.48, 0.62, 0.55)),
        (rgb(0.23, 0.42, 0.60), rgb(0.15, 0.30, 0.46)),
        (rgb(0.83, 0.58, 0.24), rgb(0.66, 0.44, 0.16)),
        (rgb(0.89, 0.60, 0.60), rgb(0.72, 0.45, 0.45)),
        (rgb(0.40, 0.51, 0.33), rgb(0.28, 0.38, 0.22)),
        (rgb(0.22, 0.21, 0.22), rgb(0.13, 0.12, 0.13)),
        (rgb(0.95, 0.92, 0.85), rgb(0.78, 0.74, 0.66)),
        (rgb(0.58, 0.50, 0.66), rgb(0.44, 0.37, 0.52)),
    ]
    let profiles = [vaseProfile, bowlProfile, jugProfile, bottleProfile, cupProfile]
    for row in 0..<2 {
        let shelfY = 130.0 + Double(row) * 340
        woodPlank(ctx, x: 90, y: shelfY, w: 1420, h: 46)
        var px = 200.0
        var i = row * 3
        while px < 1420 {
            let (bodyC, darkC) = glazeColors[i % glazeColors.count]
            let prof = profiles[i % profiles.count]
            let hw = rnd(60, 95)
            let ph = rnd(150, 260)
            drawPotShape(ctx, cx: px, baseY: shelfY + 46, halfW: hw, height: ph, profile: prof,
                         body: bodyC, dark: darkC)
            px += hw * 2 + rnd(40, 90)
            i += 1
        }
    }
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h, strength: 0.13)
    savePNG(ctx, "\(artDir)/gallery_banner.png")
}

func sceneGalleryEmpty() {
    let w = 1400, h = 800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.955, 0.925, 0.872), bottom: rgb(0.92, 0.87, 0.80))
    woodPlank(ctx, x: 240, y: 300, w: 920, h: 50)
    // a single small plant pot
    drawPotShape(ctx, cx: 520, baseY: 352, halfW: 80, height: 130, profile: cupProfile,
                 body: rgb(0.78, 0.45, 0.28), dark: rgb(0.62, 0.34, 0.20))
    // leaves
    ctx.setFillColor(rgb(0.47, 0.60, 0.42))
    for (dx, ang) in [(-30.0, 1.9), (0.0, 1.57), (30.0, 1.2)] {
        let p = CGMutablePath()
        let bx = 520.0 + dx, by = 480.0
        let tipx = bx + cos(ang) * 150, tipy = by + sin(ang) * 150
        p.move(to: CGPoint(x: bx, y: by))
        p.addQuadCurve(to: CGPoint(x: tipx, y: tipy), control: CGPoint(x: bx - 45, y: by + 90))
        p.addQuadCurve(to: CGPoint(x: bx, y: by), control: CGPoint(x: bx + 45, y: by + 90))
        ctx.addPath(p)
        ctx.fillPath()
    }
    sparkle(ctx, x: 900, y: 500, r: 26, color: rgba(0.871, 0.665, 0.298, 0.7))
    sparkle(ctx, x: 1020, y: 430, r: 16, color: rgba(0.769, 0.412, 0.247, 0.5))
    addNoise(ctx, amount: 6)
    vignette(ctx, w, h, strength: 0.12)
    savePNG(ctx, "\(artDir)/gallery_empty.png")
}

func sceneMoreBanner() {
    let w = 1600, h = 800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: rgb(0.94, 0.90, 0.84), bottom: rgb(0.90, 0.83, 0.73))
    woodPlank(ctx, x: 0, y: 180, w: 1600, h: 70)
    ctx.setFillColor(rgb(0.86, 0.76, 0.62))
    ctx.fill(CGRect(x: 0, y: 0, width: 1600, height: 180))
    // tools on the table: rib
    let rib = CGMutablePath()
    rib.move(to: CGPoint(x: 300, y: 260))
    rib.addLine(to: CGPoint(x: 380, y: 420))
    rib.addLine(to: CGPoint(x: 500, y: 400))
    rib.addQuadCurve(to: CGPoint(x: 430, y: 250), control: CGPoint(x: 520, y: 300))
    rib.closeSubpath()
    ctx.addPath(rib)
    ctx.setFillColor(rgb(0.82, 0.68, 0.48))
    ctx.fillPath()
    // wire tool
    ctx.setStrokeColor(rgb(0.45, 0.42, 0.40))
    ctx.setLineWidth(8)
    ctx.move(to: CGPoint(x: 640, y: 300))
    ctx.addCurve(to: CGPoint(x: 940, y: 310),
                 control1: CGPoint(x: 730, y: 380), control2: CGPoint(x: 860, y: 240))
    ctx.strokePath()
    ctx.setFillColor(rgb(0.60, 0.42, 0.26))
    ctx.fill(CGRect(x: 600, y: 270, width: 46, height: 66))
    ctx.fill(CGRect(x: 934, y: 280, width: 46, height: 66))
    // sponge
    ctx.addPath(CGPath(roundedRect: CGRect(x: 1060, y: 270, width: 190, height: 100),
                       cornerWidth: 40, cornerHeight: 40, transform: nil))
    ctx.setFillColor(rgb(0.92, 0.80, 0.52))
    ctx.fillPath()
    ctx.setFillColor(rgba(0.6, 0.5, 0.3, 0.5))
    for _ in 0..<9 {
        let px = rnd(1080, 1230), py = rnd(285, 350)
        ctx.fillEllipse(in: CGRect(x: px, y: py, width: rnd(6, 12), height: rnd(6, 12)))
    }
    // small pot
    drawPotShape(ctx, cx: 1420, baseY: 250, halfW: 85, height: 230, profile: vaseProfile,
                 body: rgb(0.72, 0.44, 0.30), dark: rgb(0.56, 0.32, 0.20))
    // clay lump
    let lump = CGMutablePath()
    lump.move(to: CGPoint(x: 120, y: 250))
    lump.addQuadCurve(to: CGPoint(x: 260, y: 250), control: CGPoint(x: 190, y: 380))
    lump.closeSubpath()
    ctx.addPath(lump)
    ctx.setFillColor(rgb(0.62, 0.36, 0.24))
    ctx.fillPath()
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h, strength: 0.13)
    savePNG(ctx, "\(artDir)/more_banner.png")
}

func sceneWoodShelf() {
    let w = 1400, h = 180
    let ctx = makeCtx(w, h)
    ctx.setFillColor(PWood)
    ctx.fill(CGRect(x: 0, y: 0, width: Double(w), height: Double(h)))
    ctx.setStrokeColor(rgba(0.4, 0.28, 0.16, 0.4))
    for _ in 0..<60 {
        let gy = rnd(15, 165)
        let gx = rnd(0, 1300)
        let len = rnd(60, 260)
        ctx.setLineWidth(rnd(2, 6))
        ctx.move(to: CGPoint(x: gx, y: gy))
        ctx.addQuadCurve(to: CGPoint(x: gx + len, y: gy + rnd(-6, 6)),
                         control: CGPoint(x: gx + len / 2, y: gy + rnd(-12, 12)))
        ctx.strokePath()
    }
    // top highlight edge
    ctx.setFillColor(rgba(1, 1, 1, 0.18))
    ctx.fill(CGRect(x: 0, y: Double(h) - 22, width: Double(w), height: 22))
    ctx.setFillColor(rgba(0.2, 0.1, 0.05, 0.3))
    ctx.fill(CGRect(x: 0, y: 0, width: Double(w), height: 16))
    addNoise(ctx, amount: 8)
    savePNG(ctx, "\(artDir)/wood_shelf.png")
}

// MARK: Handbook banners

func hbBanner(_ name: String, top: CGColor, bottom: CGColor, draw: (CGContext) -> Void) {
    let w = 1600, h = 800
    let ctx = makeCtx(w, h)
    fillVertical(ctx, w, h, top: top, bottom: bottom)
    draw(ctx)
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h, strength: 0.15)
    savePNG(ctx, "\(artDir)/\(name).png")
}

func sceneHandbookBanners() {
    hbBanner("hb_wheel", top: rgb(0.76, 0.48, 0.32), bottom: rgb(0.62, 0.34, 0.20)) { ctx in
        drawWheel(ctx, cx: 800, cy: 260, rx: 380)
        // centering cone
        let cone = CGMutablePath()
        cone.move(to: CGPoint(x: 640, y: 280))
        cone.addQuadCurve(to: CGPoint(x: 800, y: 620), control: CGPoint(x: 700, y: 520))
        cone.addQuadCurve(to: CGPoint(x: 960, y: 280), control: CGPoint(x: 900, y: 520))
        cone.closeSubpath()
        ctx.addPath(cone)
        ctx.setFillColor(rgb(0.55, 0.32, 0.22))
        ctx.fillPath()
        ctx.setStrokeColor(rgba(1, 1, 1, 0.35))
        ctx.setLineWidth(10)
        for i in 0..<3 {
            let r = 470.0 + Double(i) * 60
            ctx.addArc(center: CGPoint(x: 800, y: 260), radius: r,
                       startAngle: .pi * 1.1, endAngle: .pi * 1.5, clockwise: false)
            ctx.strokePath()
        }
    }
    hbBanner("hb_clay", top: rgb(0.88, 0.80, 0.68), bottom: rgb(0.80, 0.68, 0.52)) { ctx in
        woodPlank(ctx, x: 100, y: 170, w: 1400, h: 56)
        let tones: [CGColor] = [rgb(0.62, 0.36, 0.24), rgb(0.66, 0.55, 0.42), rgb(0.80, 0.77, 0.72), rgb(0.30, 0.28, 0.29)]
        for (i, t) in tones.enumerated() {
            let cx = 320.0 + Double(i) * 330
            let lump = CGMutablePath()
            lump.move(to: CGPoint(x: cx - 130, y: 226))
            lump.addQuadCurve(to: CGPoint(x: cx + 130, y: 226), control: CGPoint(x: cx, y: 520))
            lump.closeSubpath()
            ctx.addPath(lump)
            ctx.setFillColor(t)
            ctx.fillPath()
            if i == 1 {
                ctx.setFillColor(rgba(0.3, 0.2, 0.12, 0.7))
                for _ in 0..<12 {
                    ctx.fillEllipse(in: CGRect(x: cx + rnd(-90, 80), y: rnd(250, 380), width: rnd(5, 10), height: rnd(5, 10)))
                }
            }
        }
    }
    hbBanner("hb_glaze", top: rgb(0.55, 0.68, 0.66), bottom: rgb(0.40, 0.55, 0.54)) { ctx in
        // hanging test tiles
        let tileColors: [CGColor] = [rgb(0.63, 0.78, 0.70), rgb(0.83, 0.58, 0.24), rgb(0.23, 0.42, 0.60),
                                     rgb(0.89, 0.60, 0.60), rgb(0.95, 0.92, 0.85), rgb(0.22, 0.21, 0.22)]
        for (i, t) in tileColors.enumerated() {
            let tx = 190.0 + Double(i) * 220
            let ty = 260.0 + (i % 2 == 0 ? 0 : 70)
            ctx.setFillColor(rgb(0.82, 0.71, 0.55))
            ctx.addPath(CGPath(roundedRect: CGRect(x: tx, y: ty, width: 150, height: 330),
                               cornerWidth: 22, cornerHeight: 22, transform: nil))
            ctx.fillPath()
            ctx.setFillColor(t)
            ctx.addPath(CGPath(roundedRect: CGRect(x: tx, y: ty, width: 150, height: 210),
                               cornerWidth: 22, cornerHeight: 22, transform: nil))
            ctx.fillPath()
            // drip
            ctx.addPath(CGPath(roundedRect: CGRect(x: tx + 55, y: ty + 160, width: 26, height: 90),
                               cornerWidth: 13, cornerHeight: 13, transform: nil))
            ctx.fillPath()
            ctx.setFillColor(rgba(0, 0, 0, 0.25))
            ctx.fillEllipse(in: CGRect(x: tx + 66, y: ty + 300, width: 18, height: 18))
        }
    }
    hbBanner("hb_kiln", top: rgb(0.35, 0.18, 0.14), bottom: rgb(0.62, 0.30, 0.16)) { ctx in
        // kiln interior arch
        let arch = CGMutablePath()
        arch.move(to: CGPoint(x: 200, y: 0))
        arch.addLine(to: CGPoint(x: 200, y: 480))
        arch.addQuadCurve(to: CGPoint(x: 1400, y: 480), control: CGPoint(x: 800, y: 900))
        arch.addLine(to: CGPoint(x: 1400, y: 0))
        arch.closeSubpath()
        ctx.addPath(arch)
        ctx.setFillColor(rgb(0.20, 0.08, 0.05))
        ctx.fillPath()
        ctx.saveGState()
        ctx.addPath(arch)
        ctx.clip()
        let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: [rgba(1.0, 0.70, 0.25, 0.9), rgba(0.8, 0.25, 0.08, 0)] as CFArray,
                              locations: [0, 1])!
        ctx.drawRadialGradient(grad, startCenter: CGPoint(x: 800, y: 140), startRadius: 20,
                               endCenter: CGPoint(x: 800, y: 160), endRadius: 700, options: [])
        // pots inside as dark shapes lit from below
        drawPotShape(ctx, cx: 560, baseY: 90, halfW: 110, height: 300, profile: vaseProfile,
                     body: rgb(0.55, 0.22, 0.10), dark: rgb(0.30, 0.10, 0.05))
        drawPotShape(ctx, cx: 830, baseY: 90, halfW: 140, height: 220, profile: bowlProfile,
                     body: rgb(0.62, 0.26, 0.12), dark: rgb(0.34, 0.12, 0.06))
        drawPotShape(ctx, cx: 1090, baseY: 90, halfW: 95, height: 330, profile: bottleProfile,
                     body: rgb(0.50, 0.20, 0.09), dark: rgb(0.28, 0.10, 0.05))
        ctx.restoreGState()
    }
    hbBanner("hb_history", top: rgb(0.84, 0.72, 0.52), bottom: rgb(0.72, 0.56, 0.38)) { ctx in
        ctx.setFillColor(rgba(0.99, 0.88, 0.55, 0.85))
        ctx.fillEllipse(in: CGRect(x: 1220, y: 520, width: 200, height: 200))
        // column
        ctx.setFillColor(rgb(0.88, 0.82, 0.72))
        ctx.fill(CGRect(x: 240, y: 0, width: 130, height: 560))
        ctx.fill(CGRect(x: 210, y: 540, width: 190, height: 44))
        ctx.fill(CGRect(x: 210, y: 0, width: 190, height: 40))
        ctx.setStrokeColor(rgba(0.6, 0.52, 0.42, 0.6))
        ctx.setLineWidth(9)
        for i in 0..<4 {
            let lx = 262.0 + Double(i) * 30
            ctx.move(to: CGPoint(x: lx, y: 46))
            ctx.addLine(to: CGPoint(x: lx, y: 534))
            ctx.strokePath()
        }
        // amphora
        let amph: [Double] = [0.30, 0.5, 0.75, 0.95, 1.0, 0.9, 0.7, 0.5, 0.38, 0.42, 0.55]
        drawPotShape(ctx, cx: 800, baseY: 60, halfW: 200, height: 560, profile: amph,
                     body: rgb(0.72, 0.42, 0.24), dark: rgb(0.50, 0.26, 0.14))
        // handles
        ctx.setStrokeColor(rgb(0.55, 0.30, 0.16))
        ctx.setLineWidth(26)
        ctx.move(to: CGPoint(x: 690, y: 560))
        ctx.addQuadCurve(to: CGPoint(x: 660, y: 380), control: CGPoint(x: 560, y: 470))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: 910, y: 560))
        ctx.addQuadCurve(to: CGPoint(x: 940, y: 380), control: CGPoint(x: 1040, y: 470))
        ctx.strokePath()
        // meander band
        ctx.setStrokeColor(rgb(0.28, 0.18, 0.10))
        ctx.setLineWidth(12)
        ctx.move(to: CGPoint(x: 620, y: 330))
        ctx.addLine(to: CGPoint(x: 980, y: 330))
        ctx.move(to: CGPoint(x: 620, y: 290))
        ctx.addLine(to: CGPoint(x: 980, y: 290))
        ctx.strokePath()
    }
    hbBanner("hb_care", top: rgb(0.90, 0.87, 0.80), bottom: rgb(0.82, 0.78, 0.70)) { ctx in
        woodPlank(ctx, x: 200, y: 160, w: 1200, h: 52)
        drawPotShape(ctx, cx: 620, baseY: 214, halfW: 150, height: 330, profile: bowlProfile,
                     body: rgb(0.63, 0.78, 0.70), dark: rgb(0.46, 0.60, 0.53))
        // soft cloth
        let cloth = CGMutablePath()
        cloth.move(to: CGPoint(x: 900, y: 214))
        cloth.addQuadCurve(to: CGPoint(x: 1160, y: 240), control: CGPoint(x: 1020, y: 330))
        cloth.addQuadCurve(to: CGPoint(x: 1240, y: 214), control: CGPoint(x: 1200, y: 250))
        cloth.closeSubpath()
        ctx.addPath(cloth)
        ctx.setFillColor(rgb(0.93, 0.83, 0.66))
        ctx.fillPath()
        // water drops
        for (dx, dy, r) in [(430.0, 640.0, 40.0), (530, 700, 28), (360, 560, 24)] {
            let drop = CGMutablePath()
            drop.move(to: CGPoint(x: dx, y: dy + r * 1.4))
            drop.addQuadCurve(to: CGPoint(x: dx + r, y: dy), control: CGPoint(x: dx + r * 1.1, y: dy + r * 0.8))
            drop.addArc(center: CGPoint(x: dx, y: dy), radius: r, startAngle: 0, endAngle: .pi, clockwise: true)
            drop.addQuadCurve(to: CGPoint(x: dx, y: dy + r * 1.4), control: CGPoint(x: dx - r * 1.1, y: dy + r * 0.8))
            ctx.addPath(drop)
            ctx.setFillColor(rgba(0.42, 0.58, 0.70, 0.85))
            ctx.fillPath()
        }
        sparkle(ctx, x: 1240, y: 600, r: 30, color: rgba(0.871, 0.665, 0.298, 0.8))
    }
}

// MARK: Technique illustrations

func techScene(_ index: Int, _ draw: (CGContext) -> Void) {
    let w = 1400, h = 900
    let ctx = makeCtx(w, h)
    let tints: [(CGColor, CGColor)] = [
        (rgb(0.95, 0.91, 0.85), rgb(0.90, 0.84, 0.75)),
        (rgb(0.94, 0.89, 0.82), rgb(0.88, 0.81, 0.71)),
    ]
    let (t, b) = tints[index % 2]
    fillVertical(ctx, w, h, top: t, bottom: b)
    draw(ctx)
    addNoise(ctx, amount: 7)
    vignette(ctx, w, h, strength: 0.12)
    savePNG(ctx, String(format: "%@/tech_%02d.png", artDir, index))
}

func handShape(_ ctx: CGContext, x: Double, y: Double, size: Double, flip: Bool = false) {
    // simple rounded mitt
    ctx.saveGState()
    ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
    if flip { ctx.scaleBy(x: -1, y: 1) }
    let p = CGMutablePath()
    p.addRoundedRect(in: CGRect(x: -size * 0.5, y: -size * 0.35, width: size, height: size * 0.7),
                     cornerWidth: CGFloat(size * 0.3), cornerHeight: CGFloat(size * 0.3))
    ctx.addPath(p)
    ctx.setFillColor(rgb(0.95, 0.80, 0.66))
    ctx.fillPath()
    // thumb
    ctx.fillEllipse(in: CGRect(x: -size * 0.62, y: -size * 0.1, width: size * 0.36, height: size * 0.5))
    ctx.restoreGState()
}

func sceneTechAll() {
    // 1 wedging
    techScene(1) { ctx in
        woodPlank(ctx, x: 120, y: 180, w: 1160, h: 60)
        let lump = CGMutablePath()
        lump.move(to: CGPoint(x: 470, y: 242))
        lump.addQuadCurve(to: CGPoint(x: 930, y: 242), control: CGPoint(x: 700, y: 640))
        lump.closeSubpath()
        ctx.addPath(lump)
        ctx.setFillColor(rgb(0.62, 0.36, 0.24))
        ctx.fillPath()
        handShape(ctx, x: 520, y: 520, size: 190)
        handShape(ctx, x: 880, y: 520, size: 190, flip: true)
    }
    // 2 centering
    techScene(2) { ctx in
        drawWheel(ctx, cx: 700, cy: 260, rx: 360)
        let cone = CGMutablePath()
        cone.move(to: CGPoint(x: 540, y: 280))
        cone.addQuadCurve(to: CGPoint(x: 700, y: 620), control: CGPoint(x: 610, y: 540))
        cone.addQuadCurve(to: CGPoint(x: 860, y: 280), control: CGPoint(x: 790, y: 540))
        cone.closeSubpath()
        ctx.addPath(cone)
        ctx.setFillColor(rgb(0.60, 0.35, 0.23))
        ctx.fillPath()
        handShape(ctx, x: 520, y: 460, size: 180)
        handShape(ctx, x: 880, y: 460, size: 180, flip: true)
    }
    // 3 opening
    techScene(3) { ctx in
        drawWheel(ctx, cx: 700, cy: 250, rx: 360)
        let mound = CGMutablePath()
        mound.move(to: CGPoint(x: 490, y: 268))
        mound.addQuadCurve(to: CGPoint(x: 910, y: 268), control: CGPoint(x: 700, y: 560))
        mound.closeSubpath()
        ctx.addPath(mound)
        ctx.setFillColor(rgb(0.62, 0.36, 0.24))
        ctx.fillPath()
        // opening hole
        ctx.setFillColor(rgb(0.42, 0.22, 0.13))
        ctx.fillEllipse(in: CGRect(x: 620, y: 420, width: 160, height: 60))
        handShape(ctx, x: 700, y: 560, size: 170)
    }
    // 4 pulling
    techScene(4) { ctx in
        drawWheel(ctx, cx: 700, cy: 240, rx: 360)
        let cyl: [Double] = [0.95, 0.97, 0.98, 1.0, 1.0, 0.99, 0.98, 0.97, 0.96]
        drawPotShape(ctx, cx: 700, baseY: 258, halfW: 170, height: 520, profile: cyl,
                     body: rgb(0.64, 0.38, 0.26), dark: rgb(0.50, 0.28, 0.18))
        handShape(ctx, x: 480, y: 520, size: 160)
        handShape(ctx, x: 920, y: 520, size: 160, flip: true)
        // rising arrows
        ctx.setStrokeColor(rgba(0.27, 0.21, 0.17, 0.4))
        ctx.setLineWidth(11)
        for dx in [-320.0, 320.0] {
            ctx.move(to: CGPoint(x: 700 + dx, y: 330))
            ctx.addLine(to: CGPoint(x: 700 + dx, y: 620))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: 700 + dx - 34, y: 570))
            ctx.addLine(to: CGPoint(x: 700 + dx, y: 630))
            ctx.addLine(to: CGPoint(x: 700 + dx + 34, y: 570))
            ctx.strokePath()
        }
    }
    // 5 shaping
    techScene(5) { ctx in
        drawWheel(ctx, cx: 700, cy: 240, rx: 360)
        drawPotShape(ctx, cx: 700, baseY: 258, halfW: 210, height: 520, profile: vaseProfile,
                     body: rgb(0.66, 0.40, 0.27), dark: rgb(0.52, 0.30, 0.19))
        handShape(ctx, x: 940, y: 560, size: 150, flip: true)
        ctx.setStrokeColor(rgba(0.27, 0.21, 0.17, 0.4))
        ctx.setLineWidth(10)
        ctx.move(to: CGPoint(x: 1030, y: 480))
        ctx.addLine(to: CGPoint(x: 950, y: 480))
        ctx.strokePath()
    }
    // 6 ribbing
    techScene(6) { ctx in
        drawWheel(ctx, cx: 700, cy: 240, rx: 360)
        drawPotShape(ctx, cx: 700, baseY: 258, halfW: 200, height: 540, profile: cupProfile,
                     body: rgb(0.66, 0.40, 0.27), dark: rgb(0.52, 0.30, 0.19))
        // rib tool against wall
        let rib = CGMutablePath()
        rib.move(to: CGPoint(x: 900, y: 420))
        rib.addLine(to: CGPoint(x: 1050, y: 480))
        rib.addLine(to: CGPoint(x: 1080, y: 600))
        rib.addQuadCurve(to: CGPoint(x: 930, y: 560), control: CGPoint(x: 990, y: 600))
        rib.closeSubpath()
        ctx.addPath(rib)
        ctx.setFillColor(rgb(0.85, 0.72, 0.52))
        ctx.fillPath()
        handShape(ctx, x: 1090, y: 520, size: 140, flip: true)
    }
    // 7 wiring off
    techScene(7) { ctx in
        drawWheel(ctx, cx: 700, cy: 240, rx: 380)
        drawPotShape(ctx, cx: 700, baseY: 300, halfW: 190, height: 440, profile: bowlProfile,
                     body: rgb(0.66, 0.40, 0.27), dark: rgb(0.52, 0.30, 0.19))
        ctx.setStrokeColor(rgb(0.42, 0.40, 0.38))
        ctx.setLineWidth(9)
        ctx.move(to: CGPoint(x: 380, y: 290))
        ctx.addCurve(to: CGPoint(x: 1020, y: 290),
                     control1: CGPoint(x: 600, y: 250), control2: CGPoint(x: 820, y: 330))
        ctx.strokePath()
        ctx.setFillColor(rgb(0.60, 0.42, 0.26))
        ctx.fill(CGRect(x: 330, y: 258, width: 52, height: 70))
        ctx.fill(CGRect(x: 1018, y: 258, width: 52, height: 70))
    }
    // 8 drying
    techScene(8) { ctx in
        woodPlank(ctx, x: 180, y: 240, w: 1040, h: 54)
        drawPotShape(ctx, cx: 520, baseY: 296, halfW: 130, height: 330, profile: vaseProfile,
                     body: rgb(0.72, 0.48, 0.34), dark: rgb(0.58, 0.36, 0.24))
        drawPotShape(ctx, cx: 850, baseY: 296, halfW: 140, height: 240, profile: bowlProfile,
                     body: rgb(0.78, 0.56, 0.40), dark: rgb(0.62, 0.42, 0.28))
        // sun
        ctx.setFillColor(rgba(0.99, 0.86, 0.45, 0.9))
        ctx.fillEllipse(in: CGRect(x: 1120, y: 640, width: 150, height: 150))
        ctx.setStrokeColor(rgba(0.99, 0.86, 0.45, 0.8))
        ctx.setLineWidth(10)
        for i in 0..<8 {
            let a = Double(i) * .pi / 4
            let cxs = 1195.0, cys = 715.0
            ctx.move(to: CGPoint(x: cxs + cos(a) * 95, y: cys + sin(a) * 95))
            ctx.addLine(to: CGPoint(x: cxs + cos(a) * 125, y: cys + sin(a) * 125))
            ctx.strokePath()
        }
        // wavy steam
        ctx.setStrokeColor(rgba(0.6, 0.55, 0.5, 0.5))
        ctx.setLineWidth(8)
        for dx in [460.0, 560.0] {
            ctx.move(to: CGPoint(x: dx, y: 650))
            ctx.addCurve(to: CGPoint(x: dx, y: 780),
                         control1: CGPoint(x: dx - 30, y: 690), control2: CGPoint(x: dx + 30, y: 740))
            ctx.strokePath()
        }
    }
}

// MARK: - App icon (abstract, opaque)

func makeAppIcon() {
    let s = 1024
    let ctx = makeCtx(s, s)
    // muted warm radial background
    let bgGrad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                            colors: [rgb(0.965, 0.93, 0.875), rgb(0.885, 0.80, 0.70)] as CFArray,
                            locations: [0, 1])!
    ctx.drawRadialGradient(bgGrad, startCenter: CGPoint(x: 512, y: 560), startRadius: 40,
                           endCenter: CGPoint(x: 512, y: 512), endRadius: 760,
                           options: .drawsAfterEndLocation)
    // centered ceramic disc emblem
    let c = CGPoint(x: 512, y: 512)
    ctx.setFillColor(rgba(0.45, 0.25, 0.14, 0.14))
    ctx.fillEllipse(in: CGRect(x: c.x - 300, y: c.y - 322, width: 600, height: 600))
    let discGrad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: [rgb(0.83, 0.50, 0.32), rgb(0.66, 0.34, 0.20)] as CFArray,
                              locations: [0, 1])!
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - 290, y: c.y - 290, width: 580, height: 580))
    ctx.clip()
    ctx.drawLinearGradient(discGrad, start: CGPoint(x: 512, y: 802), end: CGPoint(x: 512, y: 222), options: [])
    ctx.restoreGState()
    // thin inner rings (like a thrown disc)
    ctx.setStrokeColor(rgba(1, 1, 1, 0.30))
    ctx.setLineWidth(14)
    ctx.strokeEllipse(in: CGRect(x: c.x - 218, y: c.y - 218, width: 436, height: 436))
    ctx.setStrokeColor(rgba(1, 1, 1, 0.18))
    ctx.setLineWidth(10)
    ctx.strokeEllipse(in: CGRect(x: c.x - 132, y: c.y - 132, width: 264, height: 264))
    // center dot
    ctx.setFillColor(rgb(0.93, 0.86, 0.76))
    ctx.fillEllipse(in: CGRect(x: c.x - 46, y: c.y - 46, width: 92, height: 92))
    // small accent sparkles
    sparkle(ctx, x: 790, y: 780, r: 40, color: rgba(0.90, 0.70, 0.32, 0.9))
    sparkle(ctx, x: 250, y: 270, r: 26, color: rgba(0.90, 0.70, 0.32, 0.7))
    sparkle(ctx, x: 820, y: 300, r: 18, color: rgba(1, 1, 1, 0.55))
    addNoise(ctx, amount: 4)
    savePNG(ctx, "\(iconDir)/AppIcon-1024.png")
}

// MARK: - Run

sceneOnboardingWheel()
sceneOnboardingGlaze()
sceneOnboardingShelf()
sceneStudioBackdrop()
sceneKilnBanner()
sceneKilnCold()
sceneGalleryBanner()
sceneGalleryEmpty()
sceneMoreBanner()
sceneWoodShelf()
sceneHandbookBanners()
sceneTechAll()
makeAppIcon()
print("done")
