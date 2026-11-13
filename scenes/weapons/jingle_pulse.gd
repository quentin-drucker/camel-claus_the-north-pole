class_name JinglePulse
extends Weapon
## Every cooldown, a jingling burst hits everything within the pulse radius and pushes it back.
## Evolved (Carol of the Bells): bigger, faster, a golden bell floats over Claus and swings on each
## pulse, and the pulse is a double ring (gold, then ice).

const BELL: PackedScene = preload("res://scenes/weapons/bell_model.tscn")

@export var knockback: float = 1.2
@export var bell_height: float = 2.4

var _cooldown_left: float = 0.5
var _bell: Node3D
var _time: float = 0.0


func _init() -> void:
	data = preload("res://resources/weapons/jingle_pulse.tres")


func _ready() -> void:
	evolved_changed.connect(_on_evolved)


func _on_evolved() -> void:
	_bell = BELL.instantiate()
	_bell.position = Vector3(0.0, bell_height, 0.0)
	_bell.scale = Vector3.ONE * 0.9
	add_child(_bell)


func _process(delta: float) -> void:
	_time += delta
	if _bell:
		_bell.position.y = bell_height + sin(_time * 2.5) * 0.08
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown()
	var reach: float = radius()
	var origin: Vector3 = global_position
	var dmg: float = damage()
	for enemy: Enemy in GameState.enemies.duplicate():
		var away: Vector3 = enemy.global_position - origin
		away.y = 0.0
		if away.length() > reach + enemy.radius:
			continue
		if not enemy.is_boss:
			enemy.global_position += away.normalized() * knockback
		GameState.player.deal_damage(enemy, dmg, true, data.display_name)
	Burst.spawn(Burst.GOLD, origin, reach)
	Audio.play(&"pulse", 1.25 if evolved else 1.0)
	if _bell:
		get_tree().create_timer(0.12, false).timeout.connect(func() -> void: Burst.spawn(Burst.ICE, origin, reach * 0.7))
		var swing: Tween = create_tween()
		swing.tween_property(_bell, "rotation:z", 0.5, 0.08)
		swing.tween_property(_bell, "rotation:z", -0.35, 0.14)
		swing.tween_property(_bell, "rotation:z", 0.0, 0.2)
