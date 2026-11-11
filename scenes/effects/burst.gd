class_name Burst
extends MeshInstance3D
## A flat ring that expands and fades out, then frees itself (pulses, explosions).

const GOLD: Mesh = preload("res://assets/materials/burst_gold_mesh.tres")
const RED: Mesh = preload("res://assets/materials/burst_red_mesh.tres")

@export var duration: float = 0.35

var radius: float = 3.0


static func spawn(ring: Mesh, pos: Vector3, ring_radius: float) -> void:
	var burst := Burst.new()
	burst.mesh = ring
	burst.radius = ring_radius
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(burst)
	burst.global_position = Vector3(pos.x, 0.05, pos.z)


func _ready() -> void:
	scale = Vector3.ONE * 0.2
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3.ONE * radius * 2.0, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "transparency", 1.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
