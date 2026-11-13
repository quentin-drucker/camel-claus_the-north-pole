class_name Describe
extends RefCounted
## All player-facing text about upgrades, weapons, items, evolutions and stats, computed from the real
## game formulas (WeaponData, Player). Cards, HUD and pause menu all use this, so they never disagree.
## Returns BBCode for RichTextLabel.

const GOOD: String = "9BE0A8"
const BAD: String = "FF9AA0"
const MUTED: String = "8FA9D1"
const GOLD: String = "F2B53B"
const ICE: String = "7FD6F2"
const ICON_DIR: String = "res://assets/ui/icons/"
const WEAPONS: Array[WeaponData] = [
	preload("res://resources/weapons/gift_toss.tres"),
	preload("res://resources/weapons/candy_cane_orbit.tres"),
	preload("res://resources/weapons/jingle_pulse.tres"),
	preload("res://resources/weapons/snowball_barrage.tres"),
	preload("res://resources/weapons/ornament_mines.tres"),
	preload("res://resources/weapons/gingerbread_boomerang.tres"),
]


static func c(color: String, text: String) -> String:
	return "[color=#%s]%s[/color]" % [color, text]


static func num(v: float) -> String:
	return ("%.1f" % v).trim_suffix(".0")


static func pct(v: float) -> String:
	return "%d%%" % roundi(v * 100.0)


## "old > new" with the new value highlighted as an improvement.
static func change(old: String, new: String) -> String:
	return "%s > %s" % [old, c(GOOD, new)]


static func icon(name: String) -> Texture2D:
	var path: String = ICON_DIR + name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


static func icon_for(res: Resource) -> Texture2D:
	return icon(res.resource_path.get_file().get_basename())


static func weapon_icon(weapon: Weapon) -> Texture2D:
	var base: String = "weapon_" + weapon.scene_file_path.get_file().get_basename()
	if weapon.evolved and icon(base + "_evo"):
		return icon(base + "_evo")
	return icon(base)


static func evolved_icon(weapon: Weapon) -> Texture2D:
	var base: String = "weapon_" + weapon.scene_file_path.get_file().get_basename()
	return icon(base + "_evo") if icon(base + "_evo") else icon(base)


static func weapon_data_named(display_name: String) -> WeaponData:
	for data in WEAPONS:
		if data.display_name == display_name:
			return data
	return null


static func sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1) if text else text


## `player` null = base stats (menus outside a run).
static func weapon_summary(data: WeaponData, level: int, evolved: bool, player: Player) -> String:
	var dmg_mult: float = player.damage_mult if player else 1.0
	var atk: float = player.attack_speed_bonus if player else 0.0
	var extra: int = player.extra_projectiles if player else 0
	var parts: PackedStringArray = ["%s dmg" % num(data.damage_at(level, evolved, dmg_mult))]
	if data.show_cooldown:
		parts.append("every %.2fs" % data.cooldown_at(evolved, atk))
	if data.count_noun != "":
		var n: int = data.count_at(level, evolved, extra)
		parts.append("%d %s%s" % [n, data.count_noun, "s" if n != 1 else ""])
	if data.show_radius:
		parts.append("%s m %s" % [num(data.radius_at(level, evolved)), data.radius_label])
	return ", ".join(parts)


## Evolution line with progress: "Evolves at Lv 5 (3/5) > Present Barrage".
static func evolution_progress(data: WeaponData, level: int, evolved: bool) -> String:
	if data.evolved_name == "":
		return c(MUTED, "No evolution")
	if evolved:
		return c(GOLD, "EVOLVED into " + data.evolved_name)
	if level < WeaponData.MAX_LEVEL:
		return "Evolves at %s > %s" % [c(MUTED, "Lv %d/%d" % [level, WeaponData.MAX_LEVEL]), data.evolved_name]
	return c(GOLD, "READY to evolve into %s - call Santa's Sleigh!" % data.evolved_name)


## Card content for a level-up card. Keys: tag, tag_color, name, level, body, hint.
static func upgrade_card(player: Player, upgrade: UpgradeData, rarity_name: String, rarity_mult: float) -> Dictionary:
	var level: int = player.upgrade_level(upgrade)
	var card: Dictionary = {"name": upgrade.title, "level": "Lv %d > %d" % [level, level + 1] if level > 0 else "Lv 1", "hint": ""}
	if upgrade.stat == UpgradeData.Stat.WEAPON:
		var data: WeaponData = weapon_data_named(upgrade.title)
		if level == 0:
			card["tag"] = "NEW WEAPON"
			card["tag_color"] = GOLD
			card["body"] = sentence(upgrade.new_description.get_slice(": ", 1)) if ": " in upgrade.new_description else upgrade.new_description
			card["body"] += "\n" + c(ICE, weapon_summary(data, 1, false, player))
		else:
			var w: Weapon = player.find_weapon(upgrade.weapon_scene)
			card["tag"] = "WEAPON UPGRADE"
			card["tag_color"] = ICE
			var lines: PackedStringArray = ["Damage " + change(num(data.damage_at(level, w.evolved, player.damage_mult)),
				num(data.damage_at(level + 1, w.evolved, player.damage_mult)))]
			var n0: int = data.count_at(level, w.evolved, player.extra_projectiles)
			var n1: int = data.count_at(level + 1, w.evolved, player.extra_projectiles)
			if n1 != n0:
				lines.append("%ss %s" % [data.count_noun.capitalize(), change(str(n0), str(n1))])
			card["body"] = "\n".join(lines)
		card["hint"] = evolution_progress(data, level + 1, false)
		return card
	var amount: float = upgrade.amount * (rarity_mult if upgrade.scales_with_rarity else 1.0)
	card["tag"] = (rarity_name + " " if rarity_name else "") + "STAT UPGRADE"
	card["tag_color"] = {"RARE": ICE, "EPIC": "C9A6EC"}.get(rarity_name, MUTED)
	var gift: Weapon = player.weapons()[0] if not player.weapons().is_empty() else null
	match upgrade.stat:
		UpgradeData.Stat.MOVE_SPEED:
			var speed: float = player.base_speed * (1.0 + player.move_speed_bonus)
			card["body"] = "Move speed " + change(num(speed) + " m/s", num(player.base_speed * (1.0 + player.move_speed_bonus + amount)) + " m/s")
		UpgradeData.Stat.MAX_HP:
			card["body"] = "Max HP " + change(str(roundi(player.max_hp)), str(roundi(player.max_hp + amount))) + "\nand heals %d HP" % roundi(amount)
		UpgradeData.Stat.PICKUP_RADIUS:
			card["body"] = "Pickup reach " + change(num(player.get_pickup_radius()) + " m", num(player.base_pickup_radius * (1.0 + player.pickup_bonus + amount)) + " m")
		UpgradeData.Stat.DAMAGE:
			card["body"] = "All weapon damage\n" + change("x" + "%.2f" % player.damage_mult, "x" + "%.2f" % (player.damage_mult + amount))
		UpgradeData.Stat.ATTACK_SPEED:
			card["body"] = "Attack speed " + change("+" + pct(player.attack_speed_bonus), "+" + pct(player.attack_speed_bonus + amount))
			if gift:
				card["body"] += "\n%s: every %s" % [gift.title(), change("%.2fs" % gift.cooldown(),
					"%.2fs" % gift.data.cooldown_at(gift.evolved, player.attack_speed_bonus + amount))]
		UpgradeData.Stat.PROJECTILES:
			card["body"] = "+%d projectile for every weapon" % int(amount)
			if gift:
				card["body"] += "\n%s: %s gifts" % [gift.title(), change(str(gift.count()), str(gift.count() + int(amount)))]
	return card


static func item_card(player: Player, item: ItemData) -> Dictionary:
	var owned: int = player.items.get(item, 0)
	return {"tag": "ITEM" + ("  (you have %d)" % owned if owned > 0 else ""), "tag_color": "E8C48E",
		"name": item.title, "level": "", "body": item.description, "hint": ""}


static func evolution_card(weapon: Weapon) -> Dictionary:
	return {"tag": "EVOLUTION", "tag_color": GOLD, "name": weapon.data.evolved_name,
		"level": "", "body": weapon.data.evolved_description, "hint": c(GOLD, "Replaces " + weapon.data.display_name)}


static func blessing_card(blessing: BlessingData) -> Dictionary:
	var lasts: String = "Instant" if blessing.effect == BlessingData.Effect.BLIZZARD 		else "Lasts %d s" % roundi(blessing.duration)
	return {"tag": "BLESSING", "tag_color": "9BE0A8", "name": blessing.title, "level": "",
		"body": blessing.description, "hint": c(MUTED, lasts)}


## Loadout-screen text for a weapon: what it does, its Lv 1 numbers and what it evolves into.
static func weapon_preview(card: UpgradeData, unlocked: bool, unlock_hint: String) -> String:
	var data: WeaponData = weapon_data_named(card.title)
	var text: String = "[b][font_size=32]%s[/font_size][/b]
%s
%s
%s" % [card.title,
		sentence(card.new_description.get_slice(": ", 1)), c(ICE, weapon_summary(data, 1, false, null)),
		c(GOLD, "Evolves at Lv 5 into %s: " % data.evolved_name) + data.evolved_description]
	if not unlocked:
		text += "
" + c(BAD, "LOCKED: " + unlock_hint)
	return text


## Pause-menu detail text for an owned weapon.
static func weapon_details(weapon: Weapon, player: Player) -> String:
	var head: String = "[b][font_size=26]%s[/font_size][/b]  %s" % [weapon.title(),
		c(GOLD, "EVOLVED") if weapon.evolved else c(MUTED, "Lv %d/%d" % [weapon.level, WeaponData.MAX_LEVEL])]
	return "%s
%s
%s" % [head, c(ICE, weapon_summary(weapon.data, weapon.level, weapon.evolved, player)),
		evolution_progress(weapon.data, weapon.level, weapon.evolved)]


## Pause-menu detail text for an owned item.
static func item_details(item: ItemData, player: Player) -> String:
	var count: int = player.items.get(item, 0)
	return "[b][font_size=26]%s[/font_size][/b]  %s
%s" % [item.title, c(MUTED, "x%d" % count), item.description]


## Pause-menu stat rows: {name, base, current, cmp (+1 better / 0 same / -1 worse), sources}.
static func stats(player: Player) -> Array[Dictionary]:
	var naughty: float = minf(GameState.kills * player.damage_per_kill, 0.6)
	var rows: Array[Dictionary] = [
		_row("Max HP", player.base_max_hp, player.max_hp, "%d", player, [UpgradeData.Stat.MAX_HP], [ItemData.Effect.MAX_HP]),
		_row("Move speed", player.base_speed, player.base_speed * (1.0 + player.move_speed_bonus), "%.1f m/s", player, [UpgradeData.Stat.MOVE_SPEED], []),
		_row("Damage", 1.0, player.damage_mult * (1.0 + naughty), "x%.2f", player, [UpgradeData.Stat.DAMAGE], [ItemData.Effect.DAMAGE, ItemData.Effect.DAMAGE_PER_KILL]),
		_row("Attack speed", 0.0, player.attack_speed_bonus * 100.0, "+%d%%", player, [UpgradeData.Stat.ATTACK_SPEED], [ItemData.Effect.ATTACK_SPEED]),
		_row("Extra projectiles", 0.0, player.extra_projectiles, "+%d", player, [UpgradeData.Stat.PROJECTILES], [ItemData.Effect.PROJECTILES]),
		_row("Pickup reach", player.base_pickup_radius, player.get_pickup_radius(), "%.1f m", player, [UpgradeData.Stat.PICKUP_RADIUS], []),
		_row("Elite & boss damage", 0.0, player.elite_damage_bonus * 100.0, "+%d%%", player, [], [ItemData.Effect.ELITE_DAMAGE]),
		_row("Poison chance", 0.0, player.poison_chance * 100.0, "%d%%", player, [], [ItemData.Effect.POISON_CHANCE]),
		_row("Explode chance", 0.0, player.explode_chance * 100.0, "%d%%", player, [], [ItemData.Effect.EXPLODE_CHANCE]),
		_row("Freeze chance", 0.0, player.freeze_chance * 100.0, "%d%%", player, [], [ItemData.Effect.FREEZE_CHANCE]),
		_row("Extra lives", 0.0, player.cheat_deaths, "%d", player, [], [ItemData.Effect.CHEAT_DEATH]),
	]
	return rows


static func _row(label: String, base: float, current: float, fmt: String, player: Player,
		stats_from: Array, effects_from: Array) -> Dictionary:
	var sources: PackedStringArray = []
	for upgrade: UpgradeData in player.upgrade_levels:
		if upgrade.stat in stats_from:
			sources.append("%s x%d" % [upgrade.title, player.upgrade_levels[upgrade]])
	for item: ItemData in player.items:
		if item.effect in effects_from:
			sources.append("%s x%d" % [item.title, player.items[item]])
	var cmp: int = 0 if is_equal_approx(current, base) else (1 if current > base else -1)
	return {"name": label, "base": fmt % base, "current": fmt % current, "cmp": cmp, "sources": ", ".join(sources)}
