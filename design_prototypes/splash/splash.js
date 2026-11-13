// Camel Claus splash prototypes: web loading (HTML/JS) -> Godot boot (bg color) -> intro scene -> main menu.
"use strict";

const R = (n) => `assets/renders/${n}.png`;
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const UI_NAMES = { h: "A+ Hybrid", a: "Workshop Tin", b: "Ugly Sweater", c: "Northern Lights", d: "Polar Expedition", e: "8-Bit Holiday" };

const SPLASH = {
  a: {
    name: "Bonk!", short: "Arcade slapstick", introMs: 3900, midMs: 340, outMs: 820, palette: ["#1A2438", "#1F5A43", "#F2B53B", "#F4F8FF"],
    pitch: "Claus runs on, a gift falls out of the sky and bonks him, and the logo slams down with the impact. It sets the game's tone in one gag and introduces the word the HUD uses for kills.",
    loader: () => `<div class="la"><div class="la-top"><span>Loading the workshop</span><span class="ld-pct">0%</span></div><div class="la-plate"><div class="la-bar"></div></div><div class="la-mb ld-mb"></div></div>`,
    loadText: (p, mb) => mb,
    intro: () => `<div class="ia-world"><div class="ia-bg"></div><div class="ia-snow"></div><div class="ia-vig"></div>
      <div class="ia-run"><img class="ia-claus" src="${R("claus_side")}" alt=""></div>
      <div class="ia-star"></div><div class="ia-dizzy"><i></i><i></i><i></i></div>
      <div class="ia-giftdrop"><img class="ia-gift" src="${R("gift")}" alt=""></div>
      <div class="ia-bonk">Bonk!</div>
      <div class="ia-puff"></div>
      <h1 class="ia-logo">Camel Claus</h1><img class="ia-hat" src="${R("hat_santa")}" alt="">
      <div class="ia-plate">The North Pole</div>
      <div class="ia-press">Press any key</div></div>`,
    beats: [["0.2", "Claus runs in from the left (position track + 4-frame bob)"], ["0.76", "A gift drops from above"], ["1.05", "Bonk: impact star, squash on Claus, screen shake, comic word pops"], ["1.3", "Dizzy stars orbit his head"], ["1.5", "Logo slams down, snow puff and a second shake"], ["2.0", "\"The North Pole\" plate springs up"], ["2.6", "Press any key; auto-continues at 3.9 s"], ["out", "Riveted shutters close and open on the menu"]],
    godot: ["<code>splash.tscn</code>: a Control root with TextureRects for the backdrop, Claus, gift and hat, two Labels, a GPUParticles2D (or CPUParticles2D) for snow.", "One AnimationPlayer, 4 s: position, scale and modulate tracks; the shake is a <code>Camera2D.offset</code> track, or a method track calling the game's existing shake.", "The backdrop can be the real 3D menu diorama in a SubViewport, so the intro ends exactly where the menu begins."],
  },
  b: {
    name: "Knit One, Purl Claus", short: "Cozy handmade", introMs: 4300, midMs: 400, outMs: 900, palette: ["#8E1F2E", "#1F5A43", "#E8C48E", "#FFF8EE"],
    pitch: "The loading bar is a scarf being knitted across the screen, and the intro keeps knitting: the logo appears row by row under two needles, then Claus pops up and a hat lands on the logo.",
    loader: () => `<div class="lb-label">Knitting your sweater <span class="ld-pct">0%</span><small class="ld-mb"></small></div><div class="lb-scarf"></div><div class="lb-ball"></div>`,
    loadText: (p, mb) => mb,
    intro: () => `<div class="ib-bg layer"></div><div class="ib-band top"></div><div class="ib-band bot"></div>
      <h1 class="ib-logo">Camel Claus</h1><div class="ib-needles"><i></i><i></i></div>
      <img class="ib-hat" src="${R("hat_santa")}" alt="">
      <div class="ib-sub">The North Pole</div>
      <div class="ib-yarn"></div><div class="ib-ball"></div>
      <img class="ib-claus" src="${R("claus_3q")}" alt="">
      <div class="ib-press">Press any key</div>`,
    beats: [["web", "The download bar is a scarf; a yarn ball rolls ahead of it"], ["0.3", "The logo is knitted in 12 rows (a stepped clip reveal) under clicking needles"], ["0.3", "A yarn ball rolls across the bottom, unspooling a line"], ["1.9", "\"The North Pole\" fades in with a stitched underline"], ["2.15", "Claus pops up with overshoot, then sways"], ["2.45", "The Santa hat drops onto the logo and squashes"], ["out", "A knitted curtain drops and lifts on the menu"]],
    godot: ["The knit and Fair Isle band are two tiny tiling textures (TextureRect, stretch mode tile).", "The row-by-row reveal is a shader uniform <code>reveal_rows</code> (or a Control with <code>clip_contents</code> whose height an AnimationPlayer track steps).", "In the HTML loader the scarf width follows real download progress; the intro's first frame is the same red, so there's no flash."],
  },
  c: {
    name: "Snow Globe", short: "Quiet magic", introMs: 4500, midMs: 620, outMs: 1050, palette: ["#0E1628", "#7FD6F2", "#5FE0A6", "#C98F55"],
    pitch: "The whole game world sits inside a snow globe (the Snow Globe is an in-game item). It shakes, the snow swirls and settles, an aurora rises, and then the camera dives into the glass and lands on the menu.",
    loader: () => `<div class="lc-ring"></div><div class="lc-flake"></div><div class="lc-label">Gathering snow <span class="ld-pct">0%</span><small class="ld-mb"></small></div>`,
    loadText: (p, mb) => mb,
    intro: () => {
      const flakes = Array.from({ length: 70 }, () => {
        const a = Math.random() * 6.283, r = Math.sqrt(Math.random()) * 190;
        const x = 210 + Math.cos(a) * r, y = 210 + Math.sin(a) * r;
        return `<i style="left:${x}px;top:${y}px;--x:${(Math.random() * 30 - 15).toFixed(0)}px;--y:${(380 - y - Math.random() * 40).toFixed(0)}px;--d:${Math.random().toFixed(2)}"></i>`;
      }).join("");
      const letters = [..."Camel Claus"].map((ch, i) => ch === " " ? "<span style='--i:0'>&nbsp;</span>" : `<span style="--i:${i}">${ch}</span>`).join("");
      return `<div class="ic-sky layer"></div><div class="ic-aurora"></div>
        <h1 class="ic-logo">${letters}</h1><div class="ic-sub">The North Pole</div>
        <div class="ic-globe"><div class="ic-base"></div><div class="ic-plaque">No. 1 Camel</div><div class="ic-glass"><div class="ic-swirl">${flakes}</div></div></div>
        <div class="ic-press">Press any key</div>`;
    },
    beats: [["web", "A progress ring draws itself around a spinning snowflake"], ["0.1", "The globe fades in over a starry night (the real menu diorama is inside, dimmed)"], ["0.55", "The globe shakes (a rotation track pivoting on its base)"], ["0.55", "Snow inside swirls, then settles from 2.2 s"], ["1.7", "Aurora ribbons rise behind it"], ["2.25", "Logo letters condense out of the cold one by one"], ["3.3", "The brass plaque glints"], ["out", "The camera dives into the glass; a frost flash hands over to the menu"]],
    godot: ["The globe interior is a SubViewport showing the actual menu diorama, drawn through a circular mask shader on a TextureRect.", "The snow swirl is a GPUParticles2D with orbit velocity, switched to gravity at 2.2 s by a method track.", "The dive is a scale track on the globe plus a modulate fade into the menu scene, which already uses the aurora shader."],
  },
  d: {
    name: "Footprints", short: "Clean and confident", introMs: 3900, midMs: 330, outMs: 820, palette: ["#F4F8FF", "#22304F", "#D9343F", "#8FA9D1"],
    pitch: "Loading counts up the latitude, from the Arctic Circle to 90°N. Then hoofprints track across the snow to Claus, a map pin drops on him ('You are here') and the title lands like a field-guide cover.",
    loader: () => `<div class="ld-kicker">Locating Claus</div><div class="ld-lat">66.56°N</div><div class="ld-bar"></div><div class="ld-meta"><span class="ld-mb"></span><span class="ld-pct">0%</span></div>`,
    loadText: (p, mb) => mb,
    intro: () => {
      const pts = [];
      for (let i = 0; i < 17; i++) {
        const t = i / 16, x = -40 + t * 970, y = 650 - 330 * Math.sin(t * 1.35) - 40 * t;
        const t2 = Math.min(1, t + 0.01), x2 = -40 + t2 * 970, y2 = 650 - 330 * Math.sin(t2 * 1.35) - 40 * t2;
        const a = Math.atan2(y2 - y, x2 - x) * 180 / Math.PI + 90;
        const off = (i % 2 ? 1 : -1) * 9;
        pts.push(`<span class="id-print" style="left:${(x + off * Math.cos((a) * Math.PI / 180)).toFixed(0)}px;top:${(y + off * Math.sin(a * Math.PI / 180)).toFixed(0)}px;--a:${a.toFixed(0)}deg;--i:${i}"><i></i><i></i></span>`);
      }
      return `<div class="id-field"></div>${pts.join("")}
        <img class="id-claus" src="${R("claus_front")}" alt=""><div class="id-pin"></div><div class="id-tag">You are here</div>
        <h1 class="id-title"><span>Camel</span><span>Claus</span></h1>
        <div class="id-sub">The North Pole <small>90°00′ N</small></div>
        <div class="id-press">Press any key</div>`;
    },
    beats: [["web", "Latitude counts up with real progress: 66.56°N (Arctic Circle) to 90.00°N"], ["0.2", "17 hoofprints stamp across the snow along a curve (like footprints.gd)"], ["1.75", "Claus pops in at the end of the trail"], ["2.0", "A red map pin drops; \"You are here\" tag snaps in"], ["2.35", "Title slams in from the left, then signal tape and coordinates"], ["out", "A navy and candy-cane swipe crosses to the menu"]],
    godot: ["The prints reuse the existing footprint decal, spawned along a Curve2D (or Path3D) by a method track, one per 0.085 s.", "The paper background is one flat color plus a contour-line shader, which makes it very cheap.", "The HTML loader shows the same latitude counter, so the intro picks up mid-sentence."],
  },
  e: {
    name: "Sleigh Flyby", short: "Retro arcade", introMs: 4000, midMs: 360, outMs: 820, palette: ["#0E1424", "#F2B53B", "#7FD6F2", "#F4F8FF"],
    pitch: "An 8-bit night: Santa's sleigh streaks across the sky, its gold trail writes the logo letter by letter and drops presents, then pixel Claus hops in and PRESS START blinks. Pure arcade attract mode.",
    loader: () => `<div class="le"><div class="le-title">Loading</div><div class="le-blocks"></div><div class="le-mb ld-mb"></div></div>`,
    loadText: (p, mb) => mb.toUpperCase(),
    intro: () => {
      const stars = (n, seed) => Array.from({ length: n }, (_, i) => {
        const x = Math.round(((Math.sin(i * 12.9898 + seed) * 43758.5453) % 1 + 1) % 1 * 320) * 4;
        const y = Math.round(((Math.sin(i * 78.233 + seed) * 12345.678) % 1 + 1) % 1 * 110) * 4;
        return `${x}px ${y}px 0 ${i % 5 ? "#C9DAF0" : "#F4F8FF"}`;
      }).join(",");
      const pines = [60, 170, 260, 940, 1050, 1170].map((x, i) => `<i class="ie-pine" style="left:${x}px;${i % 2 ? "height:56px;width:40px" : ""}"></i>`).join("");
      return `<div class="ie-sky"></div><div class="ie-stars" style="box-shadow:${stars(46, 1)}"></div><div class="ie-stars b" style="box-shadow:${stars(30, 7)}"></div><div class="ie-moon"></div>
        <div class="ie-ground"></div>${pines}
        <div class="ie-trail"></div><h1 class="ie-logo">Camel Claus</h1><div class="ie-sub">The North Pole</div>
        <img class="ie-gift" src="${R("px_gift")}" style="left:740px;animation-delay:1.4s" alt=""><img class="ie-gift" src="${R("px_gift")}" style="left:470px;animation-delay:1.7s" alt=""><img class="ie-gift" src="${R("px_gift")}" style="left:205px;animation-delay:2s" alt="">
        <img class="ie-sleigh" src="${R("px_sleigh")}" alt="">
        <img class="ie-claus" src="${R("px_claus_front")}" alt="">
        <div class="ie-press">Press start</div>`;
    },
    beats: [["web", "8-bit LOADING with a 20-block bar that fills in whole blocks"], ["0.8", "Santa's sleigh flies right to left (sprite at 4x, nearest filter)"], ["1.12", "The gold trail writes the logo, one letter per step (11 steps)"], ["1.4", "Three presents drop and land in 8 frames each"], ["2.15", "\"The North Pole\" blinks in"], ["2.4", "Pixel Claus hops up with a 2-frame idle"], ["3.0", "PRESS START blinks"], ["out", "8-step pixel iris closes and opens on the menu"]],
    godot: ["The sprites are the 3D models rendered once to tiny textures (as here), or live in a SubViewport at 1/4 resolution with nearest upscaling.", "The letter reveal is a <code>visible_characters</code> track on a Label: built in, exact, free.", "All tracks use the Nearest/Discrete interpolation mode, which gives the frame-stepped look for free."],
  },
};

// Knit + Tin: B's knitting intro rebuilt for the A+ hybrid (B's styles underneath, [data-v="h"] overrides on top).
SPLASH.h = Object.assign({}, SPLASH.b, {
  base: "b", name: "Knit + Tin", short: "for the A+ hybrid", palette: ["#8E1F2E", "#1A2438", "#F2B53B", "#F4F8FF"],
  pitch: "The knitting intro you picked, rebuilt for the A+ hybrid. Same scarf loader and clicking needles, but the needles knit A's chunky logo, the subtitle springs up on A's riveted plate, and it lands on the A+ menu through the same knitted curtain the menus use between screens.",
  intro: () => SPLASH.b.intro().replace('<div class="ib-sub">The North Pole</div>', '<div class="ib-sub ih-plate">The North Pole</div>'),
  beats: [["web", "Scarf loader: the scarf's length follows real download progress"], ["0.3", "A's chunky logo is knitted in 12 rows under clicking needles"], ["0.3", "A yarn ball rolls across, unspooling a line"], ["1.9", "\"The North Pole\" springs up on A's riveted pine plate"], ["2.15", "Claus pops up and sways"], ["2.45", "The Santa hat drops onto the C and squashes"], ["out", "The knitted curtain (also the in-game screen wipe) drops and lifts on the A+ menu"]],
  godot: ["Same nodes as the knitting intro; the logo is the menu's own logo, revealed row by row with a stepped clip (a 12-step track on a Control's size, or a shader uniform).", "The plate is A's StyleBoxTexture 9-slice, so it's shared with the menus.", "The curtain is one Control with the knit texture + Fair Isle band, tweened down and up by the Transition autoload, so the intro and every menu change use the same wipe."],
});
const ORDER = ["h", "a", "b", "c", "d", "e"];
const params = new URLSearchParams(location.search);
const S = { c: ORDER.includes(params.get("c")) ? params.get("c") : "h", web: true, slow: false, motion: !matchMedia("(prefers-reduced-motion: reduce)").matches, timers: [], raf: 0, phase: "" };

function fit() {
  const host = $("#sp-fit"), st = $(".sp-stage", host);
  if (!st) return;
  const s = host.clientWidth / 1280;
  st.style.transform = `scale(${s})`;
  host.style.setProperty("--stage-h", `${720 * s}px`);
}

function later(fn, ms) { S.timers.push(setTimeout(fn, ms)); }
function clear() { S.timers.forEach(clearTimeout); S.timers = []; cancelAnimationFrame(S.raf); }

function setPhase(p, frac = 0) {
  S.phase = p;
  const st = $(".sp-stage");
  st.classList.remove("ph-web", "ph-boot", "ph-intro", "ph-out", "ph-menu");
  st.classList.add(`ph-${p}`);
  const idx = { web: 0, boot: 1, intro: 2, out: 2, menu: 3 }[p];
  $$(".tl-step").forEach((el, i) => {
    el.classList.toggle("on", i === idx);
    el.classList.toggle("done", i < idx && !(i === 0 && !S.web));
    el.classList.toggle("skipped", i === 0 && !S.web);
    if (i === idx) el.style.setProperty("--f", `${frac * 100}%`);
    else if (i > idx) el.style.setProperty("--f", "0%");
  });
  const labels = { web: "1. Web page: HTML/JS loader while the .wasm and .pck download", boot: "2. Godot starts: boot splash shows only the background color", intro: "3. Godot intro scene (splash.tscn)", out: "3. Transition into the main menu", menu: "4. Main menu (the paired UI concept, live)" };
  $(".sp-phase-label").textContent = labels[p];
}

function play(from = "web") {
  clear();
  const c = S.c, d = SPLASH[c];
  const host = $("#sp-fit");
  host.innerHTML = `<div class="sp-stage" data-s="${d.base || c}" data-v="${c}">
    <div class="sp-menu layer"><iframe title="Main menu" src="camel_claus_ui_showcase.html?embed=1&c=${c}&s=menu${c === "h" ? `&font=${localStorage.getItem("cc.font.v2") || "rocker"}` : ""}" tabindex="-1"></iframe></div>
    <div class="sp-intro layer">${d.intro()}</div>
    <div class="sp-loader layer">${d.loader()}</div>
    <div class="sp-wipe"></div><div class="sp-skip">Click or press any key to skip</div><span class="sp-phase-label"></span></div>`;
  host.dataset.s = c;
  fit();
  const st = $(".sp-stage", host);
  st.addEventListener("click", () => skip());
  if (from === "web" && S.web) runWeb(); else if (from === "menu") showMenu(true); else runBoot();
}

// Simulated download of the real build (index.wasm 39.5 MB + .pck); the last 8% is wasm compile/instantiate.
function runWeb() {
  setPhase("web");
  const total = S.slow ? 9000 : 3200, t0 = performance.now();
  const st = $(".sp-stage");
  const step = (t) => {
    const k = Math.min(1, (t - t0) / total);
    const dl = Math.min(1, k / 0.88);
    const p = k < 0.88 ? 0.92 * (1 - Math.pow(1 - dl, 1.6)) : 0.92 + 0.08 * ((k - 0.88) / 0.12);
    st.style.setProperty("--p", p.toFixed(4));
    st.style.setProperty("--pq", (Math.floor(p * 20) / 20).toFixed(2));
    const mb = k < 0.88 ? `${(39.5 * (1 - Math.pow(1 - dl, 1.6))).toFixed(1)} / 39.5 MB` : "Starting engine…";
    $$(".ld-pct", st).forEach((e) => (e.textContent = `${Math.round(p * 100)}%`));
    $$(".ld-mb", st).forEach((e) => (e.textContent = SPLASH[S.c].loadText(p, mb)));
    const lat = $(".ld-lat", st); if (lat) lat.textContent = `${(66.56 + p * 23.44).toFixed(2)}°N`;
    setPhase("web", k);
    if (k < 1) S.raf = requestAnimationFrame(step); else runBoot();
  };
  S.raf = requestAnimationFrame(step);
}

function runBoot() {
  setPhase("boot");
  later(runIntro, 450);
}

function runIntro() {
  setPhase("intro");
  const st = $(".sp-stage"), intro = $(".sp-intro", st), d = SPLASH[S.c];
  intro.classList.add("play");
  const dur = S.motion ? d.introMs : 1600;
  const t0 = performance.now();
  const tick = () => { if (S.phase !== "intro") return; setPhase("intro", Math.min(1, (performance.now() - t0) / dur)); S.raf = requestAnimationFrame(tick); };
  S.raf = requestAnimationFrame(tick);
  later(() => st.classList.add("can-skip"), 900);
  later(runOut, dur);
}

function runOut() {
  if (S.phase !== "intro") return;
  cancelAnimationFrame(S.raf);
  const d = SPLASH[S.c];
  setPhase("out", 1);
  if (!S.motion) return showMenu();
  later(() => $(".sp-stage").classList.add("show-menu"), d.midMs);
  later(showMenu, d.outMs);
}

function showMenu(direct) {
  clear();
  const st = $(".sp-stage");
  st.classList.add("show-menu");
  if (direct) $$(".tl-step").forEach((e) => e.classList.add("done"));
  setPhase("menu", 1);
}

function skip() {
  if (S.phase === "intro") { clear(); runOut(); }
}

function renderNotes() {
  const d = SPLASH[S.c];
  $("#sp-notes").innerHTML = `
    <div><h2>${S.c === "h" ? "A+" : S.c.toUpperCase()}. ${d.name}</h2><p>${d.pitch}</p>
      <p class="pair">Designed with UI concept ${S.c === "h" ? "A+" : S.c.toUpperCase()}, ${UI_NAMES[S.c]}: <a href="camel_claus_ui_showcase.html?c=${S.c}&s=menu">open it</a>. The intro ends on that concept's live main menu.</p></div>
    <div><h3>Beats (seconds)</h3><ol>${d.beats.map(([t, b]) => `<li><span class="beat-t">${t}</span>${b}</li>`).join("")}</ol></div>
    <div><h3>Building it in Godot</h3><ul>${d.godot.map((g) => `<li>${g}</li>`).join("")}</ul></div>`;
  $$(".sp-tab").forEach((b) => b.setAttribute("aria-selected", String(b.dataset.c === S.c)));
}

function select(c) {
  S.c = c;
  try { history.replaceState(null, "", `?c=${c}`); } catch { /* file:// in some browsers */ }
  renderNotes();
  play();
}

function init() {
  $("#sp-tabs").innerHTML = ORDER.map((c) => `<button class="sp-tab" role="tab" data-c="${c}"><span class="ct-sw">${SPLASH[c].palette.map((p) => `<i style="background:${p}"></i>`).join("")}</span><span class="ct-name"><b>${c === "h" ? "A+" : c.toUpperCase()}</b> ${SPLASH[c].name}</span><span class="ct-short">with ${UI_NAMES[c]}</span></button>`).join("");
  $("#sp-tabs").addEventListener("click", (e) => { const b = e.target.closest(".sp-tab"); if (b) select(b.dataset.c); });
  $("#replay").addEventListener("click", () => play());
  $("#jump-intro").addEventListener("click", () => play("intro"));
  $("#jump-menu").addEventListener("click", () => play("menu"));
  $("#opt-web").addEventListener("change", (e) => { S.web = e.target.checked; play(); });
  $("#opt-slow").addEventListener("change", (e) => { S.slow = e.target.checked; play(); });
  const rm = $("#opt-rm");
  rm.checked = !S.motion;
  document.documentElement.classList.toggle("rm", !S.motion);
  rm.addEventListener("change", (e) => { S.motion = !e.target.checked; document.documentElement.classList.toggle("rm", !S.motion); play(); });
  addEventListener("keydown", (e) => { if (e.target.closest("#chrome")) return; if (S.phase === "intro") { e.preventDefault(); skip(); } });
  new ResizeObserver(fit).observe($("#sp-fit"));
  renderNotes();
  play();
}

init();
