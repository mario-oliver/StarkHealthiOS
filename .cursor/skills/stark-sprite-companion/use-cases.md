# Stark Sprite — When to Use What

Quick reference for new workflows. Read [SKILL.md](SKILL.md) for architecture. Prefer **presets** over custom animation props.

## Decision flowchart

```
New UI moment?
├─ App bootstrap / care log entry?   → careLogOpening (blocking)
├─ Full-screen in-app fetch?         → dailyPlanLoading (blocking)
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
| App bootstrap, `/today` redirect | `careLogOpening` | run | blocking | medium | In-app fetches, tab redirects |
| In-app fetch (Today tab, profile, calendar, history, tasks) | `dailyPlanLoading` | idle | blocking or inline | medium / small | Button `busy`, row saves, care log entry |
| Mic open, awaiting speech | `voiceListening` | bark | inline (web) / blocking (iOS screen) | small | Processing/transcribe phase |
| Uploading or matching voice note | `voiceProcessing` | bark | blocking | medium | Mic button spinner |
| Saving recovery note (notes field) | `savingNote` | walk | blocking | medium | Checkbox, skip, status toggle |
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
| `idle` | Calm, present | In-app loading, empty states, marketing badge |
| `run` | Active welcome | Care log entry only |
| `walk` | Steady progress | Note saves, recovery scoring, sync |
| `sitA` / `sitB` | Settled, attentive | Completion flash, errors (sitB), reminders |
| `bark` | Short acknowledgment | Voice recording and processing |
| `playbow` | Warm invitation | Day complete, playful marketing |

## Where sprites already live (copy these patterns)

### Care log entry (`careLogOpening`)

| Location | File |
|----------|------|
| Web redirect | `app/(dashboard)/today/page.tsx` |
| iOS bootstrap | `BootstrapView.swift` |

### Loading (`dailyPlanLoading`)

| Location | File |
|----------|------|
| Today / bucket detail | `TodayPageClient.tsx`, `BucketDetailClient.tsx`, `TodayView.swift`, `BucketDetailView.swift` |
| History, tasks, calendar, profile | `HistoryClient.tsx`, `TasksPageClient.tsx`, `CalendarPageClient.tsx`, `ProfileClient.tsx` + iOS views |
| Tab redirects | `history`, `calendar`, `exercises`, `profile`, `tasks` redirect pages |
| Onboarding gate | `onboarding/page.tsx` |

Message override examples: `"Loading profile…"`, `"Loading plans…"`

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
