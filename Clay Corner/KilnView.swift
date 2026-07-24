import SwiftUI

struct KilnView: View {
    @EnvironmentObject var store: ClayStore
    @State private var revealPot: PotDesign? = nil

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    CornerArt(name: "kiln_banner")
                        .scaledToFill()
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(22)
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text("The Kiln")
                                    .font(.clayTitle(26))
                                    .foregroundColor(.white)
                                Text("Cone 6 · patience required")
                                    .font(.clayBody(13))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .background(
                                LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                               startPoint: .center, endPoint: .bottom)
                            )
                            .cornerRadius(22)
                        )

                    firingCard

                    if !store.kilnQueue.isEmpty {
                        ClaySectionHeader(title: "Waiting to fire",
                                          caption: "Pieces load automatically, one at a time")
                        ForEach(Array(store.kilnQueue.enumerated()), id: \.element.id) { index, pot in
                            queueRow(pot: pot, position: index + 1)
                        }
                    }

                    kilnNote
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .clayReadable()
            }
        }
        .sheet(item: $revealPot) { pot in
            KilnRevealSheet(pot: pot) { revealPot = nil }
        }
    }

    // MARK: Firing card

    @ViewBuilder
    private var firingCard: some View {
        if let job = store.firingJob, let pot = store.firingPot {
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let progress = job.progress(at: timeline.date)
                let done = job.isDone(at: timeline.date)
                ClayCard {
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            kilnWindow(pot: pot, progress: progress, done: done)
                                .frame(width: 108, height: 128)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(pot.displayName)
                                    .font(.clayBody(17, .bold))
                                    .foregroundColor(Studio.ink)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    ClayIcon(kind: .flame, size: 15, color: Studio.ember)
                                    Text(done ? "Firing complete" : "Firing…")
                                        .font(.clayBody(13, .bold))
                                        .foregroundColor(done ? Studio.sage : Studio.ember)
                                }
                                Text(temperatureText(progress: progress, done: done))
                                    .font(.clayBody(13))
                                    .foregroundColor(Studio.inkSoft)
                                progressBar(progress: progress)
                            }
                            Spacer(minLength: 0)
                        }
                        if done {
                            ClayPrimaryButton(title: "Open the kiln", tint: Studio.ember) {
                                if let fresh = store.collectFiredPot() {
                                    revealPot = fresh
                                }
                            }
                        }
                    }
                }
            }
        } else if store.kilnQueue.isEmpty {
            ClayCard {
                VStack(spacing: 10) {
                    CornerArt(name: "kiln_cold")
                        .scaledToFit()
                        .frame(height: 130)
                        .cornerRadius(16)
                    Text("The kiln is cold")
                        .font(.clayBody(16, .bold))
                        .foregroundColor(Studio.ink)
                    Text("Throw a pot in the Studio, glaze it, and it will show up here ready to fire.")
                        .font(.clayBody(13))
                        .foregroundColor(Studio.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func kilnWindow(pot: PotDesign, progress: Double, done: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color(red: 0.16, green: 0.09, blue: 0.07),
                        Color(red: 0.42 + 0.3 * progress, green: 0.14 + 0.16 * progress, blue: 0.06),
                    ], startPoint: .top, endPoint: .bottom)
                )
            // glow
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    RadialGradient(colors: [
                        Studio.ember.opacity(0.25 + 0.45 * progress),
                        Color.clear,
                    ], center: .bottom, startRadius: 4, endRadius: 120)
                )
            PotFigure(pot: pot, phase: 0, wet: false, showShadow: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .opacity(0.9)
                .colorMultiply(Color(red: 1.0, green: 0.62 + 0.3 * (1 - progress), blue: 0.45 + 0.5 * (1 - progress)))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Studio.woodDark, lineWidth: 3)
        }
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Studio.linen)
                Capsule()
                    .fill(LinearGradient(colors: [Studio.honey, Studio.ember],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, geo.size.width * CGFloat(progress)))
            }
        }
        .frame(height: 9)
    }

    private func temperatureText(progress: Double, done: Bool) -> String {
        if done { return "1240°C reached · cooling the reveal" }
        let temp = Int(20 + progress * 1220)
        return "\(temp)°C and climbing"
    }

    // MARK: Queue

    private func queueRow(pot: PotDesign, position: Int) -> some View {
        ClayCard(padding: 12) {
            HStack(spacing: 12) {
                PotFigure(pot: pot, phase: Double(position), wet: false, showShadow: false)
                    .frame(width: 54, height: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pot.displayName)
                        .font(.clayBody(15, .bold))
                        .foregroundColor(Studio.ink)
                        .lineLimit(1)
                    Text(coatSummary(pot))
                        .font(.clayBody(12))
                        .foregroundColor(Studio.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                ClayChip(text: "Waiting · #\(position)", tint: Studio.denim)
            }
        }
    }

    private func coatSummary(_ pot: PotDesign) -> String {
        if pot.coat.isBare { return "\(pot.clay.displayName) · bare" }
        var parts: [String] = []
        if let base = GlazeCatalog.recipe(pot.coat.baseGlazeID) { parts.append(base.name) }
        if !pot.coat.bands.isEmpty { parts.append("\(pot.coat.bands.count) band\(pot.coat.bands.count == 1 ? "" : "s")") }
        if pot.coat.rimDipGlazeID != nil { parts.append("rim dip") }
        if pot.coat.speckle { parts.append("speckle") }
        return parts.joined(separator: " · ")
    }

    private var kilnNote: some View {
        ClayCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                ClayIcon(kind: .info, size: 20, color: Studio.denim)
                Text("Real kilns fire for half a day. Ours takes half a minute — and about one piece in five comes out with a surprise crackle finish.")
                    .font(.clayBody(13))
                    .foregroundColor(Studio.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Reveal sheet

struct KilnRevealSheet: View {
    let pot: PotDesign
    let onDone: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Fresh from the kiln")
                    .font(.clayTitle(24))
                    .foregroundColor(Studio.ink)
                    .padding(.top, 26)

                SpinningPotFigure(pot: pot, speed: 0.7)
                    .frame(maxWidth: 260, maxHeight: 300)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 8) {
                    Text(pot.displayName)
                        .font(.clayBody(18, .bold))
                        .foregroundColor(Studio.ink)
                    HStack(spacing: 8) {
                        ClayChip(text: pot.clay.displayName, tint: Studio.terracotta)
                        if let base = GlazeCatalog.recipe(pot.coat.baseGlazeID) {
                            ClayChip(text: base.name, tint: Studio.denim)
                        }
                        if pot.crackle {
                            ClayChip(text: "Crackle surprise!", tint: Studio.honey)
                        }
                    }
                    if pot.crackle {
                        Text("The glaze shivered as it cooled and left a fine web of lines. Potters chase this on purpose.")
                            .font(.clayBody(13))
                            .foregroundColor(Studio.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }

                Spacer()

                ClayPrimaryButton(title: "Place in the gallery", tint: Studio.sage) {
                    onDone()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .clayReadable()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15)) {
                appeared = true
            }
        }
    }
}
