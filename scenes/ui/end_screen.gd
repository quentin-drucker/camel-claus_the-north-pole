extends CanvasLayer
## Results screen, as in the approved hybrid (style guide 5.8): freezes the run, records it in the Profile
## (coins, lifetime stats, bests, achievements) and shows
## - the postcard: greeting, headline, pills (time survived, level, "New best run"), Claus's stamp;
## - Damage: every damage source with its level, total damage and damage per second;
## - Summary: Claus, bonks / time / level, the inventory, achievements + coins earned, and Keep going
##   (Endless, after a win) / Play again (same loadout) / Main menu;
## - Unlocked: achievements earned this run, new records and the next goal.
## The HUD hides behind it. After an Endless run ends, the screen shows again with what it added.

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const CLAUS: Texture2D = preload("res://assets/ui/claus_front.png")
const DAMAGE_ROWS: int = 6
## Non-weapon damage sources -> icon name.
const SOURCE_ICONS: Dictionary = {"Christmas Cracker": "christmas_cracker", "Snow bomb": "blizzard",
	"Santa's Sleigh": "santa_sleigh", "Blizzard": "blizzard", "Other": "trophy"}

var restart_button: Button
var endless_button: Button

@onready var greeting: Label = %Greeting
@onready var headline_label: Label = %Headline
@onready var pills: HBoxContainer = %Pills
@onready var columns: HBoxContainer = %Columns


func _ready() -> void:
	hide()
	GameState.run_ended.connect(_on_run_ended)


func _on_run_ended(won: bool) -> void:
	var survived: int = int(GameState.run_time)
	# The postcard header (style guide 4.13): greeting + big headline + pills.
	greeting.text = "Greetings from the" if won else "Wish you were here..."
	headline_label.text = "North Pole!" if won else "Claus fainted!"
	if GameState.endless:
		greeting.text = "Greetings from the"
		headline_label.text = "Endless night!"
	var record: Dictionary = Profile.record_run()
	for box: Control in [pills, columns]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	pills.add_child(_pill("%s survived" % _clock(survived)))
	pills.add_child(_pill("Lv %d reached" % GameState.level))
	if not record.is_empty() and "time" in record["records"]:
		pills.add_child(_pill("New best run", true))
	_fill_damage()
	_fill_summary(record, won)
	_fill_unlocked(record)
	Audio.stop_music()
	Audio.play(&"win" if won else &"lose")
	get_tree().paused = true
	# Short beat so the final moment registers, then the panel fades in.
	await get_tree().create_timer(0.5, true).timeout
	for node: CanvasItem in get_children():
		node.modulate.a = 0.0
		create_tween().tween_property(node, "modulate:a", 1.0, 0.4)
	if GameState.is_running:  # already continued during the beat (balance bot)
		return
	get_tree().call_group(&"hud", &"hide")
	show()
	restart_button.grab_focus()


## Same run, no time limit: unfreeze and let the spawner keep escalating.
func continue_endless() -> void:
	Audio.play(&"click")
	hide()
	get_tree().call_group(&"hud", &"show")
	get_tree().paused = false
	GameState.continue_endless()
	Audio.play_music()
	Audio.set_intensity(true)


func _pill(text: String, best: bool = false) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.theme_type_variation = &"PillRed" if best else &"Pill"
	pill.add_child(Tin.label(text, &"NameLabel" if best else &"Label"))
	return pill


## A PlateTight column with a header band; returns its body box.
func _plate(title: String, width: float) -> VBoxContainer:
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"PlateTight"
	plate.custom_minimum_size = Vector2(width, 0)
	columns.add_child(plate)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	plate.add_child(column)
	column.add_child(Tin.header(title))
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 10)
	column.add_child(Tin.body(body, 14))
	return body


## Damage table: source (icon + name), level, damage, DPS; biggest first.
func _fill_damage() -> void:
	var body := _plate("Damage", 440)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 8)
	body.add_child(grid)
	for head: String in ["Source", "Lv", "Damage", "DPS"]:
		var h := Tin.label(head, &"SmallLabel")
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if head == "Source" else HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(h)
	var sources: Array = GameState.damage_by.keys()
	sources.sort_custom(func(a: String, b: String) -> bool: return GameState.damage_by[a] > GameState.damage_by[b])
	var seconds: float = maxf(GameState.run_time, 1.0)
	for source: String in sources.slice(0, DAMAGE_ROWS):
		var info: Array = _source_info(source)
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override(&"separation", 10)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(Tin.tile(info[0], "evo" if info[3] else "common", 28))
		var name_label := Tin.label(info[1])
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(name_label)
		grid.add_child(cell)
		var dmg: float = GameState.damage_by[source]
		for text: String in [info[2], Tin.num(roundi(dmg)), Tin.num(roundi(dmg / seconds))]:
			var l := Tin.label(text)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			grid.add_child(l)
	if sources.is_empty():
		body.add_child(Tin.label("No damage dealt", &"MutedLabel"))


## [icon, title, level text, evolved] for a damage source: the weapon it names, or an item/event.
func _source_info(source: String) -> Array:
	for weapon in GameState.player.weapons():
		if weapon.data.display_name == source:
			return [Describe.weapon_icon(weapon), weapon.title(), str(weapon.level), weapon.evolved]
	for item: ItemData in GameState.player.items:
		if item.title == source:
			return [Describe.icon_for(item), source, str(GameState.player.items[item]), false]
	return [Describe.icon(SOURCE_ICONS.get(source, "trophy")), source, "-", false]


func _fill_summary(record: Dictionary, won: bool) -> void:
	var body := _plate("Summary", 420)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 16)
	body.add_child(top)
	var portrait := Tin.tile(CLAUS, "common", 90)
	top.add_child(portrait)
	var numbers := VBoxContainer.new()
	numbers.alignment = BoxContainer.ALIGNMENT_CENTER
	numbers.add_theme_constant_override(&"separation", 4)
	top.add_child(numbers)
	for pair: Array in [["Bonks", Tin.num(GameState.kills)], ["Time", _clock(int(GameState.run_time))],
			["Level", str(GameState.level)]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 10)
		var k := Tin.label(pair[0], &"MutedLabel")
		k.custom_minimum_size = Vector2(60, 0)
		line.add_child(k)
		line.add_child(Tin.label(pair[1], &"BigNumber"))
		numbers.add_child(line)
	body.add_child(Tin.label("Inventory", &"SubLabel"))
	var inventory := HFlowContainer.new()
	inventory.add_theme_constant_override(&"h_separation", 6)
	inventory.add_theme_constant_override(&"v_separation", 6)
	body.add_child(inventory)
	for item: ItemData in GameState.player.items:
		var count: int = GameState.player.items[item]
		var tile := Tin.tile(Describe.icon_for(item), "epic" if item.unique else "common", 30)
		tile.mouse_filter = Control.MOUSE_FILTER_PASS
		tile.tooltip_text = "%s  x%d\n%s" % [item.title, count, item.description]
		if count > 1:
			var stack := Tin.label("x%d" % count, &"HudSmall")
			stack.size_flags_horizontal = Control.SIZE_SHRINK_END
			stack.size_flags_vertical = Control.SIZE_SHRINK_END
			tile.add_child(stack)
		inventory.add_child(tile)
	if GameState.player.items.is_empty():
		inventory.add_child(Tin.label("No items this run", &"MutedLabel"))
	var reward := HBoxContainer.new()
	reward.add_theme_constant_override(&"separation", 8)
	body.add_child(reward)
	var earned: int = record["achievements"].size() if not record.is_empty() else 0
	var trophy := TextureRect.new()
	trophy.texture = Describe.icon("trophy")
	trophy.custom_minimum_size = Vector2(22, 22)
	trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward.add_child(trophy)
	var unlocked := Tin.label("%d achievement%s unlocked" % [earned, "" if earned == 1 else "s"], &"MutedLabel")
	unlocked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward.add_child(unlocked)
	var coins: int = record["coins"]["total"] if not record.is_empty() else 0
	reward.add_child(Tin.coin("+%s coins" % Tin.num(coins)))
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 10)
	body.add_child(buttons)
	endless_button = _button(buttons, "Keep going (Endless)", &"", continue_endless)
	endless_button.visible = won and not GameState.endless
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	buttons.add_child(row)
	restart_button = _button(row, "Play again", &"PrimaryButton", _leave.bind(MAIN_SCENE))
	_button(row, "Main menu", &"", _leave.bind(MENU_SCENE))


func _button(parent: Control, text: String, variation: StringName, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(on_press)
	b.mouse_entered.connect(b.grab_focus)
	parent.add_child(b)
	return b


## Achievements earned this run (with their coins), new records, then the next goal to chase.
func _fill_unlocked(record: Dictionary) -> void:
	var body := _plate("Unlocked", 330)
	var goals: Array = record.get("achievements", [])
	for goal: AchievementData in goals.slice(0, 4):
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		body.add_child(row)
		row.add_child(Tin.stamp(Describe.goal_icon(goal), "evo", 26))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.add_theme_constant_override(&"separation", 0)
		row.add_child(text)
		text.add_child(Tin.label(goal.title, &"NameLabel"))
		text.add_child(Tin.label("Achievement", &"SmallLabel"))
		var coin := Tin.coin("+%d" % goal.reward_coins)
		coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(coin)
	if goals.size() > 4:
		body.add_child(Tin.label("+%d more" % (goals.size() - 4), &"MutedLabel"))
	for key: String in record.get("records", []):
		body.add_child(Tin.label("New record: " + Profile.BEST_LABELS[key], &"GoodLabel"))
	if goals.is_empty() and record.get("records", []).is_empty():
		body.add_child(Tin.label("Nothing new this time", &"MutedLabel"))
	var p: Dictionary = Profile.progress()
	for goal: AchievementData in Profile.ACHIEVEMENTS:
		if Profile.has_achievement(goal.id):
			continue
		body.add_child(Tin.label("Next goal", &"SubLabel"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		body.add_child(row)
		row.add_child(Tin.stamp(Describe.goal_icon(goal), "common", 26))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override(&"separation", 2)
		row.add_child(text)
		text.add_child(Tin.label(goal.title, &"NameLabel"))
		text.add_child(Tin.label(goal.description, &"SmallLabel", true))
		text.add_child(Tin.bar(&"GoodBar", minf(p.get(goal.stat, 0.0), goal.target), goal.target, 8))
		break


static func _clock(seconds: int) -> String:
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _leave(scene: String) -> void:
	Audio.play(&"click")
	Transition.change_scene(scene)
