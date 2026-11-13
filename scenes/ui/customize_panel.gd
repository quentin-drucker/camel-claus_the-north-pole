extends PanelContainer
## Main menu > Customize Claus, as in the approved hybrid (style guide 5.7): a tall panel on the left
## with Hats / Outfits / Skins tabs and a grid of picture tiles (render of the piece, name, price when
## locked; the worn one on the gold plate), and a detail panel on the right with the picked piece's
## name, description, color swatches and Equip / Buy / Equipped. The menu's Claus in the middle is the
## live preview: equipping saves to Profile and Claus redresses at once. Cosmetic only.

signal closed

## Tabs in prototype order: [name, slot].
const TABS: Array[Array] = [["Hats", CosmeticData.Slot.HAT], ["Outfits", CosmeticData.Slot.OUTFIT],
	["Skins", CosmeticData.Slot.SKIN]]
const TILE_SIZE: Vector2 = Vector2(136, 166)
const PICTURE: int = 70

var _tab: int = 0
var _picked: CosmeticData
var _tabs: Array[Button] = []
var _grid: GridContainer
var _detail: PanelContainer
var _detail_title: Label
var _detail_desc: Label
var _colors: HBoxContainer
var _action: Button
var _wallet: HBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(480, 640)
	theme_type_variation = &"PlateTight"
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", 0)
	add_child(outer)
	outer.add_child(Tin.header("Customize Claus", null, close))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	outer.add_child(Tin.body(column, 14))
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override(&"separation", 4)
	column.add_child(tab_row)
	for i in TABS.size():
		var tab := Button.new()
		tab.text = TABS[i][0]
		tab.toggle_mode = true
		tab.theme_type_variation = &"TabButton"
		tab.set_meta(&"no_brackets", true)
		tab.pressed.connect(_show_tab.bind(i))
		tab.mouse_entered.connect(tab.grab_focus)
		tab_row.add_child(tab)
		_tabs.append(tab)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override(&"h_separation", 12)
	_grid.add_theme_constant_override(&"v_separation", 12)
	column.add_child(_grid)
	_build_detail()
	visibility_changed.connect(func() -> void:
		if visible:
			_show_tab(0)
			_tabs[0].grab_focus())


## The detail panel and the coin wallet float on the right (top_level: the panel's layout ignores them,
## and they hide with it).
func _build_detail() -> void:
	_detail = PanelContainer.new()
	_detail.top_level = true
	_detail.custom_minimum_size = Vector2(360, 0)
	add_child(_detail)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	_detail.add_child(box)
	_detail_title = Tin.label("", &"TitleLabel")
	box.add_child(_detail_title)
	_detail_desc = Tin.label("", &"", true)
	_detail_desc.custom_minimum_size = Vector2(320, 0)
	box.add_child(_detail_desc)
	_colors = HBoxContainer.new()
	_colors.add_theme_constant_override(&"separation", 8)
	box.add_child(_colors)
	_action = Button.new()
	_action.custom_minimum_size = Vector2(320, 0)
	_action.pressed.connect(_on_action)
	_action.mouse_entered.connect(_action.grab_focus)
	box.add_child(_action)
	var reset := Button.new()
	reset.text = "Default look"
	reset.theme_type_variation = &"SmallButton"
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.mouse_entered.connect(reset.grab_focus)
	reset.pressed.connect(func() -> void:
		Audio.play(&"click")
		Profile.reset_look()
		_picked = Profile.equipped(TABS[_tab][1])
		_refresh())
	box.add_child(reset)
	_wallet = Tin.coin("", &"HudLabel", 30)
	_wallet.top_level = true
	add_child(_wallet)
	get_viewport().size_changed.connect(_place_floating)


func _place_floating() -> void:
	var view: Vector2 = get_viewport_rect().size
	_detail.reset_size()
	_detail.position = Vector2(view.x - _detail.size.x - 30.0, 110.0)
	_wallet.reset_size()
	_wallet.position = Vector2(view.x - _wallet.size.x - 32.0, 22.0)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	Audio.play(&"click")
	hide()
	closed.emit()


func _show_tab(i: int) -> void:
	Audio.play(&"click")
	_tab = i
	_picked = Profile.equipped(TABS[i][1])
	_refresh()


func _refresh() -> void:
	var slot: CosmeticData.Slot = TABS[_tab][1]
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == _tab)
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var worn: CosmeticData = Profile.equipped(slot)
	var items: Array[CosmeticData] = Profile.COSMETICS.filter(func(c: CosmeticData) -> bool: return c.slot == slot)
	items.sort_custom(func(a: CosmeticData, b: CosmeticData) -> bool:  # "No hat" / "No outfit" last
		return not a.id.ends_with("_none") and b.id.ends_with("_none"))
	for item in items:
		_grid.add_child(_tile(item, item == worn))
	(_wallet.get_child(1) as Label).text = Tin.num(Profile.coins())
	_fill_detail(worn)
	_place_floating.call_deferred()


## Knit picture tile: render (or skin swatch / empty ring), name strip, price when not owned.
func _tile(item: CosmeticData, is_worn: bool) -> Button:
	var owned: bool = Profile.owns_cosmetic(item)
	var tile := Button.new()
	tile.theme_type_variation = &"KnitTileButton"
	tile.toggle_mode = true
	tile.set_pressed_no_signal(is_worn)
	tile.custom_minimum_size = TILE_SIZE
	tile.tooltip_text = item.title
	tile.pressed.connect(func() -> void:
		tile.set_pressed_no_signal(is_worn)  # the plate shows what is worn, not what is picked
		Audio.play(&"click")
		_picked = item
		_fill_detail(Profile.equipped(item.slot)))
	tile.focus_entered.connect(func() -> void:
		_picked = item
		_fill_detail(Profile.equipped(item.slot)))
	tile.mouse_entered.connect(tile.grab_focus)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 4)
	tile.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_right = -8
	box.offset_top = 10
	box.offset_bottom = -12
	var art := CenterContainer.new()
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	art.add_child(_art(item))
	if not owned:
		art.modulate = Color(0.75, 0.8, 0.9)
	var strip := PanelContainer.new()
	strip.theme_type_variation = &"DarkBox"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(strip)
	var title := Tin.label(item.title, &"TagLabel", true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strip.add_child(title)
	if not owned:
		var price := Tin.coin(str(item.price), &"GoldLabel", 18)
		tile.add_child(price)
		price.position = Vector2(TILE_SIZE.x - 64.0, 8.0)
	return tile


func _art(item: CosmeticData) -> Control:
	if item.picture:
		var pic := TextureRect.new()
		pic.texture = item.picture
		pic.custom_minimum_size = Vector2(PICTURE, PICTURE)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return pic
	# Skins: a fur swatch ring (light fur inside, dark fur rim). "None" pieces: an empty steel ring.
	var ring := Panel.new()
	ring.custom_minimum_size = Vector2(64, 64)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(32)
	style.set_border_width_all(8)
	if item.slot == CosmeticData.Slot.SKIN and item.swap_to.size() >= 2:
		style.bg_color = item.swap_to[0]
		style.border_color = item.swap_to[1]
	elif item.slot == CosmeticData.Slot.SKIN:
		style.bg_color = Color("E8C48E")  # the classic coat keeps the model's own colors
		style.border_color = Color("C98F55")
	else:
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color("5C77AB")
		style.set_border_width_all(4)
	ring.add_theme_stylebox_override(&"panel", style)
	return ring


func _fill_detail(worn: CosmeticData) -> void:
	if _picked == null:
		return
	_detail_title.text = _picked.title
	_detail_desc.text = _picked.description
	var owned: bool = Profile.owns_cosmetic(_picked)
	_action.icon = null
	_action.disabled = false
	if _picked == worn:
		_action.text = "Equipped"
		_action.theme_type_variation = &""
		_action.disabled = true
	elif owned:
		_action.text = "Equip"
		_action.theme_type_variation = &"PrimaryButton"
	else:
		_action.text = "Buy for %d" % _picked.price
		_action.theme_type_variation = &"PrimaryButton"
		_action.icon = Tin.COIN
		_action.disabled = Profile.coins() < _picked.price
	_fill_colors(worn if _picked == worn else null)
	_place_floating.call_deferred()


func _on_action() -> void:
	if Profile.owns_cosmetic(_picked):
		Audio.play(&"click")
		Profile.equip(_picked)
	elif Profile.buy_cosmetic(_picked):
		Audio.play(&"chest")
		Profile.equip(_picked)
	else:
		Audio.play(&"hurt", 1.4)  # not enough coins
		return
	var picked := _picked
	_refresh()
	_picked = picked
	_action.grab_focus()


## Swatches for the worn hat/outfit (hidden for skins and pieces without color options).
func _fill_colors(item: CosmeticData) -> void:
	for child in _colors.get_children():
		_colors.remove_child(child)
		child.queue_free()
	var options: PackedStringArray = item.color_options if item else PackedStringArray()
	_colors.visible = options.size() > 1
	if options.size() <= 1:
		return
	var current: String = Profile.equipped_color(item.slot)
	for color_name in options:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(48, 48)
		swatch.tooltip_text = color_name.capitalize()
		swatch.set_meta(&"no_brackets", true)
		var style := StyleBoxFlat.new()
		style.bg_color = CosmeticData.COLORS[color_name][0]
		style.border_color = Color("F2B53B") if color_name == current else Color("0D1322")
		style.set_border_width_all(5 if color_name == current else 2)
		for state in [&"normal", &"hover", &"pressed", &"focus"]:
			swatch.add_theme_stylebox_override(state, style)
		swatch.pressed.connect(func() -> void:
			Audio.play(&"click")
			Profile.equip(item, color_name)
			_refresh())
		_colors.add_child(swatch)
