# Publishing Camel Claus: The North Pole

Two ways to put the web build online. **Recommendation: itch.io** for the game itself (it is built for
browser games: a page with screenshots, a fullscreen button, comments, devlogs, and players can find it),
plus optionally **GitHub Pages** as a no-frills link next to the source code (good for showing the
Godot + Blender AI workflow in a portfolio). You can do both; they don't conflict.

| | itch.io | GitHub Pages |
|---|---|---|
| Effort | ~10 min in the browser, no tools | ~10 min with git in a terminal |
| Page | Game page: cover, screenshots, description, fullscreen button, comments | Just the game at a URL |
| Discovery | Listed on itch (tags, browse) | None |
| Updates | Upload a new zip (or `butler push`) | Push to the `gh-pages` branch |
| Saves | Kept in the player's browser (per site) | Kept in the player's browser (per site) |
| Our build | Works as-is (single-threaded, no special headers) | Works as-is |

Saves: progress, coins and cosmetics live in the browser's IndexedDB for that website. They survive
reloads, not "clear site data" or a different browser/device. itch and GitHub Pages are different sites,
so they don't share progress.

## Fullscreen and Esc

Browsers reserve Esc for leaving fullscreen. On **GitHub Pages / your own page in Chrome or Edge** the game
uses the Keyboard Lock API, so Esc pauses and *holding* Esc leaves fullscreen. **On itch.io** (the game
runs in an iframe) and in Firefox/Safari, Esc always leaves fullscreen; the game then pauses itself, and
**P** pauses without leaving fullscreen. Worth one line on the itch page: "In fullscreen, pause with P."

## Live-demo code

Type **hohoho** (menu or mid-run) to unlock everything: all weapons, cosmetics, Workshop levels and
achievements, 99,999 coins; mid-run also max weapons + Santa ready. It works in the published build and
writes that browser's save — after a demo, use Settings > Reset progress. It isn't shown in the game;
leave it out of the public page text.

## 0. Make the build

The release build is in `build/web/` and zipped at `build/camel-claus-web.zip` (index.html at the zip
root). To rebuild: Godot → **Project → Export… → Web → Export Project**, untick **Export With Debug**,
path `build/web/index.html`; then zip the *contents* of `build/web/` (not the folder). Debug-only keys
(F2/F3/F4) and the FPS readout are not in release builds.

## A. itch.io (recommended)

1. Sign in at itch.io → your avatar → **Upload new project**.
2. **Title** `Camel Claus: The North Pole`. **Kind of project: HTML**. **Pricing**: no payments (or
   "donate"). **Uploads**: upload `build/camel-claus-web.zip`, then tick **This file will be played in
   the browser**.
3. **Embed options**: Viewport **1280 × 720**; tick **Fullscreen button**; **Mobile friendly** off
   (keyboard game); **Automatically start on page load** off (audio needs a click anyway);
   **SharedArrayBuffer support** off (our build is single-threaded).
4. **Details**: paste the description from `docs/ITCH_PAGE.md`; Genre **Action**; tags from that file;
   **AI generation disclosure**: say yes — models, textures, icons, music and code were made with an
   AI-assisted pipeline (itch asks creators to disclose this).
5. **Cover image** (630 × 500) and **screenshots**: the ones in `docs/media/` show the older UI — take fresh
   ones from the main menu, the Customize screen, a Santa's Sleigh drop and a late-game fight.
6. **Visibility**: start with **Draft**, press **Save & view page**, play a full run on the itch page
   (check sound, fullscreen, that a run's coins are still there after a reload). Then set **Public**.
7. Updates later: upload the new zip and delete the old one (or use butler:
   `butler push build/web <your-itch-user>/camel-claus:html5`).

## B. GitHub Pages — live at https://quentin-drucker.github.io/camel-claus_the-north-pole/

Set up 2026-11-11 from the public repo `github.com/quentin-drucker/camel-claus_the-north-pole`
(renamed from `camel-claus` and `camel-claus_survivors_workflow-test`; Pages URLs do not redirect). The **`gh-pages`** branch holds only the web build
(plus an empty `.nojekyll`); Pages serves it from the branch root. `build/` stays git-ignored on `main`.
`index.wasm` is ~40 MB: too big for GitHub's drag-and-drop uploader (25 MB), fine for `git push`.

**Update the live build** after a new release export, from the project folder in Git Bash:

```bash
git worktree add ../camel-claus-pages gh-pages     # check out the existing branch next to the project
cp build/web/* ../camel-claus-pages/
cd ../camel-claus-pages
git add -A
git commit -m "Web build vX.Y"
git push
cd -
git worktree remove ../camel-claus-pages
```

GitHub rebuilds the site in under a minute (repo → **Settings → Pages** shows the status). If the page
still shows the old version, hard-refresh (Ctrl+F5): browsers cache the large `.wasm`/`.pck` files.

## Before publishing: commit the source

Commit and push `main` first, so the published build matches the code on GitHub, and tag the release
(`v1.1` = the build live since 2026-11-11).
