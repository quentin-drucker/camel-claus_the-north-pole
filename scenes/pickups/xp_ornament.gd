class_name XpOrnament
extends Node3D
## Dropped by enemies. Flies to the player once inside the pickup radius, speeding up as it goes, so a
## Christmas Magnet (or Chimney Draft) pull turns into a rush of ornaments streaming into Claus.

@export var value: int = 1
@export var attract_speed: float = 8.0
## Top speed and how fast it gets there (m/s per second).
@export var max_speed: float = 34.0
@export var acceleration: float = 30.0
@export var collect_distance: float = 0.5

var _attracted: bool = false
var _speed: float = 0.0

@onready var body: Node3D = $Body


func _ready() -> void:
	add_to_group(&"xp_ornaments")


## Fly to Claus from anywhere (Christmas Magnet, Chimney Draft).
func attract() -> void:
	_attracted = true


func _process(delta: float) -> void:
	body.rotate_y(2.0 * delta)
	var player: Player = GameState.player
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < collect_distance:
		GameState.add_xp(value)
		Audio.play_xp()
		queue_free()
		return
	if dist < player.get_pickup_radius():
		_attracted = true
	if _attracted:
		_speed = minf(maxf(_speed, attract_speed) + acceleration * delta, max_speed)
		global_position += to_player / dist * minf(_speed * delta, dist)
