class_name GiftProjectile
extends Node3D
## Flies straight; hits the first enemy it touches (or the first 1 + `pierce` enemies).
## Evolved (Present Barrage): gold-wrapped model, sparkle trail, gold pop on each hit.
## Other weapons reuse it with their own `body_scene` (Peppermint Cyclone's flung canes).

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
## Replaces the gift model (scaled by `body_scale`); empty = the gift.
var body_scene: PackedScene
var body_scale: float = 1.0
## Sparkle trail color; alpha 0 = no trail.
var trail_color: Color = Color(0, 0, 0, 0)
## Ring flashed on each hit; null = none.
var hit_burst: Mesh

var _already_hit: Array[Enemy] = []

@onready var body: Node3D = $Body


func _ready() -> void:
	if evolved:
		body_scene = EVO_MODEL
		trail_color = Color("F2B53B")
		hit_burst = Burst.GOLD
	if body_scene:
		var old: Node3D = body
		body = body_scene.instantiate()
		body.position = old.position
		body.scale = Vector3.ONE * body_scale
		add_child(body)
		old.queue_free()
	if trail_color.a > 0.0:
		add_child(Poof.trail(trail_color))


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
			if hit_burst:
				Burst.spawn(hit_burst, e_pos, 0.7)
			if _already_hit.size() > pierce:
				queue_free()
			return
