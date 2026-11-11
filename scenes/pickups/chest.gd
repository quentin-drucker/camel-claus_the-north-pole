class_name Chest
extends Node3D
## Gift chest dropped by elites and the boss. Walk into it to open: pick 1 of 3 items.

@export var open_distance: float = 1.2

@onready var body: Node3D = $Body


func _ready() -> void:
	add_to_group(&"chests")


func _process(delta: float) -> void:
	body.rotate_y(1.5 * delta)
	body.position.y = 0.08 + absf(sin(GameState.run_time * 4.0)) * 0.15  # hop to draw the eye
	var to_player: Vector3 = GameState.player.global_position - global_position
	if Vector2(to_player.x, to_player.z).length() < open_distance:
		GameState.add_chest()
		queue_free()
