extends PanelContainer
## Pre-run loadout (main menu > Play): pick up to 3 unlocked weapons for the run and mark one as the
## starter. Claus starts with the starter; the others only show up as "new weapon" cards at
## level-ups, so the run's weapon pool stays small enough to reach Lv 5 and evolve.
## Laid out as two numbered steps so first-time players know what to do: (1) pack up to 3 weapons
## (cards wear a Starter / Packed / Locked tag on their border), (2) pick the starting weapon from the
## packed slots. A plain sentence above Start run says what will happen. Saved in Profile, so the last
## loadout is ready next time.

signal closed
signal started

const CARD_SIZE: Vector2 = Vector2(168, 128)  # 6 weapons in one row
const SLOT_SIZE: Vector2 = Vector2(250, 68)

var _picked: Array[String] = []
var _starter: String = ""
var _cards: Dictionary = {}  # weapon id -> Button
var _slots: Array[Button] = []

var _tags: Dictionary = {}  # weapon id -> tag Label on the card's top border
var _slot_notes: Array[Label] = []
var _count: Label
var _summary: Label
var _details: RichTextLabel
var _start_button: Button


func _ready() -> void:
	theme_type_variation = &"PlateTight"  # header band + close X like every other panel (style guide 4.1)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", 0)
	add_child(outer)
	outer.add_child(Tin.header("Pick your loadout", null, close))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	outer.add_child(Tin.body(column, 16))
	_count = Tin.label("", &"GoldLabel")
	column.add_child(_step("1", "Pack up to 3 weapons", "Click a weapon to pack it or take it out.", _count))

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override(&"separation", 10)
	column.add_child(grid)
	for card in Profile.WEAPON_CARDS:
		var id: String = Profile.weapon_id(card)
		var button := _icon_button(Describe.icon_for(card), card.title, CARD_SIZE)
		var tag := Tin.label("", &"TagCommon")
		tag.position = Vector2(12, -12)
		tag.set_meta(&"decor", true)  # breaks the card's top border on purpose, like the level-up tags
		button.add_child(tag)
		_tags[id] = tag
		button.pressed.connect(_toggle.bind(id))
		button.focus_entered.connect(_show_details.bind(card))
		button.mouse_entered.connect(button.grab_focus)
		grid.add_child(button)
		_cards[id] = button

	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.custom_minimum_size = Vector2(0, 104)
	_details.scroll_active = false
	column.add_child(_details)

	column.add_child(_step("2", "Choose your starting weapon",
		"Claus starts holding it. The others show up as new-weapon cards when you level up."))
	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override(&"separation", 14)
	column.add_child(slot_row)
	for i in Profile.LOADOUT_SIZE:
		var slot_box := VBoxContainer.new()
		slot_box.add_theme_constant_override(&"separation", 2)
		slot_row.add_child(slot_box)
		var slot := _icon_button(null, "", SLOT_SIZE)
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT  # icon left, name right
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_constant_override(&"icon_max_width", 44)
		slot.pressed.connect(_make_starter.bind(i))
		slot.mouse_entered.connect(slot.grab_focus)
		slot_box.add_child(slot)
		_slots.append(slot)
		var note := Tin.label("", &"SmallLabel")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_box.add_child(note)
		_slot_notes.append(note)
	_summary = Tin.label("", &"Label", true)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 14)
	column.add_child(buttons)
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_child(_summary)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(150, 0)
	back.pressed.connect(close)
	buttons.add_child(back)
	_start_button = Button.new()
	_start_button.text = "Start run"
	_start_button.theme_type_variation = &"PrimaryButton"
	_start_button.custom_minimum_size = Vector2(220, 0)
	_start_button.pressed.connect(_start)
	buttons.add_child(_start_button)

	visibility_changed.connect(func() -> void:
		if visible:
			_picked = Profile.loadout()
			_starter = Profile.starter()
			_refresh()
			_show_details(Profile.weapon_card(_starter))
			_start_button.grab_focus())


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Step heading: a gold number, a title, one line of help, and an optional note on the right.
func _step(number: String, title: String, help: String, right: Control = null) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	box.add_child(row)
	row.add_child(Tin.label(number + ".", &"GoalTitle"))
	var t := Tin.label(title, &"NameLabel")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if right:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(right)
	box.add_child(Tin.label(help, &"MutedLabel"))
	return box


func _icon_button(icon: Texture2D, text: String, size: Vector2) -> Button:
	var button := Button.new()
	button.custom_minimum_size = size
	button.icon = icon
	button.text = text
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override(&"icon_max_width", 56)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # long names take two lines
	return button


func _toggle(id: String) -> void:
	if not Profile.is_unlocked(id):
		Audio.play(&"hurt", 1.6)
		return
	Audio.play(&"click")
	if id in _picked:
		if _picked.size() > 1:  # keep at least one weapon
			_picked.erase(id)
	elif _picked.size() < Profile.LOADOUT_SIZE:
		_picked.append(id)
	else:
		_picked[_picked.size() - 1] = id  # full: swap out the last pick
	if _starter not in _picked:
		_starter = _picked[0]
	_refresh()


func _make_starter(slot: int) -> void:
	if slot < _picked.size():
		Audio.play(&"click")
		_starter = _picked[slot]
		_refresh()


func _refresh() -> void:
	for id: String in _cards:
		var button: Button = _cards[id]
		var unlocked: bool = Profile.is_unlocked(id)
		button.modulate = Color.WHITE if unlocked else Color(0.55, 0.6, 0.75)
		button.icon = Describe.icon_for(Profile.weapon_card(id)) if unlocked else Describe.icon("lock")
		_border(button, Color("F2B53B") if id == _starter else (Color("7FD6F2") if id in _picked else Color("4E6A9E")),
			4 if id in _picked else 2)
		var tag: Label = _tags[id]
		tag.text = "Starter" if id == _starter else ("Packed" if id in _picked else ("Locked" if not unlocked else ""))
		tag.theme_type_variation = &"TagEvo" if id == _starter else (&"TagRare" if id in _picked else &"TagCommon")
		tag.visible = tag.text != ""
		tag.reset_size()
		button.tooltip_text = Profile.unlock_hint(id) if not unlocked else ("Click to take it out" if id in _picked else "Click to pack it")
	for i in _slots.size():
		var slot: Button = _slots[i]
		var id: String = _picked[i] if i < _picked.size() else ""
		slot.icon = Describe.icon_for(Profile.weapon_card(id)) if id else null
		slot.text = Profile.weapon_card(id).title if id else "Empty slot"
		slot.disabled = id == ""
		slot.tooltip_text = "" if id == "" or id == _starter else "Click to start with this one instead"
		_border(slot, Color("F2B53B") if id != "" and id == _starter else Color("4E6A9E"), 4 if id == _starter else 2)
		_slot_notes[i].text = "" if id == "" else ("Starts with you" if id == _starter else "Joins at level-ups")
		_slot_notes[i].theme_type_variation = &"GoldLabel" if id == _starter else &"SmallLabel"
	_count.text = "%d / %d packed" % [_picked.size(), Profile.LOADOUT_SIZE]
	var others: Array[String] = []
	for id: String in _picked:
		if id != _starter:
			others.append(Profile.weapon_card(id).title)
	_summary.text = "You start with %s.%s" % [Profile.weapon_card(_starter).title,
		(" " + " and ".join(others) + " can appear when you level up.") if not others.is_empty() else ""]


## Card plate by role (style guide): gold = starter, ice = picked, plain = not picked.
func _border(button: Button, color: Color, _width: int) -> void:
	button.theme_type_variation = &"CardEvo" if color == Color("F2B53B") else (&"CardRare" if color == Color("7FD6F2") else &"CardCommon")


func _show_details(card: UpgradeData) -> void:
	var id: String = Profile.weapon_id(card)
	_details.text = Describe.weapon_preview(card, Profile.is_unlocked(id), Profile.unlock_hint(id))


func _start() -> void:
	Audio.play(&"click")
	Profile.set_loadout(_picked, _starter)
	started.emit()


func close() -> void:
	Audio.play(&"click")
	hide()
	closed.emit()
