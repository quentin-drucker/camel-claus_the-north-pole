class_name Gingerbread
extends Node3D
## One thrown gingerbread man (see GingerbreadBoomerang): flies out along `direction`, easing to a stop
## at `out_distance`, then flies back to wherever Claus is now, speeding up, and vanishes when it reaches
## him. It passes through everything and hits each enemy once on the way out and once on the way back,
## so where Claus stands when it returns decides what it sweeps.

@export var out_time: float = 0.55
@export var return_speed: float = 6.0
@export var return_accel: float = 30.0
@export var spin_speed: float = 14.0

var direction: Vector3 = Vector3.FORWARD
var out_distance: float = 6.0
var damage: float = 14.0
var hit_radius: float = 0.45
var size: float = 1.0
var crumbs: bool = false

var _start: Vector3
var _t: float = 0.0
var _returning: bool = false
var _speed: float = 0.0
var _hit: Dictionary = {}  # enemy instance id -> true, cleared when it turns back

@onready var body: Node3D = $Body


func _ready() -> void:
	_start = global_position
	body.scale *= size
	if crumbs:
		add_child(Poof.trail(Color("C98F55"), 8))


func _process(delta: float) -> void:
	body.rotate_y(spin_speed * delta)
	if not _returning:
		_t += delta
		var k: float = minf(_t / out_time, 1.0)
		global_position = _start + direction * out_distance * sin(k * PI * 0.5)
		if k >= 1.0:
			_returning = true
			_speed = return_speed
			_hit.clear()
	else:
		var claus: Vector3 = GameState.player.global_position + Vector3.UP * 0.6
		var to_claus: Vector3 = claus - global_position
		var dist: float = to_claus.length()
		_speed += return_accel * delta
		if dist < 0.6:
			queue_free()
			return
		global_position += to_claus / dist * minf(_speed * delta, dist)
	var pos: Vector3 = global_position
	var reach_base: float = hit_radius * size
	for enemy: Enemy in GameState.enemies.duplicate():
		var id: int = enemy.get_instance_id()
		if _hit.has(id):
			continue
		var e_pos: Vector3 = enemy.global_position
		var reach: float = reach_base + enemy.radius
		if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() < reach * reach:
			_hit[id] = true
			GameState.player.deal_damage(enemy, damage)
