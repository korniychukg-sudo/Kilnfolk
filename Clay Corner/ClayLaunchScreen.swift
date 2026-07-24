import SwiftUI

struct ClayLaunchScreen: View {
    @State private var spin = false

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .fill(Studio.linen)
                        .frame(width: 148, height: 148)
                    Circle()
                        .stroke(Studio.terracotta.opacity(0.35), lineWidth: 10)
                        .frame(width: 120, height: 120)
                    WheelSpokes()
                        .stroke(Studio.terracotta, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 88, height: 88)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 2.2).repeatForever(autoreverses: false), value: spin)
                    Circle()
                        .fill(Studio.terracotta)
                        .frame(width: 22, height: 22)
                }

                VStack(spacing: 6) {
                    Text("Clay Corner")
                        .font(.clayTitle(30))
                        .foregroundColor(Studio.ink)
                    Text("A tiny pottery studio")
                        .font(.clayBody(15))
                        .foregroundColor(Studio.inkSoft)
                }
            }
        }
        .onAppear { spin = true }
    }
}

struct WheelSpokes: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let a = CGFloat(i) / 6 * .pi * 2
            p.move(to: c)
            p.addLine(to: CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
        return p
    }
}
