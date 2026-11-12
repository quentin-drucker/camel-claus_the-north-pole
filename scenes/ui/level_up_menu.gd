extends CanvasLayer
## Pauses the game and offers up to 3 choices for each pending reward, in this order:
## - Santa's present: an evolution for each Lv 5 weapon, or (none ready) 3 timed blessings.
## - Level-up: upgrade cards (stats, or weapons from this run's loadout) that aren't maxed or banished,
##   each rolling a rarity. Weapon cards weigh more so a focused build can reach Lv 5. Reroll (R) and
##   Banish (B) work here only.
## - Gift chest (elites, boss): items.
## The menu stays open until nothing is pending. Card text comes from Describe (real game numbers).

enum Kind { SANTA, LEVEL_UP, CHEST }

## "color" tints the card border for stat upgrades.
const RARITIES: Array[Dictionary] = [
	{"name": "", "mult": 1.0, "weight": 75.0, "color": Color("8FA9D1")},
	{"name": "RARE", "mult": 1.5, "weight": 20.0, "color": Color("7FD6F2")},
	{"name": "EPIC", "mult": 2.0, "weight": 5.0, "color": Color("9B4FD1")},
]
const BORDER: Dictionary = {
	"NEW WEAPON": Color("F2B53B"), "WEAPON UPGRADE": Color("7FD6F2"), "EVOLUTION": Color("F2B53B"),
	"BLESSING": Color("3E9A5B"),
}
const ITEM_BORDER: Color = Color("E8C48E")
const CARD_MARGIN: int = 14
const ICON_SIZE: int = 56
const HEADER_GAP: int = 10
const DIM: Dictionary = {
	Kind.SANTA: Color(0.357, 0.227, 0.165, 0.75),  # warm wood-brown: Santa's screen feels special
	Kind.LEVEL_UP: Color(0.133, 0.188, 0.31, 0.6),
	Kind.CHEST: Color(0.133, 0.188, 0.31, 0.6),
}
const BLESSINGS: Array[BlessingData] = [
	preload("res://resources/blessings/hot_cocoa.tres"),
	preload("res://resources/blessings/reindeer_rush.tres"),
	preload("res://resources/blessings/christmas_spirit.tres"),
	preload("res://resources/blessings/mega_magnet.tres"),
	preload("res://resources/blessings/snow_angel.tres"),
	preload("res://resources/blessings/blizzard.tres"),
]

@export var upgrades: Array[UpgradeData] = []
@export var items: Array[ItemData] = []
## Pick weight of a weapon card (stat cards weigh 1).
@export var weapon_card_weight: float = 1.2

## Each choice: {"card": Dictionary from Describe, "icon": Texture2D, "border": Color, "apply": Callable,
## "upgrade": UpgradeData (level-up cards, for Banish)}
var _choices: Array[Dictionary] = []
var _kind: Kind = Kind.LEVEL_UP
var _parts: Array[Dictionary] = []  # per button: the Controls inside the card

@onready var buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
@onready var title: Label = $Center/VBox/Title
@onready var dim: ColorRect = $Dim
@onready var tools: Control = $Center/VBox/Tools
@onready var reroll_button: Button = %RerollButton
@onready var banish_button: Button = %BanishButton


func _ready() -> void:
	hide()
	GameState.leveled_up.connect(func(_level: int) -> void: _open_next())
	GameState.chest_found.connect(_open_next)
	GameState.santa_present_found.connect(_open_next)
	for i in buttons.size():
		buttons[i].pressed.connect(_on_choice.bind(i))
		_parts.append(_build_card(buttons[i]))
		var button: Button = buttons[i]
		button.focus_entered.connect(func() -> void: _pop(button, 1.04))
		button.focus_exited.connect(func() -> void: _pop(button, 1.0))
		button.mouse_entered.connect(button.grab_focus)
	for tool_button: Button in [reroll_button, banish_button]:
		tool_button.add_theme_constant_override(&"icon_max_width", 28)
	reroll_button.pressed.connect(_reroll)
	banish_button.toggled.connect(func(_on: bool) -> void: _refresh_tools())


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _kind != Kind.LEVEL_UP:
		return
	if event.is_action_pressed("reroll"):
		_reroll()
	elif event.is_action_pressed("banish") and GameState.banishes > 0:
		banish_button.button_pressed = not banish_button.button_pressed
	else:
		return
	get_viewport().set_input_as_handled()


func _open_next() -> void:
	if visible:
		return
	_choices = []
	while GameState.pending_santa > 0 or GameState.pending_level_ups > 0 or GameState.pending_chests > 0:
		if GameState.pending_santa > 0:
			_kind = Kind.SANTA
		elif GameState.pending_level_ups > 0:
			_kind = Kind.LEVEL_UP
		else:
			_kind = Kind.CHEST
		_choices = _choices_for(_kind)
		if not _choices.is_empty():
			break
		if _kind == Kind.LEVEL_UP:  # everything maxed (long Endless runs): no menu, a token heal
			GameState.player.heal(GameState.player.max_hp * 0.02)
		_consume()  # nothing left to offer for this one
	if _choices.is_empty():
		return
	banish_button.button_pressed = false
	_show_choices()
	match _kind:
		Kind.SANTA:
			var evolving: bool = _choices[0]["card"]["tag"] == "EVOLUTION"
			title.text = "Santa's present!  " + ("Evolve a weapon" if evolving else "Pick a blessing")
			Audio.play(&"evolve" if evolving else &"chest")
		Kind.LEVEL_UP:
			title.text = "Level up! Pick one"
			Audio.play(&"levelup")
		Kind.CHEST:
			title.text = "Gift chest! Pick one"
			Audio.play(&"chest")
	dim.color = DIM[_kind]
	show()
	get_tree().paused = true
	buttons[0].grab_focus()


func _choices_for(kind: Kind) -> Array[Dictionary]:
	match kind:
		Kind.SANTA:
			return _santa_choices()
		Kind.LEVEL_UP:
			return _level_up_choices()
	return _chest_choices()


func _show_choices() -> void:
	for i in buttons.size():
		buttons[i].visible = i < _choices.size()
		if buttons[i].visible:
			_fill_card(i, _choices[i])
	_refresh_tools()


## Cards this run can offer at a level-up: not maxed, not banished; weapons only from the loadout and
## only while Claus has a free hand.
func level_up_pool() -> Array[UpgradeData]:
	var player: Player = GameState.player
	var full_hands: bool = player.weapons().size() >= Player.MAX_WEAPONS
	var pool: Array[UpgradeData] = []
	for u in upgrades:
		var lvl: int = player.upgrade_level(u)
		if lvl >= u.max_level or u in GameState.banished:
			continue
		if u.stat == UpgradeData.Stat.WEAPON and lvl == 0 \
				and (full_hands or Profile.weapon_id(u) not in GameState.loadout):
			continue
		pool.append(u)
	return pool


func _level_up_choices() -> Array[Dictionary]:
	var player: Player = GameState.player
	var pool: Array[UpgradeData] = level_up_pool()
	var out: Array[Dictionary] = []
	while out.size() < buttons.size() and not pool.is_empty():
		var upgrade: UpgradeData = _take_weighted(pool)
		var rarity: Dictionary = _roll_rarity() if upgrade.scales_with_rarity else RARITIES[0]
		var card: Dictionary = Describe.upgrade_card(player, upgrade, rarity["name"], rarity["mult"])
		out.append({"card": card, "icon": Describe.icon_for(upgrade), "upgrade": upgrade,
			"border": BORDER.get(card["tag"], rarity["color"]),
			"apply": player.apply_upgrade.bind(upgrade, rarity["mult"])})
	return out


## Remove and return one card, weapon cards weighing `weapon_card_weight`.
func _take_weighted(pool: Array[UpgradeData]) -> UpgradeData:
	var total: float = 0.0
	for u in pool:
		total += _weight(u)
	var roll: float = randf() * total
	for i in pool.size():
		roll -= _weight(pool[i])
		if roll <= 0.0:
			return pool.pop_at(i)
	return pool.pop_back()


func _weight(upgrade: UpgradeData) -> float:
	return weapon_card_weight if upgrade.stat == UpgradeData.Stat.WEAPON else 1.0


func _chest_choices() -> Array[Dictionary]:
	var player: Player = GameState.player
	var out: Array[Dictionary] = []
	var pool: Array[ItemData] = items.filter(
		func(item: ItemData) -> bool: return not (item.unique and player.items.has(item))
	)
	pool.shuffle()
	for item in pool.slice(0, buttons.size()):
		out.append({"card": Describe.item_card(player, item), "icon": Describe.icon_for(item),
			"border": ITEM_BORDER, "apply": player.add_item.bind(item)})
	return out


## Every Lv 5 weapon can evolve (up to 3 cards); with none ready, 3 random blessings instead.
func _santa_choices() -> Array[Dictionary]:
	var player: Player = GameState.player
	var out: Array[Dictionary] = []
	for weapon in player.evolvable_weapons().slice(0, buttons.size()):
		out.append({"card": Describe.evolution_card(weapon), "icon": Describe.evolved_icon(weapon),
			"border": BORDER["EVOLUTION"], "apply": GameState.evolve_weapon.bind(weapon)})
	if not out.is_empty():
		return out
	var pool: Array[BlessingData] = BLESSINGS.duplicate()
	pool.shuffle()
	for blessing in pool.slice(0, buttons.size()):
		out.append({"card": Describe.blessing_card(blessing), "icon": Describe.icon_for(blessing),
			"border": BORDER["BLESSING"], "apply": player.bless.bind(blessing)})
	return out


func _reroll() -> void:
	if _kind != Kind.LEVEL_UP or GameState.rerolls <= 0:
		return
	GameState.rerolls -= 1
	Audio.play(&"click")
	banish_button.button_pressed = false
	_choices = _level_up_choices()
	if _choices.is_empty():
		_close_one()
		return
	_show_choices()
	buttons[0].grab_focus()


func _refresh_tools() -> void:
	tools.visible = _kind == Kind.LEVEL_UP
	reroll_button.text = "Reroll (%d)  [R]" % GameState.rerolls
	reroll_button.disabled = GameState.rerolls <= 0
	banish_button.disabled = GameState.banishes <= 0
	var banishing: bool = banish_button.button_pressed and GameState.banishes > 0
	banish_button.text = "Pick a card to banish" if banishing else "Banish (%d)  [B]" % GameState.banishes
	for i in buttons.size():
		if buttons[i].visible:
			buttons[i].modulate = Color("FF9AA0") if banishing else Color.WHITE


## Card layout: [icon | tag / name | level] header, effect text, evolution hint.
func _build_card(button: Button) -> Dictionary:
	button.text = ""
	button.icon = null
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, CARD_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", HEADER_GAP)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	header.add_child(icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override(&"separation", -8)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(names)
	# Tag and level share the small top row so the name gets the full width below them.
	var tag_row := HBoxContainer.new()
	names.add_child(tag_row)
	var tag := Label.new()
	tag.add_theme_font_size_override(&"font_size", 32)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_row.add_child(tag)
	var level := Label.new()
	level.add_theme_font_size_override(&"font_size", 32)
	level.add_theme_color_override(&"font_color", Color("8FA9D1"))
	tag_row.add_child(level)
	var name_label := Label.new()
	name_label.clip_text = true  # last resort; _fill_card shrinks long names first
	names.add_child(name_label)
	var body := _rich(32)
	column.add_child(body)
	var hint := _rich(32)
	hint.add_theme_color_override(&"default_color", Color("8FA9D1"))
	column.add_child(hint)
	for node: Control in [icon, names, tag_row, tag, name_label, level]:
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
	var name_label: Label = parts["name"]
	name_label.text = card["name"]
	# Pixel font stays crisp at multiples of 16: drop from 48 to 32 when a name is too long.
	# Measured from the card's fixed width: the layout isn't sorted yet while the menu is hidden.
	var room: float = buttons[i].custom_minimum_size.x - CARD_MARGIN * 2 - ICON_SIZE - HEADER_GAP
	var fits: bool = name_label.get_theme_font(&"font").get_string_size(card["name"], HORIZONTAL_ALIGNMENT_LEFT,
		-1, 48).x <= room
	name_label.add_theme_font_size_override(&"font_size", 48 if fits else 32)
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
	match _kind:
		Kind.SANTA:
			GameState.pending_santa -= 1
		Kind.LEVEL_UP:
			GameState.pending_level_ups -= 1
		Kind.CHEST:
			GameState.pending_chests -= 1


func _on_choice(index: int) -> void:
	Audio.play(&"click")
	if _kind == Kind.LEVEL_UP and banish_button.button_pressed and GameState.banishes > 0:
		# Banish: that card leaves this run's pool; the level-up stays open with fresh cards.
		GameState.banishes -= 1
		GameState.banished.append(_choices[index]["upgrade"])
		banish_button.button_pressed = false
		_choices = _level_up_choices()
		if not _choices.is_empty():
			_show_choices()
			buttons[0].grab_focus()
			return
	else:
		_choices[index]["apply"].call()
	_close_one()


func _close_one() -> void:
	_consume()
	hide()
	get_tree().paused = false
	_open_next()
