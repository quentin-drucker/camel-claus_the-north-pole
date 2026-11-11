class_name XpOrnament
extends Node3D
## Dropped by enemies. Flies to the player once inside the pickup radius.

@export var value: int = 1
@export var attract_speed: float = 14.0
@export var collect_distance: float = 0.5

var _attracted: bool = false


func _process(delta: float) -> void:
	var player: Player = GameState.player
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < collect_distance:
		GameState.add_xp(value)
		queue_free()
		return
	if dist < player.pickup_radius:
		_attracted = true
	if _attracted:
		global_position += to_player / dist * minf(attract_speed * delta, dist)
