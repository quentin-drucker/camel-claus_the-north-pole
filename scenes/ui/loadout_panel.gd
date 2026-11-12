extends PanelContainer
## Pre-run loadout (main menu > Play): pick up to 3 unlocked weapons for the run and mark one as the
## starter. Claus starts with the starter; the others only show up as "new weapon" cards at
## level-ups, so the run's weapon pool stays small enough to reach Lv 5 and evolve.
## Collection cards (top) toggle a weapon in or out; the three slots (bottom) pick the starter.
## Saved in Profile, so the last loadout is ready next time.

signal closed
signal started

const CARD_SIZE: Vector2 = Vector2(168, 128)  # 6 weapons in one row
const SLOT_SIZE: Vector2 = Vector2(196, 76)

var _picked: Array[String] = []
var _starter: String = ""
var _cards: Dictionary = {}  # weapon id -> Button
var _slots: Array[Button] = []

var _details: RichTextLabel
var _start_button: Button


func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	var title := Label.new()
	title.text = "Pick your loadout"
	title.add_theme_font_size_override(&"font_size", 64)
	title.add_theme_color_override(&"font_color", Color("F2B53B"))
	column.add_child(title)
	var help := Label.new()
	help.text = "Up to 3 weapons. You start with the gold one; the rest come from level-ups."
	help.add_theme_font_size_override(&"font_size", 32)
	help.add_theme_color_override(&"font_color", Color("8FA9D1"))
	column.add_child(help)

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override(&"separation", 10)
	column.add_child(grid)
	for card in Profile.WEAPON_CARDS:
		var id: String = Profile.weapon_id(card)
		var button := _icon_button(Describe.icon_for(card), card.title, CARD_SIZE)
		button.pressed.connect(_toggle.bind(id))
		button.focus_entered.connect(_show_details.bind(card))
		button.mouse_entered.connect(button.grab_focus)
		grid.add_child(button)
		_cards[id] = button

	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.custom_minimum_size = Vector2(0, 150)
	_details.add_theme_font_size_override(&"normal_font_size", 32)
	_details.scroll_active = false
	column.add_child(_details)

	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override(&"separation", 10)
	column.add_child(slot_row)
	var slots_label := Label.new()
	slots_label.text = "Run:"
	slots_label.add_theme_font_size_override(&"font_size", 48)
	slot_row.add_child(slots_label)
	for i in Profile.LOADOUT_SIZE:
		var slot := _icon_button(null, "", SLOT_SIZE)
		slot.pressed.connect(_make_starter.bind(i))
		slot.mouse_entered.connect(slot.grab_focus)
		slot_row.add_child(slot)
		_slots.append(slot)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override(&"separation", 14)
	column.add_child(buttons)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(200, 64)
	back.pressed.connect(close)
	buttons.add_child(back)
	_start_button = Button.new()
	_start_button.text = "Start run"
	_start_button.custom_minimum_size = Vector2(260, 64)
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


func _icon_button(icon: Texture2D, text: String, size: Vector2) -> Button:
	var button := Button.new()
	button.custom_minimum_size = size
	button.icon = icon
	button.text = text
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override(&"font_size", 32)
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
	for i in _slots.size():
		var slot: Button = _slots[i]
		var id: String = _picked[i] if i < _picked.size() else ""
		slot.icon = Describe.icon_for(Profile.weapon_card(id)) if id else null
		slot.text = ("START" if id == _starter else "level-ups") if id else "(empty)"
		slot.disabled = id == ""
		_border(slot, Color("F2B53B") if id != "" and id == _starter else Color("4E6A9E"), 4 if id == _starter else 2)


func _border(button: Button, color: Color, width: int) -> void:
	var style: StyleBoxFlat = ThemeDB.get_project_theme().get_stylebox(&"normal", &"Button").duplicate()
	style.border_color = color
	style.set_border_width_all(width)
	button.add_theme_stylebox_override(&"normal", style)


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
