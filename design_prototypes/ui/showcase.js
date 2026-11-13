// Camel Claus UI showcase: one set of screens (1280x720, the Godot design canvas), five concept skins.
"use strict";

const params = new URLSearchParams(location.search);
const STATE = {
  concept: params.get("c") || safeGet("cc.concept") || "a",
  screen: params.get("s") || safeGet("cc.screen") || "menu",
  compare: false,
  embed: params.has("embed"),
  motion: !matchMedia("(prefers-reduced-motion: reduce)").matches,
  font: params.get("font") || safeGet("cc.font.v2") || "rocker",
};
const FONTS = [["rocker", "New Rocker", "New Rocker"], ["germania", "Germania One", "Germania One"], ["grenze", "Grenze Gotisch", "Grenze Gotisch"], ["pixel", "Original pixel", "Jacquarda Bastarda 9"]];
// Per-stage gameplay state (each stage in compare mode gets its own copy).
const freshRun = () => ({
  offerSet: 0, offers: OFFER_SETS[0].slice(), reroll: 2, banish: 1, banishing: false,
  hp: 118, maxHp: 150, xp: 64, level: 9, time: 78, kills: 322, coins: 216, santa: 5,
  music: 70, sfx: 85, fullscreen: false, shake: true, dmgnums: true, uiSize: 1, resetArmed: false,
  achTab: "all", custTab: "hats", hat: "santa", outfit: "scarf", skin: "Classic Tan", custSel: null,
  tagline: 0,
});

function safeGet(k) { try { return localStorage.getItem(k); } catch { return null; } }
function safeSet(k, v) { try { localStorage.setItem(k, v); } catch { /* private mode: fine */ } }
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];
const cap = (s) => s[0].toUpperCase() + s.slice(1);
const mmss = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;
const rarityName = { common: "Common", rare: "Rare", epic: "Epic", evo: "Evolution" };

/* ---------- partials ---------- */

const img = (src, cls = "", alt = "") => `<img class="${cls}" src="${src}" alt="${alt}" draggable="false">`;

function btn(label, o = {}) {
  const attrs = [
    o.go ? `data-go="${o.go}"` : "", o.act ? `data-act="${o.act}"` : "",
    o.toast ? `data-toast="${o.toast}"` : "", o.disabled ? "disabled" : "",
    o.title ? `title="${o.title}"` : "",
  ].join(" ");
  const cls = ["btn", o.kind ? `btn-${o.kind}` : "", o.cls || ""].join(" ");
  return `<button class="${cls}" ${attrs}>${o.icon ? img(ICON(o.icon), "btn-icon") : ""}${o.count != null ? `<span class="btn-count">${o.count}</span>` : ""}<span class="btn-label">${label}</span>${o.badge ? `<span class="btn-badge">${o.badge}</span>` : ""}${o.key ? `<kbd>${o.key}</kbd>` : ""}</button>`;
}

function tile(src, o = {}) {
  return `<span class="tile ${o.cls || ""}" data-r="${o.r || "common"}" ${o.tip ? `data-tip='${JSON.stringify(o.tip).replace(/'/g, "&#39;")}'` : ""} ${o.tip ? 'tabindex="0"' : ""}>${src ? img(src) : ""}${o.n ? `<span class="tile-n">×${o.n}</span>` : ""}${o.lv ? `<span class="tile-lv">Lv ${o.lv}</span>` : ""}</span>`;
}

const bar = (pct, cls = "", text = "") => `<span class="bar ${cls}"><span class="bar-fill" style="width:${pct}%"></span>${text ? `<span class="bar-text">${text}</span>` : ""}</span>`;

const head = (title, extra = "", tag = "h2") => `<header class="panel-head"><${tag} class="panel-title">${title}</${tag}>${extra}</header>`;

const closeBtn = (go) => `<button class="x-btn" data-go="${go}" aria-label="Close"><svg viewBox="0 0 10 10"><path d="M2 2l6 6M8 2l-6 6"/></svg></button>`;

const chevron = (dir) => `<svg viewBox="0 0 10 10" class="chev"><path d="${dir < 0 ? "M7 1L3 5l4 4" : "M3 1l4 4-4 4"}"/></svg>`;

const coin = (n, cls = "") => `<span class="coin ${cls}">${img(ICON("coin"))}<span>${n}</span></span>`;

function logo() {
  return `<h1 class="logo"><span class="logo-main"><span class="logo-w1">Camel</span> <span class="logo-w2">Claus</span></span>${img(RENDER("hat_santa"), "logo-hat")}<span class="logo-sub">The North Pole</span></h1>`;
}

const bgMenu = `<div class="bg bg-menu"></div><div class="veil"></div><canvas class="snow" width="1280" height="720"></canvas><div class="deco"></div>`;
const bgGame = `<div class="bg bg-game"></div><div class="veil veil-game"></div>`;

/* ---------- screens ---------- */

const SCREEN_HTML = {
  menu(run, c) {
    const goals = ACHIEVEMENTS.filter((a) => a.p < a.of).slice(0, 3);
    return `<div class="scr scr-menu">${bgMenu}
      ${logo()}${c === "h" ? `<span class="postmark pm-menu" aria-hidden="true"></span>` : ""}
      <p class="tagline" data-act="tagline">${TAGLINES[run.tagline % TAGLINES.length]}</p>
      <nav class="menu-main">
        ${btn("Play", { go: "hud", kind: "primary", cls: "btn-play" })}
        ${btn("Workshop", { toast: "The Workshop isn't mocked up yet.", badge: "3" })}
        ${btn("Achievements", { go: "achievements" })}
        ${btn("Customize Claus", { go: "customize" })}
      </nav>
      <nav class="menu-side">
        ${btn("Settings", { go: "settings", kind: "small" })}
        ${btn("Credits", { toast: "Made with Godot, Blender and Claude. Font and sounds by Kenney (CC0).", kind: "small" })}
        ${btn("Quit", { toast: "Quit closes the game on desktop builds.", kind: "small" })}
      </nav>
      <section class="panel menu-goals">${head("Next goals", "", "h3")}
        <div class="panel-body">${goals.map((a) => `
          <div class="goal">${tile(a.render ? RENDER(a.render) : ICON(a.icon))}
            <span class="goal-text"><b>${a.t}</b><span>${a.d}</span>${bar((a.p / a.of) * 100, "bar-goal", `${a.fmt === "time" ? mmss(a.p) : fmtNum(a.p)} / ${a.fmt === "time" ? mmss(a.of) : fmtNum(a.of)}`)}</span>
          </div>`).join("")}
        </div>
      </section>
      <section class="panel menu-best">${head("Best runs", "", "h3")}
        <div class="panel-body"><table class="best">
          <tr class="me"><td>1</td><td>5:00</td><td>Lv 14</td><td>1,042 bonks</td></tr>
          <tr><td>2</td><td>4:12</td><td>Lv 11</td><td>688 bonks</td></tr>
          <tr><td>3</td><td>3:05</td><td>Lv 9</td><td>371 bonks</td></tr>
        </table></div>
      </section>
      <div class="wallet">${coin("1,240")}</div>
      <div class="keys"><span><kbd>WASD</kbd>Move</span><span><kbd>Space</kbd>Call Santa</span><span><kbd>Esc</kbd>Pause</span></div>
      <span class="ver">v1.1</span>
    </div>`;
  },

  levelup(run) {
    return `<div class="scr scr-levelup ${run.banishing ? "is-banishing" : ""}">${bgGame}<div class="rays"></div>
      <section class="panel lu" role="dialog" aria-label="Level up">
        ${head("Level up!", `<span class="lu-lv">Lv ${run.level} → ${run.level + 1}</span>`)}
        <div class="lu-offers">${run.offers.map(offerHtml).join("")}</div>
        <p class="lu-help">${run.banishing ? "Pick an upgrade to banish it for this run. Esc cancels." : "Click, press 1–3, or use arrows and Enter."}</p>
        <footer class="lu-actions">
          ${btn("Reroll", { act: "reroll", kind: "reroll", icon: "reroll", count: run.reroll, key: "R", disabled: run.reroll < 1 })}
          ${btn(run.banishing ? "Cancel" : "Banish", { act: "banish", kind: "banish", icon: "banish", count: run.banish, key: "B", disabled: run.banish < 1 && !run.banishing })}
        </footer>
      </section>
    </div>`;
  },

  hud(run) {
    return `<div class="scr scr-hud">${bgGame}
      <div class="hud">
        <div class="hud-xp">${bar(run.xp, "bar-xp")}</div>
        <div class="hud-tl">
          <div class="hud-counters">${coin(fmtNum(run.coins), "ctr-coins")}<span class="ctr ctr-kills">${img(RENDER("chaser"))}<span>${fmtNum(run.kills)}</span></span></div>
          ${bar((run.hp / run.maxHp) * 100, "bar-hp", `${run.hp} / ${run.maxHp}`)}
          <div class="hud-weapons">${HUD_WEAPONS.map((w) => tile(ICON(w.icon), { lv: w.lv, tip: { n: w.name, d: `Level ${w.lv} of 5` } })).join("")}</div>
          <ul class="goals"><li class="done"><span class="check"></span>Survive 3:00</li><li><span class="check"></span>Defeat the Grumpy Yeti</li></ul>
        </div>
        <div class="hud-timer">${mmss(run.time)}</div>
        <div class="hud-level"><span>Lv</span> ${run.level}</div>
        <div class="hud-santa ${run.santa >= 8 ? "ready" : ""}">${img(ICON("santa_sleigh"), "santa-icon")}<span class="santa-body"><span class="santa-label">Santa's Sleigh</span>${bar((run.santa / 8) * 100, "bar-santa")}</span><span class="santa-n">${run.santa >= 8 ? "Ready" : `${run.santa} / 8`}</span><kbd>Space</kbd></div>
        <div class="hud-items">${HUD_ITEMS.map((i) => tile(ICON(i.icon), { n: i.n > 1 ? i.n : 0, r: i.rarity, tip: { n: i.name, d: i.desc, r: i.rarity, x: i.n } })).join("")}</div>
        <div class="hud-boss" hidden><span class="boss-name">Grumpy Yeti</span>${bar(100, "bar-boss", "4,800 / 4,800")}</div>
        <div class="banner" hidden><span>The Grumpy Yeti approaches!</span></div>
        <div class="fx"></div>
      </div>
    </div>`;
  },

  pause(run) {
    return `<div class="scr scr-pause">${bgGame}<div class="veil veil-heavy"></div>
      <div class="pause">
        <section class="panel pz-build">${head("Your build", "", "h3")}
          <div class="panel-body">
            ${BUILD_WEAPONS.map((w) => `<div class="pz-weapon">${tile(ICON(w.icon), { tip: { n: w.name, d: w.summary } })}
              <span class="pz-w-text"><b>${w.name}</b><span class="pz-w-sum">${w.summary}</span>
              <span class="pz-evo"><span class="pips">${[1, 2, 3, 4, 5].map((n) => `<i class="${n <= w.lv ? "on" : ""}"></i>`).join("")}</span>Lv ${w.lv}/5 → ${w.evo}</span></span>
            </div>`).join("")}
            <h4 class="sub">Items</h4>
            <div class="pz-items">${HUD_ITEMS.map((i) => tile(ICON(i.icon), { n: i.n, r: i.rarity, tip: { n: i.name, d: i.desc, r: i.rarity, x: i.n } })).join("")}</div>
          </div>
        </section>
        <section class="panel pz-main">${head("Paused")}
          <div class="panel-body">
            <div class="pz-run">
              <span><b>${mmss(300 - run.time)}</b>Time</span><span><b>${run.level}</b>Level</span>
              <span><b>${fmtNum(run.kills)}</b>Bonks</span><span><b>${run.coins}</b>Coins</span>
            </div>
            <nav class="pz-buttons">
              ${btn("Resume", { go: "hud", kind: "primary" })}
              ${btn("Settings", { go: "settings" })}
              ${btn("Restart run", { go: "hud", act: "restart" })}
              ${btn("Main menu", { go: "menu" })}
            </nav>
          </div>
        </section>
        <section class="panel pz-stats">${head("Stats", "", "h3")}
          <div class="panel-body"><dl class="stats">${STATS.map((g) => `<div class="stat-group">${g.map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`).join("")}</div>`).join("")}</dl></div>
        </section>
      </div>
    </div>`;
  },

  settings(run) {
    const sizes = ["Small", "Medium", "Large"];
    return `<div class="scr scr-settings">${bgMenu}
      <section class="panel set">${head("Settings", closeBtn("menu"))}
        <div class="panel-body">
          <h4 class="sub">Sound</h4>
          ${sliderRow("Music", "music", run.music)}
          ${sliderRow("Sounds", "sfx", run.sfx)}
          <h4 class="sub">Display</h4>
          ${toggleRow("Fullscreen", "fullscreen", run.fullscreen)}
          <div class="set-row"><span class="set-label">Interface size</span>
            <div class="selector" data-key="uiSize"><button class="sel-btn" data-dir="-1" aria-label="Smaller">${chevron(-1)}</button><span class="sel-val">${sizes[run.uiSize]}</span><button class="sel-btn" data-dir="1" aria-label="Larger">${chevron(1)}</button></div></div>
          <h4 class="sub">Gameplay</h4>
          ${toggleRow("Screen shake", "shake", run.shake)}
          ${toggleRow("Damage numbers", "dmgnums", run.dmgnums)}
          ${toggleRow("Reduce motion", "motion", !STATE.motion)}
        </div>
        <footer class="set-foot">
          ${btn(run.resetArmed ? "Click again to erase" : "Reset progress", { act: "reset", kind: "danger" })}
          ${btn("Back", { go: "menu", kind: "primary" })}
        </footer>
      </section>
    </div>`;
  },

  achievements(run) {
    const done = ACHIEVEMENTS.filter((a) => a.p >= a.of).length;
    const list = ACHIEVEMENTS.filter((a) => run.achTab === "all" || a.cat === run.achTab)
      .sort((x, y) => (y.p >= y.of) - (x.p >= x.of));
    const fmtP = (a, v) => (a.fmt === "time" ? mmss(v) : fmtNum(v));
    return `<div class="scr scr-achievements">${bgMenu}
      <section class="panel ach">${head("Achievements", `<span class="ach-total"><b>${done}</b> / ${ACHIEVEMENTS.length}</span>${bar((done / ACHIEVEMENTS.length) * 100, "bar-total")}${coin("+1,240 earned", "ach-earned")}${closeBtn("menu")}`)}
        <div class="tabs" role="tablist">${ACH_TABS.map((t) => {
          const items = ACHIEVEMENTS.filter((a) => t.id === "all" || a.cat === t.id);
          const d = items.filter((a) => a.p >= a.of).length;
          return `<button class="tab ${run.achTab === t.id ? "on" : ""}" role="tab" aria-selected="${run.achTab === t.id}" data-act="achTab" data-v="${t.id}"><span class="tab-name">${t.name}</span><span class="tab-n">${d} / ${items.length}</span>${bar((d / items.length) * 100, "bar-tab")}</button>`;
        }).join("")}</div>
        <div class="ach-list">${list.map((a) => {
          const isDone = a.p >= a.of;
          return `<div class="ach-row ${isDone ? "done" : ""}">${tile(a.render ? RENDER(a.render) : ICON(a.icon), { r: isDone ? "evo" : "common" })}
            <span class="ach-text"><b>${a.t}</b><span>${a.d}</span></span>
            <span class="ach-prog"><span class="ach-num">${fmtP(a, Math.min(a.p, a.of))} / ${fmtP(a, a.of)}</span>${bar((Math.min(a.p, a.of) / a.of) * 100, "bar-ach")}</span>
            <span class="ach-reward">${isDone ? `<svg class="tick" viewBox="0 0 12 12"><path d="M2 6.5l2.6 2.6L10 3.4"/></svg>` : coin(a.r)}</span>
          </div>`;
        }).join("")}</div>
      </section>
    </div>`;
  },

  customize(run) {
    const tab = run.custTab;
    const list = COSMETICS[tab];
    const equippedId = tab === "hats" ? run.hat : tab === "outfits" ? run.outfit : run.skin;
    const selId = run.custSel ?? equippedId;
    const sel = list.find((x) => (x.id ?? x.name) === selId) || list[0];
    const previewSrc = tab === "skins" ? (COSMETICS.hats.find((h) => h.id === run.hat) || COSMETICS.hats[0]).preview : sel.preview;
    const skinFilter = { "Classic Tan": "none", Cocoa: "brightness(.72) saturate(1.1)", Cream: "brightness(1.18) saturate(.45)", Frosty: "hue-rotate(170deg) saturate(1.2)", Evergreen: "hue-rotate(95deg) saturate(1.1)", Golden: "saturate(1.8) brightness(1.08)" };
    const filt = skinFilter[tab === "skins" ? sel.name : run.skin] || "none";
    const isEquipped = (sel.id ?? sel.name) === equippedId;
    const action = !sel.owned ? btn(`Buy for ${sel.price}`, { act: "equip", kind: "primary", icon: "coin" })
      : isEquipped ? btn("Equipped", { disabled: true }) : btn("Equip", { act: "equip", kind: "primary" });
    return `<div class="scr scr-customize">${bgMenu}
      <section class="panel cu-pick">${head("Customize Claus", closeBtn("menu"))}
        <div class="tabs" role="tablist">${["hats", "outfits", "skins"].map((t) => `<button class="tab ${tab === t ? "on" : ""}" role="tab" aria-selected="${tab === t}" data-act="custTab" data-v="${t}"><span class="tab-name">${cap(t)}</span></button>`).join("")}</div>
        <div class="cu-grid ${tab === "skins" ? "is-skins" : ""}">${list.map((x) => {
          const id = x.id ?? x.name;
          const inner = tab === "skins" ? `<span class="swatch" style="--s1:${x.c[0]};--s2:${x.c[1]}"></span>` : x.img ? img(x.img) : `<span class="none-mark"></span>`;
          return `<button class="cu-tile ${id === selId ? "is-picked" : ""} ${id === equippedId ? "is-worn" : ""} ${x.owned ? "" : "is-locked"}" data-act="custSel" data-v="${id}">
            <span class="cu-img">${inner}</span><span class="cu-name">${x.name}</span>${x.owned ? "" : `<span class="cu-price">${coin(x.price)}</span>`}</button>`;
        }).join("")}</div>
      </section>
      <div class="cu-stage"><span class="cu-pedestal"></span>${img(previewSrc, "cu-claus", "Claus preview")}</div>
      <section class="panel cu-detail">
        <div class="panel-body">
          <h3 class="cu-title">${sel.name}</h3>
          <p class="cu-desc">${sel.desc || (tab === "skins" ? "Recolors Claus's fur. Hat and outfit keep their colors." : "")}</p>
          ${tab === "skins" ? `<p class="cu-note">Preview tint is approximate; in game this is the palette-swap shader.</p>` : ""}
          <div class="cu-action">${action}</div>
        </div>
      </section>
      <div class="wallet">${coin("1,240")}</div>
    </div>`;
  },

  results(run, c) {
    const r = RESULTS;
    const pills = `<div class="res-pills"><span><b>${r.time}</b> survived</span><span><b>Lv ${r.level}</b> reached</span><span class="res-best">New best run</span></div>`;
    const top = c === "h"
      ? `<header class="res-head postcard"><div class="pc-text"><span class="pc-greet">Greetings from the</span><h2 class="res-title pc-big">North Pole!</h2>${pills}</div>
          <span class="pc-stamp">${img(RENDER("claus_front"))}<b>5:00</b></span><span class="postmark pm-res" aria-hidden="true"></span></header>`
      : `<header class="res-head"><h2 class="res-title">You survived the North Pole!</h2>${pills}</header>`;
    return `<div class="scr scr-results">${bgMenu}
      <div class="res">
        ${top}
        <section class="panel res-dmg">${head("Damage", "", "h3")}
          <div class="panel-body"><table class="dmg"><thead><tr><th>Source</th><th>Lv</th><th>Damage</th><th>DPS</th></tr></thead><tbody>
            ${r.damage.map((d, i) => `<tr style="--i:${i}"><td>${tile(ICON(d.icon))}<span>${d.name}</span></td><td>${d.lv}</td><td data-count="${d.dmg}">${fmtNum(d.dmg)}</td><td>${d.dps}</td></tr>`).join("")}
          </tbody></table></div>
        </section>
        <section class="panel res-sum">${head("Summary", "", "h3")}
          <div class="panel-body">
            <div class="res-claus">${img(RENDER("claus_front"), "res-portrait")}<div class="res-stats"><span>Bonks <b data-count="${r.kills}">${fmtNum(r.kills)}</b></span><span>Time <b>${r.time}</b></span><span>Level <b>${r.level}</b></span></div></div>
            <h4 class="sub">Inventory</h4>
            <div class="res-inv">${HUD_ITEMS.map((i) => tile(ICON(i.icon), { n: i.n, r: i.rarity, tip: { n: i.name, d: i.desc, r: i.rarity } })).join("")}</div>
            <div class="res-reward"><span class="res-unlocks">${img(ICON("trophy"))}2 achievements unlocked</span>${coin(`+${r.coins} coins`, "res-coins")}</div>
            <div class="res-buttons">${btn("Keep going (Endless)", { go: "hud" })}${btn("Play again", { go: "hud", kind: "primary" })}${btn("Main menu", { go: "menu" })}</div>
          </div>
        </section>
        <section class="panel res-ach">${head("Unlocked", "", "h3")}
          <div class="panel-body">${r.unlocked.map((u) => `<div class="unlock">${img(ICON("trophy"))}<span><b>${u.t}</b>Achievement</span>${coin(`+${u.r}`)}</div>`).join("")}
            <div class="unlock unlock-next">${img(RENDER("yeti"))}<span><b>Yeti Tamer</b>Defeat the Grumpy Yeti</span>${bar(0, "bar-ach")}</div>
          </div>
        </section>
      </div>
    </div>`;
  },

  kit(run, c) {
    const states = (kind, label) => ["Idle", "Hover", "Pressed", "Disabled"].map((s) =>
      `<span class="kit-spec">${btn(label, { kind, cls: s === "Hover" ? "is-sel" : s === "Pressed" ? "is-down" : "", disabled: s === "Disabled" })}<small>${s}</small></span>`).join("");
    return `<div class="scr scr-kit">${bgMenu}<div class="veil veil-heavy"></div>
      <div class="kit">
        <section class="panel kit-buttons">${head("Buttons", "", "h3")}
          <div class="panel-body">
            <div class="kit-row">${states("primary", "Play")}</div>
            <div class="kit-row">${states("", "Settings")}</div>
            <div class="kit-row">${btn("Reroll", { kind: "reroll", icon: "reroll", count: 2, key: "R" })}${btn("Banish", { kind: "banish", icon: "banish", count: 1, key: "B" })}${btn("Reset progress", { kind: "danger" })}${btn("Try me", { act: "burst", kind: "primary" })}</div>
          </div>
        </section>
        <section class="panel kit-rarity">${head("Rarity and tiles", "", "h3")}
          <div class="panel-body kit-tiles">
            ${[["common", "magnet_scarf", "Common"], ["rare", "icicle", "Rare"], ["epic", "christmas_cracker", "Epic"], ["evo", "weapon_gift_toss_evo", "Evolution"]].map(([r, i, l]) =>
              `<span class="kit-spec">${tile(ICON(i), { r, tip: { n: l, d: `How a ${l.toLowerCase()} pick is framed everywhere`, r } })}<small>${l}</small></span>`).join("")}
            <span class="kit-spec">${tile(ICON("lock"), { cls: "is-locked" })}<small>Locked</small></span>
            <span class="kit-spec">${tile(ICON("weapon_gift_toss"), { lv: 4 })}<small>With level</small></span>
            <span class="kit-spec">${tile(ICON("spiced_dates"), { n: 2 })}<small>Stacked</small></span>
            ${c === "h" ? `<span class="kit-spec kit-stamp">${tile(ICON("trophy"), { r: "evo" })}<small>Stamp</small></span><span class="kit-spec">${tile(ICON("hot_cocoa"), { cls: "kit-stamp-done", r: "rare" })}<small>Postmarked</small></span>` : ""}
          </div>
        </section>
        <section class="panel kit-bars">${head("Meters", "", "h3")}
          <div class="panel-body">
            <span class="kit-bar"><small>Health</small>${bar(79, "bar-hp", "118 / 150")}</span>
            <span class="kit-bar"><small>Experience</small>${bar(64, "bar-xp")}</span>
            <span class="kit-bar"><small>Santa's Sleigh</small>${bar(62, "bar-santa")}</span>
            <span class="kit-bar"><small>Boss</small>${bar(70, "bar-boss", "3,360 / 4,800")}</span>
          </div>
        </section>
        <section class="panel kit-feedback">${head("Feedback", "", "h3")}
          <div class="panel-body">
            <div class="toast is-static">${img(ICON("trophy"), "toast-icon")}<span class="toast-text"><b>Achievement unlocked</b><span>Blizzard of Bonks</span></span>${coin("+60")}</div>
            <div class="banner is-static"><span>The Grumpy Yeti approaches!</span></div>
            <div class="tip is-static"><b class="tip-name" data-r="epic">Christmas Cracker <i>×3</i></b><span>Hits have a 25% chance to go BANG: 60% damage to enemies nearby</span></div>
            <div class="kit-dmg"><span class="dmg-num">14</span><span class="dmg-num crit">38</span><span class="dmg-num heal">+30</span><span class="dmg-num freeze">Frozen</span></div>
            <div class="kit-keys"><kbd>R</kbd><kbd>B</kbd><kbd>Space</kbd><kbd>Esc</kbd></div>
          </div>
        </section>
      </div>
    </div>`;
  },
};

function offerHtml(o, i) {
  const statLine = (s) => `<span class="offer-stat"><span class="k">${s[0]}</span> <span class="old">${s[1]}</span><span class="arrow">→</span><span class="new">${s[2]}</span></span>`;
  return `<button class="offer" data-r="${o.rarity}" data-act="pick" data-i="${i}" style="--i:${i}">
    <span class="offer-rarity">${rarityName[o.rarity]}</span>
    ${tile(ICON(o.icon), { r: o.rarity })}
    <span class="offer-body">
      <span class="offer-type">${o.type}</span>
      <span class="offer-name">${o.name}</span>
      ${statLine(o.stat)}${o.extra ? statLine(o.extra) : ""}
      <span class="offer-hint">${o.hint}</span>
    </span>
    <span class="offer-lv">${o.lv}</span>
    <kbd class="offer-key">${i + 1}</kbd>
  </button>`;
}

function sliderRow(label, key, v) {
  return `<div class="set-row"><span class="set-label" id="lbl-${key}">${label}</span>
    <div class="slider" role="slider" tabindex="0" aria-labelledby="lbl-${key}" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${v}" data-key="${key}" style="--v:${v}%">
      <span class="slider-track"><span class="slider-fill"></span><span class="slider-ticks"></span></span><span class="slider-knob"></span></div>
    <output class="set-val">${v}%</output></div>`;
}
function toggleRow(label, key, on) {
  return `<div class="set-row"><span class="set-label">${label}</span>
    <button class="toggle ${on ? "on" : ""}" role="switch" aria-checked="${on}" data-key="${key}"><span class="toggle-track"><span class="toggle-knob"></span></span><span class="toggle-text">${on ? "On" : "Off"}</span></button></div>`;
}

/* ---------- stages ---------- */

class Stage {
  constructor(host, concept, screen, opts = {}) {
    this.host = host; this.concept = concept; this.screen = screen; this.run = freshRun();
    this.timers = []; this.mini = !!opts.mini;
    this.base = (CONCEPTS.find((c) => c.id === concept) || {}).base || concept;
    host.innerHTML = `<div class="stage" data-c="${this.base}" data-x="${concept}" data-font="${STATE.font}"><div class="screen-host"></div><div class="tip-layer"></div><div class="wipe"></div><div class="toast-host"></div></div>`;
    this.el = $(".stage", host);
    this.screenHost = $(".screen-host", this.el);
    this.bind();
    this.render(true);
    this.fit();
    this.ro = new ResizeObserver(() => this.fit());
    this.ro.observe(host);
  }

  destroy() { this.stopTimers(); this.ro.disconnect(); cancelAnimationFrame(this.snowRaf); this.host.innerHTML = ""; }

  fit() {
    // Width drives the scale; the host's height follows (--stage-h), so the 16:9 canvas never letterboxes.
    const s = this.host.clientWidth / 1280;
    this.el.style.transform = `scale(${s})`;
    this.host.style.setProperty("--stage-h", `${720 * s}px`);
    this.host.style.setProperty("--stage-w", `${1280 * s}px`);
    this.scale = s;
  }

  stopTimers() { this.timers.forEach(clearInterval); this.timers = []; }

  render(first = false) {
    this.stopTimers();
    cancelAnimationFrame(this.snowRaf);
    this.screenHost.innerHTML = SCREEN_HTML[this.screen](this.run, this.concept);
    const scr = $(".scr", this.screenHost);
    if (!first || this.screen !== "menu") scr.classList.add("enter");
    this.startSnow();
    if (this.screen === "hud") this.startHud();
    if (this.screen === "results") this.countUp();
    if (!this.mini && !first) {
      const target = $(".btn-primary:not([disabled]), .offer, .btn", scr);
      if (target) this.select(target, false);
    }
  }

  go(screen) {
    if (screen === this.screen) return this.render();
    const swap = () => { this.screen = screen; this.render(); if (this.onNav) this.onNav(screen); };
    if (!STATE.motion) return swap();
    this.el.classList.remove("wiping"); void this.el.offsetWidth;
    this.el.classList.add("wiping");
    setTimeout(swap, 260);
    setTimeout(() => this.el.classList.remove("wiping"), 700);
  }

  select(el, focus = true) {
    $$(".is-sel", this.el).forEach((x) => x !== el && x.classList.remove("is-sel"));
    el.classList.add("is-sel");
    if (focus && document.activeElement !== el) el.focus({ preventScroll: true });
  }

  toast(text, icon = "trophy", reward) {
    const host = $(".toast-host", this.el);
    const t = document.createElement("div");
    t.className = "toast";
    t.innerHTML = `${img(ICON(icon), "toast-icon")}<span class="toast-text"><b>${reward ? "Achievement unlocked" : "Note"}</b><span>${text}</span></span>${reward ? coin(`+${reward}`) : ""}`;
    host.appendChild(t);
    setTimeout(() => t.classList.add("out"), 2600);
    setTimeout(() => t.remove(), 3200);
  }

  burst(x, y, n = 18) {
    if (!STATE.motion) return;
    const layer = document.createElement("div");
    layer.className = "burst";
    layer.style.left = `${x}px`; layer.style.top = `${y}px`;
    for (let i = 0; i < n; i++) {
      const p = document.createElement("i");
      const a = (i / n) * Math.PI * 2 + Math.random() * 0.4;
      const d = 70 + Math.random() * 90;
      p.style.setProperty("--dx", `${Math.cos(a) * d}px`);
      p.style.setProperty("--dy", `${Math.sin(a) * d - 30}px`);
      p.style.setProperty("--r", `${Math.random() * 540 - 270}deg`);
      p.style.setProperty("--d", `${0.55 + Math.random() * 0.35}s`);
      p.className = `p p${i % 3}`;
      layer.appendChild(p);
    }
    this.el.appendChild(layer);
    setTimeout(() => layer.remove(), 1100);
  }

  // Coordinates inside the 1280x720 stage for an element's center.
  center(el) {
    const r = el.getBoundingClientRect(), s = this.el.getBoundingClientRect();
    return [(r.left + r.width / 2 - s.left) / this.scale, (r.top + r.height / 2 - s.top) / this.scale];
  }

  /* --- ambient snow (menu-type screens only; in-game screens already have the world's own snow) --- */
  startSnow() {
    const cv = $("canvas.snow", this.screenHost);
    if (!cv) return;
    const ctx = cv.getContext("2d");
    const c = this.base;
    const cfg = { a: [70, 0.5, 1], b: [45, 0.35, 1], c: [55, 0.3, 1], d: [80, 0.9, 1], e: [60, 0.6, 1] }[c];
    const flakes = Array.from({ length: this.mini ? Math.round(cfg[0] / 2) : cfg[0] }, () => ({
      x: Math.random() * 1280, y: Math.random() * 720, z: 0.4 + Math.random() * 0.8, ph: Math.random() * 6.28,
    }));
    let last = 0, acc = 0;
    const draw = (t) => {
      const dt = Math.min(50, t - last || 16) / 16; last = t;
      if (c === "e") { acc += dt; if (acc < 4) { this.snowRaf = requestAnimationFrame(draw); return; } acc = 0; }
      ctx.clearRect(0, 0, 1280, 720);
      for (const f of flakes) {
        if (STATE.motion) {
          const step = c === "e" ? 4 : dt;
          f.y += cfg[1] * f.z * step * (c === "d" ? 1.4 : 1);
          f.x += (c === "d" ? 0.9 * f.z * step : Math.sin(t / 1400 + f.ph) * 0.25 * f.z);
          if (f.y > 724) { f.y = -6; f.x = Math.random() * 1280; }
          if (f.x > 1284) f.x = -4;
        }
        const s = f.z;
        if (c === "a") { ctx.fillStyle = `rgba(244,248,255,${0.55 + s * 0.35})`; const k = Math.round(2 + s * 2.5); ctx.fillRect(Math.round(f.x), Math.round(f.y), k, k); }
        else if (c === "b") { ctx.fillStyle = `rgba(244,248,255,${0.5 + s * 0.4})`; ctx.beginPath(); ctx.arc(f.x, f.y, 2 + s * 2.6, 0, 6.283); ctx.fill(); }
        else if (c === "c") {
          const tw = 0.5 + 0.5 * Math.sin(t / 600 + f.ph * 3);
          ctx.fillStyle = `rgba(201,218,240,${0.35 + s * 0.4})`; ctx.beginPath(); ctx.arc(f.x, f.y, 1.2 + s * 1.3, 0, 6.283); ctx.fill();
          if (f.ph < 0.9 && STATE.motion) { ctx.fillStyle = `rgba(127,214,242,${tw * 0.9})`; const r = 5 * tw + 1; ctx.fillRect(f.x - r, f.y - 0.6, r * 2, 1.2); ctx.fillRect(f.x - 0.6, f.y - r, 1.2, r * 2); }
        }
        else if (c === "d") { ctx.fillStyle = `rgba(244,248,255,${0.6 + s * 0.3})`; ctx.fillRect(f.x, f.y, 1.6 + s, 1.6 + s); }
        else { ctx.fillStyle = s > 0.9 ? "#F4F8FF" : "#C9DAF0"; const k = s > 0.9 ? 4 : 2; ctx.fillRect(Math.round(f.x / 4) * 4, Math.round(f.y / 4) * 4, k, k); }
      }
      if (STATE.motion) this.snowRaf = requestAnimationFrame(draw);
    };
    this.snowRaf = requestAnimationFrame(draw);
  }

  /* --- HUD simulation: ticking timer, bonks, damage numbers over the real enemies in the capture --- */
  startHud() {
    const enemies = [[166, 368], [462, 474], [748, 548], [910, 636], [823, 452], [1002, 462], [1146, 88]];
    const fx = $(".fx", this.screenHost);
    this.timers.push(setInterval(() => {
      if (this.run.time <= 0) return;
      this.run.time -= 1;
      const t = $(".hud-timer", this.screenHost); if (t) t.textContent = mmss(this.run.time);
    }, 1000));
    if (!STATE.motion || !this.run.dmgnums) return;
    this.timers.push(setInterval(() => {
      if (!fx) return;
      const [x, y] = enemies[Math.floor(Math.random() * enemies.length)];
      const crit = Math.random() < 0.18;
      const n = document.createElement("span");
      n.className = `dmg-num pop ${crit ? "crit" : ""}`;
      n.textContent = crit ? 30 + Math.floor(Math.random() * 20) : 9 + Math.floor(Math.random() * 12);
      n.style.left = `${x + Math.random() * 30 - 15}px`; n.style.top = `${y - 30 + Math.random() * 10}px`;
      fx.appendChild(n);
      setTimeout(() => n.remove(), 900);
      if (Math.random() < 0.35) {
        this.run.kills += 1;
        const k = $(".ctr-kills span", this.screenHost); if (k) k.textContent = fmtNum(this.run.kills);
      }
    }, this.mini ? 1100 : 520));
  }

  countUp() {
    if (!STATE.motion) return;
    $$("[data-count]", this.screenHost).forEach((el) => {
      const end = +el.dataset.count; const t0 = performance.now();
      const step = (t) => {
        const k = Math.min(1, (t - t0) / 1200); const e = 1 - Math.pow(1 - k, 3);
        el.textContent = fmtNum(Math.round(end * e));
        if (k < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    });
  }

  /* --- HUD demo actions (from the "Try it" bar) --- */
  hudAction(kind) {
    const r = this.run, root = this.screenHost;
    if (this.screen !== "hud") return;
    if (kind === "hit") {
      r.hp = Math.max(1, r.hp - 22);
      const hp = $(".bar-hp", root);
      $(".bar-fill", hp).style.width = `${(r.hp / r.maxHp) * 100}%`;
      $(".bar-text", hp).textContent = `${r.hp} / ${r.maxHp}`;
      hp.classList.remove("hurt"); void hp.offsetWidth; hp.classList.add("hurt");
      const v = $(".veil-game", root); v.classList.remove("hurt"); void v.offsetWidth; v.classList.add("hurt");
    }
    if (kind === "xp") {
      r.xp = Math.min(100, r.xp + 18);
      $(".bar-xp .bar-fill", root).style.width = `${r.xp}%`;
      if (r.xp >= 100) {
        $(".hud-xp", root).classList.add("full");
        setTimeout(() => { r.xp = 8; this.go("levelup"); }, 450);
      }
    }
    if (kind === "boss") {
      const b = $(".banner", root), bb = $(".hud-boss", root);
      b.hidden = false; b.classList.remove("show"); void b.offsetWidth; b.classList.add("show");
      setTimeout(() => { b.hidden = true; bb.hidden = false; bb.classList.add("show"); }, 2200);
    }
    if (kind === "ach") this.toast("Blizzard of Bonks", "trophy", 60);
    if (kind === "santa") {
      r.santa = 8;
      const s = $(".hud-santa", root); s.classList.add("ready");
      $(".bar-santa .bar-fill", s).style.width = "100%"; $(".santa-n", s).textContent = "Ready";
    }
  }

  /* --- input --- */
  bind() {
    const el = this.el;
    el.addEventListener("mouseover", (e) => {
      const t = e.target.closest(".btn:not([disabled]), .offer, .tab, .cu-tile, .toggle, .slider, .sel-btn, .x-btn");
      if (t && !t.classList.contains("is-sel")) this.select(t, false);
      const tipEl = e.target.closest("[data-tip]");
      this.showTip(tipEl);
    });
    el.addEventListener("mouseleave", () => this.showTip(null));
    el.addEventListener("focusin", (e) => {
      const t = e.target.closest("button, [tabindex]");
      if (t) this.select(t, false);
      this.showTip(e.target.closest("[data-tip]"));
    });
    el.addEventListener("pointerdown", (e) => {
      const b = e.target.closest(".btn, .offer, .cu-tile, .tab");
      if (b && !b.disabled) { b.classList.add("is-down"); setTimeout(() => b.classList.remove("is-down"), 140); }
      const sl = e.target.closest(".slider");
      if (sl) this.dragSlider(sl, e);
    });
    el.addEventListener("click", (e) => this.onClick(e));
    el.addEventListener("keydown", (e) => {
      const sl = e.target.closest(".slider");
      if (sl && (e.key === "ArrowLeft" || e.key === "ArrowRight")) {
        e.preventDefault(); e.stopPropagation();
        this.setSlider(sl, +sl.getAttribute("aria-valuenow") + (e.key === "ArrowRight" ? 5 : -5));
      }
    });
  }

  showTip(t) {
    const layer = $(".tip-layer", this.el);
    if (!t) { layer.innerHTML = ""; return; }
    const d = JSON.parse(t.dataset.tip);
    layer.innerHTML = `<div class="tip"><b class="tip-name" data-r="${d.r || "common"}">${d.n}${d.x > 1 ? ` <i>×${d.x}</i>` : ""}</b><span>${d.d}</span></div>`;
    const [x, y] = this.center(t);
    const tip = $(".tip", layer);
    const above = y > 360;
    tip.style.left = `${Math.max(150, Math.min(1130, x))}px`;
    tip.style.top = `${y + (above ? -40 : 40)}px`;
    tip.classList.add(above ? "above" : "below");
  }

  dragSlider(sl, e) {
    const move = (ev) => {
      const r = $(".slider-track", sl).getBoundingClientRect();
      this.setSlider(sl, Math.round(((ev.clientX - r.left) / r.width) * 100));
    };
    move(e);
    const up = () => { removeEventListener("pointermove", move); removeEventListener("pointerup", up); };
    addEventListener("pointermove", move); addEventListener("pointerup", up);
  }

  setSlider(sl, v) {
    v = Math.max(0, Math.min(100, v));
    sl.setAttribute("aria-valuenow", v); sl.style.setProperty("--v", `${v}%`);
    sl.parentElement.querySelector("output").textContent = `${v}%`;
    this.run[sl.dataset.key] = v;
  }

  onClick(e) {
    const t = e.target.closest("button, [data-act]");
    if (!t || t.disabled) return;
    const r = this.run;
    if (t.classList.contains("toggle")) {
      const k = t.dataset.key, on = !t.classList.contains("on");
      t.classList.toggle("on", on); t.setAttribute("aria-checked", on); $(".toggle-text", t).textContent = on ? "On" : "Off";
      if (k === "motion") setMotion(!on); else r[k] = on;
      return;
    }
    if (t.classList.contains("sel-btn")) {
      const sizes = ["Small", "Medium", "Large"];
      r.uiSize = (r.uiSize + +t.dataset.dir + 3) % 3;
      const v = $(".sel-val", t.parentElement); v.textContent = sizes[r.uiSize];
      v.classList.remove("flip"); void v.offsetWidth; v.classList.add("flip");
      return;
    }
    const act = t.dataset.act;
    if (t.dataset.toast) { this.toast(t.dataset.toast, "santa_present"); return; }
    if (act === "tagline") { r.tagline += 1; t.textContent = TAGLINES[r.tagline % TAGLINES.length]; t.classList.remove("bump"); void t.offsetWidth; t.classList.add("bump"); return; }
    if (act === "burst") { const [x, y] = this.center(t); this.burst(x, y); return; }
    if (act === "restart") { Object.assign(r, freshRun(), { music: r.music, sfx: r.sfx }); }
    if (act === "pick") return this.pick(t);
    if (act === "reroll") return this.reroll();
    if (act === "banish") { r.banishing = !r.banishing; return this.render(); }
    if (act === "reset") {
      if (!r.resetArmed) { r.resetArmed = true; $(".btn-label", t).textContent = "Click again to erase"; t.classList.add("armed"); return; }
      r.resetArmed = false; this.toast("Progress reset (not really: this is a prototype).", "banish"); return this.render();
    }
    if (act === "achTab") { r.achTab = t.dataset.v; return this.render(); }
    if (act === "custTab") { r.custTab = t.dataset.v; r.custSel = null; return this.render(); }
    if (act === "custSel") { r.custSel = t.dataset.v; this.render(); const n = $(`.cu-tile[data-v="${CSS.escape(t.dataset.v)}"]`, this.el); if (n) this.select(n); return; }
    if (act === "equip") {
      const list = COSMETICS[r.custTab]; const id = r.custSel ?? (r.custTab === "hats" ? r.hat : r.custTab === "outfits" ? r.outfit : r.skin);
      const item = list.find((x) => (x.id ?? x.name) === id);
      if (!item.owned) { item.owned = true; this.toast(`Bought ${item.name}`, "coin"); }
      if (r.custTab === "hats") r.hat = id; else if (r.custTab === "outfits") r.outfit = id; else r.skin = id;
      this.render();
      const [x, y] = [640, 380]; this.burst(x, y, 14);
      return;
    }
    if (t.dataset.go) this.go(t.dataset.go);
  }

  pick(card) {
    const r = this.run;
    const i = +card.dataset.i;
    if (r.banishing) {
      r.banish -= 1; r.banishing = false;
      card.classList.add("banished");
      const pool = OFFER_SETS.flat().filter((o) => !r.offers.includes(o));
      setTimeout(() => { r.offers[i] = pool[Math.floor(Math.random() * pool.length)]; this.render(); }, STATE.motion ? 380 : 0);
      return;
    }
    const [x, y] = this.center(card);
    card.classList.add("picked");
    $$(".offer", this.el).forEach((o) => o !== card && o.classList.add("dismissed"));
    this.burst(x, y, 22);
    setTimeout(() => { r.level += 1; r.offerSet = (r.offerSet + 1) % OFFER_SETS.length; r.offers = OFFER_SETS[r.offerSet].slice(); this.go("hud"); }, STATE.motion ? 650 : 0);
  }

  reroll() {
    const r = this.run;
    if (r.reroll < 1) return;
    r.reroll -= 1; r.offerSet = (r.offerSet + 1) % OFFER_SETS.length; r.offers = OFFER_SETS[r.offerSet].slice();
    const offers = $(".lu-offers", this.el);
    if (!STATE.motion) return this.render();
    offers.classList.add("rerolling");
    setTimeout(() => this.render(), 220);
  }

  key(e) {
    const k = e.key, s = this.screen;
    if (k === "Escape") {
      e.preventDefault();
      if (s === "levelup" && this.run.banishing) { this.run.banishing = false; return this.render(); }
      if (s === "hud") return this.go("pause");
      if (s === "pause") return this.go("hud");
      if (s !== "menu" && s !== "levelup") return this.go("menu");
      return;
    }
    if (s === "levelup") {
      if (["1", "2", "3"].includes(k)) { const c = $$(".offer", this.el)[+k - 1]; if (c) this.pick(c); return; }
      if (k === "r" || k === "R") return this.reroll();
      if ((k === "b" || k === "B") && (this.run.banish > 0 || this.run.banishing)) { this.run.banishing = !this.run.banishing; return this.render(); }
    }
    if (s === "hud") {
      if (k === " ") { e.preventDefault(); return this.hudAction("santa"); }
      if (k === "p" || k === "P") return this.go("pause");
    }
    if (k.startsWith("Arrow") && !e.target.closest(".slider")) { e.preventDefault(); this.spatial(k); }
  }

  // Gamepad-style spatial navigation between visible interactive elements.
  spatial(dir) {
    const items = $$("button:not([disabled]), .slider, [data-tip]", this.screenHost).filter((x) => x.offsetParent !== null);
    const cur = $(".is-sel", this.screenHost) || document.activeElement;
    if (!items.length) return;
    if (!cur || !items.includes(cur)) return this.select(items[0]);
    const [cx, cy] = this.center(cur);
    const v = { ArrowUp: [0, -1], ArrowDown: [0, 1], ArrowLeft: [-1, 0], ArrowRight: [1, 0] }[dir];
    let best = null, bestScore = Infinity;
    for (const it of items) {
      if (it === cur) continue;
      const [x, y] = this.center(it);
      const dx = x - cx, dy = y - cy;
      const along = dx * v[0] + dy * v[1];
      if (along <= 4) continue;
      const across = Math.abs(dx * v[1]) + Math.abs(dy * v[0]);
      const score = along + across * 2.2;
      if (score < bestScore) { bestScore = score; best = it; }
    }
    if (best) this.select(best);
  }
}

/* ---------- page chrome ---------- */

let stages = [];

function setMotion(on) {
  STATE.motion = on;
  document.documentElement.classList.toggle("rm", !on);
  const t = $("#motion-toggle"); if (t) t.setAttribute("aria-pressed", String(!on));
  stages.forEach((s) => { cancelAnimationFrame(s.snowRaf); s.startSnow(); if (s.screen === "hud") { s.stopTimers(); s.startHud(); } });
}

function renderView() {
  stages.forEach((s) => s.destroy());
  stages = [];
  const view = $("#view");
  view.className = STATE.compare ? "view compare" : "view";
  if (STATE.compare) {
    view.innerHTML = CONCEPTS.map((c) => `<figure class="cmp"><figcaption><button class="cmp-open" data-c="${c.id}"><b>${c.tag || c.id.toUpperCase()}</b> ${c.name}<span>${c.short}</span></button></figcaption><div class="stage-fit mini" data-c="${c.id}"></div></figure>`).join("");
    $$(".stage-fit", view).forEach((h) => stages.push(new Stage(h, h.dataset.c, STATE.screen, { mini: true })));
    $$(".cmp-open", view).forEach((b) => b.addEventListener("click", () => { STATE.compare = false; setConcept(b.dataset.c); syncChrome(); }));
    stages.forEach((s) => { s.onNav = () => {}; });
  } else {
    view.innerHTML = `<div class="stage-fit" id="main-fit"></div>`;
    const st = new Stage($("#main-fit"), STATE.concept, STATE.screen);
    st.onNav = (screen) => { STATE.screen = screen; safeSet("cc.screen", screen); syncChrome(); };
    stages.push(st);
  }
  syncChrome();
}

function setConcept(c) { STATE.concept = c; safeSet("cc.concept", c); renderView(); }
function setScreen(s) {
  STATE.screen = s; safeSet("cc.screen", s);
  if (STATE.compare) { stages.forEach((st) => { st.screen = s; st.render(); }); syncChrome(); }
  else { stages[0].go(s); }
}

function syncChrome() {
  if (STATE.embed) return;
  $$(".concept-tab").forEach((b) => b.setAttribute("aria-selected", String(b.dataset.c === STATE.concept && !STATE.compare)));
  $$(".screen-tab").forEach((b) => b.setAttribute("aria-selected", String(b.dataset.s === STATE.screen)));
  $("#compare-toggle").setAttribute("aria-pressed", String(STATE.compare));
  const tryBar = $("#try");
  const tries = {
    menu: [["Click the tagline for another joke", null], ["Play", "go:hud"], ["Customize", "go:customize"]],
    levelup: [["Pick a card (1–3)", null], ["Reroll (R)", "key:r"], ["Banish (B)", "key:b"]],
    hud: [["Take a hit", "hud:hit"], ["Collect XP", "hud:xp"], ["Boss arrives", "hud:boss"], ["Achievement", "hud:ach"], ["Santa ready (Space)", "hud:santa"], ["Pause (Esc)", "go:pause"]],
    pause: [["Hover items for tooltips", null], ["Resume", "go:hud"]],
    settings: [["Drag sliders, flip toggles, use arrows", null]],
    achievements: [["Switch tabs", null]],
    customize: [["Pick a hat, outfit or skin, then Equip", null]],
    results: [["Numbers count up on entry", null], ["Replay entry", "go:results"]],
    kit: [["Hover tiles for tooltips; click “Try me”", null]],
  }[STATE.screen] || [];
  const fontBar = STATE.concept === "h" || STATE.compare ? `<span class="font-pick"><span class="try-label">Title font</span>${FONTS.map(([id, label]) => `<button class="try-btn font-btn" data-font="${id}" aria-pressed="${STATE.font === id}">${label}${id === "rocker" ? " (chosen)" : ""}</button>`).join("")}</span>` : "";
  tryBar.innerHTML = `${fontBar}<span class="try-label">Try it</span>${tries.map(([l, a]) => a ? `<button class="try-btn" data-a="${a}">${l}</button>` : `<span class="try-hint">${l}</span>`).join("")}<span class="try-keys">Arrows move the selection like a gamepad · Enter picks · Esc goes back</span>`;
  const c = CONCEPTS.find((x) => x.id === STATE.concept);
  const about = $("#about");
  about.hidden = STATE.compare;
  if (!STATE.compare) {
    about.dataset.c = c.id;
    about.innerHTML = `
      <div class="about-main">
        <h2>${c.tag || c.id.toUpperCase()}. ${c.name}</h2>
        <p class="about-pitch">${c.pitch}</p>
        <div class="about-pairs">Pairs with splash ${c.splash === "h" ? "Knit + Tin" : c.splash.toUpperCase()}: <a href="camel_claus_splash_showcase.html?c=${c.splash}">open the matching intro</a></div>
      </div>
      <div class="about-tokens">
        <div class="swatches">${c.palette.map((p) => `<span style="--s:${p}" title="${p}"><i></i>${p}</span>`).join("")}</div>
        <div class="specimens"><span class="spec-logo" data-c="${c.id}" style="font-family:'${c.id === "h" ? FONTS.find((f) => f[0] === STATE.font)[2] : c.logo[0]}'">Camel Claus<small>${c.id === "h" ? FONTS.find((f) => f[0] === STATE.font)[1] : c.logo[0]}, ${c.logo[1].toLowerCase()}</small></span><span class="spec-ui" data-c="${c.id}" style="font-family:'${c.type[0]}'">Gift Toss: damage 18 → 23<small>${c.type[0]}, ${c.type[1]}</small></span></div>
      </div>
      <div class="about-lists">
        <div><h3>Strengths</h3><ul>${c.pros.map((p) => `<li>${p}</li>`).join("")}</ul></div>
        <div><h3>Watch out for</h3><ul>${c.cons.map((p) => `<li>${p}</li>`).join("")}</ul></div>
      </div>`;
  }
}

function initChrome() {
  if (STATE.embed) { document.body.classList.add("embed"); renderView(); return; }
  $("#concept-tabs").innerHTML = CONCEPTS.map((c) => `<button class="concept-tab" role="tab" data-c="${c.id}"><span class="ct-sw">${c.palette.slice(0, 4).map((p) => `<i style="background:${p}"></i>`).join("")}</span><span class="ct-name"><b>${c.tag || c.id.toUpperCase()}</b> ${c.name}</span><span class="ct-short">${c.short}</span></button>`).join("");
  $("#screen-tabs").innerHTML = SCREENS.map((s) => `<button class="screen-tab" role="tab" data-s="${s.id}">${s.name}</button>`).join("");
  $("#concept-tabs").addEventListener("click", (e) => { const b = e.target.closest(".concept-tab"); if (b) { STATE.compare = false; setConcept(b.dataset.c); } });
  $("#screen-tabs").addEventListener("click", (e) => { const b = e.target.closest(".screen-tab"); if (b) setScreen(b.dataset.s); });
  $("#compare-toggle").addEventListener("click", () => { STATE.compare = !STATE.compare; renderView(); });
  $("#motion-toggle").addEventListener("click", () => setMotion(!STATE.motion));
  $("#try").addEventListener("click", (e) => {
    const fb = e.target.closest(".font-btn");
    if (fb) { STATE.font = fb.dataset.font; safeSet("cc.font.v2", STATE.font); stages.forEach((st) => (st.el.dataset.font = STATE.font)); syncChrome(); return; }
    const b = e.target.closest(".try-btn"); if (!b || !stages[0]) return;
    const [kind, v] = b.dataset.a.split(":");
    stages.forEach((st) => {
      if (kind === "go") st.go(v);
      if (kind === "hud") st.hudAction(v);
      if (kind === "key") st.key({ key: v, preventDefault() {}, target: document.body });
    });
  });
  renderView();
}

addEventListener("keydown", (e) => {
  if (STATE.compare || !stages[0]) return;
  if (e.target.closest && e.target.closest("#chrome")) return;
  stages[0].key(e);
});

document.documentElement.classList.toggle("rm", !STATE.motion);
initChrome();
