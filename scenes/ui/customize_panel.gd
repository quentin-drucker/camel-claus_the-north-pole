extends PanelContainer
## Main menu > Customize Camel. Tabs for Skin / Hat / Outfit, a list of pieces (equipped, free, owned,
## or a price), color swatches for the equipped hat/outfit, Default look and Back. Sits on the left so
## the menu's Claus on the right is the live preview: every pick saves to Profile and Claus redresses
## at once. Locked pieces: first press shows "Buy for N?", the second buys and wears it.
## Cosmetic only, no gameplay effect.

signal closed

const TABS: Array[String] = ["Skin", "Hat", "Outfit"]

var _slot: CosmeticData.Slot = CosmeticData.Slot.SKIN
var _armed: CosmeticData  # locked piece waiting for its confirming second press

var _coins: Label
var _tabs: Array[Button] = []
var _list: GridContainer
var _colors: HBoxContainer
var _colors_label: Label
var _back: Button


func _ready() -> void:
	custom_minimum_size = Vector2(600, 0)
	theme_type_variation = &"PlateTight"  # header band on top, body below (style guide 4.1)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", 0)
	add_child(outer)
	_coins = Tin.label("", &"GoldLabel")
	outer.add_child(Tin.header("Customize Claus", _coins))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	outer.add_child(Tin.body(column, 16))
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override(&"separation", 4)
	column.add_child(tab_row)
	for i in TABS.size():
		var tab := Button.new()
		tab.text = TABS[i]
		tab.toggle_mode = true
		tab.theme_type_variation = &"TabButton"
		tab.custom_minimum_size = Vector2(120, 0)
		tab.pressed.connect(_show_tab.bind(i))
		tab_row.add_child(tab)
		_tabs.append(tab)
	_list = GridContainer.new()
	_list.columns = 2
	_list.add_theme_constant_override(&"h_separation", 8)
	_list.add_theme_constant_override(&"v_separation", 8)
	column.add_child(_list)
	_colors_label = Tin.label("Color", &"StatLabel")
	column.add_child(_colors_label)
	_colors = HBoxContainer.new()
	_colors.add_theme_constant_override(&"separation", 8)
	column.add_child(_colors)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 10)
	column.add_child(bottom)
	var reset := Button.new()
	reset.text = "Default look"
	reset.size_flags_horizontal = Control.SIZE_EXPAND
	reset.pressed.connect(func() -> void:
		Audio.play(&"click")
		Profile.reset_look()
		_refresh())
	bottom.add_child(reset)
	_back = Button.new()
	_back.text = "Back"
	_back.theme_type_variation = &"PrimaryButton"
	_back.custom_minimum_size = Vector2(150, 0)
	_back.pressed.connect(close)
	bottom.add_child(_back)
	visibility_changed.connect(func() -> void:
		if visible:
			_show_tab(CosmeticData.Slot.SKIN)
			_tabs[0].grab_focus())


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	Audio.play(&"click")
	hide()
	closed.emit()


func _show_tab(slot: int) -> void:
	_slot = slot as CosmeticData.Slot
	_armed = null
	_refresh()


func _refresh() -> void:
	_coins.text = "%d coins" % Profile.coins()
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == _slot)
	for child in _list.get_children():
		child.queue_free()
	var worn: CosmeticData = Profile.equipped(_slot)
	for item in Profile.COSMETICS:
		if item.slot != _slot:
			continue
		var owned: bool = Profile.owns_cosmetic(item)
		var status: String = "Wearing" if item == worn else ("Owned" if owned else "%d coins" % item.price)
		if item == _armed:
			status = "Buy for %d?" % item.price
		var button := Button.new()  # knit nameplate tile; the worn one sits on the gold plate
		button.theme_type_variation = &"KnitTileButton"
		button.toggle_mode = true
		button.set_pressed_no_signal(item == worn)
		button.text = "%s\n%s" % [item.title, status]
		button.custom_minimum_size = Vector2(270, 74)
		if item == worn:
			button.add_theme_color_override(&"font_pressed_color", Color("FFD64F"))
			button.add_theme_color_override(&"font_hover_pressed_color", Color("FFD64F"))
		elif not owned:
			button.add_theme_color_override(&"font_color", Color("A9BDDC"))
			button.icon = Describe.icon("lock")
		button.pressed.connect(_pick.bind(item))
		button.mouse_entered.connect(button.grab_focus)
		_list.add_child(button)
	_fill_colors(worn)


func _pick(item: CosmeticData) -> void:
	if Profile.owns_cosmetic(item):
		Audio.play(&"click")
		_armed = null
		Profile.equip(item)
	elif item != _armed:
		Audio.play(&"click")
		_armed = item  # ask first: coins are precious
	elif Profile.buy_cosmetic(item):
		Audio.play(&"chest")
		_armed = null
		Profile.equip(item)
	else:
		Audio.play(&"hurt", 1.4)  # not enough coins
	_refresh()


## Swatches for the worn hat/outfit (hidden for skins and pieces without color options).
func _fill_colors(item: CosmeticData) -> void:
	for child in _colors.get_children():
		child.queue_free()
	var options: PackedStringArray = item.color_options if item else PackedStringArray()
	_colors_label.visible = options.size() > 1
	_colors.visible = options.size() > 1
	if options.size() <= 1:
		return
	var current: String = Profile.equipped_color(_slot)
	for name in options:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(56, 56)
		swatch.tooltip_text = name.capitalize()
		var style := StyleBoxFlat.new()
		style.bg_color = CosmeticData.COLORS[name][0]
		style.border_color = Color("F2B53B") if name == current else Color("22304F")
		style.set_border_width_all(5 if name == current else 2)
		for state in [&"normal", &"hover", &"pressed", &"focus"]:
			swatch.add_theme_stylebox_override(state, style)
		swatch.pressed.connect(func() -> void:
			Audio.play(&"click")
			Profile.equip(item, name)
			_refresh())
		_colors.add_child(swatch)
