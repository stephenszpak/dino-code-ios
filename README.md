# DinoCode

A kindergarten-friendly iPad app that teaches 5-year-olds what a software
developer does: tap arrow buttons to build a little "program," hit PLAY, and
watch a dinosaur execute it step by step across a grid to reach a cookie.
Built for a school show-and-tell - landscape-only, big tap targets, designed
to be AirPlayed to a classroom screen while a kid holds the iPad.

## How it works

Tapping an arrow **doesn't** move the dinosaur - it appends an arrow icon to
the program strip. PLAY runs the whole queued program, one grid step per
second, so a wrong move fails visibly at the step that caused it (a wall
bump/obstacle bonk) instead of silently. CLEAR resets the program and the
dinosaur's position. Reaching the cookie triggers a confetti + haptic
celebration, and PLAY turns into a NEXT LEVEL button.

- **3 hand-designed levels** teaching the basics (straight line, combining
  directions, routing around an obstacle).
- **10 more levels, procedurally generated** on the fly (up to 4 rocks each),
  deterministically seeded per level number so replaying a level doesn't
  reshuffle it mid-demo.
- **3 selectable dino skins** (Meadow / Sunset / Berry) - same shape, only
  the color palette changes, chosen from a dedicated skin-picker screen.

## Requirements

- Xcode 16+ / iPadOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
  - The `.xcodeproj` is generated from [`project.yml`](project.yml) and is
    **not** committed to git - regenerate it after cloning, and again
    anytime you add/remove/rename a file.

## Getting started

```bash
xcodegen generate
open DinoCode.xcodeproj
```

Then run on an iPad simulator (this was built/tested against iPad Pro 13").
The app is landscape-only, so if the simulator boots in portrait you may
need to rotate it once (Device menu, or ⌘←/⌘→) to see it upright.

## Project structure

```
DinoCode/
  App/            App entry point + Info.plist
  Models/         GameState (the SwiftUI <-> SpriteKit bridge), levels,
                  procedural level generator, dino skins
  SpriteKit/      GameScene, the dino's shape + animations, grid/cookie/
                  obstacle rendering, confetti
  Audio/          Synthesized tap/step/win/bonk tones (AVAudioEngine,
                  no sound files) + haptics
  UI/             SwiftUI chrome: arrow pad, program strip, level selector,
                  play/clear/undo buttons, skin picker
```

`Models/GameState.swift` is the one shared `ObservableObject` that both
SwiftUI and SpriteKit read/write - it's the thing to read first if the
SwiftUI-drives-SpriteKit pattern is new to you; it's heavily commented for
exactly that reason.

## Live-tweaking during a demo

Colors, sizes, and animation timings are all named constants near the top of
their files rather than buried in the drawing code - `DinoShapeBuilder.swift`
(shape) and `DinoNode.swift` (animation) are the two most fun to open and
change live in Xcode ("watch what happens if I change this number").

## Regenerating the Xcode project

Any time you add, remove, or rename a file:

```bash
xcodegen generate
```

Don't hand-edit `DinoCode.xcodeproj` - it's regenerated from `project.yml`
and isn't tracked in git.
