class_name GiftProjectile
extends Node3D
## Flies straight; hits the first enemy it touches (or the first 1 + `pierce` enemies).
## Evolved (Present Barrage): gold-wrapped model, sparkle trail, gold pop on each hit.

const EVO_MODEL: PackedScene = preload("res://scenes/weapons/gift_evo_model.tscn")

@export var lifetime: float = 1.5
@export var hit_radius: float = 0.3
## Radians per second the gift tumbles while flying.
@export var spin_speed: float = 9.0

var direction: Vector3 = Vector3.FORWARD
var speed: float = 14.0
var damage: float = 5.0
## Extra enemies this gift can pass through.
var pierce: int = 0
var evolved: bool = false

var _already_hit: Array[Enemy] = []

@onready var body: Node3D = $Body


func _ready() -> void:
	if not evolved:
		return
	var old: Node3D = body
	body = EVO_MODEL.instantiate()
	body.position = old.position
	add_child(body)
	old.queue_free()
	var trail := CPUParticles3D.new()
	trail.amount = 6
	trail.lifetime = 0.3
	trail.local_coords = false
	trail.mesh = Poof.cube_mesh()
	trail.color = Color("F2B53B")
	trail.direction = Vector3.UP
	trail.spread = 180.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.6
	trail.gravity = Vector3.ZERO
	trail.scale_amount_min = 0.3
	trail.scale_amount_max = 0.6
	add_child(trail)


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
			if evolved:
				Burst.spawn(Burst.GOLD, e_pos, 0.7)
			if _already_hit.size() > pierce:
				queue_free()
			return
