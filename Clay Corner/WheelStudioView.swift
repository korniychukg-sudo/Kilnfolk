import SwiftUI

// MARK: - Tools & speeds

enum WheelTool: String, CaseIterable, Identifiable {
    case hands, sponge, rib, lift

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hands: return "Fingers"
        case .sponge: return "Sponge"
        case .rib: return "Rib"
        case .lift: return "Lift"
        }
    }

    var icon: ClayIconKind {
        switch self {
        case .hands: return .hand
        case .sponge: return .sponge
        case .rib: return .rib
        case .lift: return .pull
        }
    }

    var hint: String {
        switch self {
        case .hands: return "Press the wall sideways to push it in or pull it out"
        case .sponge: return "Rub gently to soften and smooth the curves"
        case .rib: return "Drag to flatten the wall into a clean straight line"
        case .lift: return "Drag up to raise the pot, down to squash it"
        }
    }
}

enum WheelSpeed: String, CaseIterable, Identifiable {
    case stop, slow, fast

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stop: return "Stop"
        case .slow: return "Slow"
        case .fast: return "Fast"
        }
    }

    var radiansPerSecond: Double {
        switch self {
        case .stop: return 0
        case .slow: return 1.7
        case .fast: return 3.6
        }
    }
}

struct WheelSnapshot: Equatable {
    var profile: [Double]
    var heightScale: Double
}

private struct SceneLayout {
    var potRect: CGRect
    var wheelCenter: CGPoint
    var wheelRX: CGFloat
    var wheelRY: CGFloat
}

// MARK: - The Wheel

struct SlipParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var born: TimeInterval
    var tint: Double
}

struct WheelStudioView: View {
    @EnvironmentObject var store: ClayStore
    @EnvironmentObject var journey: JourneyStore
    @Binding var selectedTab: Int

    @State private var profile: [Double] = PotShapes.freshLump()
    @State private var heightScale: Double = 0.8
    @State private var clay: ClayBodyKind = .terracotta
    @State private var tool: WheelTool = .hands
    @State private var wheelSpeed: WheelSpeed = .slow
    @State private var undoStack: [WheelSnapshot] = []
    @State private var lastTouch: CGPoint? = nil
    @State private var showClayPicker = false
    @State private var showResetConfirm = false
    @State private var showGlazeStudio = false
    @State private var stoppedHint = false
    @State private var didLoadDraft = false
    @State private var phaseAnchor: Double = 0
    @State private var anchorTime = Date()
    @State private var ghostOn = true
    @State private var particles: [SlipParticle] = []

    private var shapedEnough: Bool {
        PotShapes.shapingAmount(profile) > 0.035
    }

    private var activeForm: PotForm? {
        FormLibrary.form(journey.activeFormID)
    }

    private var liveFit: Double {
        guard let form = activeForm else { return 0 }
        return FormScoring.fit(profile: profile, heightScale: heightScale, form: form)
    }

    private var wipPot: PotDesign {
        var p = PotDesign(clay: clay, profile: profile, heightScale: heightScale)
        if let form = activeForm {
            p.formID = form.id
            p.formStars = FormScoring.stars(fit: liveFit)
        }
        return p
    }

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > geo.size.height * 1.15
            ZStack {
                Studio.cream.ignoresSafeArea()
                if isWide {
                    HStack(spacing: 0) {
                        sceneArea
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(spacing: 14) {
                            header
                            Spacer(minLength: 0)
                            controls
                        }
                        .padding(16)
                        .frame(width: min(330, geo.size.width * 0.42))
                    }
                } else {
                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                        sceneArea
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        controls
                            .padding(.horizontal, 18)
                            .padding(.bottom, 10)
                            .clayReadable()
                    }
                }
            }
        }
        .onAppear(perform: restoreDraft)
        .sheet(isPresented: $showClayPicker) { clayPickerSheet }
        .fullScreenCover(isPresented: $showGlazeStudio) {
            GlazeStudioView(
                basePot: wipPot,
                onReturn: { showGlazeStudio = false },
                onSent: {
                    showGlazeStudio = false
                    journey.activeFormID = nil
                    freshLump()
                    store.clearDraft()
                    selectedTab = 1
                }
            )
            .environmentObject(store)
            .environmentObject(journey)
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Fresh clay?"),
                  message: Text("The current piece will be squashed back into a lump."),
                  primaryButton: .destructive(Text("Squash it"), action: freshLump),
                  secondaryButton: .cancel(Text("Keep shaping")))
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("The Wheel")
                    .font(.clayTitle(26))
                    .foregroundColor(Studio.ink)
                Text("Shape it with your finger")
                    .font(.clayBody(13))
                    .foregroundColor(Studio.inkSoft)
            }
            Spacer()
            Button(action: undo) {
                ClayIcon(kind: .undo, size: 21, color: undoStack.isEmpty ? Studio.inkFaint : Studio.ink)
                    .padding(9)
                    .background(Circle().fill(Studio.card))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(undoStack.isEmpty)
            Button(action: { showResetConfirm = true }) {
                ClayIcon(kind: .reset, size: 21, color: Studio.ink)
                    .padding(9)
                    .background(Circle().fill(Studio.card))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: Scene

    private var sceneArea: some View {
        GeometryReader { geo in
            let layout = sceneLayout(geo.size)
            ZStack {
                CornerArt(name: "studio_backdrop")
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.9)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    Canvas { ctx, size in
                        let phase = currentPhase(at: timeline.date)
                        drawWheel(&ctx, layout: layout, phase: phase)
                        PotPainter.drawInRect(&ctx, rect: layout.potRect, pot: wipPot,
                                              phase: phase, wet: true, showShadow: false)
                        if let form = activeForm, ghostOn {
                            drawGhost(&ctx, form: form, layout: layout)
                        }
                        drawParticles(&ctx, now: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)

                VStack {
                    if let form = activeForm {
                        challengeBanner(form)
                    } else {
                        dailyChip
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Text("H \(PotMeasure.heightCM(heightScale)) cm · W \(PotMeasure.widthCM(profile)) cm")
                            .font(.clayBody(11, .bold))
                            .foregroundColor(Studio.inkSoft)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Studio.card.opacity(0.88)))
                            .padding(.trailing, 10)
                            .padding(.bottom, 6)
                    }
                }
                .padding(.top, 8)

                if stoppedHint {
                    Text("Press a pedal below to spin the wheel")
                        .font(.clayBody(13, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Studio.ink.opacity(0.82)))
                        .transition(.opacity)
                        .position(x: geo.size.width / 2, y: layout.potRect.minY + 18)
                }
            }
            .contentShape(Rectangle())
            .gesture(shapingGesture(layout: layout))
        }
        .clipped()
    }

    private func sceneLayout(_ size: CGSize) -> SceneLayout {
        let wheelRX = min(size.width * 0.40, 185)
        let wheelRY = wheelRX * 0.26
        let center = CGPoint(x: size.width / 2, y: size.height - wheelRY - 18)
        let potW = wheelRX * 1.66
        let topPad: CGFloat = 26
        let potRect = CGRect(x: center.x - potW / 2, y: topPad,
                             width: potW, height: center.y - topPad - wheelRY * 0.42)
        return SceneLayout(potRect: potRect, wheelCenter: center, wheelRX: wheelRX, wheelRY: wheelRY)
    }

    private func drawGhost(_ ctx: inout GraphicsContext, form: PotForm, layout: SceneLayout) {
        let geo = PotGeometry(rect: layout.potRect, profile: form.targetProfile,
                              heightScale: form.targetHeight)
        let path = geo.slicePath(0, 1)
        ctx.stroke(path, with: .color(Studio.denim.opacity(0.75)),
                   style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [7, 6]))
    }

    private func drawParticles(_ ctx: inout GraphicsContext, now: TimeInterval) {
        for p in particles {
            let age = now - p.born
            guard age >= 0 && age < 0.7 else { continue }
            let t = age / 0.7
            let x = p.x + p.vx * CGFloat(age)
            let y = p.y + p.vy * CGFloat(age) + CGFloat(age * age) * 220
            let size = 4.5 * (1 - t) + 1.5
            let tone = clay.wetTone
            let color = Color(red: tone.r + p.tint, green: tone.g + p.tint, blue: tone.b + p.tint)
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: size, height: size)),
                     with: .color(color.opacity(0.75 * (1 - t))))
        }
    }

    private func spawnParticles(at point: CGPoint, intensity: Double) {
        let now = Date().timeIntervalSinceReferenceDate
        let count = intensity > 0.5 ? 3 : 2
        for _ in 0..<count {
            particles.append(SlipParticle(
                x: point.x, y: point.y,
                vx: CGFloat.random(in: -70...70),
                vy: CGFloat.random(in: -120 ... -30),
                born: now,
                tint: Double.random(in: -0.06...0.10)))
        }
        if particles.count > 60 {
            particles.removeFirst(particles.count - 60)
        }
    }

    private func challengeBanner(_ form: PotForm) -> some View {
        let fit = liveFit
        let stars = FormScoring.stars(fit: fit)
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(form.name)
                    .font(.clayBody(13, .bold))
                    .foregroundColor(Studio.ink)
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        ClayIcon(kind: i < stars ? .starFill : .star, size: 11,
                                 color: i < stars ? Studio.honey : Studio.inkFaint)
                    }
                }
            }
            Text("\(Int((fit * 100).rounded()))%")
                .font(.clayTitle(19))
                .foregroundColor(fit >= 0.78 ? Studio.sage : Studio.terracotta)
                .frame(minWidth: 46)
            Button(action: { ghostOn.toggle() }) {
                Text(ghostOn ? "Hide guide" : "Show guide")
                    .font(.clayBody(11, .bold))
                    .foregroundColor(Studio.denim)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Studio.denim.opacity(0.12)))
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: {
                journey.activeFormID = nil
            }) {
                ClayIcon(kind: .close, size: 13, color: Studio.inkSoft)
                    .padding(7)
                    .background(Circle().fill(Studio.linen))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Studio.card.opacity(0.95)))
        .shadow(color: Studio.shadow, radius: 6, x: 0, y: 3)
    }

    private var dailyChip: some View {
        let form = journey.formOfTheDay()
        let done = journey.dailyDone()
        return Button(action: {
            if !done { journey.activeFormID = form.id }
        }) {
            HStack(spacing: 7) {
                ClayIcon(kind: done ? .check : .sparkle, size: 14,
                         color: done ? Studio.sage : Studio.honey)
                Text(done ? "Form of the day done!" : "Form of the day: \(form.name)")
                    .font(.clayBody(12, .bold))
                    .foregroundColor(Studio.ink)
                if journey.state.dailyStreak > 0 {
                    HStack(spacing: 3) {
                        ClayIcon(kind: .flame, size: 12, color: Studio.ember)
                        Text("\(journey.state.dailyStreak)")
                            .font(.clayBody(12, .bold))
                            .foregroundColor(Studio.ember)
                    }
                }
                if !done {
                    ClayIcon(kind: .chevronRight, size: 11, color: Studio.inkFaint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Studio.card.opacity(0.95)))
            .shadow(color: Studio.shadow, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func drawWheel(_ ctx: inout GraphicsContext, layout: SceneLayout, phase: Double) {
        let c = layout.wheelCenter
        let rx = layout.wheelRX, ry = layout.wheelRY

        // shadow
        let shadowRect = CGRect(x: c.x - rx * 1.12, y: c.y + ry * 0.35, width: rx * 2.24, height: ry * 1.1)
        ctx.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.14)))

        // splash pan behind the wheel head
        let panRect = CGRect(x: c.x - rx * 1.22, y: c.y - ry * 0.55, width: rx * 2.44, height: ry * 2.3)
        ctx.fill(Path(ellipseIn: panRect), with: .color(Color(red: 0.47, green: 0.36, blue: 0.28)))
        ctx.stroke(Path(ellipseIn: panRect), with: .color(Color.white.opacity(0.10)), lineWidth: 2)

        // wheel side (thickness)
        let sideRect = CGRect(x: c.x - rx, y: c.y - ry + ry * 0.55, width: rx * 2, height: ry * 2)
        ctx.fill(Path(ellipseIn: sideRect), with: .color(Color(red: 0.24, green: 0.22, blue: 0.23)))

        // wheel head
        let headRect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
        let headGradient = Gradient(stops: [
            .init(color: Color(red: 0.40, green: 0.38, blue: 0.40), location: 0),
            .init(color: Color(red: 0.30, green: 0.28, blue: 0.30), location: 1),
        ])
        ctx.fill(Path(ellipseIn: headRect),
                 with: .linearGradient(headGradient,
                                       startPoint: CGPoint(x: c.x, y: c.y - ry),
                                       endPoint: CGPoint(x: c.x, y: c.y + ry)))
        ctx.stroke(Path(ellipseIn: headRect), with: .color(Color.white.opacity(0.14)), lineWidth: 1.2)

        // slip ring on the head
        let ringRect = CGRect(x: c.x - rx * 0.72, y: c.y - ry * 0.72, width: rx * 1.44, height: ry * 1.44)
        ctx.stroke(Path(ellipseIn: ringRect), with: .color(Color.white.opacity(0.08)), lineWidth: 3)

        // rotation markers
        for i in 0..<5 {
            let theta = phase + Double(i) * (.pi * 2 / 5)
            let s = sin(theta), co = cos(theta)
            let x = c.x + CGFloat(s) * rx * 0.84
            let y = c.y + CGFloat(co) * ry * 0.84
            let near = (co + 1) / 2
            let d = 2.4 + CGFloat(near) * 2.6
            ctx.fill(Path(ellipseIn: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d * 0.7)),
                     with: .color(Color.white.opacity(0.10 + 0.22 * near)))
        }
    }

    // MARK: Gesture & shaping

    private func shapingGesture(layout: SceneLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard wheelSpeed != .stop else {
                    if !stoppedHint {
                        withAnimation(.easeInOut(duration: 0.25)) { stoppedHint = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.4)) { stoppedHint = false }
                        }
                    }
                    return
                }
                guard let last = lastTouch else {
                    undoStack.append(WheelSnapshot(profile: profile, heightScale: heightScale))
                    if undoStack.count > 30 { undoStack.removeFirst() }
                    lastTouch = value.location
                    return
                }
                applyShaping(current: value.location, last: last, layout: layout)
                let speed = abs(value.location.x - last.x) + abs(value.location.y - last.y)
                if speed > 1.2 {
                    spawnParticles(at: value.location, intensity: Double(min(1, speed / 14)))
                }
                lastTouch = value.location
            }
            .onEnded { _ in
                lastTouch = nil
                store.saveDraft(profile: profile, heightScale: heightScale, clay: clay)
            }
    }

    private func applyShaping(current: CGPoint, last: CGPoint, layout: SceneLayout) {
        let geoPot = PotGeometry(rect: layout.potRect, profile: profile, heightScale: heightScale)
        let tRaw = geoPot.tAt(y: current.y)
        guard tRaw > -0.10 && tRaw < 1.12 else { return }
        let t = min(1, max(0, tRaw))
        let n = profile.count
        let fi = t * Double(n - 1)
        let dx = Double(current.x - last.x)
        let dy = Double(current.y - last.y)
        let side: Double = current.x >= layout.potRect.midX ? 1 : -1
        let drNorm = side * dx / Double(geoPot.maxHalfW)

        switch tool {
        case .hands:
            let sigma = 2.3
            for i in 0..<n {
                let wgt = exp(-pow(Double(i) - fi, 2) / (2 * sigma * sigma))
                profile[i] += drNorm * wgt * 0.85
            }
        case .sponge:
            let sigma = 3.0
            let strength = min(1.0, abs(drNorm) * 6 + abs(dy) / 70 + 0.10)
            var next = profile
            for i in 1..<(n - 1) {
                let wgt = exp(-pow(Double(i) - fi, 2) / (2 * sigma * sigma))
                let avg = (profile[i - 1] + profile[i] + profile[i + 1]) / 3
                next[i] += (avg - next[i]) * wgt * strength * 0.9
            }
            profile = next
        case .rib:
            let sigma = 3.4
            var wsum = 0.0, rsum = 0.0
            for i in 0..<n {
                let wgt = exp(-pow(Double(i) - fi, 2) / (2 * sigma * sigma))
                wsum += wgt
                rsum += profile[i] * wgt
            }
            guard wsum > 0 else { return }
            let target = rsum / wsum
            let strength = min(1.0, abs(drNorm) * 8 + abs(dy) / 90 + 0.10)
            for i in 0..<n {
                let wgt = exp(-pow(Double(i) - fi, 2) / (2 * sigma * sigma))
                profile[i] += (target - profile[i]) * wgt * strength * 0.5
            }
        case .lift:
            let old = heightScale
            heightScale = min(1.0, max(0.55, heightScale - dy / 520))
            let ratio = old / heightScale
            if abs(ratio - 1) > 0.0001 {
                for i in 0..<n {
                    profile[i] = profile[i] * pow(ratio, 0.35)
                }
            }
        }

        for i in 0..<n { profile[i] = min(1.0, max(0.10, profile[i])) }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 12) {
            Text(tool.hint)
                .font(.clayBody(12))
                .foregroundColor(Studio.inkSoft)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(WheelTool.allCases) { item in
                    toolButton(item)
                }
            }

            HStack(spacing: 10) {
                clayButton
                pedal
            }

            ClayPrimaryButton(title: shapedEnough ? "Glaze this piece" : "Shape the clay first…",
                              enabled: shapedEnough) {
                showGlazeStudio = true
            }
        }
    }

    private func toolButton(_ item: WheelTool) -> some View {
        let selected = tool == item
        return Button(action: {
            tool = item
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 4) {
                ClayIcon(kind: item.icon, size: 22, color: selected ? .white : Studio.ink)
                Text(item.label)
                    .font(.clayBody(11, .bold))
                    .foregroundColor(selected ? .white : Studio.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Studio.terracotta : Studio.card)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var clayButton: some View {
        Button(action: { showClayPicker = true }) {
            HStack(spacing: 7) {
                Circle()
                    .fill(clay.wetTone.color)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Studio.ink.opacity(0.2), lineWidth: 1))
                Text(clay.displayName)
                    .font(.clayBody(13, .bold))
                    .foregroundColor(Studio.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Capsule().fill(Studio.card))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var pedal: some View {
        HStack(spacing: 4) {
            ForEach(WheelSpeed.allCases) { speed in
                let selected = wheelSpeed == speed
                Button(action: { setSpeed(speed) }) {
                    Text(speed.label)
                        .font(.clayBody(13, .bold))
                        .foregroundColor(selected ? .white : Studio.inkSoft)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selected ? Studio.sage : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Capsule().fill(Studio.card))
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private func setSpeed(_ speed: WheelSpeed) {
        let now = Date()
        phaseAnchor = currentPhase(at: now)
        anchorTime = now
        wheelSpeed = speed
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func currentPhase(at date: Date) -> Double {
        phaseAnchor + date.timeIntervalSince(anchorTime) * wheelSpeed.radiansPerSecond
    }

    private func undo() {
        guard let snap = undoStack.popLast() else { return }
        profile = snap.profile
        heightScale = snap.heightScale
        store.saveDraft(profile: profile, heightScale: heightScale, clay: clay)
    }

    private func freshLump() {
        profile = PotShapes.freshLump()
        heightScale = 0.8
        undoStack = []
        store.clearDraft()
    }

    private func restoreDraft() {
        guard !didLoadDraft else { return }
        didLoadDraft = true
        if let d = store.draft, d.profile.count == PotShapes.sampleCount {
            profile = d.profile
            heightScale = d.heightScale
            clay = d.clay
        }
    }

    // MARK: Clay picker

    private var clayPickerSheet: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Text("Choose your clay")
                        .font(.clayTitle(22))
                        .foregroundColor(Studio.ink)
                    Spacer()
                    Button(action: { showClayPicker = false }) {
                        ClayIcon(kind: .close, size: 18, color: Studio.ink)
                            .padding(8)
                            .background(Circle().fill(Studio.card))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(ClayBodyKind.allCases) { kind in
                            clayCard(kind)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 20)
            .clayReadable()
        }
    }

    private func clayCard(_ kind: ClayBodyKind) -> some View {
        let selected = clay == kind
        let unlocked = journey.isClayUnlocked(kind)
        let unlockLevel = journey.clayUnlockLevel(kind)
        let rankName = JourneyStore.ranks.first(where: { $0.level == unlockLevel })?.name ?? ""
        return Button(action: {
            guard unlocked else { return }
            clay = kind
            store.saveDraft(profile: profile, heightScale: heightScale, clay: clay)
            showClayPicker = false
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(kind.wetTone.color).frame(width: 46, height: 46)
                    Circle().fill(kind.firedTone.color).frame(width: 22, height: 22)
                        .offset(x: 12, y: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5).frame(width: 22, height: 22).offset(x: 12, y: 12))
                }
                .frame(width: 52, height: 52)
                .opacity(unlocked ? 1 : 0.35)
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.displayName)
                        .font(.clayBody(16, .bold))
                        .foregroundColor(unlocked ? Studio.ink : Studio.inkSoft)
                    Text(unlocked ? kind.blurb : "Unlocks at rank \(unlockLevel) · \(rankName). Keep firing pieces to get there.")
                        .font(.clayBody(12))
                        .foregroundColor(Studio.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if selected {
                    ClayIcon(kind: .check, size: 18, color: Studio.sage)
                } else if !unlocked {
                    ClayChip(text: "Rank \(unlockLevel)", tint: Studio.denim)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Studio.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? Studio.sage : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
