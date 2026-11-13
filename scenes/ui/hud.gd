extends CanvasLayer
## HP bar, XP bar, level, time left, owned weapons/items (at-a-glance; details in the pause menu),
## Santa's Sleigh meter + active blessing timers (bottom left), boss bar, banners (boss, Santa ready,
## evolution ready, evolved), and FPS. Bars update from signals; the clock,
## boss bar and owned row are polled.

## Toast slide distance (px); small so it never leaves the screen.
const TOAST_SLIDE: float = 16.0
const BANNER_MAX_WIDTH: float = 1200.0
const DESIGN_WIDTH: float = 1280.0

@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var fps_label: Label = %FpsLabel
@onready var boss_panel: Control = %BossPanel
@onready var boss_bar: ProgressBar = %BossBar
@onready var banner: Label = %Banner
@onready var owned: HBoxContainer = %Owned
@onready var banner_icon: TextureRect = %BannerIcon
@onready var santa_icon: TextureRect = %SantaIcon
@onready var santa_label: Label = %SantaLabel
@onready var santa_bar: ProgressBar = %SantaBar
@onready var blessings_row: HBoxContainer = %Blessings
@onready var items_row: HBoxContainer = %Items
@onready var kills_label: Label = %KillsLabel
@onready var santa_box: PanelContainer = %SantaBox

var _owned_key: String = ""
var _announced_boss: Object = null  # each Yeti (Endless sends more) gets its own banner
var _ready_announced: Dictionary = {}  # Weapon -> true once "evolution ready" was shown
var _santa_taught: bool = false
var _santa_ready: bool = false
var _blessing_key: String = ""
var _blessing_labels: Dictionary = {}  # BlessingData -> Label with seconds left
var _achievement_check_left: float = 1.0
var _toasts: Array[AchievementData] = []
var _toast: PanelContainer


func _ready() -> void:
	add_to_group(&"hud")  # events (Blizzard) show banners through call_group
	fps_label.visible = OS.is_debug_build()  # dev readout only
	GameState.player.health_changed.connect(_on_health_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	_on_health_changed(GameState.player.hp, GameState.player.max_hp)
	_on_xp_changed(GameState.xp, GameState.xp_needed())
	_on_leveled_up(GameState.level)
	Profile.achievement_earned.connect(func(goal: AchievementData) -> void:
		_toasts.append(goal)
		if _toasts.size() == 1:
			_show_toast())
	GameState.santa_changed.connect(_on_santa_changed)
	GameState.endless_started.connect(func() -> void:
		timer_label.add_theme_color_override(&"font_color", Color("F2B53B"))
		_show_banner("Endless! How long can Claus last?"))
	_on_santa_changed(GameState.santa_progress, GameState.santa_needed(), GameState.santa_ready)
	GameState.weapon_evolved.connect(func(w: Weapon) -> void:
		_show_banner("Evolution!  " + w.title(), Describe.weapon_icon(w)))


func _process(_delta: float) -> void:  # _delta is used for the achievement check timer
	# Normal runs count down to 5:00; Endless counts up in gold.
	var shown: int = floori(GameState.run_time) if GameState.endless \
		else ceili(maxf(GameState.RUN_LENGTH - GameState.run_time, 0.0))
	timer_label.text = "%d:%02d" % [floori(shown / 60.0), shown % 60]
	boss_panel.visible = GameState.boss != null
	if GameState.boss:
		boss_bar.value = GameState.boss.hp / GameState.boss.max_hp * 100.0
		if GameState.boss != _announced_boss:
			_announced_boss = GameState.boss
			_show_banner("The Grumpy Yeti approaches!")
	kills_label.text = str(GameState.kills)
	fps_label.text = "%d fps - %d enemies - %d kills%s" % [
		Engine.get_frames_per_second(), GameState.enemies.size(), GameState.kills,
		"   GOD MODE (F2 debug)" if GameState.player.invincible else "",
	]
	_refresh_owned()
	_refresh_blessings()
	_achievement_check_left -= _delta
	if _achievement_check_left <= 0.0 and GameState.is_running:
		_achievement_check_left = 1.0
		Profile.check_achievements()  # earned goals arrive through achievement_earned -> toast
	if _santa_ready:  # gentle pulse so a full meter is noticed without being loud
		santa_icon.pivot_offset = santa_icon.size / 2.0
		santa_icon.scale = Vector2.ONE * (1.0 + 0.12 * absf(sin(Time.get_ticks_msec() / 250.0)))


## Airmail-envelope toast (style guide 4.9) in the bottom-right corner: slides in, holds, slides out;
## queued if several. Never pauses and never covers the timer or a menu title.
func _show_toast() -> void:
	if _toasts.is_empty():
		return
	var goal: AchievementData = _toasts[0]
	if _toast == null:
		_toast = PanelContainer.new()
		_toast.theme_type_variation = &"AirmailPanel"
		_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 12)
		_toast.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Describe.icon("trophy")
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.add_theme_constant_override(&"separation", 0)
		row.add_child(text)
		text.add_child(Tin.label("Achievement unlocked", &"ToastTitle"))
		var name_label := Tin.label("", &"InkLabel")
		name_label.name = "Text"
		text.add_child(name_label)
		var reward := Tin.label("", &"InkLabel")
		reward.name = "Reward"
		reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(reward)
		add_child(_toast)
	_toast.find_child("Text", true, false).text = goal.title
	_toast.find_child("Reward", true, false).text = "+%d coins" % goal.reward_coins if goal.reward_coins > 0 else ""
	_toast.reset_size()
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var shown_at: Vector2 = screen - Vector2(20.0, 96.0) - _toast.get_combined_minimum_size()
	Audio.play(&"santa_ready", 1.2)
	# A short slide that never leaves the screen; the toast runs while paused (achievements land on the
	# results screen, which pauses the tree), so it can't freeze half-way in.
	_toast.process_mode = Node.PROCESS_MODE_ALWAYS
	_toast.position = shown_at + Vector2(TOAST_SLIDE, 0.0)
	_toast.modulate.a = 0.0
	_toast.show()
	var tween: Tween = _toast.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_toast, "position", shown_at, 0.4)
	tween.parallel().tween_property(_toast, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.6)
	tween.tween_property(_toast, "position", shown_at + Vector2(TOAST_SLIDE, 0.0), 0.4)
	tween.parallel().tween_property(_toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		_toast.hide()
		_toasts.pop_front()
		_show_toast())


func _on_santa_changed(progress: int, needed: int, is_ready: bool) -> void:
	_santa_ready = is_ready
	santa_bar.max_value = needed
	santa_bar.value = progress
	santa_label.text = "Santa is ready!  [Space]" if is_ready else "Santa's Sleigh  %d / %d" % [progress, needed]
	santa_label.add_theme_color_override(&"font_color", Color("F2B53B") if is_ready else Color("F4F8FF"))
	santa_box.self_modulate = Color(1.0, 0.85, 0.5) if is_ready else Color.WHITE  # warm box when ready
	santa_icon.scale = Vector2.ONE
	if is_ready and not _santa_taught:
		_santa_taught = true
		_show_banner("Santa's Sleigh is ready - press Space", Describe.icon("santa_sleigh"))


## Active blessings with their seconds left; rebuilt only when the set changes.
func _refresh_blessings() -> void:
	var active: Dictionary = GameState.player.blessings
	var key: String = str(active.keys())
	if key != _blessing_key:
		_blessing_key = key
		_blessing_labels.clear()
		for child in blessings_row.get_children():
			child.queue_free()
		for blessing: BlessingData in active:
			var icon := TextureRect.new()
			icon.texture = Describe.icon_for(blessing)
			icon.custom_minimum_size = Vector2(28, 28)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text = blessing.title
			blessings_row.add_child(icon)
			var label := Tin.label("", &"HudSmall")
			label.add_theme_color_override(&"font_color", Color("9BE0A8"))
			blessings_row.add_child(label)
			_blessing_labels[blessing] = label
	for blessing: BlessingData in _blessing_labels:
		if active.has(blessing):
			_blessing_labels[blessing].text = "%ds" % ceili(active[blessing])


func _show_banner(text: String, icon: Texture2D = null) -> void:
	banner.text = text
	banner_icon.texture = icon
	# The box hugs the text (wraps past 1200 px) so the slam (up to 1.6x, style guide 4.11) stays on screen.
	var width: float = minf(banner.get_theme_font(&"font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		banner.get_theme_font_size(&"font_size")).x + 24.0, BANNER_MAX_WIDTH)
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.offset_left = -width / 2.0
	banner.offset_right = width / 2.0
	banner.pivot_offset = Vector2(width / 2.0, banner.size.y / 2.0)
	banner.scale = Vector2.ONE * clampf((DESIGN_WIDTH - 40.0) / width, 1.0, 1.6)
	create_tween().tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for node: CanvasItem in [banner, banner_icon]:
		node.visible = node == banner or icon != null
		node.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(node, "modulate:a", 1.0, 0.2)
		tween.tween_interval(2.2)
		tween.tween_property(node, "modulate:a", 0.0, 0.5)
		tween.tween_callback(node.hide)


## Weapons as tiles with their level under them (top-left) and items as icons with stack counts
## (bottom-center, Vampire Survivors style). Rebuilt only when something changed.
func _refresh_owned() -> void:
	var player: Player = GameState.player
	var weapons: Array = []  # [icon, badge, color, rarity]
	for w in player.weapons():
		var badge: String = "Evo" if w.evolved else ("Ready" if w.can_evolve() else "Lv %d" % w.level)
		var color: Color = Color("F2B53B") if w.evolved or w.can_evolve() else Color("F4F8FF")
		weapons.append([Describe.weapon_icon(w), badge, color, "evo" if w.evolved else "common"])
		if w.can_evolve() and not _ready_announced.has(w):
			_ready_announced[w] = true
			_show_banner("Evolution ready - call Santa's Sleigh!")
	var items: Array = []  # [icon, stack]
	for item: ItemData in player.items:
		var count: int = player.items[item]
		items.append([Describe.icon_for(item), "x%d" % count if count > 1 else ""])
	var key: String = str(weapons) + str(items)
	if key == _owned_key:
		return
	_owned_key = key
	for row: Container in [owned, items_row]:
		for child in row.get_children():
			child.queue_free()
	for entry in weapons:
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override(&"separation", 2)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(Tin.tile(entry[0], entry[3], 34))
		var badge := Tin.label(entry[1], &"HudSmall")
		badge.add_theme_color_override(&"font_color", entry[2])
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(badge)
		owned.add_child(slot)
	for entry in items:
		var slot := PanelContainer.new()
		slot.theme_type_variation = &"TileHud"
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = entry[0]
		icon.custom_minimum_size = Vector2(34, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		if entry[1] != "":
			var stack := Tin.label(entry[1], &"HudSmall")
			stack.size_flags_horizontal = Control.SIZE_SHRINK_END
			stack.size_flags_vertical = Control.SIZE_SHRINK_END
			slot.add_child(stack)
		items_row.add_child(slot)


func _on_health_changed(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [ceili(hp), ceili(max_hp)]


func _on_xp_changed(xp: int, xp_needed: int) -> void:
	xp_bar.max_value = xp_needed
	xp_bar.value = xp


func _on_leveled_up(level: int) -> void:
	level_label.text = "Lv %d" % level
