class_name SnowballBarrage
extends Weapon
## Lobs count() snowballs in high arcs at enemies in range (spread over the nearest few, leading
## their walk), each splashing everything within radius() where it lands. The landing spot shows as
## the snowball's shadow, so the hit is readable in a crowd.
## Evolved (Avalanche): bigger snowballs that burst into `fragments` small ones hopping outward,
## each splashing again for `fragment_damage` of the hit.

const SHELL: PackedScene = preload("res://scenes/weapons/snowball_shell.tscn")

## How far Claus looks for targets (the data's attack_range is the splash radius).
@export var target_range: float = 13.0
@export var flight_time: float = 0.65
@export var fragments: int = 4
@export var fragment_damage: float = 0.4

var _cooldown_left: float = 0.4


func _init() -> void:
	data = preload("res://resources/weapons/snowball_barrage.tres")


func _process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var origin: Vector3 = global_position
	var range_sq: float = target_range * target_range
	var targets: Array[Enemy] = GameState.enemies.filter(
		func(e: Enemy) -> bool: return origin.distance_squared_to(e.global_position) < range_sq
	)
	if targets.is_empty():
		return
	targets.sort_custom(
		func(a: Enemy, b: Enemy) -> bool:
			return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
	targets = targets.slice(0, 8)  # spread over the nearest few instead of all on one
	targets.shuffle()
	_cooldown_left = cooldown()
	Audio.play(&"throw", 0.75 if evolved else 0.85)
	for i in count():
		var target: Enemy = targets[i % targets.size()]
		var e_pos: Vector3 = target.global_position
		# Lead the target along its walk toward Claus so the splash lands on it.
		var walk: Vector3 = (origin - e_pos).normalized() * target.data.speed * target.speed_mult * flight_time
		var spot: Vector3 = e_pos + walk * 0.8
		if i >= targets.size():  # more snowballs than targets: scatter the extras around it
			spot += Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
		launch(origin + Vector3.UP * 0.8, spot, damage(), radius(), fragments if evolved else 0, 1.4 if evolved else 1.0)


func launch(from: Vector3, to: Vector3, dmg: float, splash: float, pieces: int, size: float) -> void:
	var shell: SnowballShell = SHELL.instantiate()
	shell.start = from
	shell.target = Vector3(to.x, 0.0, to.z)
	shell.flight_time = flight_time * (0.7 if size < 1.0 else 1.0)
	shell.damage = dmg
	shell.splash_radius = splash
	shell.size = size
	shell.fragments = pieces
	shell.fragment_damage = fragment_damage
	get_tree().current_scene.add_child(shell)
