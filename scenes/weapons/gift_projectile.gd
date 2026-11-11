class_name GiftProjectile
extends Node3D
## Flies straight; hits the first enemy it touches (or the first 1 + `pierce` enemies).

@export var lifetime: float = 1.5
@export var hit_radius: float = 0.3
## Radians per second the gift tumbles while flying.
@export var spin_speed: float = 9.0

var direction: Vector3 = Vector3.FORWARD
var speed: float = 14.0
var damage: float = 5.0
## Extra enemies this gift can pass through.
var pierce: int = 0

var _already_hit: Array[Enemy] = []

@onready var body: Node3D = $Body


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	body.rotate_y(spin_speed * delta)
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var pos: Vector3 = global_position
	for enemy in GameState.enemies:
		var e_pos: Vector3 = enemy.global_position
		var reach: float = enemy.radius + hit_radius
		if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() < reach * reach \
				and not _already_hit.has(enemy):
			_already_hit.append(enemy)
			GameState.player.deal_damage(enemy, damage)
			if _already_hit.size() > pierce:
				queue_free()
			return
