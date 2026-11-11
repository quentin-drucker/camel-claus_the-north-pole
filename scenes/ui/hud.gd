extends CanvasLayer
## HP bar, XP bar, level, time left, owned weapons/items (at-a-glance; details in the pause menu),
## boss bar, banners (boss, evolution ready, evolved), and FPS. Bars update from signals; the clock,
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

var _owned_key: String = ""
var _boss_announced: bool = false
var _ready_announced: Dictionary = {}  # Weapon -> true once "evolution ready" was shown


func _ready() -> void:
	fps_label.visible = OS.is_debug_build()  # dev readout only
	GameState.player.health_changed.connect(_on_health_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	_on_health_changed(GameState.player.hp, GameState.player.max_hp)
	_on_xp_changed(GameState.xp, GameState.xp_needed())
	_on_leveled_up(GameState.level)
	GameState.weapon_evolved.connect(func(w: Weapon) -> void:
		_show_banner("EVOLUTION!  " + w.title().to_upper(), Describe.weapon_icon(w)))


func _process(_delta: float) -> void:
	var left: int = ceili(maxf(GameState.RUN_LENGTH - GameState.run_time, 0.0))
	timer_label.text = "%d:%02d" % [floori(left / 60.0), left % 60]
	boss_panel.visible = GameState.boss != null
	if GameState.boss:
		boss_bar.value = GameState.boss.hp / GameState.boss.max_hp * 100.0
		if not _boss_announced:
			_boss_announced = true
			_show_banner("THE GRUMPY YETI APPROACHES!")
	fps_label.text = "%d fps - %d enemies - %d kills%s" % [
		Engine.get_frames_per_second(), GameState.enemies.size(), GameState.kills,
		"   GOD MODE (F2 debug)" if GameState.player.invincible else "",
	]
	_refresh_owned()


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
			_show_banner("EVOLUTION READY - FIND A GIFT CHEST!")
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
