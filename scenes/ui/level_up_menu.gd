extends CanvasLayer
## Pauses the game and offers 3 choices: level-up cards (upgrades/weapons that aren't maxed, each
## rolling a rarity) or, for a gift chest, items, plus an evolution when one is ready.
## Level-ups are offered before chests; the menu stays open until nothing is pending.

## "color" tints the card border; "text" the card text (palette colors, readable on navy).
const RARITIES: Array[Dictionary] = [
	{"name": "", "mult": 1.0, "weight": 75.0, "color": Color("8FA9D1"), "text": Color("F4F8FF")},
	{"name": "RARE", "mult": 1.5, "weight": 20.0, "color": Color("7FD6F2"), "text": Color("7FD6F2")},
	{"name": "EPIC", "mult": 2.0, "weight": 5.0, "color": Color("9B4FD1"), "text": Color("F4F8FF")},
]
const EVOLUTION_COLOR: Color = Color("F2B53B")
const ICON_DIR: String = "res://assets/ui/icons/"

@export var upgrades: Array[UpgradeData] = []
@export var items: Array[ItemData] = []

## Each choice: {"text", "color" (border), "text_color", "icon": Texture2D, "apply": Callable}
var _choices: Array[Dictionary] = []
var _is_chest: bool = false

@onready var buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
@onready var title: Label = $Center/VBox/Title


func _ready() -> void:
	hide()
	GameState.leveled_up.connect(func(_level: int) -> void: _open_next())
	GameState.chest_found.connect(_open_next)
	for i in buttons.size():
		buttons[i].pressed.connect(_on_choice.bind(i))


func _open_next() -> void:
	if visible:
		return
	_choices = []
	while GameState.pending_level_ups > 0 or GameState.pending_chests > 0:
		_is_chest = GameState.pending_level_ups == 0
		_choices = _chest_choices() if _is_chest else _level_up_choices()
		if not _choices.is_empty():
			break
		_consume()  # nothing left to offer for this one
	if _choices.is_empty():
		return
	title.text = "Gift chest! Pick one" if _is_chest else "Level up! Pick one"
	for i in buttons.size():
		buttons[i].visible = i < _choices.size()
		if not buttons[i].visible:
			continue
		var choice: Dictionary = _choices[i]
		buttons[i].text = choice["text"]
		buttons[i].icon = choice["icon"]
		buttons[i].add_theme_color_override(&"font_color", choice["text_color"])
		var style: StyleBoxFlat = ThemeDB.get_project_theme().get_stylebox(&"normal", &"Button").duplicate()
		style.border_color = choice["color"]
		buttons[i].add_theme_stylebox_override(&"normal", style)
	Audio.play(&"chest" if _is_chest else &"levelup")
	show()
	get_tree().paused = true
	buttons[0].grab_focus()


func _level_up_choices() -> Array[Dictionary]:
	var player: Player = GameState.player
	var pool: Array[UpgradeData] = upgrades.filter(
		func(u: UpgradeData) -> bool: return player.upgrade_level(u) < u.max_level
	)
	pool.shuffle()
	var out: Array[Dictionary] = []
	for upgrade in pool.slice(0, buttons.size()):
		var level: int = player.upgrade_level(upgrade)
		if upgrade.stat == UpgradeData.Stat.WEAPON:
			var text: String = upgrade.new_description if level == 0 else upgrade.describe(1.0)
			var header: String = "NEW WEAPON" if level == 0 else "%s  (Lv %d)" % [upgrade.title, level + 1]
			out.append({"text": header + "\n" + text, "color": EVOLUTION_COLOR if level == 0 else Color("8FA9D1"),
				"text_color": Color("F4F8FF"), "icon": _icon(upgrade),
				"apply": player.apply_upgrade.bind(upgrade, 1.0)})
			continue
		var rarity: Dictionary = _roll_rarity() if upgrade.scales_with_rarity else RARITIES[0]
		var name_line: String = ((rarity["name"] + "  ") if rarity["name"] else "") + upgrade.title
		out.append({"text": "%s  (Lv %d)\n%s" % [name_line, level + 1, upgrade.describe(rarity["mult"])],
			"color": rarity["color"], "text_color": rarity["text"], "icon": _icon(upgrade),
			"apply": player.apply_upgrade.bind(upgrade, rarity["mult"])})
	return out


func _chest_choices() -> Array[Dictionary]:
	var player: Player = GameState.player
	var out: Array[Dictionary] = []
	var evolvable: Array[Weapon] = player.evolvable_weapons()
	if not evolvable.is_empty():
		var weapon: Weapon = evolvable[0]
		out.append({"text": "EVOLUTION: %s\n%s" % [weapon.data.evolved_name, weapon.data.evolved_description],
			"color": EVOLUTION_COLOR, "text_color": EVOLUTION_COLOR, "icon": load(ICON_DIR + "evolution.png"),
			"apply": func() -> void: weapon.evolved = true})
	var pool: Array[ItemData] = items.filter(
		func(item: ItemData) -> bool: return not (item.unique and player.items.has(item))
	)
	pool.shuffle()
	for item in pool.slice(0, buttons.size() - out.size()):
		var owned: int = player.items.get(item, 0)
		var header: String = item.title + ("  (x%d)" % (owned + 1) if owned > 0 else "")
		out.append({"text": header + "\n" + item.description, "color": item.color,
			"text_color": item.color, "icon": _icon(item), "apply": player.add_item.bind(item)})
	return out


## Icon named like the resource file (art_src/tools/make_icons.py).
func _icon(res: Resource) -> Texture2D:
	var path: String = ICON_DIR + res.resource_path.get_file().get_basename() + ".png"
	return load(path) if ResourceLoader.exists(path) else null


func _roll_rarity() -> Dictionary:
	var roll: float = randf() * 100.0
	for rarity in RARITIES:
		roll -= rarity["weight"]
		if roll <= 0.0:
			return rarity
	return RARITIES[0]


func _consume() -> void:
	if _is_chest:
		GameState.pending_chests -= 1
	else:
		GameState.pending_level_ups -= 1


func _on_choice(index: int) -> void:
	Audio.play(&"click")
	_choices[index]["apply"].call()
	_consume()
	hide()
	get_tree().paused = false
	_open_next()
