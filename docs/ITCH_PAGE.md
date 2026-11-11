# Camel Claus — itch.io page + upload steps

## Upload (≈5 minutes, needs Quentin's itch.io account)

1. Export: Godot → **Project → Export… → Web → Export Project** (release, uncheck "Export With Debug")
   to `build/web/index.html`, or reuse the current build. Zip the *contents* of `build/web/` (index.html at
   the zip root). A ready zip from 2026-11-11 is at `build/camel-claus-web.zip` (git-ignored).
2. itch.io → **Dashboard → Create new project**:
   - Kind of project: **HTML**. Upload the zip, tick **"This file will be played in the browser"**.
   - Embed options: **Viewport 1280 × 720**, tick **Fullscreen button** and **Mobile friendly: off**.
     **SharedArrayBuffer support: off** (our build is single-threaded, so no special headers are needed).
   - Classification: Game · Genre: Action · Release status: Released (or Prototype).
3. Paste the page text below, upload the screenshots from `docs/media/`, set a cover image
   (630 × 500; crop `docs/media/01_main_menu.png`), and **Save & view page**. Play it once there.
4. Submit the itch link to the hackathon.

Optional CLI route (butler): `butler login`, then
`butler push build/web <user>/camel-claus:html5`.

## Page text

**Title:** Camel Claus

**Short description (tagline):** A cozy 5-minute survivors-like: Claus the camel, lost at the North Pole,
versus a horde of grumpy plush critters.

**Description:**

Claus the camel has wandered all the way to the North Pole — and the locals are *not* happy about it.
Frost imps, ice bats, grumpy walking pine trees and one very Grumpy Yeti are coming for him.

Survive **5 minutes**. Your gifts fly on their own; you just move, dodge and collect.

- **Level up** every few seconds and pick 1 of 3 upgrades — new weapons, weapon levels, and stat boosts
  that roll **Rare** or **Epic**.
- **Crowned elites** drop **gift chests**: pick 1 of 3 items like the Christmas Cracker (explosions),
  Fruitcake (poison), Icicle (freeze) or the Snow Globe (cheat death).
- **Evolve** weapons: max a weapon and own its matching item, and a chest turns Gift Toss into the
  **Present Barrage** or Jingle Pulse into **Carol of the Bells**.
- Press **Esc** any time to pause and see your full build, evolution progress and stats.

**Controls:** WASD / arrow keys to move · Esc / P to pause · mouse or Enter for menus.

**Credits:** Made by Quentin Drucker with Godot 4, Blender and Claude (AI-assisted pipeline: all 3D
models, pixel textures, icons and the music arrangement were generated in code). Font and sound
effects by Kenney (kenney.nl, CC0). Music: an original arrangement of "Jingle Bells" (J. L. Pierpont,
1857, public domain).

**Tags:** survivors-like, roguelite, christmas, cozy, pixel-art, low-poly, short, godot, browser
