extends CanvasLayer
## Results screen: freezes the run, records it in the Profile (coins, lifetime stats, bests,
## achievements) and fades in with the result, the build (evolved icons), run stats, the coin payout,
## new records and achievements; then "Play again" (same loadout) or "Main menu". After a win,
## "Keep going" continues the same run in Endless mode; when that ends, this screen shows again with
## what the Endless part added.

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var endless_button: Button = %EndlessButton
@onready var build_row: HBoxContainer = %BuildRow
@onready var summary: RichTextLabel = %Summary


func _ready() -> void:
	hide()
	GameState.run_ended.connect(_on_run_ended)
	restart_button.pressed.connect(_leave.bind(MAIN_SCENE))
	menu_button.pressed.connect(_leave.bind(MENU_SCENE))
	endless_button.pressed.connect(continue_endless)


func _on_run_ended(won: bool) -> void:
	var survived: int = int(GameState.run_time)
	var headline: String = "You survived the North Pole!" if won else "Claus fainted in the snow..."
	if GameState.endless:
		headline = "Endless run over!"
	result_label.text = "%s\nSurvived %d:%02d  -  level %d  -  %d critters bonked" % [
		headline, floori(survived / 60.0), survived % 60, GameState.level, GameState.kills,
	]
	_fill_summary(Profile.record_run())
	endless_button.visible = won and not GameState.endless
	for child in build_row.get_children():
		child.queue_free()
	var player: Player = GameState.player
	for weapon in player.weapons():
		_add_icon(Describe.weapon_icon(weapon))
	for item: ItemData in player.items:
		_add_icon(Describe.icon_for(item))
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
	show()
	restart_button.grab_focus()


## Same run, no time limit: unfreeze and let the spawner keep escalating.
func continue_endless() -> void:
	Audio.play(&"click")
	hide()
	get_tree().paused = false
	GameState.continue_endless()
	Audio.play_music()
	Audio.set_intensity(true)


## Two columns: what happened (left), what it earned (right).
func _fill_summary(record: Dictionary) -> void:
	var gs: Node = GameState
	var evolved: PackedStringArray = []
	for weapon in gs.player.weapons():
		if weapon.evolved:
			evolved.append(weapon.title())
	var left: PackedStringArray = [
		"Damage dealt  %s" % _thousands(roundi(gs.damage_dealt)),
		"Santa's sleighs  %d" % gs.santa_calls,
		"Evolved  " + (Describe.c(Describe.GOLD, ", ".join(evolved)) if evolved else Describe.c(Describe.MUTED, "none yet")),
	]
	var right: PackedStringArray = []
	if not record.is_empty():
		var coins: Dictionary = record["coins"]
		right.append(Describe.c(Describe.GOLD, "+%d coins" % coins["total"]) + Describe.c(Describe.MUTED,
			"  (bonks %d, time %d, elites %d, boss %d, win %d)" % [coins["kills"], coins["time"], coins["elites"], coins["boss"], coins["win"]]))
		for key: String in record["records"]:
			right.append(Describe.c(Describe.GOOD, "New record: " + Profile.BEST_LABELS[key]))
		for goal: AchievementData in record["achievements"]:
			right.append(Describe.c(Describe.GOLD, "Achievement: %s (+%d)" % [goal.title, goal.reward_coins]))
	right.append("Coins  %d" % Profile.coins())
	summary.text = "[table=2][cell]%s[/cell][cell]%s[/cell][/table]" % ["
".join(left), "
".join(right)]


static func _thousands(n: int) -> String:
	var digits: String = str(n)
	var out: String = ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return out


func _add_icon(texture: Texture2D) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(56, 56)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	build_row.add_child(icon)


func _leave(scene: String) -> void:
	Audio.play(&"click")
	Transition.change_scene(scene)
