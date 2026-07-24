# Clay Corner v2 — Potter's Journey Implementation Plan

Spec: `../specs/2026-07-24-clay-corner-v2-journey-design.md`

## Step 1 — Data layer

1. `ClayModels.swift`: add `formID: String?` and `formStars: Int?` to `PotDesign`
   (optionals — old blobs decode unchanged).
2. New `FormLibrary.swift`:
   - `PotForm { id, name, tier (1-4), story, controls: [Double], targetHeight }`
   - `targetProfile` interpolates controls → 28 samples (same math as PotShapes).
   - `FormLibrary.all` (12 forms), `forms(inTier:)`, `form(_:)`.
   - `FormScoring.fit(profile:heightScale:form:) -> Double`, `stars(fit:) -> Int`
     (3★ ≥ 0.90, 2★ ≥ 0.78, 1★ ≥ 0.62).
   - `tierUnlocked(tier:totalStars:)` (4/10/18★ for tiers 2/3/4).
3. New `JourneyStore.swift`:
   - `JourneyState: Codable` per spec; key `corner.journey.v1`; tolerant decode.
   - Ranks table (12 names + thresholds 0,40,90,150,220,300,400,520,660,820,1000,1200).
   - `glazeUnlockLevel[id]`, `clayUnlockLevel[kind]`; `isGlazeUnlocked/isClayUnlocked`.
   - `@Published var activeFormID: String?` (challenge routing).
   - `formOfTheDay(dateKey:)` deterministic; `dailyDone(dateKey)` check.
   - `registerFiredPot(pot:) -> RevealSummary { xpGained, lines[], oldLevel, newLevel,
     unlockedGlazes, unlockedClays, newBadges, stars, fit }` — sole mutation point:
     banks stars/fit, marks glaze/clay first-use, daily streak, badge evaluation.
   - Badge defs (17) with title/hint/earn check.

## Step 2 — Wheel challenge mode + scene v2

`WheelStudioView.swift`:
- Read `journey.activeFormID`; when set: draw dashed ghost silhouette (target profile)
  in the pot rect, show fit meter capsule (name, live fit %, star pips, ghost toggle,
  X to abandon), pass form into GlazeStudio → pot.
- Dimensions HUD chip: `H \(Int(heightScale*30)) cm · W \(Int(maxR*22)) cm`.
- Slip particles: spawn 2-3 per shaping event into a `@State` ring buffer (pos, vel,
  born); rendered in the same TimelineView Canvas, ~0.7 s life, fade out.
- Splash pan: two ellipses drawn in front of wheel base.
- Form-of-the-day chip in header when no active form.
- Clay picker: locked clays show lock + rank tag, tap = hint bubble not selection.

## Step 3 — Journey tab

New `JourneyView.swift`:
- Segmented Forms | Awards | Lore (custom pill control, same pattern as glaze modes).
- Forms: daily hero card (form, streak flame, Start), rank card (ring progress to next
  rank, rank name, xp), tier sections with form cards: silhouette thumb (PotFigure with
  target profile, clay tone), name, stars, best fit %, Start/Locked.
- Awards: grid of Canvas medallions (earned = honey fill + date; locked = outline+hint).
- Lore: existing `HandbookView` content list re-hosted (NavigationLinks unchanged).
- `RootView`: tab 3 icon → new `.compass`-style wheel-with-star glyph? Keep `.book` →
  new `.banner` icon named `journey` (drawn); title "Journey"; inject JourneyStore.

## Step 4 — Locked glazes + reveal ceremony

- `GlazeStudioView`: swatches for locked glazes render dimmed with lock; tap shows
  hint text under palette; locked cannot be applied (base/band/rim).
- `KilnView` reveal path: `store.collectFiredPot()` → `journey.registerFiredPot(pot)`
  → `KilnRevealSheet(pot:summary:)`: confetti burst on appear, stars row (challenge),
  fit %, XP tally count-up lines, rank-up card with unlocked swatches, badge chips.
- New `ConfettiView.swift`: one-shot TimelineView burst (ANIMATION ~2.2 s, 46 pieces,
  capsules/dots in studio palette), reduce-motion safe (static sprinkle).

## Step 5 — Gallery + More + Onboarding polish

- `GalleryView`: cabinet back panel art behind shelf block, favorite spotlight
  (radial gradient behind pot), form chip on thumbs (small), detail sheet: dimensions
  line + form/stars row.
- `MoreView`: rank + xp + streak stats; flow rows updated.
- `OnboardingView`: slide 3 text → journey pitch.

## Step 6 — Art & assets

`art_src/gen.swift` additions/replacements (regenerate all into Art/):
- `journey_banner` (atelier wall: ghost silhouettes on paper pinned above bench),
- `awards_banner` (medal shelf),
- `studio_backdrop` v2 (tool shelf + warmer light + splash pan hints),
- `cabinet_back` (dark wood cabinet interior panel).

## Step 7 — Verify & deliver

- Build Debug sim + Release device, zero errors/warnings.
- Sim verification with three seeded journeys (fresh / mid with pending unlock at next
  fire / near-master) + v1-blob compatibility (existing seeded pots decode).
- Screenshots refreshed (01-08: onboarding, wheel+ghost challenge, glaze locked row,
  kiln, reveal ceremony, gallery v2, journey forms, awards).
- Remove debug hooks, update APP_TRACKER + APP_DESCRIPTIONS, commit, deliver via `mv`.
