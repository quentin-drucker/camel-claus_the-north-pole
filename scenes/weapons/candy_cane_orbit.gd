class_name CandyCaneOrbit
extends Weapon
## Candy canes circle Claus and smack every enemy they pass (each enemy at most every `rehit_time`).
## Spins faster with attack speed; one cane per count(). `data.attack_range` is the orbit radius.

const CANE: PackedScene = preload("res://scenes/weapons/candy_cane_model.tscn")

## Radians per second at +0% attack speed.
@export var spin_speed: float = 2.6
@export var hit_radius: float = 0.5
@export var rehit_time: float = 0.5

var _angle: float = 0.0
var _canes: Array[Node3D] = []
var _last_hit: Dictionary = {}  # enemy instance id -> run time of last hit


func _init() -> void:
	data = preload("res://resources/weapons/candy_cane_orbit.tres")


func _process(delta: float) -> void:
	var wanted: int = count()
	while _canes.size() < wanted:
		var cane: Node3D = CANE.instantiate()
		add_child(cane)
		_canes.append(cane)
	while _canes.size() > wanted:
		_canes.pop_back().queue_free()
	_angle += spin_speed * (1.0 + GameState.player.attack_speed_bonus) * delta
	var now: float = GameState.run_time
	if _last_hit.size() > 600:  # ponytail: forget dead enemies in bulk instead of tracking frees
		_last_hit.clear()
	var dmg: float = damage()
	for i in _canes.size():
		var a: float = _angle + TAU * i / _canes.size()
		var cane: Node3D = _canes[i]
		cane.position = Vector3(cos(a), 0.0, sin(a)) * data.attack_range
		cane.rotation.y = -a  # hook leads the swing
		var pos: Vector3 = cane.global_position
		for enemy: Enemy in GameState.enemies.duplicate():
			var reach: float = enemy.radius + hit_radius
			var e_pos: Vector3 = enemy.global_position
			if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() > reach * reach:
				continue
			var id: int = enemy.get_instance_id()
			if now - _last_hit.get(id, -99.0) >= rehit_time:
				_last_hit[id] = now
				GameState.player.deal_damage(enemy, dmg)
