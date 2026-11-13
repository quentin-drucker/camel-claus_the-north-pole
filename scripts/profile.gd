extends Node
## Autoload "Profile": everything that survives between runs (meta-progression), saved as JSON in
## user://profile.json. In a web build user:// lives in the browser's IndexedDB (per site).
## GameState is per run; Profile is per player. A run reads the loadout and Workshop bonuses from here
## at start, achievements are checked live (HUD, once a second) and once more when the run is recorded
## (record_run(), called by the results screen), which also pays coins and updates stats and bests.
##
## Save format: a Dictionary with a `version`. load_profile() fills any missing key from DEFAULTS, so
## new fields never break old saves; bump VERSION and migrate in _migrate() when a field changes meaning.
## A save that can't be parsed is kept as profile.corrupt.json and the player starts fresh.

signal changed
signal achievement_earned(achievement: AchievementData)

const VERSION: int = 1

## Every weapon in the game, in collection order. A weapon's id is its scene's file name
## ("gift_toss"); saves, loadouts and unlocks use ids.
const WEAPON_CARDS: Array[UpgradeData] = [
	preload("res://resources/upgrades/weapon_gift_toss.tres"),
	preload("res://resources/upgrades/weapon_candy_cane_orbit.tres"),
	preload("res://resources/upgrades/weapon_jingle_pulse.tres"),
	preload("res://resources/upgrades/weapon_snowball_barrage.tres"),
	preload("res://resources/upgrades/weapon_ornament_mines.tres"),
	preload("res://resources/upgrades/weapon_gingerbread_boomerang.tres"),
]
const STARTER_WEAPONS: Array[String] = ["gift_toss", "candy_cane_orbit", "jingle_pulse"]
const LOADOUT_SIZE: int = 3
## Coins to buy a weapon once its achievement is earned.
const WEAPON_PRICES: Dictionary = {"snowball_barrage": 150, "ornament_mines": 150, "gingerbread_boomerang": 150}

const WORKSHOP: Array[WorkshopData] = [
	preload("res://resources/workshop/cozy_sweater.tres"),
	preload("res://resources/workshop/hoof_wax.tres"),
	preload("res://resources/workshop/sharper_bows.tres"),
	preload("res://resources/workshop/shiny_baubles.tres"),
	preload("res://resources/workshop/long_scarf.tres"),
	preload("res://resources/workshop/second_wish.tres"),
	preload("res://resources/workshop/naughty_eraser.tres"),
]
const ACHIEVEMENTS: Array[AchievementData] = [
	preload("res://resources/achievements/snow_day.tres"),
	preload("res://resources/achievements/snowball_fight.tres"),
	preload("res://resources/achievements/critter_control.tres"),
	preload("res://resources/achievements/crown_collector.tres"),
	preload("res://resources/achievements/sweet_tooth.tres"),
	preload("res://resources/achievements/hands_full.tres"),
	preload("res://resources/achievements/evolution.tres"),
	preload("res://resources/achievements/double_evolution.tres"),
	preload("res://resources/achievements/santas_favourite.tres"),
	preload("res://resources/achievements/snow_survivor.tres"),
	preload("res://resources/achievements/yeti_tamer.tres"),
	preload("res://resources/achievements/blizzard_of_bonks.tres"),
	preload("res://resources/achievements/endless_night.tres"),
	preload("res://resources/achievements/triple_evolution.tres"),
	preload("res://resources/achievements/not_a_scratch.tres"),
	preload("res://resources/achievements/mix_and_match.tres"),
	preload("res://resources/achievements/workshop_regular.tres"),
	preload("res://resources/achievements/collector.tres"),
]

## Claus's looks (main menu > Customize). Cosmetic only; free ones (price 0) are owned from the start.
const COSMETICS: Array[CosmeticData] = [
	preload("res://resources/cosmetics/skin_classic.tres"),
	preload("res://resources/cosmetics/skin_cocoa.tres"),
	preload("res://resources/cosmetics/skin_cream.tres"),
	preload("res://resources/cosmetics/skin_frosty.tres"),
	preload("res://resources/cosmetics/skin_evergreen.tres"),
	preload("res://resources/cosmetics/skin_golden.tres"),
	preload("res://resources/cosmetics/hat_none.tres"),
	preload("res://resources/cosmetics/hat_santa.tres"),
	preload("res://resources/cosmetics/hat_beanie.tres"),
	preload("res://resources/cosmetics/hat_elf.tres"),
	preload("res://resources/cosmetics/hat_antlers.tres"),
	preload("res://resources/cosmetics/outfit_none.tres"),
	preload("res://resources/cosmetics/outfit_scarf.tres"),
	preload("res://resources/cosmetics/outfit_sweater.tres"),
	preload("res://resources/cosmetics/outfit_elf_collar.tres"),
	preload("res://resources/cosmetics/outfit_santa_coat.tres"),
]
## The original Claus: tan, red Santa hat, blue-and-white scarf ("Default look" restores it).
const DEFAULT_LOOK: Dictionary = {
	"skin": "skin_classic", "hat": "hat_santa", "hat_color": "red", "outfit": "outfit_scarf", "outfit_color": "blue",
}
const SLOT_KEYS: Array[String] = ["skin", "hat", "outfit"]

## Run payout: 1 coin per COIN_KILLS kills and per COIN_SECONDS survived, plus elites, the boss and a
## win bonus. A win is ~300 coins, a loss at 2:30 ~70, so losing still buys something.
const COIN_KILLS: int = 10
const COIN_SECONDS: int = 10
const COIN_ELITE: int = 15
const COIN_BOSS: int = 60
const COIN_WIN: int = 50

## Lifetime totals shown on the Stats page, in order (key -> label).
const STAT_LABELS: Dictionary = {
	"runs": "Runs played", "wins": "Runs survived", "deaths": "Times fainted", "kills": "Critters bonked",
	"damage_dealt": "Damage dealt", "damage_taken": "Damage taken", "time": "Time in the snow",
	"coins_earned": "Coins earned", "evolutions": "Weapons evolved", "santa_calls": "Santa's sleighs called",
	"elites": "Elites defeated", "bosses": "Yetis defeated", "xp": "XP collected",
}
const BEST_LABELS: Dictionary = {
	"time": "Longest run", "kills": "Most kills", "damage": "Most damage", "evolutions": "Most evolutions",
	"level": "Highest level", "endless": "Longest Endless run",
}

const DEFAULTS: Dictionary = {
	"version": VERSION,
	"coins": 0,
	"shop": {},  # Workshop upgrade id -> level bought
	"unlocked": STARTER_WEAPONS,  # weapon ids
	"loadout": STARTER_WEAPONS,  # up to LOADOUT_SIZE weapon ids
	"starter": "gift_toss",  # weapon Claus starts each run with (one of the loadout)
	"achievements": {},  # achievement id -> unix time earned
	"stats": {},  # lifetime totals (STAT_LABELS keys)
	"bests": {},  # personal bests (BEST_LABELS keys) + "build": weapon titles of the most-kills run
	"seen_combos": [],  # sorted loadout ids already played ("Mix and Match")
	"cosmetics_owned": [],  # bought cosmetic ids (free ones are always owned)
	"look": DEFAULT_LOOK,  # equipped cosmetic per slot + chosen colors
	"seen_intro": false,  # the Knit + Tin intro plays in full once, then as a short sting
	"top_runs": [],  # main menu "Best runs": up to TOP_RUNS of {time, level, kills}, longest first
}
const TOP_RUNS: int = 3

## Tests point this at a scratch file so they never touch the player's save.
var save_path: String = "user://profile.json"
var data: Dictionary = DEFAULTS.duplicate(true)  # filled before _ready so early callers (tests) work


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	data = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary:
		push_warning("Profile: unreadable save kept as %s.corrupt, starting fresh" % save_path)
		DirAccess.rename_absolute(save_path, save_path + ".corrupt")
		return
	for key: String in parsed:
		data[key] = parsed[key]
	_migrate()
	_sanitize()


func save() -> void:
	data["version"] = VERSION
	var tmp: String = save_path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Profile: can't write %s (%s)" % [tmp, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	DirAccess.rename_absolute(tmp, save_path)  # replace in one step so a crash can't leave half a file
	changed.emit()


## Demo code (DemoCode, type "hohoho"): every weapon, cosmetic, Workshop level and achievement, plus
## plenty of coins, so a live demo can show everything. Achievements are marked done without paying
## their rewards. Settings > Reset progress undoes it.
func unlock_everything() -> void:
	data["coins"] = maxi(coins(), 99999)
	data["unlocked"] = weapon_ids()
	for item in COSMETICS:
		if item.id not in data["cosmetics_owned"]:
			data["cosmetics_owned"].append(item.id)
	for item in WORKSHOP:
		data["shop"][item.id] = item.max_level()
	for goal in ACHIEVEMENTS:
		if not has_achievement(goal.id):
			data["achievements"][goal.id] = int(Time.get_unix_time_from_system())
	save()


## Wipe progress (Settings > Reset progress).
func reset() -> void:
	data = DEFAULTS.duplicate(true)
	save()


func _migrate() -> void:
	pass  # VERSION 1 is the first format


## Fix anything a stale or hand-edited save could break: unknown weapons, wrong types.
func _sanitize() -> void:
	for key: String in ["shop", "achievements", "stats", "bests", "look"]:
		if not data[key] is Dictionary:
			data[key] = {}
	for key: String in ["unlocked", "loadout", "seen_combos", "cosmetics_owned", "top_runs"]:
		if not data[key] is Array:
			data[key] = DEFAULTS[key].duplicate()
	if data["top_runs"].is_empty() and data["bests"].has("time"):  # saves from before the list existed
		var b: Dictionary = data["bests"]
		data["top_runs"] = [{"time": int(b["time"]), "level": int(b.get("level", 1)), "kills": int(b.get("kills", 0))}]
	data["coins"] = maxi(int(data["coins"]), 0)
	for key: String in DEFAULT_LOOK:  # unknown or unowned pieces fall back to the default look
		if not data["look"].has(key):
			data["look"][key] = DEFAULT_LOOK[key]
	for i in SLOT_KEYS.size():
		var item: CosmeticData = cosmetic(data["look"][SLOT_KEYS[i]])
		if item == null or item.slot != i or not owns_cosmetic(item):
			data["look"][SLOT_KEYS[i]] = DEFAULT_LOOK[SLOT_KEYS[i]]
	var known: Array[String] = weapon_ids()
	var unlocked: Array = (data["unlocked"] as Array).filter(func(id: Variant) -> bool: return id in known)
	for id in STARTER_WEAPONS:
		if id not in unlocked:
			unlocked.append(id)
	data["unlocked"] = unlocked
	var loadout: Array = (data["loadout"] as Array).filter(func(id: Variant) -> bool: return id in unlocked)
	if loadout.is_empty():
		loadout = STARTER_WEAPONS.duplicate()
	data["loadout"] = loadout.slice(0, LOADOUT_SIZE)
	if data["starter"] not in data["loadout"]:
		data["starter"] = data["loadout"][0]


# --- Weapons ------------------------------------------------------------------------------------
static func weapon_id(card: UpgradeData) -> String:
	return card.weapon_scene.resource_path.get_file().get_basename()


static func weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	for card in WEAPON_CARDS:
		ids.append(weapon_id(card))
	return ids


static func weapon_card(id: String) -> UpgradeData:
	for card in WEAPON_CARDS:
		if weapon_id(card) == id:
			return card
	return null


func is_unlocked(id: String) -> bool:
	return id in data["unlocked"]


## The achievement that makes a weapon buyable, or null for starter weapons.
func unlock_goal(id: String) -> AchievementData:
	for goal in ACHIEVEMENTS:
		if goal.unlocks_weapon == id:
			return goal
	return null


## Earned its achievement but not bought yet.
func is_buyable(id: String) -> bool:
	var goal: AchievementData = unlock_goal(id)
	return not is_unlocked(id) and goal != null and has_achievement(goal.id)


func buy_weapon(id: String) -> bool:
	if not is_buyable(id) or data["coins"] < WEAPON_PRICES.get(id, 0):
		return false
	data["coins"] -= WEAPON_PRICES.get(id, 0)
	data["unlocked"].append(id)
	save()
	check_achievements()  # "Collector"
	return true


## How a locked weapon gets unlocked (loadout screen, Workshop).
func unlock_hint(id: String) -> String:
	if is_buyable(id):
		return "buy it in the Workshop for %d coins" % WEAPON_PRICES.get(id, 0)
	var goal: AchievementData = unlock_goal(id)
	if goal == null:
		return ""
	var have: float = minf(progress().get(goal.stat, 0.0), goal.target)
	return "%s (%d/%d), then buy it in the Workshop" % [goal.description, have, goal.target]


func loadout() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(data["loadout"])
	return ids


func starter() -> String:
	return data["starter"]


## Set the run loadout (unlocked ids only, at most LOADOUT_SIZE); the starter must be one of them.
func set_loadout(ids: Array[String], starter_id: String) -> void:
	var clean: Array[String] = []
	for id in ids:
		if is_unlocked(id) and id not in clean and clean.size() < LOADOUT_SIZE:
			clean.append(id)
	if clean.is_empty():
		return
	data["loadout"] = clean
	data["starter"] = starter_id if starter_id in clean else clean[0]
	save()


# --- Cosmetics ------------------------------------------------------------------------------------
static func cosmetic(id: String) -> CosmeticData:
	for item in COSMETICS:
		if item.id == id:
			return item
	return null


func owns_cosmetic(item: CosmeticData) -> bool:
	return item.price == 0 or item.id in data["cosmetics_owned"]


func buy_cosmetic(item: CosmeticData) -> bool:
	if owns_cosmetic(item) or data["coins"] < item.price:
		return false
	data["coins"] -= item.price
	data["cosmetics_owned"].append(item.id)
	save()
	return true


## The equipped item for a slot and its chosen color name ("" for skins / no color options).
func equipped(slot: CosmeticData.Slot) -> CosmeticData:
	return cosmetic(data["look"][SLOT_KEYS[slot]])


func equipped_color(slot: CosmeticData.Slot) -> String:
	return data["look"].get(SLOT_KEYS[slot] + "_color", "")


## Wear an owned item (and optionally a color from its options). Saves and tells Claus to redress.
func equip(item: CosmeticData, color: String = "") -> void:
	if not owns_cosmetic(item):
		return
	var key: String = SLOT_KEYS[item.slot]
	data["look"][key] = item.id
	if item.slot != CosmeticData.Slot.SKIN:
		var keep: String = equipped_color(item.slot)
		data["look"][key + "_color"] = color if color in item.color_options 			else (keep if keep in item.color_options else (item.color_options[0] if not item.color_options.is_empty() else ""))
	save()


func reset_look() -> void:
	data["look"] = DEFAULT_LOOK.duplicate()
	save()


# --- Workshop -----------------------------------------------------------------------------------
func coins() -> int:
	return data["coins"]


func workshop_level(item: WorkshopData) -> int:
	return int(data["shop"].get(item.id, 0))


## Price of the next level, or -1 when maxed.
func workshop_cost(item: WorkshopData) -> int:
	var level: int = workshop_level(item)
	return item.costs[level] if level < item.max_level() else -1


func buy_workshop(item: WorkshopData) -> bool:
	var cost: int = workshop_cost(item)
	if cost < 0 or data["coins"] < cost:
		return false
	data["coins"] -= cost
	data["shop"][item.id] = workshop_level(item) + 1
	save()
	check_achievements()  # "Workshop Regular"
	return true


## Total bonus of one Workshop stat (sum over items with that stat).
func workshop_bonus(stat: WorkshopData.Stat) -> float:
	var total: float = 0.0
	for item in WORKSHOP:
		if item.stat == stat:
			total += item.amount * workshop_level(item)
	return total


## Run start: the Workshop's permanent bonuses on Claus (GameState adds XP, rerolls and banishes).
func apply_workshop(player: Player) -> void:
	var hp: float = workshop_bonus(WorkshopData.Stat.MAX_HP)
	player.max_hp += hp
	player.hp += hp
	player.move_speed_bonus += workshop_bonus(WorkshopData.Stat.MOVE_SPEED)
	player.damage_mult += workshop_bonus(WorkshopData.Stat.DAMAGE)
	player.pickup_bonus += workshop_bonus(WorkshopData.Stat.PICKUP)


## Keep the TOP_RUNS longest runs (more bonks breaks a tie).
func _add_top_run(entry: Dictionary) -> void:
	var runs: Array = data["top_runs"]
	runs.append(entry)
	runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["time"] > b["time"] or (a["time"] == b["time"] and a["kills"] > b["kills"]))
	data["top_runs"] = runs.slice(0, TOP_RUNS)


# --- Achievements, stats, bests -----------------------------------------------------------------
func has_achievement(id: String) -> bool:
	return data["achievements"].has(id)


func stat(key: String) -> float:
	return float(data["stats"].get(key, 0.0))


## Every value an achievement can track. Lifetime totals include the run in progress until it is
## recorded, so live checks see it and record_run() never counts it twice.
func progress() -> Dictionary:
	var gs: Node = GameState
	var live: bool = not gs.recorded and gs.run_time > 0.0
	var run_kills: float = gs.kills
	var p: Dictionary = {
		"run_kills": run_kills,
		"run_evolutions": gs.evolutions,
		"run_weapons": gs.player.weapons().size() if is_instance_valid(gs.player) else 0,
		"run_santa_calls": gs.santa_calls,
		"run_seconds": gs.run_time,
		"run_flawless_win": 1.0 if gs.won and gs.damage_taken <= 0.0 else 0.0,
		"total_runs": stat("runs"),
		"total_wins": stat("wins"),
		"total_kills": stat("kills") + (run_kills if live else 0.0),
		"total_elites": stat("elites") + (gs.elites_killed if live else 0),
		"total_bosses": stat("bosses") + (gs.bosses_killed if live else 0),
		"total_evolutions": stat("evolutions") + (gs.evolutions if live else 0),
		"total_combos": (data["seen_combos"] as Array).size(),
		"total_weapons_unlocked": (data["unlocked"] as Array).size(),
		"total_workshop_levels": 0.0,
	}
	for item in WORKSHOP:
		p["total_workshop_levels"] += workshop_level(item)
	return p


## Earn every goal whose target is reached; pays coins at once. Returns the newly earned ones.
func check_achievements() -> Array[AchievementData]:
	var earned: Array[AchievementData] = []
	var p: Dictionary = progress()
	for goal in ACHIEVEMENTS:
		if has_achievement(goal.id) or p.get(goal.stat, 0.0) < goal.target:
			continue
		data["achievements"][goal.id] = int(Time.get_unix_time_from_system())
		data["coins"] += goal.reward_coins
		earned.append(goal)
	if not earned.is_empty():
		save()
		for goal in earned:
			achievement_earned.emit(goal)
	return earned


## Coins a run pays, itemised for the results screen.
static func run_coins(kills: int, seconds: float, elites: int, bosses: int, won: bool) -> Dictionary:
	@warning_ignore("integer_division")
	var parts: Dictionary = {
		"kills": kills / COIN_KILLS, "time": int(seconds) / COIN_SECONDS,
		"elites": elites * COIN_ELITE, "boss": bosses * COIN_BOSS, "win": COIN_WIN if won else 0,
	}
	parts["total"] = parts.values().reduce(func(a: int, b: int) -> int: return a + b, 0)
	return parts


## Once per results screen: pay coins, add the run to lifetime stats and bests, check goals.
## An Endless continuation is recorded again when it ends, counting only what happened since the last
## record (GameState.record_base), so a run is never counted twice.
## Returns {coins: Dictionary, records: Array[String] of BEST_LABELS keys, achievements: Array}.
func record_run() -> Dictionary:
	var gs: Node = GameState
	if gs.recorded:
		return {}
	var first: bool = gs.record_base.is_empty()
	var now: Dictionary = {
		"kills": gs.kills, "time": gs.run_time, "elites": gs.elites_killed, "bosses": gs.bosses_killed,
		"damage_dealt": gs.damage_dealt, "damage_taken": gs.damage_taken, "evolutions": gs.evolutions,
		"santa_calls": gs.santa_calls, "xp": gs.xp_collected,
	}
	var d: Dictionary = {}
	for key: String in now:
		d[key] = now[key] - gs.record_base.get(key, 0)
	var payout: Dictionary = run_coins(d["kills"], d["time"], d["elites"], d["bosses"], gs.won and first)
	var stats: Dictionary = data["stats"]
	var add: Dictionary = {
		"runs": 1 if first else 0, "wins": 1 if gs.won and first else 0, "deaths": 0 if gs.won else 1,
		"kills": d["kills"], "damage_dealt": roundi(d["damage_dealt"]), "damage_taken": roundi(d["damage_taken"]),
		"time": roundi(d["time"]), "coins_earned": payout["total"], "evolutions": d["evolutions"],
		"santa_calls": d["santa_calls"], "elites": d["elites"], "bosses": d["bosses"], "xp": d["xp"],
	}
	for key: String in add:
		stats[key] = stat(key) + add[key]
	data["coins"] += payout["total"]
	var bests: Dictionary = data["bests"]
	var run_values: Dictionary = {"time": roundi(gs.run_time), "kills": gs.kills,
		"damage": roundi(gs.damage_dealt), "evolutions": gs.evolutions, "level": gs.level}
	if gs.endless:
		run_values["endless"] = roundi(gs.run_time)
	var records: Array[String] = []
	for key: String in run_values:
		if run_values[key] > float(bests.get(key, 0.0)):
			if bests.has(key) or key == "endless":  # the first run sets the normal bests quietly
				records.append(key)
			bests[key] = run_values[key]
			if key == "kills" and gs.player:
				bests["build"] = gs.player.weapons().map(func(w: Weapon) -> String: return w.title())
	if first:
		_add_top_run({"time": roundi(gs.run_time), "level": gs.level, "kills": gs.kills})
		var combo: Array = gs.loadout.duplicate()
		combo.sort()
		if combo not in data["seen_combos"]:
			data["seen_combos"].append(combo)
	gs.recorded = true
	gs.record_base = now
	var earned: Array[AchievementData] = check_achievements()
	save()
	return {"coins": payout, "records": records, "achievements": earned}
