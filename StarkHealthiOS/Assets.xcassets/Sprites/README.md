# Stark Sprite Assets

Transparent PNG frames for the Stark dog sprite companion system.

## Folder structure

```
Sprites/Stark/
  idle/idle_001.imageset … idle_005.imageset
  run/run_001.imageset … run_003.imageset (3 frames)
  walk/walk_001.imageset … walk_004.imageset
  sitA/sitA_001.imageset … sitA_002.imageset
  sitB/sitB_001.imageset … sitB_002.imageset
  bark/bark_001.imageset … bark_002.imageset
  playbow/playbow_001.imageset … playbow_002.imageset
```

Each `.imageset` expects a `{name}.png` file with a transparent background at 1x scale. Add `@2x` and `@3x` variants in the imageset if needed.

## Naming convention

Frame asset names are `{animation}_{NNN}` with zero-padded three-digit index, e.g. `idle_001`, `run_004`.

Asset names must be unique across the catalog — folder groups are organizational only.

## Adding a new animation

1. Add a case to `SpriteAnimation` in `Models/SpriteAnimation.swift`.
2. Register frame count, fps, and loop behavior in `Utilities/SpriteAnimationCatalog.swift`.
3. Create a folder under `Sprites/Stark/{animation}/` with one `.imageset` per frame.
4. Optionally add a `SpritePreset` case in `Models/SpritePreset.swift`.

No changes to `StarkSpriteView` or `SpriteOverlayView` are required.

## Usage

```swift
// Preset
SpriteOverlayView(preset: .dailyPlanLoading)

// Custom
SpriteOverlayView(
    animation: .run,
    message: "Fetching today's PT plan…",
    mode: .blocking
)

// Inline sprite only
StarkSpriteView(animation: .idle, size: .small)
```
