# Liar's Level

A short, brutal, funny **troll platformer**: the game lies to you, and the Liar (your smug narrator) laughs when you believe it.
**50 levels in 5 worlds, sorted so every level is harder than the last**, instant respawn, a ghost of your best run, daily challenge, 6 hero skins. Built in **Godot 4.3** (also verified on 4.7.2), GDScript only.

> Licensing: levels, audio (synthesized by `tools/make_audio.py`) and the Liar mascot are original. Sprites, tiles, particles and
> backgrounds come from **CC0** packs by Kenney, ansimuz and the Frogatto contributors (sources + licences in `art_src/SOURCES.md`,
> files actually used in `art/USED.md`). Font: **Lilita One** (SIL OFL, `fonts/OFL.txt`). Nothing comes from the extracted *Level Devil* APK.

## Run it
- Open the folder in Godot 4.3+ and press F5, or `godot --path .`
- Controls: **Arrows / A D** move, **Space / Up / W** jump, **R** restart, **Esc / P** pause.
  Gamepad (stick/D-pad + A) and on-screen touch buttons work too (they appear automatically on touchscreens).

## The idea (why it's addictive)
- **Every lie is learnable.** Each trap has a *tell*: hidden spikes leave faint specks, crumbling floor is cracked,
  shy floor sweats, ceiling blocks have angry eyes, fake doors have a red frame, invisible blocks glow faintly,
  the runaway door has eyes. Die once, learn it, never die to it again.
- **Respawn in 0.38 s**, no loading, no lives. "One more try" is one keypress.
- **Short levels** (4-10 s when you know them). Level 1 is honest on purpose, so you trust the signs; then level 2 betrays you.
- **The Liar talks**: a taunt on every death (by cause and by death count), a "skip level" button after 10 deaths, hint after 6.
- **Return hooks**: Daily Lie (one level/day, streak counter), best times, perfect-coin stars, 6 hero skins unlocked by progress,
  rank titles (Gullible -> Master of Lies), "Copy brag" button on clear/ending.
- **Audio matches the trolling**: cheerful music while it lies to you (world 1), nervy (2), sly swing (3), frantic (4), boss theme (20).
  Music ducks on deaths so the sound effects/jokes cut through; sad-trombone sting every 9th death.

## Mechanics (legend lives at the top of `tools/build_levels.py`)
Signs that lie - hidden spikes - fake doors - crumbling floor - shy floor (vanishes as you approach) - ceiling blocks that drop when you
walk under (and can stack into stairs) - invisible blocks - runaway exit door (flees up to 3 times) - "DO NOT PRESS" button -
saws - springs - cursed coin (reverses controls) - **moving platforms and lifts** - **rising lava** - **gravity pads** (walk on the ceiling) -
**the fake "LEVEL CLEARED" screen** (it shatters, then the real exit appears).

## Gameplay systems
- **Ghost race:** your best run is recorded (inputs only) and replayed as a translucent ghost next time. The simulation is deterministic, so the replay is exact (`tests/ghost_test.gd`).
- **Nothing moves until you do:** saws, platforms and lava start on your first input, so every attempt is identical and idle time can't hurt you.
- **The Liar reacts:** taunts by cause and death count, plus reactions to repeated deaths in the same spot, idling, restart-spamming, coins and first death.
- **Fair by construction:** every level has a scripted bot solution; `tests/robust.gd` jitters it by +-12 px and levels below ~85% get re-designed (e.g. a 1 px-margin spike in Moving Day was found and fixed this way).
- **Onboarding:** level 1 shows the controls and teaches trust before betraying it.

## Project layout
```
scripts/world.gd        deterministic simulation (physics + every trap). No nodes, fully testable.
scripts/art.gd          texture loader for the CC0 packs (art/ = used files, art_src/ = untouched downloads)
scripts/play.gd         gameplay screen: rendering, input, HUD, overlays, touch controls
scripts/menu.gd, levels_screen.gd, ending.gd, main.gd   screens + fade manager
scripts/game.gd         autoload: save file, progression, daily streak, taunts
scripts/sfx.gd          autoload: sound pool, looping music, ducking
scripts/level_data.gd   GENERATED from tools/build_levels.py (do not hand-edit)
tools/build_levels.py   author levels here (32x18 grid, 40 px cells) + their bot solutions
tools/make_audio.py     synthesizes every sfx and music loop -> audio/*.wav
tests/                  headless tests (below)
```

## Tests (all passing)
```
godot --headless --path . --import                                  # first time only
godot --headless --path . --script res://tests/run_tests.gd         # every level beaten by a scripted bot
godot --headless --path . --script res://tests/robust.gd            # fairness: +-12 px timing jitter on every jump
godot --headless --path . --script res://tests/input_test.gd        # real keyboard path, death/respawn, pause
godot --headless --path . --script res://tests/ghost_test.gd        # a recorded run replays exactly in a fresh world
godot --headless --path . -- --autoplay                             # plays the REAL game, menus to ending, bot driven
```
`tools/lv.sh <n>` rebuilds the levels and traces level n's bot run (handy when you author a level).
Workflow for a new level: add it in `build_levels.py` with a `sol=[...]` bot script; if the bot can't beat it, the level isn't done.

## Build an Android APK
Godot 4.7.2 + its Android templates + SDK/JDK are configured on this PC. `export_presets.cfg` is ready
(package `com.dhoola.liarslevel`, landscape, arm64). A signed **debug** APK is at `build/LiarsLevel-debug.apk`.
For Play Store you need a release keystore and an AAB (set `gradle_build/use_gradle_build=true`, export format AAB) - not done here.

## Honest status
- Verified: simulation, 20/20 solvable, fair timing margins, full menu->ending flow, keyboard input, runs on Godot 4.3 and 4.7.2, APK builds+signs.
- **Not verified**: on-device touch feel (no phone connected), and the audio *by ear* (I can't listen; levels were checked numerically: no clipping, no DC).
  A human play-through and a pass on music taste are the next steps. Tune `Game.SKIP_AFTER`, `World.RESPAWN_DELAY`, and the taunt lists freely.
- No game can guarantee player retention; this one is built with the known levers (instant retry, learnable surprise, daily streak, humour, share hook).

## Monetization (`scripts/ads.gd`, autoload `Ads`)
- Rewarded ads, optional: **Skip level** (after 10 deaths) and **Hint** (after 6 deaths).
- Interstitial only on level-clear -> next level: not before 3 levels cleared, every 3rd clear, >= 90 s apart, never after a death.
- **Remove Ads** (interstitials only). Test: `tests/ads_test.gd`.
- Modes: `mock` (debug builds / `--mock-ads`: fake "TEST AD" screen), `off` (release build without SDK: no ads, skip/hint are free).
- **Real ads/billing are NOT wired yet.** To ship: install the Godot AdMob plugin + Play Billing plugin, switch to the Gradle export (AAB, release keystore),
  put your AdMob IDs in `ads.gd` (it holds Google's public test IDs), fill `_sdk_rewarded/_sdk_interstitial`, set `mode="admob"`, and make the Remove Ads purchase set `Game.data.ads_removed`.
  Also needed: Play developer account, privacy policy URL, Data safety form; do not target children.

## Opening sequence
1. `scripts/brand.gd`: GAMICS brand opening played in the game's own world (dusk forest, ember falls, emblem slams in, light sweep, "PRESENTS", the Liar vouches for the studio). Uses `art/brand/emblem*.png` and `audio/gamics_intro.wav` (timed so the impact lands at 0.75 s).
2. `scripts/intro.gd`: the game intro (hero, lying sign, hidden spike, "I lied", logo slam).
3. `scripts/menu.gd`: menu built from the pixel-art kit in `art/menu/`.
Tap/click/any key skips each part. Dev flags: `--intro` starts at the game intro, `--menu` at the menu.

## Level order and difficulty
`tools/build_levels.py` scores every level (trap types and counts, wide gaps, number of jumps, solution length) and sorts all 50 levels from
easiest to hardest. The first level is the tutorial and "The Liar" is always the finale. The score is saved as `diff` in `scripts/level_data.gd`;
`tests/levels_test.gd` fails if two levels are identical or if the score is not strictly increasing. Old saves (24-level order) are remapped by level name.
This is a model, not a substitute for playtesting: re-order if real players find a level easier/harder than its slot.

## Controls settings
Menu or pause menu > CONTROLS: drag each on-screen button, change size and opacity, left-handed mode, reset (`scripts/controls_editor.gd`, saved in `Game.data.controls`).
