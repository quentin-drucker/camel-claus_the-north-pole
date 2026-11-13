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
const ICON_SIZE: int = 52
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

## Seconds the panel stays up after a pick while the postmark stamps the row (windowed runs only).
const PICK_HOLD: float = 0.35
const RAYS_SPEED: float = TAU / 50.0  # one slow turn every 50 s

var _holding: bool = false

@onready var buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
@onready var title: Label = %Title
@onready var level_tag: Control = %LevelTag
@onready var level_label: Label = %LevelLabel
@onready var rays: Control = %Rays
@onready var dim: ColorRect = $Dim
@onready var tools: Control = %Tools
@onready var reroll_button: Button = %RerollButton
@onready var banish_button: Button = %BanishButton

var _reroll_count: Label
var _banish_count: Label


func _ready() -> void:
	hide()
	GameState.leveled_up.connect(func(_level: int) -> void: _open_next())
	GameState.chest_found.connect(_open_next)
	GameState.santa_present_found.connect(_open_next)
	for i in buttons.size():
		buttons[i].pressed.connect(_on_choice.bind(i))
		_parts.append(_build_card(buttons[i]))
		buttons[i].mouse_entered.connect(buttons[i].grab_focus)  # hover = focus, so the brackets agree
	reroll_button.pressed.connect(_reroll)
	_reroll_count = _dress_tool(reroll_button, "R")
	_banish_count = _dress_tool(banish_button, "B")
	for i in buttons.size():  # 1-3 pick a card (the keycap sits in the row's corner)
		var key := Tin.keycap(str(i + 1))
		buttons[i].add_child(key)
		key.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE)
		key.position -= Vector2(14, 16)  # inside the row's frame, above its lip
	rays.set_meta(&"decor", true)  # decoration larger than the screen on purpose (tests skip its bounds)
	banish_button.toggled.connect(func(_on: bool) -> void: _refresh_tools())


func _process(delta: float) -> void:
	if visible:
		rays.rotation += RAYS_SPEED * delta


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode >= KEY_1 and key.keycode <= KEY_3:
		var i: int = key.keycode - KEY_1
		if i < _choices.size() and buttons[i].visible:
			buttons[i].grab_focus()
			_on_choice(i)
			get_viewport().set_input_as_handled()
		return
	if _kind != Kind.LEVEL_UP:
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
	level_tag.visible = _kind == Kind.LEVEL_UP
	var from_level: int = GameState.level - GameState.pending_level_ups
	level_label.text = "Lv %d → %d" % [from_level, from_level + 1]
	match _kind:
		Kind.SANTA:
			var evolving: bool = _choices[0]["card"]["tag"] == "EVOLUTION"
			title.text = "Santa's present!  " + ("Evolve a weapon" if evolving else "Pick a blessing")
			Audio.play(&"evolve" if evolving else &"chest")
		Kind.LEVEL_UP:
			title.text = "Level up!"
			Audio.play(&"levelup")
		Kind.CHEST:
			title.text = "Gift chest!"
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
	_reroll_count.text = str(GameState.rerolls)
	reroll_button.disabled = GameState.rerolls <= 0
	banish_button.disabled = GameState.banishes <= 0
	var banishing: bool = banish_button.button_pressed and GameState.banishes > 0
	banish_button.get_meta(&"label").text = "Cancel" if banishing else "Banish"
	_banish_count.text = str(GameState.banishes)
	%Help.text = "Pick a card to banish it for this run. B cancels." if banishing 		else "Click, press 1-3, or use arrows and Enter."
	for i in buttons.size():
		if buttons[i].visible:
			buttons[i].modulate = Color("FF9AA0") if banishing else Color.WHITE


## Megabonk-style row (style guide 4.4): [rarity tile | name / effect / hint | level], with the rarity tag
## breaking the row's top border. The row plate itself (fill, knit, line) comes from Row<Rarity>.
func _build_card(button: Button) -> Dictionary:
	button.text = ""
	button.icon = null
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, CARD_MARGIN)
	margin.add_theme_constant_override(&"margin_left", 18)
	# 12 px top/bottom: the longest weapon cards (3 text lines) then fit the 116 px row exactly.
	margin.add_theme_constant_override(&"margin_top", 12)
	margin.add_theme_constant_override(&"margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var tile := Tin.tile(null, "common", ICON_SIZE)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 2)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var name_label := Tin.label("", &"HeaderLabel")
	name_label.clip_text = true  # last resort; names are short
	column.add_child(name_label)
	var body := _rich(&"RichTextLabel")
	column.add_child(body)
	var hint := _rich(&"SmallRich")
	column.add_child(hint)
	var level := Tin.label("", &"GoldLabel")
	level.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(level)
	var tag := Tin.label("", &"TagCommon")
	tag.position = Vector2(14, -14)
	tag.set_meta(&"decor", true)  # breaks the row's top border on purpose (style guide 4.4)
	button.add_child(tag)
	return {"tile": tile, "icon": tile.get_child(0), "tag": tag, "name": name_label, "level": level,
		"body": body, "hint": hint}


## Reroll / Banish as in the prototype: icon, name and a keycap inside the slab, the uses left above it.
func _dress_tool(button: Button, key: String) -> Label:
	var text: String = button.text.get_slice(" (", 0)
	button.text = ""
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = button.icon
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	button.icon = null
	var label := Tin.label(text, &"HeaderLabel")
	row.add_child(label)
	row.add_child(Tin.keycap(key))
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -6  # the slab's lip
	button.set_meta(&"label", label)
	button.custom_minimum_size = Vector2(230, 56)
	# The uses left sit above the button (wrap it in a column, keeping its place in the row).
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	var parent: Node = button.get_parent()
	var index: int = button.get_index()
	parent.remove_child(button)
	parent.add_child(column)
	parent.move_child(column, index)
	var count := Tin.label("", &"HudSmall")
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count)
	column.add_child(button)
	return count


func _rich(variation: StringName) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich.theme_type_variation = variation
	return rich


func _fill_card(i: int, choice: Dictionary) -> void:
	var card: Dictionary = choice["card"]
	var parts: Dictionary = _parts[i]
	var rarity: String = Tin.rarity_of(card["tag"])
	buttons[i].theme_type_variation = StringName("Row" + rarity.capitalize())
	parts["tile"].theme_type_variation = StringName("Tile" + rarity.capitalize())
	parts["icon"].texture = choice["icon"]
	# Level-up cards wear their rarity (Common / Rare / Epic); chests, evolutions and blessings their kind.
	parts["tag"].text = rarity.capitalize() if _kind == Kind.LEVEL_UP else Tin.sentence(card["tag"])
	parts["tag"].theme_type_variation = StringName("Tag" + rarity.capitalize())
	parts["tag"].reset_size()  # shrink to the new text so the tag hugs it on the border
	parts["name"].text = card["name"]
	parts["level"].text = card["level"]
	parts["body"].text = card["body"]
	parts["hint"].text = card["hint"]
	parts["hint"].visible = card["hint"] != ""


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
		if _holding:
			return
		_choices[index]["apply"].call()
		# The pick is applied at once (tests and the balance bot rely on that); on screen, a postmark
		# stamps the chosen row and the panel holds a moment before closing.
		if DisplayServer.get_name() != "headless":
			_holding = true
			var row: Button = buttons[index]
			Tin.stamp_onto(row, Vector2(row.size.x - 190.0, row.size.y / 2.0))
			await get_tree().create_timer(PICK_HOLD, true, false, true).timeout
			_holding = false
			for mark in row.get_children():
				if mark is TextureRect and mark.texture == Tin.POSTMARK:
					mark.queue_free()
	_close_one()


func _close_one() -> void:
	_consume()
	hide()
	get_tree().paused = false
	_open_next()
