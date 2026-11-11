extends Camera3D
## Fixed-angle camera that follows the target without rotating.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 13.93, 9.75)


func _ready() -> void:
	process_priority = 10  # move after the player each frame, so no lag/jitter


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + offset
