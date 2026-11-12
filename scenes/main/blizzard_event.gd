class_name BlizzardEvent
extends Node
## The run's one mid-run event (Santa's Sleigh stays the main special). At `start_time` a blizzard
## blows for `duration` seconds: every critter walks `enemy_slow` slower, but the thick snow hides
## ornaments, so Claus's pickup reach shrinks by `reach_penalty` — a breather that rewards walking to
## your XP. Looks: white frost creeps in at the screen edges only (the middle stays clear), the snowfall
## falls faster, the music dips a little. Fades in and out over `fade` seconds.

@export var start_time: float = 165.0
@export var duration: float = 20.0
@export var fade: float = 2.0
@export var enemy_slow: float = 0.35
@export var reach_penalty: float = 0.3
@export var snow_speed: float = 2.2

var _active: bool = false
var _done: bool = false
var _strength: float = 0.0  # 0..1, eased in and out
var _frost: TextureRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5  # under the HUD (which is on the default layer above the 3D world) and menus
	add_child(layer)
	_frost = TextureRect.new()
	_frost.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	gradient.colors = PackedColorArray([Color(0.957, 0.973, 1.0, 0.0), Color(0.957, 0.973, 1.0, 0.0),
		Color(0.957, 0.973, 1.0, 0.75)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_frost.texture = texture
	_frost.modulate.a = 0.0
	layer.add_child(_frost)


func _exit_tree() -> void:
	Audio.blizzard_db = 0.0  # leaving mid-blizzard (menu, restart) must not keep the music dipped


func _process(delta: float) -> void:
	var t: float = GameState.run_time
	if not _done and not _active and GameState.is_running and t >= start_time:
		_active = true
		get_tree().call_group(&"hud", &"_show_banner", "BLIZZARD!  CRITTERS SLOW DOWN - GRAB YOUR XP")
		Audio.play(&"freeze", 0.6)
	if _active and (t >= start_time + duration or not GameState.is_running):
		_active = false
		_done = true
	var target: float = 1.0 if _active else 0.0
	var before: float = _strength
	_strength = move_toward(_strength, target, delta / fade)
	if is_equal_approx(before, _strength) and (_strength == 0.0 or _strength == 1.0):
		return
	_apply(_strength - before)


## Apply the change in strength `d` (so bonuses from upgrades picked meanwhile are never touched).
func _apply(d: float) -> void:
	GameState.enemy_speed_mult -= enemy_slow * d
	if GameState.player:
		GameState.player.pickup_bonus -= reach_penalty * d
		var snow: CPUParticles3D = GameState.player.get_node_or_null(^"Snowfall")
		if snow:
			snow.speed_scale = lerpf(1.0, snow_speed, _strength)
	_frost.modulate.a = _strength
	Audio.blizzard_db = -5.0 * _strength
