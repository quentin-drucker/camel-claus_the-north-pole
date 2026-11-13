extends CanvasLayer
## Escape / P: pauses the run. Three plates side by side, as in the approved hybrid (style guide 5.4):
## - Your build: each weapon (tile, name, summary, level pips -> its evolution) and the items as tiles
##   (hover for the description).
## - Paused: time left, level, bonks, coins, then Resume / Settings / Restart run / Main menu.
## - Stats: Claus's stats now (green = better than base, red = worse; hover for the sources).
## All numbers come from Describe, so they match the level-up cards and the real game.

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
## Leaving fullscreen mid-run opens the pause menu: where the browser keeps Esc for itself (Firefox,
## Safari, iframes like itch.io) that Esc exits fullscreen and may or may not reach the game, so the
## run never keeps going behind the player's back. The same Esc arriving a moment later must not close
## the menu again, hence the short guard.
const FULLSCREEN_ESC_GUARD: float = 0.4
const PIP_ON: Color = Color("F2B53B")
const PIP_OFF: Color = Color("0D1322")

var _was_fullscreen: bool = false
var _opened_by_fullscreen_at: float = -10.0
var build_grid: GridContainer  # item tiles (tests walk it)
var _weapons: VBoxContainer
var _run_numbers: GridContainer
var _stats: GridContainer
var resume_button: Button
var settings_button: Button

@onready var main_panel: Control = %MainPanel
@onready var settings: Control = %SettingsPanel


func _ready() -> void:
	hide()
	settings.hide()
	_build()
	settings.closed.connect(func() -> void:
		main_panel.show()
		settings_button.grab_focus())


func _build() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 16)
	main_panel.add_child(columns)
	# Your build
	var build_body := _plate(columns, "Your build", 470)
	var scroll := ScrollContainer.new()  # a huge Endless build scrolls instead of leaving the screen
	scroll.custom_minimum_size = Vector2(0, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_body.add_child(scroll)
	var build := VBoxContainer.new()
	build.add_theme_constant_override(&"separation", 12)
	build.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(build)
	_weapons = VBoxContainer.new()
	_weapons.add_theme_constant_override(&"separation", 12)
	build.add_child(_weapons)
	build.add_child(Tin.label("Items", &"SubLabel"))
	build_grid = GridContainer.new()
	build_grid.columns = 9
	build_grid.add_theme_constant_override(&"h_separation", 4)
	build_grid.add_theme_constant_override(&"v_separation", 4)
	build.add_child(build_grid)
	# Paused
	var middle := _plate(columns, "Paused", 360)
	_run_numbers = GridContainer.new()
	_run_numbers.columns = 2
	_run_numbers.add_theme_constant_override(&"h_separation", 60)
	_run_numbers.add_theme_constant_override(&"v_separation", 10)
	middle.add_child(_run_numbers)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 14)
	middle.add_child(buttons)
	resume_button = _button(buttons, "Resume", &"PrimaryButton", _resume)
	settings_button = _button(buttons, "Settings", &"", func() -> void:
		Audio.play(&"click")
		main_panel.hide()
		settings.show())
	_button(buttons, "Restart run", &"", _leave.bind(MAIN_SCENE))
	_button(buttons, "Main menu", &"", _leave.bind(MENU_SCENE))
	# Stats
	var right := _plate(columns, "Stats", 340)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override(&"v_separation", 6)
	right.add_child(_stats)


## A PlateTight column with a header band; returns its body box.
func _plate(parent: Control, title: String, width: float) -> VBoxContainer:
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"PlateTight"
	plate.custom_minimum_size = Vector2(width, 0)
	plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(plate)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	plate.add_child(column)
	column.add_child(Tin.header(title))
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 12)
	column.add_child(Tin.body(body, 16))
	return body


func _button(parent: Control, text: String, variation: StringName, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.pressed.connect(on_press)
	b.mouse_entered.connect(b.grab_focus)
	parent.add_child(b)
	return b


func _process(_delta: float) -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var full: bool = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if _was_fullscreen and not full and not visible and GameState.is_running and not get_tree().paused:
		_open()
		_opened_by_fullscreen_at = Time.get_ticks_msec() / 1000.0
	_was_fullscreen = full


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if Time.get_ticks_msec() / 1000.0 - _opened_by_fullscreen_at < FULLSCREEN_ESC_GUARD:
		get_viewport().set_input_as_handled()  # the Esc that just left fullscreen already paused us
		return
	if visible:
		if settings.visible:
			settings.close()
		else:
			_resume()
	elif GameState.is_running and not get_tree().paused:  # not over a level-up or end screen
		_open()
	else:
		return
	get_viewport().set_input_as_handled()


func _open() -> void:
	_refresh()
	main_panel.show()
	settings.hide()
	show()
	get_tree().paused = true
	Audio.set_paused_duck(true)
	Audio.play(&"menu")
	resume_button.grab_focus()


func _resume() -> void:
	Audio.play(&"click")
	Audio.set_paused_duck(false)
	hide()
	get_tree().paused = false


func _leave(scene: String) -> void:
	Audio.play(&"click")
	Audio.set_paused_duck(false)
	GameState.end_run_silently()
	Transition.change_scene(scene)


func _refresh() -> void:
	var player: Player = GameState.player
	for box: Control in [_weapons, build_grid, _run_numbers, _stats]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	for weapon in player.weapons():
		_weapons.add_child(_weapon_row(weapon, player))
	for item: ItemData in player.items:
		var count: int = player.items[item]
		var tile := Tin.tile(Describe.icon_for(item), "epic" if item.unique else "common", 32)
		tile.mouse_filter = Control.MOUSE_FILTER_PASS  # tooltip
		tile.tooltip_text = "%s  x%d\n%s" % [item.title, count, item.description]
		if count > 1:
			var stack := Tin.label("x%d" % count, &"HudSmall")
			stack.size_flags_horizontal = Control.SIZE_SHRINK_END
			stack.size_flags_vertical = Control.SIZE_SHRINK_END
			tile.add_child(stack)
		build_grid.add_child(tile)
	if player.items.is_empty():
		build_grid.add_child(Tin.label("None yet - open gift chests", &"MutedLabel"))
	var left: int = ceili(maxf(GameState.RUN_LENGTH - GameState.run_time, 0.0)) if not GameState.endless \
		else floori(GameState.run_time)
	var coins: int = Profile.run_coins(GameState.kills, GameState.run_time, GameState.elites_killed,
		GameState.bosses_killed, false)["total"]
	for pair: Array in [["%d:%02d" % [floori(left / 60.0), left % 60], "Time"], [str(GameState.level), "Level"],
			[Tin.num(GameState.kills), "Bonks"], [Tin.num(coins), "Coins"]]:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override(&"separation", 0)
		cell.add_child(Tin.label(pair[0], &"BigNumber"))
		cell.add_child(Tin.label(pair[1], &"SmallLabel"))
		_run_numbers.add_child(cell)
	for row in Describe.stats(player):
		var name_label := Tin.label(row["name"], &"StatLabel")
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS  # tooltips
		name_label.tooltip_text = "Base %s%s" % [row["base"], ("\nFrom: " + row["sources"]) if row["sources"] else ""]
		_stats.add_child(name_label)
		var value := Tin.label(row["current"], &"" if row["cmp"] == 0 else (&"GoodLabel" if row["cmp"] > 0 else &"BadLabel"))
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stats.add_child(value)


## Weapon line: rarity tile, name, summary, five level pips and where it evolves.
func _weapon_row(weapon: Weapon, player: Player) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	var tile := Tin.tile(Describe.weapon_icon(weapon), "evo" if weapon.evolved else "common", 44)
	tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(tile)
	var text := VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(Tin.label(weapon.title(), &"NameLabel"))
	text.add_child(Tin.label(Describe.weapon_summary(weapon.data, weapon.level, weapon.evolved, player), &"SmallLabel", true))
	var evo := HBoxContainer.new()
	evo.add_theme_constant_override(&"separation", 3)
	text.add_child(evo)
	for i in WeaponData.MAX_LEVEL:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10, 10)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.color = PIP_ON if i < weapon.level or weapon.evolved else PIP_OFF
		evo.add_child(pip)
	var line: String
	if weapon.data.evolved_name == "":
		line = "Lv %d/%d" % [weapon.level, WeaponData.MAX_LEVEL]
	elif weapon.evolved:
		line = "Evolved: " + weapon.data.evolved_name
	elif weapon.can_evolve():
		line = "Ready! Call Santa → " + weapon.data.evolved_name
	else:
		line = "Lv %d/%d → %s" % [weapon.level, WeaponData.MAX_LEVEL, weapon.data.evolved_name]
	var evo_label := Tin.label(line, &"GoldLabel")
	evo.add_child(Control.new())  # small gap after the pips
	evo.add_child(evo_label)
	return row
