extends CanvasLayer
## Pauses the game and offers 3 choices: level-up cards (upgrades/weapons that aren't maxed, each
## rolling a rarity) or, for a gift chest, items, plus an evolution when one is ready.
## Level-ups are offered before chests; the menu stays open until nothing is pending.
## Card text comes from Describe (real game numbers); this script only lays it out.

## "color" tints the card border for stat upgrades.
const RARITIES: Array[Dictionary] = [
	{"name": "", "mult": 1.0, "weight": 75.0, "color": Color("8FA9D1")},
	{"name": "RARE", "mult": 1.5, "weight": 20.0, "color": Color("7FD6F2")},
	{"name": "EPIC", "mult": 2.0, "weight": 5.0, "color": Color("9B4FD1")},
]
const BORDER: Dictionary = {
	"NEW WEAPON": Color("F2B53B"), "WEAPON UPGRADE": Color("7FD6F2"), "EVOLUTION": Color("F2B53B"),
}
const ITEM_BORDER: Color = Color("E8C48E")

@export var upgrades: Array[UpgradeData] = []
@export var items: Array[ItemData] = []

## Each choice: {"card": Dictionary from Describe, "icon": Texture2D, "border": Color, "apply": Callable}
var _choices: Array[Dictionary] = []
var _is_chest: bool = false
var _parts: Array[Dictionary] = []  # per button: the Controls inside the card

@onready var buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
@onready var title: Label = $Center/VBox/Title


func _ready() -> void:
	hide()
	GameState.leveled_up.connect(func(_level: int) -> void: _open_next())
	GameState.chest_found.connect(_open_next)
	for i in buttons.size():
		buttons[i].pressed.connect(_on_choice.bind(i))
		_parts.append(_build_card(buttons[i]))
		var button: Button = buttons[i]
		button.focus_entered.connect(func() -> void: _pop(button, 1.04))
		button.focus_exited.connect(func() -> void: _pop(button, 1.0))
		button.mouse_entered.connect(button.grab_focus)


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
		if buttons[i].visible:
			_fill_card(i, _choices[i])
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
		var rarity: Dictionary = _roll_rarity() if upgrade.scales_with_rarity else RARITIES[0]
		var card: Dictionary = Describe.upgrade_card(player, upgrade, rarity["name"], rarity["mult"])
		out.append({"card": card, "icon": Describe.icon_for(upgrade),
			"border": BORDER.get(card["tag"], rarity["color"]),
			"apply": player.apply_upgrade.bind(upgrade, rarity["mult"])})
	return out


func _chest_choices() -> Array[Dictionary]:
	var player: Player = GameState.player
	var out: Array[Dictionary] = []
	var evolvable: Array[Weapon] = player.evolvable_weapons()
	if not evolvable.is_empty():
		var weapon: Weapon = evolvable[0]
		var evo_icon: Texture2D = Describe.icon("weapon_" + weapon.scene_file_path.get_file().get_basename() + "_evo")
		out.append({"card": Describe.evolution_card(weapon), "icon": evo_icon, "border": BORDER["EVOLUTION"],
			"apply": func() -> void:
				weapon.evolve()
				GameState.weapon_evolved.emit(weapon)})
	var pool: Array[ItemData] = items.filter(
		func(item: ItemData) -> bool: return not (item.unique and player.items.has(item))
	)
	pool.shuffle()
	for item in pool.slice(0, buttons.size() - out.size()):
		out.append({"card": Describe.item_card(player, item), "icon": Describe.icon_for(item),
			"border": ITEM_BORDER, "apply": player.add_item.bind(item)})
	return out


## Card layout: [icon | tag / name | level] header, effect text, evolution hint.
func _build_card(button: Button) -> Dictionary:
	button.text = ""
	button.icon = null
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 10)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	header.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override(&"separation", -8)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(names)
	var tag := Label.new()
	tag.add_theme_font_size_override(&"font_size", 32)
	names.add_child(tag)
	var name_label := Label.new()
	name_label.clip_text = true
	names.add_child(name_label)
	var level := Label.new()
	level.add_theme_font_size_override(&"font_size", 32)
	level.add_theme_color_override(&"font_color", Color("8FA9D1"))
	level.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(level)
	var body := _rich(32)
	column.add_child(body)
	var hint := _rich(32)
	hint.add_theme_color_override(&"default_color", Color("8FA9D1"))
	column.add_child(hint)
	for node: Control in [icon, names, tag, name_label, level]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return {"icon": icon, "tag": tag, "name": name_label, "level": level, "body": body, "hint": hint}


func _rich(size: int) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich.add_theme_font_size_override(&"normal_font_size", size)
	return rich


func _fill_card(i: int, choice: Dictionary) -> void:
	var card: Dictionary = choice["card"]
	var parts: Dictionary = _parts[i]
	parts["icon"].texture = choice["icon"]
	parts["tag"].text = card["tag"]
	parts["tag"].add_theme_color_override(&"font_color", Color(card["tag_color"]))
	parts["name"].text = card["name"]
	parts["level"].text = card["level"]
	parts["body"].text = card["body"]
	parts["hint"].text = card["hint"]
	parts["hint"].visible = card["hint"] != ""
	var style: StyleBoxFlat = ThemeDB.get_project_theme().get_stylebox(&"normal", &"Button").duplicate()
	style.border_color = choice["border"]
	if card["tag"] == "EVOLUTION":
		style.bg_color = Color("5B3A2A")  # warm wood-brown glow behind the evolution card
		style.set_border_width_all(5)
	buttons[i].add_theme_stylebox_override(&"normal", style)


func _pop(button: Button, to_scale: float) -> void:
	button.pivot_offset = button.size / 2.0
	create_tween().tween_property(button, "scale", Vector2.ONE * to_scale, 0.08)


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
