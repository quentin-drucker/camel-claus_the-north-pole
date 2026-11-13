extends SceneTree
## Run: godot --headless --path . -s res://tests/test_text_fit.gd  (exit code 1 = failure)
## Puts every screen into its wordiest states (every card, full build, banners, end screens) and checks
## that no text is cut off: single-line labels must fit their width, and every visible control must
## stay inside the screen and inside the card/button it belongs to.

const SLACK: float = 2.0  # px of rounding we tolerate
const DESIGN_SCREEN: Rect2 = Rect2(0, 0, 1280, 720)

var _failures: int = 0
var _checked: int = 0
var _started: bool = false


func _initialize() -> void:
	# Headless windows are square: letterbox to the 1280x720 design canvas so layouts match the game.
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	# Never touch the player's real save: the results screen records every run.
	root.get_node("Profile").save_path = "user://test_scratch_profile.json"
	if FileAccess.file_exists("user://test_scratch_profile.json"):
		DirAccess.remove_absolute("user://test_scratch_profile.json")
	change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _process(_delta: float) -> bool:
	if not _started and current_scene != null:
		_started = true
		_run()
	return false


func _run() -> void:
	await _frames(3)
	_audit("main menu")
	var box: Rect2 = current_scene.get_node("%MenuBox").get_global_rect()
	if not DESIGN_SCREEN.encloses(box):
		_fail("main menu", "menu panel %s runs off the screen" % box)
	current_scene.get_node("%SettingsPanel").show()
	current_scene.get_node("%MenuBox").hide()
	await _frames(2)
	_audit("main menu settings")
	current_scene.get_node("%SettingsPanel").hide()
	var loadout: Node = current_scene.get_node("%LoadoutPanel")
	loadout.show()
	await _frames(2)
	for button: Button in loadout._cards.values():  # every weapon's details text, locked or not
		button.focus_entered.emit()
		await _frames(2)
		_audit("loadout details " + button.text)
	loadout.hide()
	var profile: Node = root.get_node("Profile")
	var menu_scene: Node = current_scene
	var customize: Node = menu_scene.get_node("%CustomizePanel")
	customize.show()
	for rich in [false, true]:  # nothing bought, then everything owned and the priciest pieces worn
		if rich:
			for item: Resource in profile.COSMETICS:
				profile.data["cosmetics_owned"].append(item.id)
			profile.data["coins"] = 999999
		for tab in 3:
			customize._show_tab(tab)
			await _frames(2)
			_audit("customize tab %d %s" % [tab, "rich" if rich else "fresh"])
	customize.hide()
	profile.data = profile.DEFAULTS.duplicate(true)
	for page: String in ["%WorkshopPanel", "%AchievementsPanel", "%StatsPanel", "%CreditsPanel"]:
		for veteran in [false, true]:  # fresh profile, then huge numbers and everything earned
			if veteran:
				profile.data["coins"] = 999999
				for key: String in profile.STAT_LABELS:
					profile.data["stats"][key] = 99999999
				for key: String in profile.BEST_LABELS:
					profile.data["bests"][key] = 99999
				profile.data["bests"]["build"] = ["Present Barrage", "Peppermint Cyclone", "Carol of the Bells"]
				for goal: Resource in profile.ACHIEVEMENTS:
					profile.data["achievements"][goal.id] = 1
			var panel: Control = menu_scene.get_node(page)
			panel.show()
			await _frames(3)
			_audit("%s %s" % [page, "veteran" if veteran else "fresh"])
			panel.hide()
			profile.data = profile.DEFAULTS.duplicate(true)

	change_scene_to_file("res://scenes/main/main.tscn")
	await _frames(3)
	var gs: Node = root.get_node("GameState")
	var player: Node = gs.player
	player.invincible = true
	paused = true
	var main: Node = current_scene
	var hud: Node = main.get_node("HUD")
	var menu: Node = main.get_node("LevelUpMenu")
	_audit("HUD at start")

	await _cards(menu, player, "fresh")
	# Full build: every weapon one level below max, every item.
	for upgrade: Resource in menu.upgrades:
		if upgrade.stat == load("res://scripts/data/upgrade_data.gd").Stat.WEAPON:
			while player.upgrade_level(upgrade) < upgrade.max_level - 1:
				player.apply_upgrade(upgrade)
	for item: Resource in menu.items:
		player.add_item(item)
		player.add_item(item)
	await _cards(menu, player, "full build")
	for weapon: Node in player.weapons():
		while weapon.level < weapon.data.MAX_LEVEL:
			weapon.level += 1
	for weapon: Node in player.weapons():
		if weapon.can_evolve():
			_show_card(menu, {"card": load("res://scripts/ui/describe.gd").evolution_card(weapon),
				"icon": null, "border": Color.GOLD, "apply": Callable()})
			await _frames(2)
			_audit("evolution card " + weapon.title())
	menu.hide()

	hud._refresh_owned()
	for text: String in ["THE GRUMPY YETI APPROACHES!", "EVOLUTION READY - CALL SANTA'S SLEIGH!",
			"SANTA'S SLEIGH IS READY - PRESS SPACE"]:
		hud._show_banner(text)
		await _frames(2)
		_audit("banner " + text)
	for weapon: Node in player.weapons():
		weapon.evolved = weapon.can_evolve() or weapon.evolved
		hud._show_banner("EVOLUTION!  " + weapon.title().to_upper(), load("res://scripts/ui/describe.gd").weapon_icon(weapon))
		await _frames(2)
		_audit("banner evolved " + weapon.title())
	# Santa: blessing cards, the banish prompt, and the HUD with every blessing running.
	var describe: GDScript = load("res://scripts/ui/describe.gd")
	for blessing: Resource in menu.BLESSINGS:
		_show_card(menu, {"card": describe.blessing_card(blessing), "icon": describe.icon_for(blessing),
			"border": Color.WHITE, "apply": Callable()})
		await _frames(2)
		_audit("blessing card " + blessing.title)
	menu._kind = 1  # level-up: reroll/banish row visible, in its longest wording
	menu.banish_button.button_pressed = true
	menu._refresh_tools()
	await _frames(2)
	_audit("level-up banish prompt")
	menu.banish_button.button_pressed = false
	menu.hide()
	for blessing: Resource in menu.BLESSINGS:
		player.blessings[blessing] = 99.0
	gs.santa_changed.emit(999, 999, false)
	await _frames(2)
	_audit("HUD every blessing + big meter")
	gs.santa_changed.emit(999, 999, true)
	await _frames(2)
	_audit("HUD Santa ready")
	gs.kills = 99999
	gs.level = 99
	await _frames(2)
	_audit("HUD full build")

	var pause_menu: Node = main.get_node("PauseMenu")
	paused = false
	pause_menu._open()
	await _frames(2)
	_audit("pause build + stats")
	pause_menu.main_panel.hide()
	pause_menu.settings.show()
	await _frames(2)
	_audit("pause settings")
	pause_menu.hide()

	var end: Node = main.get_node("EndScreen")
	gs.run_time = 299.0
	end._on_run_ended(false)
	await _frames(45)
	_audit("lose screen")
	end._on_run_ended(true)
	await _frames(45)
	_audit("win screen")

	print("text fit: %d screens checked, %d problems" % [_checked, _failures])
	quit(1 if _failures > 0 else 0)


func _cards(menu: Node, player: Node, label: String) -> void:
	var describe: GDScript = load("res://scripts/ui/describe.gd")
	for upgrade: Resource in menu.upgrades:
		if player.upgrade_level(upgrade) >= upgrade.max_level:
			continue
		for rarity: Array in [["", 1.0], ["EPIC", 2.0]]:
			_show_card(menu, {"card": describe.upgrade_card(player, upgrade, rarity[0], rarity[1]),
				"icon": describe.icon_for(upgrade), "border": Color.WHITE, "apply": Callable()})
			await _frames(2)
			_audit("%s card %s %s" % [label, upgrade.title, rarity[0]])
	for item: Resource in menu.items:
		_show_card(menu, {"card": describe.item_card(player, item), "icon": describe.icon_for(item),
			"border": Color.WHITE, "apply": Callable()})
		await _frames(2)
		_audit("%s item card %s" % [label, item.title])


func _show_card(menu: Node, choice: Dictionary) -> void:
	for button: Button in menu.buttons:
		button.show()
	for i in menu.buttons.size():
		menu._fill_card(i, choice)
	menu.show()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Checks every visible Control under the current scene.
func _audit(where: String) -> void:
	_checked += 1
	var screen: Rect2 = DESIGN_SCREEN  # the headless window is 1280x1280; players see 1280x720
	for node: Node in current_scene.find_children("*", "Control", true, false):
		var control: Control = node
		if not _shown(control):
			continue
		var rect: Rect2 = control.get_global_rect()
		var name: String = "%s (%s)" % [control.name, control.get_class()]
		if control is Label and control.text != "" and control.autowrap_mode == TextServer.AUTOWRAP_OFF:
			var font: Font = control.get_theme_font(&"font")
			var size: int = control.get_theme_font_size(&"font_size")
			for line: String in control.text.split("\n"):
				var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				if width > control.size.x + SLACK:
					_fail(where, "%s text '%s' is %d px wide in a %d px label" % [name, line, width, control.size.x])
		# Deliberate overhangs (rays bigger than the screen, a rarity tag breaking its row's border) carry
		# meta "decor": their text is still measured above, only their bounds are skipped.
		if control.has_meta(&"decor"):
			continue
		if not screen.grow(SLACK).encloses(rect) and not _in_scroll(control):  # scrolled-away rows are clipped, not cut
			_fail(where, "%s at %s sticks out of the screen" % [name, rect])
		var button: Control = _button_ancestor(control)
		if button and not button.get_global_rect().grow(SLACK).encloses(rect):
			_fail(where, "%s sticks out of its button %s (%s vs %s)" % [name, button.name, rect, button.get_global_rect()])


func _shown(control: Control) -> bool:
	if not control.is_visible_in_tree() or control.size == Vector2.ZERO:
		return false
	var node: Node = control
	while node:
		if node is CanvasLayer and not node.visible:
			return false
		node = node.get_parent()
	return true


func _in_scroll(control: Control) -> bool:
	var node: Node = control.get_parent()
	while node is Control:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false


func _button_ancestor(control: Control) -> Control:
	var node: Node = control.get_parent()
	while node is Control:
		if node is BaseButton:
			return node
		node = node.get_parent()
	return null


func _fail(where: String, message: String) -> void:
	_failures += 1
	print("FAIL [%s] %s" % [where, message])
