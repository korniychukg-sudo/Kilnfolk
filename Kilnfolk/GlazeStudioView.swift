import SwiftUI

// MARK: - Glaze Studio

struct GlazeStudioView: View {
    @EnvironmentObject var store: FolkStore
    @EnvironmentObject var journey: JourneyStore

    let basePot: PotDesign
    let onReturn: () -> Void
    let onSent: () -> Void

    @State private var coat = GlazeCoat()
    @State private var potName = ""
    @State private var mode: GlazeMode = .base
    @State private var selectedGlazeID: String = GlazeCatalog.all[0].id
    @State private var bandWidth: BandWidth = .medium
    @State private var previewBandCenter: Double? = nil
    @State private var lockHint: String? = nil

    enum GlazeMode: String, CaseIterable, Identifiable {
        case base, bands, rim, extras
        var id: String { rawValue }
        var label: String {
            switch self {
            case .base: return "Dip"
            case .bands: return "Bands"
            case .rim: return "Rim"
            case .extras: return "Extras"
            }
        }
    }

    enum BandWidth: String, CaseIterable, Identifiable {
        case thin, medium, wide
        var id: String { rawValue }
        var label: String {
            switch self {
            case .thin: return "Thin"
            case .medium: return "Medium"
            case .wide: return "Wide"
            }
        }
        var value: Double {
            switch self {
            case .thin: return 0.05
            case .medium: return 0.10
            case .wide: return 0.17
            }
        }
    }

    private var previewPot: PotDesign {
        var p = basePot
        p.coat = coat
        if mode == .bands, let center = previewBandCenter {
            var bands = coat.bands
            bands.append(GlazeBand(center: center, width: bandWidth.value, glazeID: selectedGlazeID))
            p.coat.bands = bands
        }
        return p
    }

    var body: some View {
        GeometryReader { geo in
            let isWide = glazeIsWide(geo.size)
            ZStack {
                Studio.linen.ignoresSafeArea()
                if isWide {
                    HStack(spacing: 0) {
                        potPreviewArea
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                header
                                controlPanel
                            }
                            .padding(16)
                        }
                        .frame(width: min(360, geo.size.width * 0.46))
                    }
                } else {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                        potPreviewArea
                            .frame(maxWidth: .infinity)
                            .frame(height: max(200, geo.size.height * 0.36))
                        ScrollView(showsIndicators: false) {
                            controlPanel
                                .padding(.horizontal, 18)
                                .padding(.bottom, 16)
                                .folkReadable()
                        }
                    }
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onReturn) {
                HStack(spacing: 5) {
                    FolkIcon(kind: .chevronLeft, size: 15, color: Studio.ink)
                    Text("Wheel")
                        .font(.folkBody(14, .bold))
                        .foregroundColor(Studio.ink)
                        .lineLimit(1)
                }
                .fixedSize()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Studio.card))
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
            VStack(spacing: 1) {
                Text("Glaze Studio")
                    .font(.folkTitle(20))
                    .foregroundColor(Studio.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(basePot.clay.displayName)
                    .font(.folkBody(11))
                    .foregroundColor(Studio.inkSoft)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            Spacer()
            Color.clear.frame(width: 74, height: 10)
        }
    }

    // MARK: Pot preview

    private var potPreviewArea: some View {
        GeometryReader { geo in
            let potRect = potPreviewRect(geo.size)
            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    Canvas { ctx, _ in
                        PotPainter.drawInRect(&ctx, rect: potRect, pot: previewPot,
                                              phase: timeline.date.timeIntervalSinceReferenceDate * 0.8,
                                              wet: false, showShadow: true)
                    }
                }
                if mode == .bands {
                    Text(coat.bands.count >= 6 ? "Six bands is plenty — remove one below" : "Drag on the pot to paint a band")
                        .font(.folkBody(11, .bold))
                        .foregroundColor(Studio.inkSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Studio.card.opacity(0.9)))
                        .position(x: geo.size.width / 2, y: 14)
                }
            }
            .contentShape(Rectangle())
            .gesture(bandGesture(potRect: potRect))
        }
    }

    private func glazeIsWide(_ size: CGSize) -> Bool {
        size.width > size.height * 1.15
    }

    private func potPreviewRect(_ size: CGSize) -> CGRect {
        let w = min(size.width * 0.62, 380)
        let h = min(size.height - 26, w * 1.3)
        return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2 + 6, width: w, height: h)
    }

    private func bandGesture(potRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard mode == .bands, coat.bands.count < 6 else { return }
                let geoPot = PotGeometry(rect: potRect, profile: basePot.profile, heightScale: basePot.heightScale)
                let t = geoPot.tAt(y: value.location.y)
                guard t > -0.1 && t < 1.1 else {
                    previewBandCenter = nil
                    return
                }
                previewBandCenter = min(0.96, max(0.06, t))
            }
            .onEnded { _ in
                guard mode == .bands, let center = previewBandCenter else { return }
                previewBandCenter = nil
                guard coat.bands.count < 6 else { return }
                coat.bands.append(GlazeBand(center: center, width: bandWidth.value, glazeID: selectedGlazeID))
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
    }

    // MARK: Controls

    private var controlPanel: some View {
        VStack(spacing: 12) {
            modePicker
            paletteRow
            modeDetails
            nameField
            FolkPrimaryButton(title: "Into the kiln", tint: Studio.ember) {
                var pot = basePot
                pot.coat = coat
                pot.name = potName
                pot.createdAt = Date()
                store.sendToKiln(pot)
                onSent()
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(GlazeMode.allCases) { m in
                let selected = mode == m
                Button(action: { mode = m }) {
                    Text(m.label)
                        .font(.folkBody(13, .bold))
                        .foregroundColor(selected ? .white : Studio.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(selected ? Studio.terracotta : Color.clear))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Capsule().fill(Studio.card))
    }

    private var showsPalette: Bool { mode != .extras }

    @ViewBuilder
    private var paletteRow: some View {
        if showsPalette {
            VStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(GlazeCatalog.all) { glaze in
                            glazeSwatch(glaze)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                }
                if let hint = lockHint {
                    Text(hint)
                        .font(.folkBody(11, .bold))
                        .foregroundColor(Studio.denim)
                        .transition(.opacity)
                }
            }
        }
    }

    private func glazeSwatch(_ glaze: GlazeRecipe) -> some View {
        let selected = selectedGlazeID == glaze.id
        let unlocked = journey.isGlazeUnlocked(glaze.id)
        return Button(action: {
            guard unlocked else {
                let lvl = journey.glazeUnlockLevel(glaze.id)
                let rank = JourneyStore.ranks.first(where: { $0.level == lvl })?.name ?? ""
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockHint = "\(glaze.name) unlocks at rank \(lvl) · \(rank)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    withAnimation(.easeInOut(duration: 0.4)) { lockHint = nil }
                }
                return
            }
            selectedGlazeID = glaze.id
            switch mode {
            case .base: coat.baseGlazeID = glaze.id
            case .rim: coat.rimDipGlazeID = glaze.id
            default: break
            }
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(glaze.fired.color)
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(glaze.wet.color)
                        .frame(width: 40, height: 40)
                        .mask(
                            Rectangle().frame(width: 20).frame(maxWidth: .infinity, alignment: .leading)
                        )
                    if glaze.speckled {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 2.5, height: 2.5)
                                .offset(x: CGFloat(i * 7 - 7), y: CGFloat((i % 2) * 8 - 4))
                        }
                    }
                }
                .overlay(
                    Circle().stroke(selected && unlocked ? Studio.ink : Studio.ink.opacity(0.15),
                                    lineWidth: selected && unlocked ? 2.5 : 1)
                )
                .opacity(unlocked ? 1 : 0.32)
                .overlay(
                    Group {
                        if !unlocked {
                            VStack(spacing: 0) {
                                FolkIcon(kind: .shield, size: 13, color: Studio.denim)
                                Text("\(journey.glazeUnlockLevel(glaze.id))")
                                    .font(.folkBody(9, .bold))
                                    .foregroundColor(Studio.denim)
                            }
                            .padding(5)
                            .background(Circle().fill(Studio.card.opacity(0.92)))
                        }
                    }
                )
                Text(glaze.name)
                    .font(.folkBody(10, .bold))
                    .foregroundColor(unlocked ? (selected ? Studio.ink : Studio.inkSoft) : Studio.inkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var modeDetails: some View {
        switch mode {
        case .base:
            FolkCard(padding: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Base dip")
                            .font(.folkBody(14, .bold))
                            .foregroundColor(Studio.ink)
                        Text(coat.baseGlazeID == nil
                             ? "Bare clay — tap a glaze above to dip the whole pot"
                             : "Dipped in \(GlazeCatalog.recipe(coat.baseGlazeID)?.name ?? "")")
                            .font(.folkBody(12))
                            .foregroundColor(Studio.inkSoft)
                    }
                    Spacer()
                    if coat.baseGlazeID != nil {
                        Button(action: { coat.baseGlazeID = nil }) {
                            FolkChip(text: "Bare clay", tint: Studio.denim)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        case .bands:
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(BandWidth.allCases) { bw in
                        let selected = bandWidth == bw
                        Button(action: { bandWidth = bw }) {
                            Text(bw.label)
                                .font(.folkBody(12, .bold))
                                .foregroundColor(selected ? .white : Studio.inkSoft)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(selected ? Studio.sage : Studio.card))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                if !coat.bands.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(coat.bands) { band in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(GlazeCatalog.recipe(band.glazeID)?.fired.color ?? Studio.linen)
                                    .frame(width: 18, height: 18)
                                Text(GlazeCatalog.recipe(band.glazeID)?.name ?? "Band")
                                    .font(.folkBody(13, .bold))
                                    .foregroundColor(Studio.ink)
                                Text(heightWord(band.center))
                                    .font(.folkBody(12))
                                    .foregroundColor(Studio.inkSoft)
                                Spacer()
                                Button(action: { coat.bands.removeAll { $0.id == band.id } }) {
                                    FolkIcon(kind: .close, size: 14, color: Studio.inkSoft)
                                        .padding(6)
                                        .background(Circle().fill(Studio.linen))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Studio.card))
                        }
                    }
                }
            }
        case .rim:
            FolkCard(padding: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Rim dip")
                            .font(.folkBody(14, .bold))
                            .foregroundColor(Studio.ink)
                        Text(coat.rimDipGlazeID == nil
                             ? "Tap a glaze above to dip just the rim"
                             : "Rim dipped in \(GlazeCatalog.recipe(coat.rimDipGlazeID)?.name ?? "")")
                            .font(.folkBody(12))
                            .foregroundColor(Studio.inkSoft)
                    }
                    Spacer()
                    if coat.rimDipGlazeID != nil {
                        Button(action: { coat.rimDipGlazeID = nil }) {
                            FolkChip(text: "Remove", tint: Studio.denim)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        case .extras:
            VStack(spacing: 10) {
                FolkCard(padding: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Speckle dust")
                                .font(.folkBody(14, .bold))
                                .foregroundColor(Studio.ink)
                            Text("A pinch of iron flecks scattered over the glaze")
                                .font(.folkBody(12))
                                .foregroundColor(Studio.inkSoft)
                        }
                        Spacer()
                        Button(action: { coat.speckle.toggle() }) {
                            ZStack {
                                Capsule()
                                    .fill(coat.speckle ? Studio.sage : Studio.inkFaint)
                                    .frame(width: 46, height: 27)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                                    .offset(x: coat.speckle ? 9 : -9)
                            }
                            .animation(.easeInOut(duration: 0.18), value: coat.speckle)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Button(action: { coat = GlazeCoat() }) {
                    Text("Wash off all glaze")
                        .font(.folkBody(13, .bold))
                        .foregroundColor(Studio.denim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Studio.card))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func heightWord(_ t: Double) -> String {
        switch t {
        case ..<0.3: return "near the foot"
        case ..<0.6: return "at the belly"
        case ..<0.85: return "at the shoulder"
        default: return "near the rim"
        }
    }

    private var nameField: some View {
        HStack(spacing: 10) {
            FolkIcon(kind: .sparkle, size: 16, color: Studio.honey)
            TextField("Name your piece (optional)", text: $potName)
                .font(.folkBody(15))
                .foregroundColor(Studio.ink)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Studio.card))
    }
}
