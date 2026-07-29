import SwiftUI

struct KilnRevealData: Identifiable {
    let pot: PotDesign
    let summary: RevealSummary
    var id: UUID { pot.id }
}

struct KilnView: View {
    @EnvironmentObject var store: FolkStore
    @EnvironmentObject var journey: JourneyStore
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @State private var reveal: KilnRevealData? = nil

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    FolkArt(name: "kiln_banner")
                        .scaledToFill()
                        .frame(height: FolkLayout.bannerHeight(hSize, vSize))
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(22)
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text("The Kiln")
                                    .font(.folkTitle(26))
                                    .foregroundColor(.white)
                                Text("Cone 6 · patience required")
                                    .font(.folkBody(13))
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
                        FolkSectionHeader(title: "Waiting to fire",
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
                .folkReadable()
            }
        }
        .sheet(item: $reveal) { data in
            KilnRevealSheet(pot: data.pot, summary: data.summary) { reveal = nil }
        }
    }

    // MARK: Firing card

    @ViewBuilder
    private var firingCard: some View {
        if let job = store.firingJob, let pot = store.firingPot {
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                let progress = job.progress(at: timeline.date)
                let done = job.isDone(at: timeline.date)
                FolkCard {
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            kilnWindow(pot: pot, progress: progress, done: done)
                                .frame(width: 108, height: 128)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(pot.displayName)
                                    .font(.folkBody(17, .bold))
                                    .foregroundColor(Studio.ink)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    FolkIcon(kind: .flame, size: 15, color: Studio.ember)
                                    Text(done ? "Firing complete" : "Firing…")
                                        .font(.folkBody(13, .bold))
                                        .foregroundColor(done ? Studio.sage : Studio.ember)
                                }
                                Text(temperatureText(progress: progress, done: done))
                                    .font(.folkBody(13))
                                    .foregroundColor(Studio.inkSoft)
                                progressBar(progress: progress)
                            }
                            Spacer(minLength: 0)
                        }
                        if done {
                            FolkPrimaryButton(title: "Open the kiln", tint: Studio.ember) {
                                if let fresh = store.collectFiredPot() {
                                    let summary = journey.registerFiredPot(
                                        fresh,
                                        firedTotal: store.stats.fired,
                                        crackleTotal: store.galleryPots.filter { $0.crackle }.count)
                                    reveal = KilnRevealData(pot: fresh, summary: summary)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                            }
                        }
                    }
                }
            }
        } else if store.kilnQueue.isEmpty {
            FolkCard {
                VStack(spacing: 10) {
                    FolkArt(name: "kiln_cold")
                        .scaledToFit()
                        .frame(height: 130)
                        .cornerRadius(16)
                    Text("The kiln is cold")
                        .font(.folkBody(16, .bold))
                        .foregroundColor(Studio.ink)
                    Text("Throw a pot in the Studio, glaze it, and it will show up here ready to fire.")
                        .font(.folkBody(13))
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
        FolkCard(padding: 12) {
            HStack(spacing: 12) {
                PotFigure(pot: pot, phase: Double(position), wet: false, showShadow: false)
                    .frame(width: 54, height: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pot.displayName)
                        .font(.folkBody(15, .bold))
                        .foregroundColor(Studio.ink)
                        .lineLimit(1)
                    Text(coatSummary(pot))
                        .font(.folkBody(12))
                        .foregroundColor(Studio.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                FolkChip(text: "Waiting · #\(position)", tint: Studio.denim)
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
        FolkCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                FolkIcon(kind: .info, size: 20, color: Studio.denim)
                Text("Real kilns fire for half a day. Ours takes half a minute — and about one piece in five comes out with a surprise crackle finish.")
                    .font(.folkBody(13))
                    .foregroundColor(Studio.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Reveal sheet

struct KilnRevealSheet: View {
    let pot: PotDesign
    let summary: RevealSummary
    let onDone: () -> Void
    @State private var appeared = false
    @State private var linesShown = 0

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Text("Fresh from the kiln")
                        .font(.folkTitle(24))
                        .foregroundColor(Studio.ink)
                        .padding(.top, 24)

                    SpinningPotFigure(pot: pot, speed: 0.7)
                        .frame(height: 230)
                        .frame(maxWidth: 240)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text(pot.displayName)
                            .font(.folkBody(18, .bold))
                            .foregroundColor(Studio.ink)
                        HStack(spacing: 8) {
                            FolkChip(text: pot.clay.displayName, tint: Studio.terracotta)
                            if let base = GlazeCatalog.recipe(pot.coat.baseGlazeID) {
                                FolkChip(text: base.name, tint: Studio.denim)
                            }
                            if pot.crackle {
                                FolkChip(text: "Crackle surprise!", tint: Studio.honey)
                            }
                        }
                    }

                    if let formName = summary.formName {
                        formResultCard(formName)
                    }

                    xpCard

                    if summary.newLevel > summary.oldLevel {
                        rankUpCard
                    }

                    ForEach(summary.newBadges) { badge in
                        badgeCard(badge)
                    }

                    if pot.crackle {
                        Text("The glaze shivered as it cooled and left a fine web of lines. Potters chase this on purpose.")
                            .font(.folkBody(13))
                            .foregroundColor(Studio.inkSoft)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    FolkPrimaryButton(title: "Place in the gallery", tint: Studio.sage) {
                        onDone()
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
                .folkReadable()
            }

            ConfettiBurst(seed: pot.artSeed)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15)) {
                appeared = true
            }
            for i in 0...summary.xpLines.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.28) {
                    withAnimation(.easeOut(duration: 0.3)) { linesShown = i }
                }
            }
        }
    }

    private func formResultCard(_ formName: String) -> some View {
        FolkCard(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(formName)
                        .font(.folkBody(15, .bold))
                        .foregroundColor(Studio.ink)
                    Text(summary.stars > 0
                         ? "Fit \(Int((summary.fit * 100).rounded()))% — the form holds!"
                         : "Fit \(Int((summary.fit * 100).rounded()))% — not quite this time. Throw it again!")
                        .font(.folkBody(12))
                        .foregroundColor(Studio.inkSoft)
                    if summary.dailyDone {
                        HStack(spacing: 4) {
                            FolkIcon(kind: .flame, size: 12, color: Studio.ember)
                            Text("Form of the day · \(summary.dailyStreak)-day streak")
                                .font(.folkBody(12, .bold))
                                .foregroundColor(Studio.ember)
                        }
                    }
                }
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        FolkIcon(kind: i < summary.stars ? .starFill : .star, size: 22,
                                 color: i < summary.stars ? Studio.honey : Studio.inkFaint)
                    }
                }
            }
        }
    }

    private var xpCard: some View {
        FolkCard(padding: 14) {
            VStack(spacing: 8) {
                ForEach(Array(summary.xpLines.enumerated()), id: \.offset) { i, line in
                    HStack {
                        Text(line.label)
                            .font(.folkBody(13))
                            .foregroundColor(Studio.inkSoft)
                        Spacer()
                        Text("+\(line.xp) XP")
                            .font(.folkBody(13, .bold))
                            .foregroundColor(Studio.sage)
                    }
                    .opacity(i < linesShown ? 1 : 0)
                }
                Rectangle().fill(Studio.linen).frame(height: 1)
                HStack {
                    Text("Journey")
                        .font(.folkBody(14, .bold))
                        .foregroundColor(Studio.ink)
                    Spacer()
                    Text("+\(summary.totalXP) XP")
                        .font(.folkTitle(17))
                        .foregroundColor(Studio.terracotta)
                }
            }
        }
    }

    private var rankUpCard: some View {
        let rankName = JourneyStore.ranks.first(where: { $0.level == summary.newLevel })?.name ?? ""
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                FolkIcon(kind: .sparkle, size: 18, color: .white)
                Text("Rank up! \(rankName)")
                    .font(.folkBody(16, .bold))
                    .foregroundColor(.white)
                FolkIcon(kind: .sparkle, size: 18, color: .white)
            }
            if !summary.unlockedGlazes.isEmpty || !summary.unlockedClays.isEmpty {
                VStack(spacing: 6) {
                    ForEach(summary.unlockedGlazes) { glaze in
                        HStack(spacing: 8) {
                            Circle().fill(glaze.fired.color).frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                            Text("New glaze unlocked: \(glaze.name)")
                                .font(.folkBody(13, .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    ForEach(summary.unlockedClays) { kind in
                        HStack(spacing: 8) {
                            Circle().fill(kind.wetTone.color).frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                            Text("New clay unlocked: \(kind.displayName)")
                                .font(.folkBody(13, .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Studio.terracotta, Studio.ember],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Studio.shadow, radius: 10, x: 0, y: 5)
        )
    }

    private func badgeCard(_ badge: JourneyBadge) -> some View {
        FolkCard(padding: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Studio.honey.opacity(0.2)).frame(width: 44, height: 44)
                    Circle().stroke(Studio.honey, lineWidth: 2).frame(width: 44, height: 44)
                    FolkIcon(kind: .starFill, size: 20, color: Studio.honey)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Award earned")
                        .font(.folkBody(11, .bold))
                        .foregroundColor(Studio.honey)
                    Text(badge.title)
                        .font(.folkBody(15, .bold))
                        .foregroundColor(Studio.ink)
                    Text(badge.hint)
                        .font(.folkBody(12))
                        .foregroundColor(Studio.inkSoft)
                }
                Spacer()
            }
        }
    }
}
