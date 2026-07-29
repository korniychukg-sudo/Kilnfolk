# Kilnfolk v2 — "Potter's Journey" Design

Date: 2026-07-24. Version stays 1.0 (build 1) per delivery rule.

## Problem

v1 is a pleasant sandbox (throw → glaze → fire → shelf) plus a handbook, but it reads
like a reference app: there is no goal, no skill curve, no reason to return tomorrow.
The one unique asset — continuous finger-forming of a lathe profile — is never *tested*,
only used freely. The Master asked for a richer, more stylish app that feels genuinely
useful and engaging, with functional change allowed.

## Concept

Turn the sandbox into a potter's apprenticeship. The finger-forming mechanic becomes a
skill you *practice and prove* by throwing 12 classic historical forms against a ghost
silhouette with live accuracy scoring. Everything you fire feeds one progression: XP,
12 potter ranks, glazes and clays you unlock, awards, and a form-of-the-day habit loop.
The handbook stops being the centerpiece and becomes the "Lore" shelf of the Journey tab.

## Approaches considered

1. **Commissions board** (random customer orders with constraints) — replayable but
   random text orders feel gamey and need an economy to matter. Rejected for scope/tone.
2. **Decoration depth** (carving, sgraffito, handles) — pretty but doesn't add purpose;
   the app would still be aimless. Rejected.
3. **Classic-forms mastery + progression** (chosen) — curated, teachable, uses the
   unique input directly, gives long-term goals, and folds the handbook into a journey
   naturally. Recommended and chosen.

## Feature design

### A. Forms Atelier (shape challenges)

- `FormLibrary`: 12 classic forms in 4 tiers of 3 — Tea Bowl, Bud Vase, Honey Pot
  (Apprentice); Moon Jar, Straight Mug, Milk Jug (Journeyman); Amphora, Ginger Jar,
  Bottle Vase (Artisan); Trumpet Vase, Meiping, Double Gourd (Master). Each form:
  id, name, tier, 1–2 sentence real-world story, target control points (interpolated
  to the 28-sample profile at load), target heightScale.
- Tier gating by earned stars: tier 2 at 4★ total, tier 3 at 10★, tier 4 at 18★.
- Challenge flow: start from Journey (or form-of-the-day chip) → Studio opens with a
  ghost silhouette overlay (dashed outline of the target on the wheel), a live
  **fit meter** (form name + fit % + tiny stars preview), and a ghost on/off toggle.
- Fit metric: `fit = max(0, 1 − meanAbsDiff(profile, target) × 4.2 − |hs − hsTarget| × 1.1)`.
  Stars: 3★ ≥ 0.90, 2★ ≥ 0.78, 1★ ≥ 0.62. Best stars + best fit stored per form.
- Stars are banked when the piece is **fired** (reveal moment), not on the wheel —
  keeps the loop through glaze + kiln. Pot records optional `formID`/`formStars`.
- Exiting a challenge (Fresh clay / starting another form) simply clears the target.

### B. Progression (XP, ranks, unlocks)

- New `JourneyStore` (ObservableObject) with its own UserDefaults key
  `kilnfolk.journey.v1` — zero migration risk for v1 pots; tolerant decode throughout.
- XP on every reveal: 20 base + 15 × stars (challenge) + 10 first-use of each glaze +
  10 first-use of each clay + 15 daily-form bonus.
- 12 ranks with names (New Hands → Master Potter), thresholds 0…1200.
- Unlocks by rank: start with 5 glazes (Celadon Mist, Oat Milk, Honey Amber,
  Tomato Ember, Moss Hollow) and 2 clays (Terracotta, Speckled Buff).
  L2 Rose Quartz · L3 Porcelain clay · L4 Ocean Tide · L5 Sage Field + Lavender Ash ·
  L6 Midnight clay · L7 Butter Cream · L8 Charcoal Satin · L10 Midnight Pool.
- Locked items appear in pickers with a lock glyph + rank tag; tapping shows a hint.

### C. Form of the Day + streak

Deterministic pick from unlocked-tier forms by date key. Chip on the Studio header and
a hero card in Journey. Completing it (fire a ≥1★ piece of that form that day)
increments a daily streak (stored dateKey + count, gap resets).

### D. Awards (17 badges)

first fire; 5 / 15 / 40 pieces fired; all 4 clays used; all 12 glazes used; 3 crackle
surprises; first 3★; five 3★ forms; clear tier 2 / 3 / 4 (≥1★ every form); 3-day and
7-day daily streaks; a really tall pot (heightScale ≥ 0.97); a wide-open bowl
(top radius ≥ 0.9, height ≤ 0.65); reach Master Potter. Grid in Journey → Awards with
earned dates; locked ones show hints. Badge medallions drawn in Canvas (no PNG).

### E. Reveal ceremony upgrade

Reveal sheet becomes a moment: confetti burst (capsules + dots, custom view), fit
result card with stars for challenge pieces, XP tally count-up, and, when the XP
crosses a rank threshold, a level-up card listing what just unlocked (glaze/clay
swatches). Multiple unlocks stack vertically.

### F. Style & usefulness pass

- Wheel scene v2: splash pan in front of the wheel, slip particles that fly while
  shaping, stronger wet sheen; richer backdrop art (tool shelf, warmer window light).
- Live **dimensions HUD** on the wheel: `H 24 cm · W 18 cm` derived from the profile
  (30 cm max height, 22 cm max width) — also shown in the gallery detail sheet.
- Gallery v2: wooden cabinet back-panel art behind shelves, soft spotlight behind
  favorites, form chip on challenge pieces.
- Journey tab replaces Handbook tab position: segmented **Forms | Awards | Lore**
  (Lore = existing handbook sections untouched).
- Onboarding slide 3 rewritten around the journey; More tab gains rank/XP stats row.

### G. Data model changes

- `PotDesign` + optional `formID: String?`, `formStars: Int?` (decodeIfPresent-safe
  because they are optionals — v1 blobs decode unchanged).
- `JourneyState` (Codable): xp, formStars [String: Int], formBestFit [String: Double],
  glazesUsed [String], claysUsed [String], crackleCount, badges [String: Date],
  dailyStreak, lastDailyKey, bankedTallPot/wideBowl flags derived at fire time.
- Badge/unlock evaluation happens in one place: `JourneyStore.registerFiredPot(...)`
  called from `FolkStore.collectFiredPot` result path in KilnView; returns a
  `RevealSummary` (xp gained, breakdown, new rank?, unlocked items, new badges) the
  reveal sheet renders.

## Architecture

New files: `FormLibrary.swift` (forms + tiers + fit scoring), `JourneyStore.swift`
(state, XP, ranks, unlocks, badges, daily), `JourneyView.swift` (segmented tab),
`ConfettiView.swift`. Modified: WheelStudioView (ghost overlay, fit meter, HUD,
particles, challenge entry), GlazeStudioView (locked swatches), KilnView (reveal v2),
GalleryView (cabinet, chips, dimensions), RootView (tab rename/icon, environment),
FolkModels (pot optionals), MoreView, OnboardingView, art generator (4 new/updated
images). Handbook views unchanged, re-hosted inside JourneyView.

JourneyStore is injected as a second `@EnvironmentObject` alongside FolkStore.
Challenge targeting is a small `@Published var activeFormID: String?` on JourneyStore
so Journey → Studio communication needs no new plumbing.

## Error handling

All decodes tolerant (`try?` + defaults); orphan challenge id (form removed) ignored;
fit scoring guards against profile length mismatch; daily streak survives midnight via
date keys; badges idempotent (first-earn date kept).

## Testing

Compile-clean Debug + Release; logic spot-checks via seeded UserDefaults states on the
simulator (fresh user, mid-journey user with unlocks pending, reveal crossing a rank
threshold); visual verification of every changed screen; screenshots refreshed.
