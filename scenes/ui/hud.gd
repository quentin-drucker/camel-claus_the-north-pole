extends CanvasLayer
## HP bar, XP bar, level, time left and FPS. Updates from signals except the clock.

@onready var hp_bar: ProgressBar = %HpBar
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var fps_label: Label = %FpsLabel


func _ready() -> void:
	GameState.player.health_changed.connect(_on_health_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	_on_health_changed(GameState.player.hp, GameState.player.max_hp)
	_on_xp_changed(GameState.xp, GameState.xp_needed())
	_on_leveled_up(GameState.level)


func _process(_delta: float) -> void:
	var left: int = ceili(maxf(GameState.RUN_LENGTH - GameState.run_time, 0.0))
	timer_label.text = "%d:%02d" % [floori(left / 60.0), left % 60]
	fps_label.text = "%d fps · %d enemies" % [Engine.get_frames_per_second(), GameState.enemies.size()]


func _on_health_changed(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _on_xp_changed(xp: int, xp_needed: int) -> void:
	xp_bar.max_value = xp_needed
	xp_bar.value = xp


func _on_leveled_up(level: int) -> void:
	level_label.text = "Lv %d" % level
