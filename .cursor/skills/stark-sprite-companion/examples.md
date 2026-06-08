# Stark Sprite — Agent Examples

Scenarios for future feature work. Always read [SKILL.md](SKILL.md) first.

---

## Scenario 1: Replace a loading spinner

**User request:** "Show the dog sprite while the exercises tab loads."

**Agent steps:**

1. Find the screen's initial-load branch (`loading && !payload`).
2. Confirm no preset fits exactly — `dailyPlanLoading` is close; reuse with optional message override.
3. Replace `ProgressView` / "Loading…" text with overlay preset.
4. Mirror on both platforms.

```tsx
// stark-sesh — ExercisesPageClient.tsx
if (loading) {
  return <SpriteOverlay preset="dailyPlanLoading" message="Loading care plan…" />
```

```swift
// iOS — ExercisesView.swift
if loading && payload == nil {
    SpriteOverlayView(preset: .dailyPlanLoading, message: "Loading care plan…")
}
```

**Do not:** Add sprite to per-row `busy` states.

---

## Scenario 2: Empty state on a new list

**User request:** "When history is empty, show a friendly dog moment."

**Agent steps:**

1. Use existing `emptyState` preset — inline mode.
2. Place inside the empty branch of the list, not as a blocking overlay.

```tsx
{items.length === 0 && (
  <SpriteOverlay preset="emptyState" mode="inline" />
)}
```

```swift
if items.isEmpty {
    SpriteOverlayView(preset: .emptyState)
}
```

---

## Scenario 3: Exercise completion moment

**User request:** "Celebrate when a task is checked off."

**Agent steps:**

1. Use `exerciseComplete` preset, **inline** mode.
2. Show briefly or embed in row — avoid full-screen blocking overlay.
3. Prefer a subtle inline companion; do not modal spam.

```tsx
// Option A: inline in completion UI
{justCompleted && (
  <SpriteOverlay preset="exerciseComplete" mode="inline" className="py-4" />
)}
```

**Do not:** Auto-show on every checkbox toggle without UX review.

---

## Scenario 4: New product moment → new preset

**User request:** "When syncing with another caregiver, show a walk animation."

**Agent steps:**

1. Check presets — `caregiverSync` already exists. Wire it; do not create duplicate.
2. If copy differs, override message at call site or update preset in **both** registries.

```tsx
<SpriteOverlay preset="caregiverSync" />
```

If truly new:

1. Add `SpritePresetKey` / `SpritePreset` case
2. Add entry in `presets.ts` and `SpritePreset.swift`
3. Wire screen on iOS + web

---

## Scenario 5: New animation state

**User request:** "Add a `stretch` animation with 3 frames."

**Agent steps:**

1. **Catalog layer only** — extend enum + register metadata:

```ts
// lib/sprites/animations.ts
stretch: { frames: 3, fps: 5, loop: true }
```

```swift
// SpriteAnimation.swift
case stretch

// SpriteAnimationCatalog.swift
.stretch: SpriteAnimationDefinition(frameCount: 3, fps: 5, loops: true)
```

2. Scaffold assets: `stretch_001` … `stretch_003` in both asset trees.
3. Add preset if needed; wire screen.
4. **Do not** edit `StarkSprite.tsx` or `StarkSpriteView.swift`.

---

## Scenario 6: Voice listening UI

**User request:** "Show the dog while listening to voice commands."

**Agent steps:**

1. Use `voiceListening` preset (inline).
2. Show when recording is active, not during processing (that's `voiceProcessing`).

```tsx
{isRecording && (
  <SpriteOverlay preset="voiceListening" mode="inline" />
)}
```

Keep `VoiceRecordBar` / `VoiceRecordButton` mic control unchanged.

---

## Scenario 7: Calm error state

**User request:** "Network failed — don't show a harsh error."

**Agent steps:**

1. Use `errorRetry` preset inline alongside existing retry button.
2. Do not use blocking overlay unless the entire screen is unusable.

```tsx
{error && !payload && (
  <div className="flex flex-col items-center gap-4 p-6">
    <SpriteOverlay preset="errorRetry" mode="inline" />
    <Button onClick={retry}>Retry</Button>
  </div>
)}
```

---

## Scenario 8: Agent self-check before PR

Before finishing sprite work, verify:

- [ ] No frame paths in screen/feature files
- [ ] Preset exists on iOS **and** web with matching copy
- [ ] Mode is intentional (blocking vs inline)
- [ ] Reduced motion still works (renderer unchanged)
- [ ] Sprite not added to unrelated busy/button states
- [ ] Asset scaffolding updated if new animation added
