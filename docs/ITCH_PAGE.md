# Camel Claus: The North Pole — itch.io page text

Full publishing steps (itch.io and GitHub Pages): see `PUBLISHING.md`.

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

Optional CLI route (butler): `butler login`, then
`butler push build/web <user>/camel-claus:html5`.

## Page text

**Title:** Camel Claus: The North Pole

**Short description (tagline):** A cozy 5-minute survivors-like: Claus the camel, lost at the North Pole,
versus a horde of grumpy plush critters.

**Description:**

Claus the camel has wandered all the way to the North Pole — and the locals are *not* happy about it.
Frost imps, ice bats, grumpy walking pine trees and one very Grumpy Yeti are coming for him.

Survive **5 minutes**. Your weapons fire on their own; you just move, dodge and collect.

- **Pick a loadout**: 3 of 6 festive weapons (Gift Toss, Candy Cane Orbit, Jingle Pulse, Snowball
  Barrage, Ornament Mines, Gingerbread Boomerang). You start with one; the others come from level-ups.
- **Level up** every few seconds and pick 1 of 3 upgrades. **Reroll** or **Banish** cards you don't want.
- **Santa's Sleigh**: bonking critters fills Santa's meter. Call him with **Space** and he drops a special
  present: it **evolves** a max-level weapon (every weapon has one), or grants a short, powerful blessing.
  Save the charge for an evolution, or spend it now. Your call.
- **Crowned elites** drop gift chests with items; watch out for **Snowball Lobbers** and their purple rings.
- Grab **Cookies & Milk**, the **Christmas Magnet** and **Snow Bombs** dropped by critters.
- Survived 5 minutes? **Keep going** in **Endless mode** and see how long Claus lasts.
- **Customize Claus**: skins, hats and outfits with color choices. Several are free from the start; the
  rest are bought with the coins you earn. Purely cosmetic.
- Every run earns **Christmas Coins** for the **Workshop** (permanent upgrades), unlocks new weapons
  through **achievements**, and counts toward your **stats and personal bests**.

**Controls:** WASD / arrow keys to move · **Space** or **E** to call Santa's Sleigh · **R** reroll /
**B** banish on level-ups · Esc / P to pause (full build and stats) · mouse or Enter for menus.
In fullscreen, pause with **P** (your browser uses Esc to leave fullscreen).

**Saving:** progress is saved in your browser (per site). Clearing site data for itch.io resets it.

**Credits:** Made by Quentin Drucker with Godot 4 and Blender (AI-assisted pipeline: all 3D
models, pixel textures, icons and the music arrangement were generated in code). Font and sound
effects by Kenney (kenney.nl, CC0). Music: an original arrangement of "Jingle Bells" (J. L. Pierpont,
1857, public domain).

**Tags:** survivors-like, roguelite, christmas, cozy, pixel-art, low-poly, short, godot, browser
