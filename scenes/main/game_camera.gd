extends Camera3D
## Fixed-angle camera that follows the target without rotating. shake() adds a short, decaying
## jitter (trauma squared, so small hits stay subtle). Call via the "camera" group.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 13.93, 9.75)
## Max jitter in metres at full trauma.
@export var max_shake: float = 0.45
@export var shake_decay: float = 2.5

var _trauma: float = 0.0


func _ready() -> void:
	process_priority = 10  # move after the player each frame, so no lag/jitter
	add_to_group(&"camera")


func shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _process(delta: float) -> void:
	if not target:
		return
	_trauma = maxf(_trauma - shake_decay * delta, 0.0)
	var jitter: Vector3 = Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)) * max_shake * _trauma * _trauma
	global_position = target.global_position + offset + jitter
