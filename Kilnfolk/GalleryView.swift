import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var store: FolkStore
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @State private var filter: GalleryFilter = .all
    @State private var selectedPotID: UUID? = nil

    enum GalleryFilter: String, CaseIterable, Identifiable {
        case all, favorites
        var id: String { rawValue }
        var label: String { self == .all ? "All pieces" : "Favorites" }
    }

    private var shownPots: [PotDesign] {
        let pots = store.galleryPots
        return filter == .all ? pots : pots.filter { $0.favorite }
    }

    var body: some View {
        GeometryReader { geo in
            // Content is capped at the readable width, so count columns against that.
            let columns = min(geo.size.width, 660) > 600 ? 4 : 3
            ZStack {
                Studio.cream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        FolkArt(name: "gallery_banner")
                            .scaledToFill()
                            .frame(height: FolkLayout.bannerHeight(hSize, vSize))
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(22)
                            .overlay(
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("The Gallery")
                                        .font(.folkTitle(26))
                                        .foregroundColor(.white)
                                    Text("Every piece you have fired")
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

                        HStack(spacing: 10) {
                            statChip(value: store.stats.fired, word: "fired")
                            statChip(value: store.galleryPots.filter { $0.favorite }.count, word: "loved")
                            statChip(value: store.galleryPots.filter { $0.crackle }.count, word: "crackled")
                            Spacer()
                        }

                        filterPicker

                        if shownPots.isEmpty {
                            emptyState
                        } else {
                            shelves(columns: columns)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .folkReadable()
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedPotID.flatMap { store.pot($0) } },
            set: { if $0 == nil { selectedPotID = nil } }
        )) { pot in
            PotDetailSheet(potID: pot.id) { selectedPotID = nil }
                .environmentObject(store)
        }
    }

    private func statChip(value: Int, word: String) -> some View {
        HStack(spacing: 5) {
            Text("\(value)")
                .font(.folkBody(15, .bold))
                .foregroundColor(Studio.ink)
            Text(word)
                .font(.folkBody(12))
                .foregroundColor(Studio.inkSoft)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Studio.card))
    }

    private var filterPicker: some View {
        HStack(spacing: 4) {
            ForEach(GalleryFilter.allCases) { f in
                let selected = filter == f
                Button(action: { filter = f }) {
                    Text(f.label)
                        .font(.folkBody(13, .bold))
                        .foregroundColor(selected ? .white : Studio.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(selected ? Studio.terracotta : Color.clear))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Capsule().fill(Studio.card))
    }

    private var emptyState: some View {
        FolkCard {
            VStack(spacing: 10) {
                FolkArt(name: "gallery_empty")
                    .scaledToFit()
                    .frame(height: 140)
                    .cornerRadius(16)
                Text(filter == .favorites ? "No favorites yet" : "The shelf is waiting")
                    .font(.folkBody(16, .bold))
                    .foregroundColor(Studio.ink)
                Text(filter == .favorites
                     ? "Tap the star on a piece you love and it will live here."
                     : "Fire your first piece and it will take pride of place right here.")
                    .font(.folkBody(13))
                    .foregroundColor(Studio.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Shelves

    private func shelves(columns: Int) -> some View {
        let rows: [[PotDesign]] = stride(from: 0, to: shownPots.count, by: columns).map {
            Array(shownPots[$0..<min($0 + columns, shownPots.count)])
        }
        return VStack(spacing: 22) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                shelfRow(row, columns: columns)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(
            // GeometryReader pins the panel art to the shelves' own size; a bare
            // scaledToFill background grows to a square and covers its neighbours.
            GeometryReader { panel in
                FolkArt(name: "cabinet_back", fallback: Studio.linen)
                    .scaledToFill()
                    .frame(width: panel.size.width, height: panel.size.height)
                    .clipped()
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Studio.woodDark.opacity(0.6), lineWidth: 3)
                    )
            }
        )
    }

    private func shelfRow(_ row: [PotDesign], columns: Int) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(row) { pot in
                    shelfPot(pot)
                }
                // keep grid alignment when the last row is short
                ForEach(0..<(columns - row.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity).frame(height: 10)
                }
            }
            .padding(.horizontal, 8)
            FolkArt(name: "wood_shelf", fallback: Studio.wood)
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .cornerRadius(4)
                .shadow(color: Studio.shadow, radius: 5, x: 0, y: 4)
        }
    }

    private func shelfPot(_ pot: PotDesign) -> some View {
        Button(action: { selectedPotID = pot.id }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if pot.favorite {
                        RadialGradient(colors: [Studio.honey.opacity(0.30), .clear],
                                       center: .center, startRadius: 4, endRadius: 58)
                            .frame(height: 106)
                    }
                    PotFigure(pot: pot, phase: Double(pot.artSeed % 7), wet: false, showShadow: true)
                        .frame(height: 106)
                        .frame(maxWidth: .infinity)
                    if pot.favorite {
                        FolkIcon(kind: .starFill, size: 15, color: Studio.honey)
                            .padding(3)
                    }
                }
                HStack(spacing: 3) {
                    if let stars = pot.formStars, stars > 0, pot.formID != nil {
                        FolkIcon(kind: .starFill, size: 9, color: Studio.honey)
                    }
                    Text(shelfLabel(pot))
                        .font(.folkBody(11, .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }

    private func shelfLabel(_ pot: PotDesign) -> String {
        if pot.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let form = FormLibrary.form(pot.formID) {
            return form.name
        }
        return pot.displayName
    }
}

// MARK: - Detail sheet

struct PotDetailSheet: View {
    @EnvironmentObject var store: FolkStore
    let potID: UUID
    let onClose: () -> Void

    @State private var spinPhase: Double = 0
    @State private var lastDragX: CGFloat? = nil
    @State private var editingName = ""
    @State private var nameLoaded = false
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            if let pot = store.pot(potID) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HStack {
                            Spacer()
                            Button(action: onClose) {
                                FolkIcon(kind: .close, size: 17, color: Studio.ink)
                                    .padding(9)
                                    .background(Circle().fill(Studio.card))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 14)

                        PotFigure(pot: pot, phase: spinPhase, wet: false)
                            .frame(height: 260)
                            .frame(maxWidth: 300)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if let last = lastDragX {
                                            spinPhase += Double(value.location.x - last) * 0.02
                                        }
                                        lastDragX = value.location.x
                                    }
                                    .onEnded { _ in lastDragX = nil }
                            )

                        Text("Drag the pot to spin it")
                            .font(.folkBody(11))
                            .foregroundColor(Studio.inkFaint)

                        HStack(spacing: 10) {
                            FolkIcon(kind: .sparkle, size: 16, color: Studio.honey)
                            TextField("Untitled Piece", text: $editingName, onCommit: {
                                store.renamePot(pot.id, to: editingName)
                            })
                            .font(.folkBody(16, .bold))
                            .foregroundColor(Studio.ink)
                            .disableAutocorrection(true)
                            Button(action: {
                                store.toggleFavorite(pot.id)
                            }) {
                                FolkIcon(kind: pot.favorite ? .starFill : .star, size: 20,
                                         color: pot.favorite ? Studio.honey : Studio.inkFaint)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Studio.card))

                        FolkCard(padding: 14) {
                            VStack(spacing: 9) {
                                if let form = FormLibrary.form(pot.formID) {
                                    HStack {
                                        Text("Classic form")
                                            .font(.folkBody(13))
                                            .foregroundColor(Studio.inkSoft)
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Text(form.name)
                                                .font(.folkBody(13, .bold))
                                                .foregroundColor(Studio.ink)
                                            ForEach(0..<max(0, min(3, pot.formStars ?? 0)), id: \.self) { _ in
                                                FolkIcon(kind: .starFill, size: 11, color: Studio.honey)
                                            }
                                        }
                                    }
                                }
                                infoRow(label: "Size",
                                        value: "\(PotMeasure.heightCM(pot.heightScale)) cm tall · \(PotMeasure.widthCM(pot.profile)) cm wide")
                                infoRow(label: "Clay body", value: pot.clay.displayName)
                                infoRow(label: "Base glaze",
                                        value: GlazeCatalog.recipe(pot.coat.baseGlazeID)?.name ?? "Bare clay")
                                if !pot.coat.bands.isEmpty {
                                    infoRow(label: "Bands", value: bandList(pot))
                                }
                                if let rim = GlazeCatalog.recipe(pot.coat.rimDipGlazeID) {
                                    infoRow(label: "Rim dip", value: rim.name)
                                }
                                infoRow(label: "Finish", value: pot.crackle ? "Crackle surprise" : "Clean")
                                if let fired = pot.firedAt {
                                    infoRow(label: "Fired", value: dateText(fired))
                                }
                            }
                        }

                        Button(action: { confirmDelete = true }) {
                            HStack(spacing: 8) {
                                FolkIcon(kind: .trash, size: 16, color: Studio.ember)
                                Text("Shatter this piece")
                                    .font(.folkBody(14, .bold))
                                    .foregroundColor(Studio.ember)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Studio.card))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .folkReadable()
                }
                .onAppear {
                    if !nameLoaded {
                        nameLoaded = true
                        editingName = pot.name
                        spinPhase = Double(pot.artSeed % 7)
                    }
                }
                .alert(isPresented: $confirmDelete) {
                    Alert(title: Text("Shatter \(pot.displayName)?"),
                          message: Text("Broken pottery cannot be mended. The piece will be gone for good."),
                          primaryButton: .destructive(Text("Shatter")) {
                              store.deletePot(pot.id)
                              onClose()
                          },
                          secondaryButton: .cancel(Text("Keep it")))
                }
            }
        }
        .onDisappear {
            if let pot = store.pot(potID), nameLoaded, editingName != pot.name {
                store.renamePot(pot.id, to: editingName)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.folkBody(13))
                .foregroundColor(Studio.inkSoft)
            Spacer()
            Text(value)
                .font(.folkBody(13, .bold))
                .foregroundColor(Studio.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func bandList(_ pot: PotDesign) -> String {
        pot.coat.bands
            .compactMap { GlazeCatalog.recipe($0.glazeID)?.name }
            .joined(separator: ", ")
    }

    private func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}
