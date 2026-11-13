extends CanvasLayer
## Escape / P: pauses the run and shows the build (weapons + items with levels, effects and evolution
## progress) and Claus's stats compared to base (green = better, red = worse, white = unchanged).
## All text comes from Describe, so it matches the level-up cards and the real game numbers.

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const SLOT_SIZE: Vector2 = Vector2(72, 80)  # 3 rows of a huge Endless build must still fit 720 px
## Leaving fullscreen mid-run opens the pause menu: where the browser keeps Esc for itself (Firefox,
## Safari, iframes like itch.io) that Esc exits fullscreen and may or may not reach the game, so the
## run never keeps going behind the player's back. The same Esc arriving a moment later must not close
## the menu again, hence the short guard.
const FULLSCREEN_ESC_GUARD: float = 0.4

var _was_fullscreen: bool = false
var _opened_by_fullscreen_at: float = -10.0

@onready var main_panel: Control = %MainPanel
@onready var build_grid: GridContainer = %BuildGrid
@onready var details: RichTextLabel = %Details
@onready var stats_grid: GridContainer = %StatsGrid
@onready var hp_line: Label = %HpLine
@onready var settings: Control = %SettingsPanel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	settings.hide()
	resume_button.pressed.connect(_resume)
	settings_button.pressed.connect(func() -> void:
		Audio.play(&"click")
		main_panel.hide()
		settings.show())
	settings.closed.connect(func() -> void:
		main_panel.show()
		settings_button.grab_focus())
	restart_button.pressed.connect(_leave.bind(MAIN_SCENE))
	menu_button.pressed.connect(_leave.bind(MENU_SCENE))


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
	for child in build_grid.get_children():
		child.queue_free()
	var first: Callable
	for weapon in player.weapons():
		var badge: String = "EVO" if weapon.evolved else ("READY" if weapon.can_evolve() else "Lv%d" % weapon.level)
		var show_it: Callable = func() -> void: details.text = Describe.weapon_details(weapon, player)
		_add_slot(Describe.weapon_icon(weapon), badge, show_it, weapon.evolved or weapon.can_evolve())
		if not first.is_valid():
			first = show_it
	for item: ItemData in player.items:
		var show_it: Callable = func() -> void: details.text = Describe.item_details(item, player)
		_add_slot(Describe.icon_for(item), "x%d" % player.items[item], show_it, false)
	if first.is_valid():
		first.call()
	hp_line.text = "HP %d / %d     Level %d     %d kills" % [ceili(player.hp), ceili(player.max_hp), GameState.level, GameState.kills]
	for child in stats_grid.get_children():
		child.queue_free()
	for header in ["", "Base", "Now"]:
		_stat_label(header, Color(Describe.MUTED))
	for row in Describe.stats(player):
		var name_label: Label = _stat_label(row["name"], Color("F4F8FF"))
		name_label.tooltip_text = ("From: " + row["sources"]) if row["sources"] else "Not changed yet"
		_stat_label(row["base"], Color(Describe.MUTED))
		var color: Color = Color("F4F8FF") if row["cmp"] == 0 else (Color(Describe.GOOD) if row["cmp"] > 0 else Color(Describe.BAD))
		_stat_label(row["current"], color).tooltip_text = name_label.tooltip_text


func _add_slot(icon: Texture2D, badge: String, on_focus: Callable, gold: bool) -> void:
	var slot := Button.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.icon = icon
	slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	slot.text = badge
	slot.add_theme_constant_override(&"icon_max_width", 48)
	# Knit nameplate tile; a weapon that has evolved (or can) sits on the gold evolution plate.
	slot.theme_type_variation = &"RowEvo" if gold else &"KnitTileButton"
	if gold:
		slot.add_theme_color_override(&"font_color", Color("FFD64F"))
	slot.focus_entered.connect(on_focus)
	slot.mouse_entered.connect(on_focus)
	build_grid.add_child(slot)


func _stat_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_PASS  # tooltips
	stats_grid.add_child(label)
	return label
