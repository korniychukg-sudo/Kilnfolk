import SwiftUI

struct JourneyView: View {
    @EnvironmentObject var store: FolkStore
    @EnvironmentObject var journey: JourneyStore
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @Binding var selectedTab: Int
    @State private var segment: JourneySegment = .forms

    enum JourneySegment: String, CaseIterable, Identifiable {
        case forms, awards, lore
        var id: String { rawValue }
        var label: String {
            switch self {
            case .forms: return "Forms"
            case .awards: return "Awards"
            case .lore: return "Lore"
            }
        }
    }

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    FolkSectionHeader(title: "Potter's Journey",
                                      caption: "Master the classic forms, rank by rank")
                        .padding(.top, 12)

                    segmentPicker

                    switch segment {
                    case .forms: formsSection
                    case .awards: awardsSection
                    case .lore: loreSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
                .folkReadable()
            }
        }
        .navigationBarHidden(true)
    }

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            ForEach(JourneySegment.allCases) { s in
                let selected = segment == s
                Button(action: { segment = s }) {
                    Text(s.label)
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

    // MARK: - Forms

    private var formsSection: some View {
        VStack(spacing: 14) {
            rankCard
            dailyCard
            ForEach(1...4, id: \.self) { tier in
                tierSection(tier)
            }
        }
    }

    private var rankCard: some View {
        FolkCard(padding: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Studio.linen, lineWidth: 8)
                        .frame(width: 66, height: 66)
                    Circle()
                        .trim(from: 0, to: CGFloat(max(0.02, journey.rankProgress)))
                        .stroke(Studio.terracotta, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))
                    Text("\(journey.level)")
                        .font(.folkTitle(22))
                        .foregroundColor(Studio.ink)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(journey.rankName)
                        .font(.folkBody(16, .bold))
                        .foregroundColor(Studio.ink)
                    if let next = journey.nextRank {
                        Text("\(journey.state.xp) XP · \(next.xp - journey.state.xp) to \(next.name)")
                            .font(.folkBody(12))
                            .foregroundColor(Studio.inkSoft)
                    } else {
                        Text("\(journey.state.xp) XP · the wheel holds no more secrets")
                            .font(.folkBody(12))
                            .foregroundColor(Studio.inkSoft)
                    }
                    HStack(spacing: 6) {
                        FolkIcon(kind: .starFill, size: 13, color: Studio.honey)
                        Text("\(journey.totalStars) stars earned")
                            .font(.folkBody(12, .bold))
                            .foregroundColor(Studio.inkSoft)
                    }
                }
                Spacer()
            }
        }
    }

    private var dailyCard: some View {
        let form = journey.formOfTheDay()
        let done = journey.dailyDone()
        return FolkCard(padding: 14) {
            HStack(spacing: 14) {
                formThumb(form, size: CGSize(width: 58, height: 72))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        FolkIcon(kind: .sparkle, size: 13, color: Studio.honey)
                        Text("Form of the day")
                            .font(.folkBody(11, .bold))
                            .foregroundColor(Studio.honey)
                    }
                    Text(form.name)
                        .font(.folkBody(16, .bold))
                        .foregroundColor(Studio.ink)
                    if journey.state.dailyStreak > 0 {
                        HStack(spacing: 4) {
                            FolkIcon(kind: .flame, size: 12, color: Studio.ember)
                            Text("\(journey.state.dailyStreak)-day streak")
                                .font(.folkBody(12))
                                .foregroundColor(Studio.inkSoft)
                        }
                    } else {
                        Text("Throw it today to start a streak")
                            .font(.folkBody(12))
                            .foregroundColor(Studio.inkSoft)
                    }
                }
                Spacer()
                if done {
                    FolkChip(text: "Done today", tint: Studio.sage)
                } else {
                    startButton(form)
                }
            }
        }
    }

    private func tierSection(_ tier: Int) -> some View {
        let unlocked = journey.isTierUnlocked(tier)
        let needed = FormLibrary.starsNeeded(forTier: tier)
        return VStack(spacing: 10) {
            HStack {
                Text(FormLibrary.tierName(tier))
                    .font(.folkBody(15, .bold))
                    .foregroundColor(Studio.ink)
                if !unlocked {
                    FolkChip(text: "\(needed) stars to unlock", tint: Studio.denim)
                }
                Spacer()
                HStack(spacing: 3) {
                    FolkIcon(kind: .starFill, size: 11, color: Studio.honey)
                    Text("\(FormLibrary.forms(inTier: tier).reduce(0) { $0 + journey.stars(for: $1.id) }) of 9")
                        .font(.folkBody(12, .bold))
                        .foregroundColor(Studio.inkSoft)
                }
            }
            ForEach(FormLibrary.forms(inTier: tier)) { form in
                formCard(form, tierUnlocked: unlocked)
            }
        }
        .padding(.top, 4)
    }

    private func formCard(_ form: PotForm, tierUnlocked: Bool) -> some View {
        let stars = journey.stars(for: form.id)
        let best = journey.bestFit(for: form.id)
        return FolkCard(padding: 12) {
            HStack(spacing: 12) {
                formThumb(form, size: CGSize(width: 52, height: 66))
                    .opacity(tierUnlocked ? 1 : 0.35)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(form.name)
                            .font(.folkBody(15, .bold))
                            .foregroundColor(tierUnlocked ? Studio.ink : Studio.inkSoft)
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                FolkIcon(kind: i < stars ? .starFill : .star, size: 11,
                                         color: i < stars ? Studio.honey : Studio.inkFaint)
                            }
                        }
                    }
                    Text(tierUnlocked ? form.story : "Earn more stars in earlier tiers to reveal this form.")
                        .font(.folkBody(11.5))
                        .foregroundColor(Studio.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if let best = best, tierUnlocked {
                        Text("Best fit \(Int((best * 100).rounded()))%")
                            .font(.folkBody(11, .bold))
                            .foregroundColor(Studio.sage)
                    }
                }
                Spacer()
                if tierUnlocked {
                    startButton(form)
                }
            }
        }
    }

    private func startButton(_ form: PotForm) -> some View {
        Button(action: {
            journey.activeFormID = form.id
            selectedTab = 0
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Text(journey.activeFormID == form.id ? "On wheel" : "Throw")
                .font(.folkBody(12, .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(journey.activeFormID == form.id ? Studio.sage : Studio.terracotta))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formThumb(_ form: PotForm, size: CGSize) -> some View {
        var ghost = PotDesign(clay: .terracotta, profile: form.targetProfile,
                              heightScale: form.targetHeight)
        ghost.stage = .fired
        return PotFigure(pot: ghost, phase: 0, wet: false, showShadow: false)
            .frame(width: size.width, height: size.height)
    }

    // MARK: - Awards

    private var awardsSection: some View {
        VStack(spacing: 12) {
            FolkArt(name: "awards_banner")
                .scaledToFill()
                .frame(height: FolkLayout.isPad(hSize, vSize) ? 170 : 110)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(18)
            let earned = JourneyStore.badgeDefs.filter { journey.hasBadge($0.id) }.count
            Text("\(earned) of \(JourneyStore.badgeDefs.count) awards earned")
                .font(.folkBody(13, .bold))
                .foregroundColor(Studio.inkSoft)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(JourneyStore.badgeDefs) { badge in
                    badgeCard(badge)
                }
            }
        }
    }

    private func badgeCard(_ badge: JourneyBadge) -> some View {
        let earned = journey.hasBadge(badge.id)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? Studio.honey.opacity(0.2) : Studio.linen)
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(earned ? Studio.honey : Studio.inkFaint,
                            style: StrokeStyle(lineWidth: 2.5, dash: earned ? [] : [4, 4]))
                    .frame(width: 56, height: 56)
                FolkIcon(kind: earned ? .starFill : .star, size: 24,
                         color: earned ? Studio.honey : Studio.inkFaint)
            }
            Text(badge.title)
                .font(.folkBody(13, .bold))
                .foregroundColor(earned ? Studio.ink : Studio.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(earned ? earnedText(badge) : badge.hint)
                .font(.folkBody(11))
                .foregroundColor(Studio.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Studio.card)
                .shadow(color: Studio.shadow, radius: 6, x: 0, y: 3)
        )
    }

    private func earnedText(_ badge: JourneyBadge) -> String {
        guard let date = journey.badgeDate(badge.id) else { return badge.hint }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    // MARK: - Lore

    private var loreSection: some View {
        VStack(spacing: 14) {
            ForEach(HandbookLibrary.sections) { section in
                NavigationLink(destination: HandbookSectionView(section: section)) {
                    loreCard(section)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func loreCard(_ section: HandbookSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FolkArt(name: section.artName)
                .scaledToFill()
                .frame(height: FolkLayout.isPad(hSize, vSize) ? 150 : 100)
                .frame(maxWidth: .infinity)
                .clipped()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(section.title)
                        .font(.folkBody(15, .bold))
                        .foregroundColor(Studio.ink)
                    Text(section.caption)
                        .font(.folkBody(12))
                        .foregroundColor(Studio.inkSoft)
                }
                Spacer()
                FolkChip(text: "\(section.items.count) notes", tint: Studio.terracotta)
                FolkIcon(kind: .chevronRight, size: 14, color: Studio.inkFaint)
            }
            .padding(13)
            .background(Studio.card)
        }
        .cornerRadius(18)
        .shadow(color: Studio.shadow, radius: 7, x: 0, y: 4)
    }
}
