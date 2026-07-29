import SwiftUI

/// One-shot celebration burst drawn in a Canvas. Deterministic per `seed`.
struct ConfettiBurst: View {
    var seed: UInt64 = 7
    var duration: Double = 2.4

    @State private var startTime: Date? = nil

    private struct Piece {
        var x0: Double
        var vx: Double
        var vy: Double
        var spin: Double
        var size: Double
        var colorIndex: Int
        var isCapsule: Bool
        var delay: Double
    }

    private var pieces: [Piece] {
        var rng = FolkRandom(seed: seed)
        return (0..<46).map { _ in
            Piece(x0: rng.range(0.08, 0.92),
                  vx: rng.range(-40, 40),
                  vy: rng.range(-330, -170),
                  spin: rng.range(-5, 5),
                  size: rng.range(5, 11),
                  colorIndex: Int(rng.range(0, 5.99)),
                  isCapsule: rng.next() > 0.45,
                  delay: rng.range(0, 0.25))
        }
    }

    private static let palette: [Color] = [
        Studio.terracotta, Studio.honey, Studio.sage, Studio.denim, Studio.ember,
        Color(red: 0.89, green: 0.60, blue: 0.60),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { ctx, size in
                guard let start = startTime else { return }
                let t = timeline.date.timeIntervalSince(start)
                guard t < duration else { return }
                for p in pieces {
                    let age = t - p.delay
                    guard age > 0 else { continue }
                    let x = p.x0 * size.width + p.vx * age
                    let y = size.height * 0.42 + p.vy * age + 300 * age * age
                    guard y < size.height + 20 else { continue }
                    let fade = max(0, 1 - age / (duration - p.delay))
                    let color = Self.palette[p.colorIndex % Self.palette.count]
                    var layer = ctx
                    layer.translateBy(x: x, y: y)
                    layer.rotate(by: .radians(p.spin * age))
                    let rect = p.isCapsule
                        ? CGRect(x: -p.size / 2, y: -p.size / 5, width: p.size, height: p.size * 0.4)
                        : CGRect(x: -p.size / 2.6, y: -p.size / 2.6, width: p.size * 0.77, height: p.size * 0.77)
                    let path = p.isCapsule
                        ? Path(roundedRect: rect, cornerRadius: rect.height / 2)
                        : Path(ellipseIn: rect)
                    layer.fill(path, with: .color(color.opacity(0.9 * fade)))
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { startTime = Date() }
    }
}
