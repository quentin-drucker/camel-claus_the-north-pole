// Camel Claus UI prototypes: real game content (from resources/*.tres) shared by every concept.
// Icons are copies of assets/ui/icons; renders are the game's own models, rendered in Godot.
"use strict";

const ICON = (n) => `assets/icons/${n}.png`;
const RENDER = (n) => `assets/renders/${n}.png`;

const CONCEPTS = [
  {
    id: "h", base: "a", tag: "A+", name: "Hybrid", short: "Tin + knit + North Pole post",
    pitch: "A, unchanged underneath: same plates, slab buttons, brackets and HUD. Added on top are cozy knit from B (texture behind cards, a Fair Isle camel trim under panel headers, sewn sweater buttons on sliders and toggles) and North Pole post from D (stamp-framed icons, postmarks on finished things, an airmail toast, a luggage-tag level badge and a postcard results screen). Titles use New Rocker, a readable blackletter (alternatives are under the stage).",
    type: ["Tiny5", "UI text"], logo: ["New Rocker", "Titles (replaces the pixel blackletter)"],
    palette: ["#1A2438", "#1F5A43", "#F2B53B", "#8E1F2E", "#F4F8FF", "#22304F"],
    pros: ["Keeps A's proven Megabonk structure and HUD readability", "Knit and post give it an identity no other roguelite has", "Every addition is a small texture or an extra node, not a new layout"],
    cons: ["Easy to over-decorate: knit and stamps should stay on cards and rewards, never the HUD", "Postmark text needs a font baked into a texture in Godot"],
    splash: "h",
  },
  {
    id: "a", name: "Workshop Tin", short: "Megabonk-style arcade",
    pitch: "The closest to Megabonk: riveted enamel plates from Santa's toy workshop, slab buttons with a pressable lip, and corner brackets that jump to whatever is focused.",
    type: ["Jacquarda Bastarda 9", "UI text"], logo: ["Bowlby One", "Logo"],
    palette: ["#1A2438", "#22304F", "#1F5A43", "#F2B53B", "#F4F8FF", "#D9343F"],
    pros: ["Instantly readable at a glance; the most proven layout for this genre", "Slab buttons and brackets feel great with mouse and gamepad", "Cheapest to build in Godot: one 9-slice StyleBox plus a bracket node"],
    cons: ["The closest to Megabonk; needs its own logo and motifs to avoid feeling borrowed", "Blackletter pixel text needs 18 px or more to stay legible"],
    splash: "a",
  },
  {
    id: "b", name: "Ugly Sweater", short: "Cozy knitted Christmas",
    pitch: "Claus's own wardrobe as the interface: knitted panels with Fair Isle camel bands, stitched seams, wooden toggle buttons, and menus that hang and sway like ornaments.",
    type: ["Grandstander", "UI text"], logo: ["Jacquard 24", "Display"],
    palette: ["#8E1F2E", "#D9343F", "#1F5A43", "#F4F8FF", "#E8C48E", "#5B3A2A"],
    pros: ["The most unique to this game; nobody else has a knitted UI", "Warm and cozy, matching the music direction", "The pattern bands come straight from cosmetics (sweater, scarf)"],
    cons: ["Busiest look; texture must stay off the HUD", "Swaying panels need tuning so they don't feel sluggish"],
    splash: "b",
  },
  {
    id: "c", name: "Northern Lights", short: "Frosted North Pole fantasy",
    pitch: "Magic at the top of the world: faceted ice panels with chamfered corners, aurora light drifting behind the menus, and sparkles that only appear when something is chosen.",
    type: ["Alegreya Sans", "UI text"], logo: ["Cinzel", "Display"],
    palette: ["#141D33", "#22304F", "#7FD6F2", "#C9DAF0", "#3E9A5B", "#F2B53B"],
    pros: ["The most atmospheric; reuses the game's aurora shader", "Clean shapes keep busy screens calm", "Gold-on-ice rewards read as precious"],
    cons: ["The least playful of the five", "Serif display caps lean fantasy-RPG more than cute"],
    splash: "c",
  },
  {
    id: "d", name: "Polar Expedition", short: "Modern indie roguelite",
    pitch: "Claus is lost, so the UI is his field kit: crisp white survey sheets, navy ink, candy-cane signal tape, slanted buttons and big confident numbers.",
    type: ["Barlow", "UI text"], logo: ["Barlow Condensed", "Display"],
    palette: ["#F4F8FF", "#22304F", "#D9343F", "#8FA9D1", "#F2B53B", "#141D33"],
    pros: ["The sharpest hierarchy and densest information", "Scales cleanly to any resolution (no pixel fonts)", "Its own story: the lost-explorer framing"],
    cons: ["White panels are bright over the snow and need dark HUD variants", "The least overtly Christmassy"],
    splash: "d",
  },
  {
    id: "e", name: "8-Bit Holiday", short: "Retro holiday arcade",
    pitch: "Today's cozy-pixel UI grown up: stepped pixel frames, gift-wrap patterns, an arcade cursor, and frame-by-frame motion with modern spacing and hierarchy.",
    type: ["Kenney Pixel", "UI text"], logo: ["Kenney Mini Square", "Display"],
    palette: ["#141D33", "#22304F", "#F2B53B", "#D9343F", "#7FD6F2", "#3E9A5B"],
    pros: ["The smallest jump from the current game; uses its fonts and icons", "Pixel-perfect at 720p; the icons already match", "Frame-stepped motion is the cheapest to animate"],
    cons: ["The most nostalgic, so it needs the modern spacing to avoid looking dated", "Pixel fonts limit size choices (whole multiples only)"],
    splash: "e",
  },
];

const SCREENS = [
  { id: "menu", name: "Main menu" },
  { id: "levelup", name: "Level up" },
  { id: "hud", name: "Gameplay HUD" },
  { id: "pause", name: "Pause + build" },
  { id: "settings", name: "Settings" },
  { id: "achievements", name: "Achievements" },
  { id: "customize", name: "Customize" },
  { id: "results", name: "Results" },
  { id: "kit", name: "Components" },
];

// Offers rotate through these sets when you reroll.
const OFFER_SETS = [
  [
    { rarity: "common", type: "Weapon upgrade", name: "Gift Toss", icon: "weapon_gift_toss", lv: "Lv 4 → 5",
      stat: ["Damage", "18", "23"], extra: ["Gifts per throw", "2", "3"], hint: "Ready to evolve into Present Barrage" },
    { rarity: "rare", type: "Stat upgrade", name: "Extra Hump", icon: "extra_hump", lv: "Lv 2 → 3",
      stat: ["Max HP", "130", "160"], hint: "Also heals 30 HP right away" },
    { rarity: "epic", type: "New weapon", name: "Jingle Pulse", icon: "weapon_jingle_pulse", lv: "New",
      stat: ["Damage", "—", "14"], hint: "A jingling burst hits and pushes back everything near Claus" },
  ],
  [
    { rarity: "common", type: "Stat upgrade", name: "Magnet Scarf", icon: "magnet_scarf", lv: "Lv 1 → 2",
      stat: ["Pickup reach", "2.5 m", "3.3 m"], hint: "Ornaments fly to you from further away" },
    { rarity: "rare", type: "Weapon upgrade", name: "Candy Cane Orbit", icon: "weapon_candy_cane_orbit", lv: "Lv 2 → 3",
      stat: ["Damage", "11", "14"], extra: ["Canes", "2", "3"], hint: "Evolves at Lv 5 into Peppermint Cyclone" },
    { rarity: "common", type: "Stat upgrade", name: "Swift Hooves", icon: "swift_hooves", lv: "Lv 1 → 2",
      stat: ["Move speed", "5.0 m/s", "5.5 m/s"], hint: "Outrun the Chonks" },
  ],
  [
    { rarity: "epic", type: "Stat upgrade", name: "Heavier Gifts", icon: "heavier_gifts", lv: "Lv 2 → 3",
      stat: ["All weapon damage", "×1.20", "×1.45"], hint: "Epic roll: +25% instead of +20%" },
    { rarity: "common", type: "Stat upgrade", name: "Faster Wrapping", icon: "faster_wrapping", lv: "Lv 1 → 2",
      stat: ["Gift Toss", "every 1.20 s", "every 1.08 s"], hint: "+10% attack speed for every weapon" },
    { rarity: "rare", type: "Stat upgrade", name: "Double Gift", icon: "double_gift", lv: "Lv 1",
      stat: ["Gifts per throw", "2", "3"], hint: "Applies to every weapon that throws" },
  ],
];

const HUD_WEAPONS = [
  { icon: "weapon_gift_toss", name: "Gift Toss", lv: 4 },
  { icon: "weapon_candy_cane_orbit", name: "Candy Cane Orbit", lv: 2 },
  { icon: "weapon_snowball_barrage", name: "Snowball Barrage", lv: 1 },
];
const HUD_ITEMS = [
  { icon: "spiced_dates", name: "Spiced Dates", n: 2, rarity: "common", desc: "+25% damage" },
  { icon: "icicle", name: "Icicle", n: 1, rarity: "rare", desc: "Hits have a 15% chance to freeze the enemy for 1 s" },
  { icon: "fruitcake", name: "Fruitcake", n: 1, rarity: "rare", desc: "Hits have a 30% chance to poison: +60% of the hit as damage over 3 s" },
  { icon: "christmas_cracker", name: "Christmas Cracker", n: 3, rarity: "epic", desc: "Hits have a 25% chance to go BANG: 60% damage to enemies nearby" },
  { icon: "snow_globe", name: "Snow Globe", n: 1, rarity: "epic", desc: "Survive one fatal hit: time freezes around you (one use per globe)" },
  { icon: "hay_bale", name: "Hay Bale", n: 1, rarity: "common", desc: "+40 max HP (and heals it)" },
  { icon: "sleigh_bells", name: "Silver Bells", n: 2, rarity: "common", desc: "+20% attack speed (all weapons)" },
];

const BUILD_WEAPONS = [
  { icon: "weapon_gift_toss", name: "Gift Toss", lv: 4, evo: "Present Barrage", summary: "18 dmg, every 1.08 s, 2 gifts" },
  { icon: "weapon_candy_cane_orbit", name: "Candy Cane Orbit", lv: 2, evo: "Peppermint Cyclone", summary: "11 dmg, 2 canes, 1.6 m reach" },
  { icon: "weapon_snowball_barrage", name: "Snowball Barrage", lv: 1, evo: "Avalanche", summary: "16 dmg, every 2.40 s, 1.2 m splash" },
];

const STATS = [
  [["Max HP", "150"], ["HP regen", "0.5 / s"], ["Move speed", "5.5 m/s"], ["Pickup reach", "3.3 m"]],
  [["Damage", "×1.45"], ["Attack speed", "+30%"], ["Extra projectiles", "+1"], ["Damage to elites", "+40%"]],
  [["XP gain", "×1.00"], ["Coin gain", "×1.10"], ["Rerolls left", "2"], ["Banishes left", "1"]],
];

const ACHIEVEMENTS = [
  { cat: "survival", t: "Snow Day", d: "Finish your first run", p: 1, of: 1, r: 20, icon: "snow_globe" },
  { cat: "survival", t: "Sweet Tooth", d: "Survive 3 minutes in one run", p: 180, of: 180, r: 30, icon: "hot_cocoa", fmt: "time" },
  { cat: "survival", t: "Snow Survivor", d: "Survive the full 5 minutes", p: 0, of: 1, r: 60, icon: "snow_angel" },
  { cat: "survival", t: "Not a Scratch", d: "Survive 5 minutes without taking damage", p: 0, of: 1, r: 300, icon: "hay_bale" },
  { cat: "survival", t: "Endless Night", d: "Keep going in Endless mode until 8:00", p: 0, of: 480, r: 100, icon: "blizzard", fmt: "time" },
  { cat: "bonks", t: "Snowball Fight", d: "Bonk 100 critters in one run", p: 100, of: 100, r: 25, render: "chaser" },
  { cat: "bonks", t: "Critter Control", d: "Bonk 300 critters in total", p: 212, of: 300, r: 30, render: "zoomer" },
  { cat: "bonks", t: "Blizzard of Bonks", d: "Bonk 1000 critters in one run", p: 322, of: 1000, r: 60, render: "chonk" },
  { cat: "bonks", t: "Crown Collector", d: "Defeat a crowned elite", p: 1, of: 1, r: 30, render: "crown" },
  { cat: "bonks", t: "Yeti Tamer", d: "Defeat the Grumpy Yeti", p: 0, of: 1, r: 80, render: "yeti" },
  { cat: "santa", t: "Evolution!", d: "Evolve a weapon with Santa's present", p: 1, of: 1, r: 40, icon: "evolution" },
  { cat: "santa", t: "Double Evolution", d: "Evolve 2 weapons in one run", p: 1, of: 2, r: 80, icon: "weapon_gift_toss_evo" },
  { cat: "santa", t: "Full Sleigh", d: "Evolve 3 weapons in one run", p: 1, of: 3, r: 120, icon: "santa_sleigh" },
  { cat: "santa", t: "Santa's Favourite", d: "Call Santa's Sleigh 4 times in one run", p: 2, of: 4, r: 40, icon: "santa_present" },
  { cat: "collect", t: "Hands Full", d: "Carry 3 weapons in one run", p: 3, of: 3, r: 25, icon: "santas_sack" },
  { cat: "collect", t: "Mix and Match", d: "Play 3 different loadouts", p: 2, of: 3, r: 40, icon: "reroll" },
  { cat: "collect", t: "Collector", d: "Unlock every weapon", p: 4, of: 6, r: 100, icon: "trophy" },
  { cat: "collect", t: "Workshop Regular", d: "Buy 5 Workshop upgrades", p: 3, of: 5, r: 50, icon: "coin" },
];
const ACH_TABS = [
  { id: "all", name: "All" }, { id: "survival", name: "Survival" }, { id: "bonks", name: "Bonks" },
  { id: "santa", name: "Santa" }, { id: "collect", name: "Collection" },
];

const COSMETICS = {
  hats: [
    { id: "santa", name: "Santa Hat", price: 0, owned: true, img: RENDER("hat_santa"), preview: RENDER("claus_3q"), desc: "Claus's classic. Bobble included." },
    { id: "beanie", name: "Bobble Beanie", price: 0, owned: true, img: RENDER("hat_beanie"), preview: RENDER("claus_hat_beanie"), desc: "Knitted by an elf who ran out of red." },
    { id: "elf", name: "Elf Hat", price: 100, owned: true, img: RENDER("hat_elf"), preview: RENDER("claus_hat_elf"), desc: "Pointy, green, slightly too small." },
    { id: "antlers", name: "Reindeer Antlers", price: 150, owned: false, img: RENDER("hat_antlers"), preview: RENDER("claus_hat_antlers"), desc: "Comes with a red nose. Camels love it." },
    { id: "none", name: "No hat", price: 0, owned: true, img: null, preview: RENDER("claus_hat_none"), desc: "Let the humps breathe." },
  ],
  outfits: [
    { id: "scarf", name: "Cozy Scarf", price: 0, owned: true, img: RENDER("outfit_scarf"), preview: RENDER("claus_3q"), desc: "Blue and white, the school colors." },
    { id: "sweater", name: "Christmas Sweater", price: 120, owned: true, img: RENDER("outfit_sweater"), preview: RENDER("claus_outfit_sweater"), desc: "Ugly on purpose. Warm by accident." },
    { id: "coat", name: "Santa Coat", price: 180, owned: false, img: RENDER("outfit_coat"), preview: RENDER("claus_outfit_coat"), desc: "Santa won't miss it. Probably." },
    { id: "collar", name: "Elf Collar", price: 100, owned: false, img: RENDER("outfit_collar"), preview: RENDER("claus_outfit_collar"), desc: "Jingles a little when you run." },
    { id: "none", name: "No outfit", price: 0, owned: true, img: null, preview: RENDER("claus_outfit_none"), desc: "Just camel." },
  ],
  skins: [
    { name: "Classic Tan", c: ["#E8C48E", "#C98F55"], price: 0, owned: true },
    { name: "Cocoa", c: ["#C98F55", "#8A5A33"], price: 0, owned: true },
    { name: "Cream", c: ["#F4F8FF", "#E8C48E"], price: 0, owned: true },
    { name: "Frosty", c: ["#7FD6F2", "#4E6A9E"], price: 120, owned: false },
    { name: "Evergreen", c: ["#3E9A5B", "#1F5A43"], price: 150, owned: false },
    { name: "Golden", c: ["#F2B53B", "#C98F55"], price: 300, owned: false },
  ],
};

const RESULTS = {
  won: true, time: "5:00", level: 14, kills: 1042, coins: 186, best: true,
  damage: [
    { icon: "weapon_gift_toss_evo", name: "Present Barrage", lv: 5, dmg: 48210, dps: 161 },
    { icon: "weapon_candy_cane_orbit", name: "Candy Cane Orbit", lv: 4, dmg: 22940, dps: 76 },
    { icon: "weapon_snowball_barrage", name: "Snowball Barrage", lv: 3, dmg: 9420, dps: 31 },
    { icon: "fruitcake", name: "Fruitcake poison", lv: 1, dmg: 3105, dps: 10 },
    { icon: "christmas_cracker", name: "Christmas Cracker", lv: 3, dmg: 2730, dps: 9 },
  ],
  unlocked: [{ t: "Blizzard of Bonks", r: 60 }, { t: "Snow Survivor", r: 60 }],
};

const TAGLINES = ["Lost camel. Angry critters. Survive 5 minutes!", "One hump short of a reindeer.", "Ho ho hump!", "Now with 40% more bonk."];

const fmtNum = (n) => n.toLocaleString("en-US");
