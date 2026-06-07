# Stark Sprite — When to Use What

Quick reference for new workflows. Read [SKILL.md](SKILL.md) for architecture. Prefer **presets** over custom animation props.

## Decision flowchart

```
New UI moment?
├─ Full-screen initial fetch?        → dailyPlanLoading (blocking)
├─ Inline/panel fetch?               → dailyPlanLoading (inline, size small)
├─ User recording voice?             → voiceListening (inline web bar / blocking iOS screen)
├─ Transcribing or processing voice? → voiceProcessing (blocking overlay)
├─ Saving qualitative note only?     → savingNote (blocking) — NOT generic busy
├─ Task/movement marked COMPLETED?   → SpriteCompletionFlash (inline, ~2.5s)
├─ List or section empty?            → emptyState (inline, size small)
├─ Fatal load failure + retry?       → errorRetry (inline) + Retry button
├─ Marketing / brand moment near CTA?→ StarkSprite idle (small, corner badge) — no preset
└─ None of the above?                → Check stub presets below OR add new preset
```

## Preset cheat sheet

| User situation | Preset | Animation | Mode | Size | Do NOT use for |
|----------------|--------|-----------|------|------|----------------|
| Opening app, Today tab, profile, calendar month, redirects | `dailyPlanLoading` | run | blocking or inline | medium / small | Button `busy`, row saves |
| Mic open, awaiting speech | `voiceListening` | idle | inline (web) / blocking (iOS screen) | small | Processing/transcribe phase |
| Uploading or matching voice note | `voiceProcessing` | run | blocking | medium | Mic button spinner |
| Saving recovery note (notes field) | `savingNote` | bark | blocking | medium | Checkbox, skip, status toggle |
| Exercise checked off | `SpriteCompletionFlash` | sitA/sitB/playbow (rotated) | inline | small | Skip, uncheck, every tap |
| No logs, no tasks, empty bucket | `emptyState` | idle | inline | small | Loading state |
| Network/load failed, calm retry | `errorRetry` | sitB | inline | medium | Inline caption errors mid-screen |
| Bucket score updating | `recoveryScoring` | walk | blocking | medium | *(stub — wire when scoring UI exists)* |
| Daily plan 100% done | `dayComplete` | playbow | inline | medium | *(stub)* |
| Reminder onboarding | `notificationSetup` | sitA | inline | medium | *(stub)* |
| Another caregiver synced | `caregiverSync` | walk | inline | medium | *(stub)* |

## Animation mood guide

| Animation | Feels like | Good for |
|-----------|------------|----------|
| `idle` | Calm, present | Empty states, listening, marketing badge |
| `run` | Active, working | Loading, voice processing |
| `walk` | Steady progress | Recovery scoring, sync |
| `sitA` / `sitB` | Settled, attentive | Completion flash, errors (sitB), reminders |
| `bark` | Short acknowledgment | Saving notes |
| `playbow` | Warm invitation | Day complete, playful marketing |

## Where sprites already live (copy these patterns)

### Loading (`dailyPlanLoading`)

| Location | File |
|----------|------|
| Today / bucket detail | `TodayPageClient.tsx`, `BucketDetailClient.tsx`, `TodayView.swift`, `BucketDetailView.swift` |
| History, tasks, calendar, profile | `HistoryClient.tsx`, `TasksPageClient.tsx`, `CalendarPageClient.tsx`, `ProfileClient.tsx` + iOS views |
| Redirects | `app/(dashboard)/today/page.tsx`, `history`, `calendar`, `exercises`, `profile`, `tasks` |
| Bootstrap | `BootstrapView.swift` |
| Onboarding gate | `onboarding/page.tsx` |

Message override examples: `"Opening Stark's care log…"`, `"Loading profile…"`, `"Loading plans…"`

### Voice

| Phase | Web | iOS |
|-------|-----|-----|
| Listening | `VoiceRecordBar.tsx` — inline `voiceListening` | `VoiceRecordCoordinator.isRecording` → Today/Bucket `.overlay` |
| Processing | Today/Bucket — `isTranscribing \|\| hasProcessingNotes` | `isTranscribing \|\| voiceRecord.isProcessing` |

### Rows (Task / Movement / Action)

| Moment | Web | iOS |
|--------|-----|-----|
| Note save | `savingNote` when `body.notes !== undefined` | `TaskRowView` — `fullScreenCover` + `savingNote` |
| Completion | `SpriteCompletionFlash` after `status: 'COMPLETED'` | `SpriteCompletionFlashView` same trigger |

Files: `TaskRow.tsx`, `MovementRow.tsx`, `ActionRow.tsx`, `TaskRowView.swift`, `MovementRowView.swift`

### Empty + error

| Moment | Files |
|--------|-------|
| Empty lists | `HistoryClient`, `CalendarDayPanel`, `TasksPageClient`, `BucketDetailClient`, iOS History/Exercises/CalendarDayPanel/BucketDetail |
| Fatal error | `TodayPageClient`, `CalendarDayPanel`, `TodayView`, `BootstrapView` |

### Marketing

| Location | Pattern |
|----------|---------|
| Landing hero | `MarketingHero.tsx` / `MarketingHeroView.swift` — `StarkSprite animation="idle" size="small"` corner badge near CTAs |
| Feature cards | Defer unless requested — do not replace every Lucide icon |

## Building a new workflow (agent checklist)

1. Name the care moment (load / save / empty / error / voice / complete / brand).
2. Look up preset in cheat sheet — use existing if match.
3. Pick **mode**: blocking only when user must wait; inline for empty/complete/error beside content.
4. Wire **one line** at screen level — never frame paths or fps in feature code.
5. Mirror iOS + web if the flow exists on both.
6. Skip: per-button spinners, mic processing spinner, skip/uncheck celebrations.

## Stub presets (defined, not yet wired everywhere)

Wire these when the product moment ships — do not duplicate:

- `recoveryScoring` — bucket score computation overlay
- `dayComplete` — all daily tasks finished
- `notificationSetup` — reminder onboarding screen
- `caregiverSync` — multi-caregiver timeline update toast
