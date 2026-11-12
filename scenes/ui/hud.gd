extends CanvasLayer
## HP bar, XP bar, level, time left, owned weapons/items (at-a-glance; details in the pause menu),
## Santa's Sleigh meter + active blessing timers (bottom left), boss bar, banners (boss, Santa ready,
## evolution ready, evolved), and FPS. Bars update from signals; the clock,
## boss bar and owned row are polled.

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
		_show_banner("ENDLESS! HOW LONG CAN CLAUS LAST?"))
	_on_santa_changed(GameState.santa_progress, GameState.santa_needed(), GameState.santa_ready)
	GameState.weapon_evolved.connect(func(w: Weapon) -> void:
		_show_banner("EVOLUTION!  " + w.title().to_upper(), Describe.weapon_icon(w)))


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
			_show_banner("THE GRUMPY YETI APPROACHES!")
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


## Small "Achievement!" card in the bottom-right corner: fades in and out without pausing; queued if several.
func _show_toast() -> void:
	if _toasts.is_empty():
		return
	var goal: AchievementData = _toasts[0]
	if _toast == null:
		_toast = PanelContainer.new()
		_toast.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_toast.position = Vector2(-20.0, 112.0)
		_toast.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		_toast.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Describe.icon("trophy")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		var text := Label.new()
		text.name = "Text"
		text.add_theme_font_size_override(&"font_size", 32)
		row.add_child(text)
		add_child(_toast)
	var label: Label = _toast.find_child("Text", true, false)
	label.text = "Achievement: %s
%s%s" % [goal.title, goal.description,
		"  (+%d coins)" % goal.reward_coins if goal.reward_coins > 0 else ""]
	# Bottom-right corner: nothing else lives there, so it never covers the timer or a menu title.
	var screen: Vector2 = get_viewport().get_visible_rect().size
	_toast.position = screen - Vector2(20.0, 20.0) - _toast.get_combined_minimum_size()
	Audio.play(&"santa_ready", 1.2)
	_toast.modulate.a = 0.0
	_toast.show()
	var tween: Tween = create_tween()
	tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(2.6)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		_toast.hide()
		_toasts.pop_front()
		_show_toast())


func _on_santa_changed(progress: int, needed: int, is_ready: bool) -> void:
	_santa_ready = is_ready
	santa_bar.max_value = needed
	santa_bar.value = progress
	santa_bar.modulate = Color("F2B53B") if is_ready else Color("7FD6F2")
	santa_label.text = "SANTA READY!  [Space]" if is_ready else "Santa's Sleigh  %d/%d" % [progress, needed]
	santa_label.add_theme_color_override(&"font_color", Color("F2B53B") if is_ready else Color("F4F8FF"))
	santa_icon.scale = Vector2.ONE
	if is_ready and not _santa_taught:
		_santa_taught = true
		_show_banner("SANTA'S SLEIGH IS READY - PRESS SPACE", Describe.icon("santa_sleigh"))


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
			var label := Label.new()
			label.add_theme_font_size_override(&"font_size", 32)
			label.add_theme_color_override(&"font_color", Color("9BE0A8"))
			blessings_row.add_child(label)
			_blessing_labels[blessing] = label
	for blessing: BlessingData in _blessing_labels:
		if active.has(blessing):
			_blessing_labels[blessing].text = "%ds" % ceili(active[blessing])


func _show_banner(text: String, icon: Texture2D = null) -> void:
	banner.text = text
	banner_icon.texture = icon
	for node: CanvasItem in [banner, banner_icon]:
		node.visible = node == banner or icon != null
		node.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(node, "modulate:a", 1.0, 0.25)
		tween.tween_interval(2.2)
		tween.tween_property(node, "modulate:a", 0.0, 0.5)
		tween.tween_callback(node.hide)


## Row of weapon and item icons (with level / count), rebuilt only when something changed.
func _refresh_owned() -> void:
	var player: Player = GameState.player
	var entries: Array = []  # [icon texture, badge text, badge color]
	for w in player.weapons():
		var badge: String = "EVO" if w.evolved else ("READY" if w.can_evolve() else "Lv%d" % w.level)
		var color: Color = Color("F2B53B") if w.evolved or w.can_evolve() else Color("F4F8FF")
		entries.append([Describe.weapon_icon(w), badge, color])
		if w.can_evolve() and not _ready_announced.has(w):
			_ready_announced[w] = true
			_show_banner("EVOLUTION READY - CALL SANTA'S SLEIGH!")
	for item: ItemData in player.items:
		var count: int = player.items[item]
		entries.append([Describe.icon_for(item), "x%d" % count if count > 1 else "", Color("F4F8FF")])
	var key: String = str(entries)
	if key == _owned_key:
		return
	_owned_key = key
	for child in owned.get_children():
		child.queue_free()
	for entry in entries:
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override(&"separation", -6)
		var icon := TextureRect.new()
		icon.texture = entry[0]
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(icon)
		var badge := Label.new()
		badge.text = entry[1]
		badge.add_theme_font_size_override(&"font_size", 32)
		badge.add_theme_color_override(&"font_color", entry[2])
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(badge)
		owned.add_child(slot)


func _on_health_changed(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [ceili(hp), ceili(max_hp)]


func _on_xp_changed(xp: int, xp_needed: int) -> void:
	xp_bar.max_value = xp_needed
	xp_bar.value = xp


func _on_leveled_up(level: int) -> void:
	level_label.text = "Lv %d" % level
