# "Workshop Tin" GUI/HUD Style Guide (A+ Hybrid)

**Status:** approved by Quentin, 2026-11-12. This is the house UI style for Camel Claus: The North Pole and
the starting template for future games (hackathon included). It is the UI half of the art direction; the
world/model half is `../Camel_Claus_Retro_Style_References/Camel_Claus_Modern_Retro_Art_Direction.md`.

**See it live:** `design_prototypes/camel_claus_ui_showcase.html` (tab **A+ Hybrid**) and
`design_prototypes/camel_claus_splash_showcase.html` (tab **Knit + Tin**). Reference captures are in
`screens/` (1280×720, the game's design canvas). When this guide and the prototype disagree, the prototype
CSS (`design_prototypes/ui/concept_a.css` + `concept_h.css`) holds the exact numbers.

---

## 1. The style in one breath

Bold, tactile arcade UI in the Megabonk tradition (riveted enamel plates, slab buttons you press, corner
brackets that jump to the selection, rarity-colored upgrade rows, a bare outlined HUD), dressed for the
North Pole with two **accent layers** used sparingly:

| Layer | What it is | Where it may appear |
|---|---|---|
| **Base: Workshop Tin** | Navy enamel plates, pine header band, brass rivets, steel double line, slab buttons, corner brackets, blackletter titles + pixel body | Everywhere |
| **Cozy: Ugly Sweater** | Knit texture, Fair Isle camel trim, sewn wooden sweater buttons, knitted curtain wipe | Behind cards, under panel headers, slider/toggle knobs, screen transitions, intro |
| **Post: North Pole Mail** | Postage stamps, postmarks, airmail stripes, luggage tag, postcards | Rewards: achievements, goals, results, toasts, picked upgrades, level badge |

**The rule that keeps it polished:** the base carries every screen; accent layers only *decorate rewards and
transitions*. The gameplay HUD stays pure base (no knit, no stamps) because readability mid-fight wins.

### Screen × layer matrix

| Screen | Base | Knit | Post |
|---|---|---|---|
| Main menu | ✔ layout, plates, slabs | trim under panel headers; goal cards knit | stamp icons on goal cards; postmark beside the logo |
| Level up | ✔ modal plate, rarity rows, slab actions | knit inside offer rows; trim under header | luggage-tag "Lv 9 → 10"; postmark slams onto the pick |
| Gameplay HUD | ✔ only | – | airmail toast for achievements (corner, transient) |
| Pause | ✔ three plates | trim under headers | – |
| Settings | ✔ plate, rows | subtle knit in body; sweater-button knobs; yarn-striped slider fill | – |
| Achievements | ✔ frame, header, tabs | trim | **the list is a postcard**: airmail border, ruled lines, stamps, postmarks, "Delivered" |
| Customize | ✔ plates, nameplate tiles | knit tiles (it's a wardrobe) | – |
| Results | ✔ plates | trim | **"Greetings from the North Pole!" postcard** header with stamp + postmark |
| Transitions | – | knitted curtain drops and lifts | – |
| Intro / splash | riveted subtitle plate, chunky logo | knitted background, scarf loader, needles knit the logo | – |

---

## 2. Principles

1. **Readable first.** Text and numbers are crisp at native resolution and never pixel-blurred. Titles are
   blackletter *flavor* (**New Rocker**, chosen by Quentin 2026-11-12) not unreadable textura; body/numbers are a clean pixel face (Tiny5,
   whose 5 ≠ S). Anything players read under pressure (HUD) has a 2 px dark outline and no texture behind it.
2. **Tactile.** Everything clickable looks pressable: a lighter top bevel, a dark bottom lip, and it moves
   down 4 px when pressed. Selection is always shown by the same corner brackets.
3. **One recipe per thing.** One plate, one header, one button family, one tile, one bar. New screens are
   assembled from these, never restyled ad hoc.
4. **Boldness in one place per screen.** The menu's logo, the level-up's rarity rows, the results'
   postcard. Everything around them stays disciplined.
5. **Information design from Megabonk:** offers as rows with before → after numbers (new value green),
   counted action buttons (count above the button), stats as a two-column list, quests/achievements as
   rows with a progress bar and the reward in the last column, a panel-free HUD.
6. **Cheap.** 9-slice textures, flat colors, tweens of position/scale/rotation/alpha. No blur, no glass,
   no full-screen shaders in menus. Web (GL Compatibility) friendly.
7. **Purple = danger/epic, gold = rewards, ice = rare, red = destructive.** Never decorative.

---

## 3. Tokens

All sizes are in **720p design-canvas pixels** (1280×720, stretch `canvas_items`).

### 3.1 Color

| Token | Hex | Use |
|---|---|---|
| `ink-dark` | `#0D1322` | outlines, text outline, button outer ring, drop lips |
| `plate` | `#1A2438` | panel body fill |
| `plate-2` | `#263450` | rows/cards on a plate (common) |
| `navy` | `#22304F` | game navy (art bible); postmark ink; curtain shadow |
| `steel` | `#5C77AB` | inner hairline of plates and bars |
| `band` | `#1F5A43` | panel header band (pine), band shade `#163F30` |
| `text` | `#F4F8FF` | primary text |
| `muted` | `#A9BDDC` | secondary text on plates |
| `label` | `#E8C48E` | stat names in offers ("Damage:"), section subheads |
| `title-gold` | `#FFD64F` | goal/quest titles |
| `gold` | `#F2B53B` | XP, coins, primary button, levels, evolution |
| `good` | `#4CE06A` (bars) / `#8DE09F` (text) | new values, progress |
| `hp` | `#E5222F` on `#3A1218` | health bar |
| `boss` | `#9B4FD1` on `#200F2E` | boss bar, banner stroke `#4A1F6E` |
| `done-row` | `#2E5D8F` + line `#6FA0D8` | completed list rows (Megabonk blue) |
| `tab-progress` | `#E08A2C` | category progress bars on tabs |
| `toggle-on` | `#2E8A4A` | switch track when on |
| **Knit layer** | | |
| `knit-red` | `#8E1F2E` | Fair Isle trim base, curtain, splash background |
| `knit-pine` | `#1F5A43` | scarf loader body |
| `yarn` | `#F4E6D4` / `#D9C3A8` | yarn ball stripes |
| `wood` | `#D9A56A` / `#C98F55` / `#8A5A33` | sweater button face / rim / ring; holes `#3E2619`, thread `#F4F8FF` |
| **Post layer** | | |
| `paper` | `#F4F8FF` | postcard, stamp paper, toast, luggage tag |
| `airmail` | `#D9343F` / `#F4F8FF` / `#3A5B9C` | stripe border (9 / 6 / 9 / 6 px at -45°) |
| `stamp-frame` | common `#D9343F`, rare `#3A8FBF`, epic `#7B3FB0`, evo `#E0A22A` | stamp inner frame |
| `stamp-field` | `#DCE6F5` | stamp picture area |
| `postmark` | `#22304F` @ 55–78% on light, `#F4F8FF` @ 90% on dark | cancellation marks |
| `post-red` | `#C42F3A` | "Greetings from the", postcard labels |

**Rarity fills (offer rows / tiles):**

| Rarity | Row fill | Row line | Tile fill | Tag color |
|---|---|---|---|---|
| Common | `#263450` | `#8FA9D1` | `#24314D` | `#8FA9D1` |
| Rare | `#17425C` | `#7FD6F2` | `#1D4A66` | `#7FD6F2` |
| Epic | `#37204F` | `#B47BE6` | `#43265E` | `#B47BE6` |
| Evolution | `#4A3A12` | `#F2B53B` | `#5C4512` | `#F2B53B` |

### 3.2 Type

| Role | Font | Size (720p) | Treatment |
|---|---|---|---|
| Logo | **Bowlby One** | 76 (menu), 110 (intro), 84 (postcard) | `text` fill, 12–14 px `ink-dark` outline, 9–10 px drop shadow straight down |
| Display / titles / buttons / names | **New Rocker** (chosen) | dialog title 36, panel title 27, button 27 (small 19), offer name 27, logo subtitle 36, tag 20 | 2 px `ink-dark` outline (8-direction) |
| Body / numbers / HUD | **Tiny5** | body 18, small 15, HUD counters 27, HUD timer 54, level 40 | 2 px outline on the HUD; 2 px drop on plates |
| Alternatives tested | Germania One (cleanest), Grenze Gotisch 700 | same sizes | switch per game if the vibe changes; never the pixel blackletter for body text |

Rules: sentence case everywhere (no all-caps labels); titles ≤ 3 words in the display face; anything longer
or numeric goes in Tiny5. Minimum display size 18, minimum body size 15. All four fonts are OFL.

### 3.3 Geometry

| Thing | Value |
|---|---|
| Plate border | 3 px `ink-dark` outer ring + 2 px `steel` inner line + 2 px gap + 1 px dark (reads as a double line) |
| Plate drop | 7 px `ink-dark` @ 55%, straight down |
| Rivet | 10 px brass dot (`#FFE6A8` → `#F2B53B` → `#8A5A33`), 6 px from each corner |
| Corner radius | 3 px on buttons, 0 on plates (tin), 50% on knobs |
| Header band | full width, padding 10/20, 3 px dark bottom line + 2 px steel line, then the 18 px Fair Isle trim |
| Button | padding 7/28/12 (top/side/bottom), min height 52; bevel: 3 px light top, 6 px dark lip bottom; 3 px dark ring; 5 px dark drop |
| Tile | 56 px (HUD 46), 2 px rarity line inside, 2 px dark ring |
| Stamp | perforation ring 3.5 px (6.5 px hole pitch), 2 px paper, 2.5 px color frame, picture field |
| Brackets | 15 × 3 px L's, 12 px outside the target, white with 2 px dark drop |
| Gaps | 14–22 between stacked items; panels 32 px from screen edges |

---

## 4. Components

### 4.1 Plate (panel)
Body `plate`, double border, four rivets, drop shadow. Optional **header band** (pine) with the title in the
display face, then the **Fair Isle trim**: an 18 px strip of `knit-red` knit with a repeating white
pixel-camel + snowflake motif, 3 px dark line under it. Content starts 18 px below the trim.

### 4.2 Slab buttons
| Variant | Top bevel / face / lip | Text |
|---|---|---|
| Default | `#6A86BD` / `#3A4D78` / `#1C2742` | `text`, display face, 2 px outline |
| Primary (one per screen) | `#FFE08F` / `#F2B53B` / `#A8742C` | `navy`, no outline |
| Reroll / info | `#9FD8F5` / `#3D82B8` / `#1F4C78` | `text` |
| Banish / danger | `#F28890` / `#C42F3A` / `#7A1C27` | `text` |
| Disabled | `#3A4766` / `#2A3550` / `#1A2238` | `#6F80A3`, no outline |

States: **hover/focus** = brightness +14% and brackets; **pressed** = moves down 4 px, lip shrinks to 2 px;
**disabled** = flat colors above. Sized to their text (menu stacks look hand-stacked, not uniform). Counts
(rerolls left) sit **above** the button in Tiny5 20; key hints are a small outlined `kbd` box inside.
Destructive actions ask twice ("Click again to erase").

### 4.3 Focus brackets
Four white L-brackets around the hovered/focused control, sliding in from 26 → 12 px in 0.16 s with
overshoot. One shared node draws them for every button, card, tab, slider and tile with a tooltip. Mouse
hover and gamepad focus look identical.

### 4.4 Offer row (level up)
Full-width row in the rarity fill with knit texture behind, rivets, rarity-colored 2 px line. Left: 76 px
rarity tile with the icon. Middle: name (display 27, outlined) → one or two stat lines
`Stat: old → new` (stat name `label`, new value `good`) → hint (Tiny5 15 `muted`). Right top: level in gold
("Lv 4 → 5" or "New"). The **rarity name breaks the top border** at the left (display 20–22, tag color).
Hotkey number bottom-right at 55% opacity. Hover: slides 6 px right + brightens. Pick: scale pulse,
others fade, and a white **postmark** stamps onto the row.

### 4.5 Tiles and stamps
Tiles = icons in rarity squares (§3.1). In reward contexts (achievements, goals, inventory on results) the
tile becomes a **stamp**: perforated paper edge, colored inner frame by rarity, light picture field, tilted
±2–3°, 3 px dark drop. Finished = a navy **postmark** (round, "NORTH POLE / DEC 25 / 90° N / CAMEL POST")
overlapping the stamp's corner at ±12–16°.

### 4.6 Bars
Flat, 2 px dark ring. HP 28 px tall with centered "118 / 150" (Tiny5 16, outlined). XP: 9 px hairline
across the top edge of the screen. Santa meter: red → gold gradient. Boss: wide, purple, name above in the
display face. Goal/achievement progress: 8 px green with the count above-right.

### 4.7 Settings controls
Slider: 14 px dark track with steel hairline, **yarn-striped fill** (red/white at 115°), knob = **sewn wooden
sweater button** (32 px: wood face, darker rim, four holes, white thread cross). Toggle: 58×30 track, 24 px
sweater-button knob that rolls 90° as it slides; track turns `toggle-on` with knit texture; the switch comes
**first**, then "On"/"Off" in Tiny5 to its right. Selector: two small square slabs with **snow chevron
icons** (not "<" text) around a gold value that flips in. The settings plate itself is the knit plate
(`PlateTightKnit`), with the header band and close X.

### 4.8 Tabs
Display face 18–19, each with its own count (Tiny5 13) and a 5 px progress bar (`tab-progress`). Active tab
gets a faint steel wash.

### 4.9 Toast (achievement) — airmail envelope
Paper body, 7 px airmail-stripe border, 2 px dark ring, slides in from the right, 2.6 s, slides out.
Trophy icon, "Achievement unlocked" in `post-red` display face, name in navy, coin reward right.

### 4.10 Tooltip
Small plate (rivets), name in display face colored by rarity, "×2" stack in muted, description in Tiny5 15,
max 340 px wide, appears above (or below near the top edge).

### 4.11 Banner
Bowlby 52 white with a 9 px dark-purple stroke and a 6 px drop, scales in from 1.6, holds, fades (2.2 s).

### 4.12 Luggage tag
Paper tag with a notched left point and a punched hole; navy Tiny5 text. Used for "Lv 9 → 10".

### 4.13 Postcard (results)
Paper card, 10 px airmail border, rotated −0.6°. "Greetings from the" (display, `post-red`) above a huge
Bowlby "North Pole!" whose letters are **filled with the snowy diorama** (image-in-text) with a 3 px navy
stroke and 4/5 px navy drop. Right: a Claus **stamp** (perforated, red frame, "5:00" value) with a wavy
postmark across it. Run pills (time, level, "New best run" in red) under the title.

### 4.14 Damage numbers
Tiny5, white 24 (crit 34 gold `#FFD64F`), 2 px dark outline, pop up 1.2× then drift up and fade (0.9 s).

---

## 5. Screen layouts (1280×720)

- **Main menu** (Megabonk composition): logo centered top (y 26); subtitle "The North Pole" in gold display
  36; joke tagline (Tiny5 17, `title-gold`, click for another) at y 176; slab stack centered from y 236,
  Play first as the big gold primary; **Next goals** = three knit cards with stamp icons on the left
  (x 32, y 150, 300 wide); **Best runs** plate right (x 958, y 150, 290 wide, own row highlighted
  `done-row`); small slabs (Settings, Stats, Credits, Quit) bottom-left; Workshop carries a red count badge (upgrades
  you can afford); coins top-right; **control hints bottom center as snow keycaps (navy text) on a dark
  bar with a steel border** (`HintBar` + `KeyCap`): plain small text there was too low-contrast to read as
  controls; version bottom-right. Credits is a plate page (made with, art/music, sounds, music, fonts). Live 3D diorama behind with a soft dark radial veil behind the center
  column. A postmark sits beside the logo subtitle.
- **Level up:** 800 px modal plate centered, header "Level up!" + luggage tag; three offer rows; help line;
  Reroll / Banish slabs with counts above. Behind: the game dimmed 50%, slow gold rays (50 s/turn) and a
  falling ornament shower.
- **HUD:** XP hairline top; top-left: coins + bonks (27), HP bar (270 wide), weapon tiles with "Lv n" under,
  objectives as black boxes with a checkbox; timer top-center (54); "Lv 9" top-right (40); Santa meter
  bottom-left in a dark box (gold ring when ready); item strip bottom-center (46 px tiles, icons outlined in
  their rarity color, "×n" stacks); boss bar under the timer when a boss is up.
- **Pause:** three plates: Your build (weapons with level pips + evolution target, item grid) · Paused (run
  numbers, Resume primary, Settings, Restart run, Main menu) · Stats (grouped two-column list).
- **Settings:** 640 px knit plate centered, header band + close X; groups Sound (sliders + %) / Display
  (Fullscreen, Interface size selector) / Gameplay (Screen shake, Damage numbers, Reduce motion); Reset
  progress (danger, confirm twice) left, Back (primary) right.
- **Achievements:** frame with header "Achievements 6 / 18" + total bar + coins earned + close; tabs with
  per-category progress; the list is a **postcard** (paper, airmail border, "Camel Post · North Pole 90°N"
  label, ruled lines); completed first, each with a stamp, progress bar, reward or "Delivered ✓" + postmark.
- **Customize:** left knit plate with tabs (Hats / Outfits / Skins) and a grid of knit **picture** tiles
  (render of the piece, name strip, coin price when locked, gold plate = worn; skins show a fur-swatch
  ring); Claus preview center (the menu camera moves in); detail plate right (name, line of flavor,
  Equip / Buy primary / Equipped). **Each hat and outfit has exactly one look** (its baked colors): no
  recolor swatches (see §13).
- **Loadout (Play):** two numbered steps so first-timers know what to do. "1. Pack up to 3 weapons" + one
  help line + "n / 3 packed"; weapon cards wear a tag on their top border (Starter gold, Packed ice,
  Locked muted). "2. Choose your starting weapon" + one help line; three wide slots (icon + name) with a
  caption under each ("Starts with you" gold / "Joins at level-ups"). A plain sentence by Start run says
  what will happen ("You start with X. Y and Z can appear when you level up.").
- **Results:** postcard header, then three plates: Damage table · Summary (portrait, stats, inventory
  stamps, rewards, Keep going / Play again / Main menu) · Unlocked.

---

## 6. Motion

| Moment | Spec |
|---|---|
| Panel / dialog enter | scale 0.86 → 1, 0.26 s, back-out (overshoot); stacked buttons stagger 40 ms |
| Offer rows enter | slide 60 px from the right, 0.3 s back-out, stagger 70 ms |
| Brackets | 0.16 s from 26 px out to 12 px, back-out |
| Button press | 4 px down instantly, release on mouse up |
| Screen change | **knitted curtain**: knit + Fair Isle band panel drops (0.27 s, ease-in-out), holds, lifts (0.3 s) |
| Pick an upgrade | postmark slams (scale 2.4 → 1, 0.32 s), row pulses, others fade 0.3 s |
| Reroll | rows flip away on X (0.2 s), new rows slide in |
| Toast | slide in 60 px with overshoot 0.4 s, hold 2.6 s, slide out 0.4 s |
| Results | postcard drops in rotated (0.5 s), postmark stamps at 0.45 s, numbers count up 1.2 s |
| Ambient (menus only) | pixel snow ~70 flakes; level-up rays + ornament shower; nothing ambient on the HUD |
| Reduced motion | all of the above become instant; ambient off; the curtain becomes a 0.2 s fade |

---

## 7. Startup and intro ("Knit + Tin")

Chain: **custom HTML shell loader** (scarf grows with real download progress, label "Knitting your sweater
NN%", yarn ball rolls at its tip, background `knit-red` knit) → **Godot boot** (`boot_splash/show_image =
false`, `bg_color = #8E1F2E`) → **intro scene** (≈4.3 s, skippable on any key/click/tap) → main menu via the
knitted curtain.

Intro beats: 0.3 s needles click while the Bowlby logo is knitted in 12 rows (stepped reveal), a yarn ball
rolls across the bottom unspooling a line · 1.9 s "The North Pole" springs up on a riveted pine plate ·
2.15 s Claus pops up with overshoot then sways · 2.45 s the Santa hat drops onto the C and squashes ·
3.0 s "Press any key" pulses · end: curtain drops and lifts on the menu.

Dev rule: editor runs skip the intro (`OS.has_feature("template")` is false) unless the project setting
`camel_claus/always_show_intro` is on; exported builds always play it. The first launch plays it in full;
later launches play the same timeline at double speed as a ~2 s sting (Profile `seen_intro`).

---

## 8. Building it in Godot (recipe, as implemented)

- **Fonts:** TTFs in `assets/fonts/`. Tiny5 imported with antialiasing **off**, hinting off, subpixel
  positioning off (crisp pixels at any window scale); New Rocker and Bowlby One with default import.
  Outlines are the theme's `outline_size` (≈ 2 × the visible px) + `font_outline_color`; drops are the
  theme's shadow offset with `shadow_outline_size` equal to the outline.
- **Theme:** one generated `.tres`, set as `gui/theme/custom`. Default font Tiny5 18. Every role is a **type
  variation**, and nodes only set `theme_type_variation`:
  - text: `TitleLabel` 36, `HeaderLabel` 27, `TagLabel` 20 (+ `TagCommon/Rare/Epic/Evo`), `GoalTitle`,
    `SubtitleLabel`, `LogoLabel` 76, `LogoBigLabel` 112, `BannerLabel`, `MutedLabel`, `SmallLabel`,
    `GoldLabel`, `GoodLabel`, `StatLabel`, `BigNumber`, `KeyLabel`, `HudLabel`, `HudSmall`, `HudTimer`,
    `HudLevel`, `InkLabel`, `InkSmall`, `InkTitle`, `PostRedLabel`, `ToastTitle`, `SmallRich`, `InkRich`,
    `SubLabel` (section headings), `NameLabel` (names in lists), `TabName`, `BadLabel`, `BadgeLabel`,
    `KeyCapLabel`, `HintLabel`;
  - buttons: `PrimaryButton`, `BigPrimaryButton`, `RerollButton`, `DangerButton`, `SmallButton`,
    `TabButton`, `KnitTileButton`, `RowCommon/Rare/Epic/Evo`, `CardCommon/Rare/Evo`, `CloseButton`;
  - panels: `PanelContainer` (plate), `PlateTight` (for panels with a header), `PlateKnit`, `PinePlate`,
    `HeaderBand` (pine band **with the Fair Isle trim baked into its 9-slice**, edges tiled),
    `KnitCard`, `TileCommon/Rare/Epic/Evo`, `TileHud`, `StampCommon/Rare/Epic/Evo`, `PaperPanel`,
    `AirmailPanel`, `DarkBox`, `DoneRow`, `LuggageTag`, `PlateTightKnit`, `KeyCap`, `HintBar`, `Badge`,
    `Pill`, `PillRed`;
  - bars: `HpBar`, `XpBar`, `GoodBar`, `TabProgress`, `BossBar`, `SantaBar`; plus `HSlider` (yarn fill,
    sweater-button grabber) and `CheckButton`/`CheckBox` (sweater-button switch icons, also as the
    `*_mirrored` icons, `icon_max_width` 0).
- **StyleBoxTexture 9-slices** from generated PNGs (nearest filter is the project default; default 2D import
  is already lossless without mipmaps). Knit plates use `AXIS_STRETCH_MODE_TILE_FIT` so the knit tiles.
  Buttons use expand margins so the dark ring and drop sit outside the click area; the pressed state moves
  the slab and its text down 4 px.
- **Helpers:** `Tin` (`scripts/ui/tin.gd`) builds header bands (`header(title, extra, on_close)` adds the
  red close X), stamps (optionally postmarked), tiles, labels, bars, coin counters (`coin()`), keycaps
  (`keycap()`, `key_hint()`), thousands separators (`num()`) and the postmark slam for UI made in code.
- **Focus brackets:** the `FocusBrackets` autoload (CanvasLayer 99) draws four L's around the hovered,
  else focused, button/range/`brackets`-meta control; menus make buttons grab focus on hover.
- **Knitted curtain:** the `Transition` autoload (CanvasLayer 100) owns a knit TextureRect with a Fair Isle
  band and a dark hem, tweened down (0.27 s) and up (0.3 s) around every scene change.
- **Postcard headline:** white Bowlby with a navy outline (the HTML prototype filled the letters with the
  diorama; the Godot version stays solid for readability and cost; a screen-UV shader can add it later).
- **Intro:** `scenes/ui/splash.tscn` + `splash.gd`: one parallel Tween timeline (`set_delay` per beat), so the
  sting is just `speed_scale` and skipping jumps straight to the curtain. The knitting is a clip Control whose
  height steps 12 times.
- **Web shell:** `art_src/tools/make_web_shell.py` writes `web/shell.html` from Godot 4.7's default shell, with
  the knit tile, band and a Latin New Rocker subset inlined (45 KB); `onProgress` drives the scarf.
- **Never:** per-node font sizes; textures behind HUD text; blur/glass; more than one gold button per screen.

---

## 9. Reusing this for a new game

Keep: the base (plates, slabs, brackets, rows, HUD recipe, motion table, fonts, sizes, principles).
Swap per game: **the two accent layers** (e.g. a beach game might use "towel stripes" for cozy and
"luggage stickers" for post), the header band color, the palette accents (keep dark/plate/steel/text),
the logo font if the name needs it. Rarity colors stay unless the game's danger color collides.
Checklist: (1) copy the theme + generator, (2) set band/accent colors, (3) regenerate textures, (4) build
menu → level up → HUD → pause → settings → results in that order, (5) run a text-fit test at 1280×720 and
a font check (5 vs S, 0 vs O), (6) confirm the HUD has no texture behind numbers.

## 10. Do / don't

- **Do** keep one gold primary button per screen; put counts above action buttons; show before → after.
- **Do** tell the player what to do on any screen with a choice: one plain help line, and **numbered steps**
  when there are two decisions (the loadout). Status belongs on the item itself (a tag on the card), and a
  sentence by the confirm button says what will happen.
- **Do** show keyboard controls as keycaps (snow key, navy text) on a dark bar, never as plain small text.
- **Do** use stamps/postmarks only for things the player *earned*; use knit for comfort spaces (settings,
  wardrobe, transitions).
- **Don't** put knit or stamps on the HUD, under numbers, or behind long text.
- **Don't** use the pixel blackletter (Jacquarda Bastarda) for anything but optional decoration ≥ 36 px.
- **Don't** add new panel or button looks; extend the variants table instead.
- **Don't** animate ambient effects during gameplay; the world already moves.

## 11. Reference captures (`screens/`)

`01_main_menu` · `02_level_up` (hover on the rare row) · `03_hud` (with airmail toast) · `04_pause` ·
`05_settings` · `06_achievements` · `07_customize` · `08_results` · `09_components` · `10_splash_loader` ·
`11_splash_knitting` · `12_splash_final` · `13_knit_curtain_wipe`.

## 12. Reference implementation (Camel Claus: The North Pole)

| Piece | Where |
|---|---|
| Texture generator (plates, buttons, rows, tiles, stamps, airmail, postmarks, knobs, knit, rays, yarn, keycap, close X, tick, checkboxes, chevrons) | `art_src/tools/make_ui_textures.py` → `assets/ui/tin/` |
| Theme builder (all roles above) | `art_src/tools/build_ui_theme.gd` → `assets/ui/workshop_tin_theme.tres` |
| One-off migration (clear old per-node overrides, assign roles) | `art_src/tools/apply_tin_roles.gd` |
| UI builders | `scripts/ui/tin.gd` (`class_name Tin`) |
| Selection brackets | `scripts/ui/focus_brackets.gd` (autoload `FocusBrackets`) |
| Knitted curtain | `scripts/transition.gd` (autoload `Transition`) |
| Intro | `scenes/ui/splash.tscn`, `splash.gd` (main scene) |
| Web loading page | `art_src/tools/make_web_shell.py` → `web/shell.html` (Web preset custom shell) |
| Screens | `scenes/ui/main_menu`, `level_up_menu`, `hud`, `pause_menu`, `settings_panel`, `meta_panel` (Workshop, Achievements postcard, Stats), `customize_panel`, `loadout_panel`, `end_screen` (postcard) |
| Layout test | `tests/test_text_fit.gd` (122 screens at 1280×720; meta `decor` skips deliberate overhangs) |
| Achievement / cosmetic pictures | `AchievementData.icon`, `CosmeticData.picture` (renders in `assets/ui/renders/`, 96 px) |

**Order that worked:** fonts → textures → theme → set project theme → brackets + curtain → screens one by
one (menu, level up, HUD, pause, settings, meta, customize, loadout, results) → intro → web shell → tests →
web export checked in a browser.

## 13. Lessons (read before reusing)

- **Roles, not sizes.** The old UI had ~90 per-node font-size overrides tuned for one font; switching fonts
  meant touching all of them. With type variations, a new game changes fonts and sizes in one builder file.
- **The MCP tools can't remove a theme override** (`null` is rejected for typed overrides). Clear them with a
  small `-s` script (`apply_tin_roles.gd`) or rebuild the node.
- **Variable names collide.** In the HTML prototype, the hybrid layer reused CSS variable names (`--band`,
  `--ink`) that the base already used and broke the base. Namespace accent-layer tokens.
- **Built-in class names are reserved** as theme type names (`TabBar` failed); pick unique role names.
- **A CheckButton inherits Button's `icon_max_width`**, which shrank the switch art: set it to 0 for toggles.
- **Tweens freeze when the tree pauses.** Anything that animates in while paused (toasts on the results
  screen) must be bound to a node with `PROCESS_MODE_ALWAYS`, and should never start off-screen.
- **Scale "slam" animations** must size their box to the text first, or the scaled box leaves the screen.
- **Scenes saved by a headless script can lose their UID header**; other scenes then warn "invalid UID".
  Restore the UID, run `--import`, and prefer editing through the editor.
- **Check the build against the approved prototype screen by screen** (open the capture next to the
  game): the first in-game pass missed whole features (Credits, tabs, icons, settings rows, keycaps)
  because only the look was ported, not the content. Use the prototype's content list as the checklist.
- **A right-to-left CheckButton draws the `*_mirrored` icons.** Flipping a toggle so the switch comes before
  its text (`layout_direction = RTL`) showed Godot's default grey switch until the theme set
  `checked_mirrored` / `unchecked_mirrored` too.
- **Don't palette-swap baked pieces with a two-color swap.** A baked texture has more shades than the two
  swatches, so a "green Santa hat" kept a red cone: the default color showed through. Give each piece one
  look (its own model + texture); keep palette swaps for skins whose every fur shade is listed.
- **Give every list item its own picture.** One shared trophy for all achievements read as "icons not
  loading"; per-goal pictures (item icons or enemy renders) fixed it.
- **Pixel fonts:** check digits (Pixelify's 5 looked like S; Tiny5's doesn't). Ornate blackletter is for
  titles only; New Rocker reads at 19 px and up.
