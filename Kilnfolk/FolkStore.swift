import SwiftUI

final class FolkStore: ObservableObject {
    @Published var pots: [PotDesign] = []
    @Published var firingJob: KilnJob? = nil
    @Published var draft: WheelDraft? = nil
    @Published var onboardingSeen = false
    @Published var stats = FolkStats()

    private let potsKey = "kilnfolk.pots.v1"
    private let kilnKey = "kilnfolk.kiln.v1"
    private let draftKey = "kilnfolk.draft.v1"
    private let metaKey = "kilnfolk.meta.v1"

    private struct MetaBlob: Codable {
        var onboardingSeen = false
        var stats = FolkStats()
    }

    init() {
        load()
        repairKilnState()
    }

    // MARK: Derived

    var galleryPots: [PotDesign] {
        pots.filter { $0.stage == .fired }.sorted { ($0.firedAt ?? $0.createdAt) > ($1.firedAt ?? $1.createdAt) }
    }

    var kilnQueue: [PotDesign] {
        pots.filter { $0.stage == .queued }.sorted { $0.createdAt < $1.createdAt }
    }

    var firingPot: PotDesign? {
        guard let job = firingJob else { return nil }
        return pots.first { $0.id == job.potID }
    }

    func pot(_ id: UUID) -> PotDesign? {
        pots.first { $0.id == id }
    }

    // MARK: Flags & stats

    func markOnboardingSeen() {
        onboardingSeen = true
        saveMeta()
    }

    // MARK: Wheel draft

    func saveDraft(profile: [Double], heightScale: Double, clay: ClayBodyKind) {
        draft = WheelDraft(profile: profile, heightScale: heightScale, clay: clay)
        persist(draft, key: draftKey)
    }

    func clearDraft() {
        draft = nil
        UserDefaults.standard.removeObject(forKey: draftKey)
    }

    // MARK: Kiln flow

    /// A glazed pot leaves the studio and joins the kiln queue.
    func sendToKiln(_ pot: PotDesign) {
        var p = pot
        p.stage = .queued
        pots.append(p)
        stats.thrown += 1
        saveMeta()
        clearDraft()
        startNextFiringIfIdle()
        savePots()
    }

    func startNextFiringIfIdle() {
        guard firingJob == nil else { return }
        guard let next = kilnQueue.first else { return }
        if let idx = pots.firstIndex(where: { $0.id == next.id }) {
            pots[idx].stage = .firing
            firingJob = KilnJob(potID: next.id, startedAt: Date())
            persist(firingJob, key: kilnKey)
            savePots()
        }
    }

    /// The moment of truth: open the kiln and reveal the fired piece.
    /// Returns the finished pot for the reveal card.
    @discardableResult
    func collectFiredPot() -> PotDesign? {
        guard let job = firingJob, job.isDone(at: Date()),
              let idx = pots.firstIndex(where: { $0.id == job.potID }) else { return nil }
        pots[idx].stage = .fired
        pots[idx].firedAt = Date()
        // Crackle is a happy accident of the kiln: ~1 pot in 5, decided by the pot itself.
        pots[idx].crackle = (pots[idx].artSeed % 5 == 0) && !pots[idx].coat.isBare
        stats.fired += 1
        firingJob = nil
        UserDefaults.standard.removeObject(forKey: kilnKey)
        saveMeta()
        savePots()
        let finished = pots[idx]
        startNextFiringIfIdle()
        return finished
    }

    /// Drops orphaned kiln jobs (e.g. after a reset mid-fire).
    private func repairKilnState() {
        if let job = firingJob, !pots.contains(where: { $0.id == job.potID && $0.stage == .firing }) {
            firingJob = nil
            UserDefaults.standard.removeObject(forKey: kilnKey)
        }
        if firingJob == nil {
            // Any pot stuck in .firing without a job goes back to the queue.
            var touched = false
            for idx in pots.indices where pots[idx].stage == .firing {
                pots[idx].stage = .queued
                touched = true
            }
            if touched { savePots() }
            startNextFiringIfIdle()
        }
    }

    // MARK: Gallery edits

    func renamePot(_ id: UUID, to name: String) {
        guard let idx = pots.firstIndex(where: { $0.id == id }) else { return }
        pots[idx].name = String(name.prefix(40))
        savePots()
    }

    func toggleFavorite(_ id: UUID) {
        guard let idx = pots.firstIndex(where: { $0.id == id }) else { return }
        pots[idx].favorite.toggle()
        savePots()
    }

    func deletePot(_ id: UUID) {
        pots.removeAll { $0.id == id }
        if firingJob?.potID == id {
            firingJob = nil
            UserDefaults.standard.removeObject(forKey: kilnKey)
            startNextFiringIfIdle()
        }
        savePots()
    }

    func resetAll() {
        pots = []
        firingJob = nil
        draft = nil
        stats = FolkStats()
        UserDefaults.standard.removeObject(forKey: potsKey)
        UserDefaults.standard.removeObject(forKey: kilnKey)
        UserDefaults.standard.removeObject(forKey: draftKey)
        saveMeta()
    }

    // MARK: Persistence

    private func load() {
        pots = fetch([PotDesign].self, key: potsKey) ?? []
        firingJob = fetch(KilnJob.self, key: kilnKey)
        draft = fetch(WheelDraft.self, key: draftKey)
        let meta = fetch(MetaBlob.self, key: metaKey) ?? MetaBlob()
        onboardingSeen = meta.onboardingSeen
        stats = meta.stats
    }

    private func savePots() {
        persist(pots, key: potsKey)
    }

    private func saveMeta() {
        persist(MetaBlob(onboardingSeen: onboardingSeen, stats: stats), key: metaKey)
    }

    private func persist<T: Encodable>(_ value: T?, key: String) {
        guard let value = value, let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func fetch<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
