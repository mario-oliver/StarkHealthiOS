---
name: stark-sprite-companion
description: >-
  Guides agents through Stark Health's three-layer dog sprite system (Catalog →
  Renderer → Overlay) on iOS and web. Use when adding loading states, empty
  states, voice UX, exercise completion moments, sprite presets, new animations,
  or any StarkSprite / SpriteOverlay integration in StarkHealthiOS or stark-sesh.
---

# Stark Sprite Companion System

Premium companion layer — not a game mascot. Sprites reduce anxiety during loading and warm care routines. Use **selectively**; do not replace every spinner or celebrate every tap.

## Three-layer stack

Agents must work top-down. Screens never hardcode frame paths.

```
Layer 3 — Overlay   SpriteOverlayView / SpriteOverlay   (message, mode, scrim)
Layer 2 — Renderer  StarkSpriteView / StarkSprite        (frame animation)
Layer 1 — Catalog   SpriteAnimationCatalog / SPRITE_ANIMATION_DEFINITIONS  (fps, frames, loop, asset names)
```

| Layer | Responsibility | Agent edits when… |
|-------|----------------|-------------------|
| **Catalog** | Frame count, fps, loop, asset name resolution | Adding a new animation state |
| **Renderer** | Steps through frames; respects reduced motion | Rarely — only for renderer behavior changes |
| **Overlay** | Layout, copy, blocking/inline, background, entrance | Rarely — only for overlay UX changes |
| **Preset** | Maps care context → animation + copy + mode | Adding or changing a product moment |
| **Screen** | Chooses preset or passes animation + message | Wiring a feature to the sprite system |

**Rule:** Feature code imports Layer 3 (or Layer 2 for inline-only). Never import frame paths in screens.

## File map

### iOS (`StarkHealthiOS/StarkHealthiOS/`)

| Layer | File |
|-------|------|
| Catalog | `Utilities/SpriteAnimationCatalog.swift` |
| Types | `Models/SpriteAnimation.swift` |
| Presets | `Models/SpritePreset.swift` |
| Renderer | `Components/Sprite/StarkSpriteView.swift` |
| Overlay | `Components/Sprite/SpriteOverlayView.swift` |
| Assets | `Assets.xcassets/Sprites/Stark/{animation}/{name}.imageset/` |
| Asset docs | `Assets.xcassets/Sprites/README.md` |

### Web (`stark-sesh/`)

| Layer | File |
|-------|------|
| Catalog | `lib/sprites/animations.ts` |
| Types | `lib/sprites/types.ts` |
| Presets | `lib/sprites/presets.ts` |
| Hook | `lib/sprites/use-sprite-animation.ts` |
| Renderer | `components/sprite/StarkSprite.tsx` |
| Overlay | `components/sprite/SpriteOverlay.tsx` |
| Assets | `public/sprites/stark/{animation}/{animation}_{NNN}.png` |

## Agent decision workflow

Copy this checklist when adding sprite UX:

```
- [ ] 1. Identify care context (loading, voice, empty state, etc.)
- [ ] 2. Check if a preset already exists — prefer preset over custom props
- [ ] 3. Choose mode: blocking (full-screen wait) vs inline (empty state, embedded)
- [ ] 4. Wire at screen level only — do NOT duplicate animation logic
- [ ] 5. Update BOTH platforms if the moment is cross-platform
- [ ] 6. Keep inline busy/button spinners unchanged unless explicitly requested
```

### Choose preset vs custom

**Use a preset** when the moment matches an existing care context:

| Preset | Animation | Mode | Use when |
|--------|-----------|------|----------|
| `dailyPlanLoading` | run | blocking | Initial fetch of today's plan |
| `voiceListening` | idle | inline | Mic active, awaiting speech |
| `voiceProcessing` | run | blocking | Transcribing / matching to plan |
| `exerciseComplete` | sitA | inline | Task or movement checked off |
| `savingNote` | bark | blocking | Persisting a recovery note |
| `recoveryScoring` | walk | blocking | Computing bucket scores |
| `emptyState` | idle | inline | No activity logged yet |
| `notificationSetup` | sitA | inline | Reminder onboarding |
| `dayComplete` | playbow | inline | Daily plan finished |
| `errorRetry` | sitB | inline | Calm failure state |
| `caregiverSync` | walk | inline | Another caregiver logged care |

**Use custom props** only to override message/subtext on an existing preset, or for one-off experiments before promoting to a preset.

### Choose mode

| Mode | Blocks interaction | Typical placement |
|------|-------------------|-------------------|
| `blocking` | Yes | `if (loading) return <SpriteOverlay … />` or `.overlay { … }` over screen |
| `inline` | No | Empty states, completion prompts, embedded companion moments |

Default backgrounds: `dimmed` for blocking, `transparent` for inline.

## Integration patterns (copy these)

### Web — full-screen loading

```tsx
import { SpriteOverlay } from '@/components/sprite/SpriteOverlay'

if (loading) {
  return <SpriteOverlay preset="dailyPlanLoading" mode="blocking" />
}
```

### Web — voice processing over content

```tsx
{(isTranscribing || hasProcessingNotes) && (
  <SpriteOverlay preset="voiceProcessing" />
)}
```

### Web — inline empty state

```tsx
<SpriteOverlay preset="emptyState" mode="inline" />
```

### Web — sprite only (no copy)

```tsx
import { StarkSprite } from '@/components/sprite/StarkSprite'

<StarkSprite animation="idle" size="small" />
```

### iOS — full-screen loading

```swift
if loading && payload == nil {
    SpriteOverlayView(preset: .dailyPlanLoading)
}
```

### iOS — voice processing overlay

```swift
.overlay {
    if isTranscribing || session.voiceRecord.isProcessing {
        SpriteOverlayView(preset: .voiceProcessing)
    }
}
```

### iOS — preset with message override

```swift
SpriteOverlayView(preset: .dailyPlanLoading, message: "Opening Stark's care log…")
```

## Adding a new preset (agent workflow)

When product asks for a new care moment:

1. Add preset key to **both** `SpritePreset.swift` and `lib/sprites/types.ts` + `lib/sprites/presets.ts`
2. Pick animation from catalog; write calm, premium copy (no exclamation spam)
3. Set `mode` and `background` per decision table above
4. Wire in the target screen(s) on iOS and web
5. Do **not** add frame paths or fps values in screen files

## Adding a new animation (agent workflow)

1. Add case to `SpriteAnimation` enum / `SPRITE_ANIMATIONS` union
2. Register in catalog: frame count, fps, loop
3. Scaffold assets:
   - iOS: `{animation}_{NNN}.imageset` under `Assets.xcassets/Sprites/Stark/{animation}/`
   - Web: `public/sprites/stark/{animation}/{animation}_{NNN}.png`
4. Optionally add preset(s) that use the new animation
5. Renderer and overlay components need **no changes**

Frame naming: `{animation}_{NNN}` with zero-padded three digits (`idle_001`).

## Design constraints (enforce on every change)

- Premium, calm, warm — appropriate for aging dog care
- Motion sparingly; no bounce, no gamification
- Do not add sprites to every `busy` flag or button save state
- Do not replace the mic button spinner (`VoiceRecordButton`) unless explicitly requested
- Respect reduced motion (built into renderer; do not bypass)
- Cross-platform parity: same preset keys and copy on iOS and web

## Anti-patterns

| Don't | Do instead |
|-------|------------|
| Hardcode `/sprites/stark/run/run_001.png` in a screen | Use preset or `animation="run"` |
| Duplicate fps/frame logic in a feature | Extend catalog only |
| Add celebration overlay on every checkbox toggle | Use `exerciseComplete` inline sparingly |
| Create a one-off sprite component in a feature folder | Use `StarkSprite` / `SpriteOverlay` |
| iOS-only preset without web mirror | Update both preset registries |

## Existing integrations (reference)

| Screen | Preset | Trigger |
|--------|--------|---------|
| `TodayView` / `TodayPageClient` | `dailyPlanLoading` | Initial load |
| `TodayView` / `TodayPageClient` | `voiceProcessing` | Transcribing or notes processing |
| `BucketDetailView` / `BucketDetailClient` | `dailyPlanLoading`, `voiceProcessing` | Same |
| `BootstrapView` | `dailyPlanLoading` (custom message) | App bootstrap |

## Additional examples

For full before/after agent scenarios, see [examples.md](examples.md).
