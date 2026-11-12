class_name EnemySnowball
extends Node3D
## A Snowball Lobber's throw, placed at the landing spot (where Claus stood when the wind-up began).
## Wind-up: a purple ring grows on the ground while the thrower stops and wobbles. Flight: the
## snowball arcs from the thrower's raised hands to the ring. On landing it hits Claus only if he's
## still inside the ring, so moving always dodges it. Killing the thrower during the wind-up cancels it.

## Enemy snowballs alive at once (wind-ups included); more throws wait.
const MAX_ALIVE: int = 30

static var alive: int = 0
## Snowballs that actually left a Lobber's hands (balance bot report).
static var launched: int = 0

@export var hit_radius: float = 1.0
@export var arc_height: float = 2.5

var thrower: Enemy
var damage: float = 12.0
var windup: float = 0.6
var flight: float = 1.0

var _t: float = 0.0
var _start: Vector3
var _thrown: bool = false

@onready var marker: Node3D = $Marker
@onready var body: Node3D = $Body


func _enter_tree() -> void:
	alive += 1


func _exit_tree() -> void:
	alive -= 1


func _ready() -> void:
	add_to_group(&"enemy_snowballs")
	body.hide()
	marker.scale = Vector3.ONE * hit_radius * 0.3
	thrower.speed_mult = 0.0


func _process(delta: float) -> void:
	_t += delta
	if not _thrown:
		if not is_instance_valid(thrower) or thrower.hp <= 0.0:
			queue_free()
			return
		marker.scale = Vector3.ONE * hit_radius * lerpf(0.3, 1.0, minf(_t / windup, 1.0))
		thrower.scale = Vector3.ONE * (1.0 + 0.07 * sin(_t * 40.0))  # telegraph wobble
		if _t < windup:
			return
		_thrown = true
		launched += 1
		thrower.scale = Vector3.ONE
		thrower.speed_mult = 1.0
		_start = thrower.global_position + Vector3.UP * 1.1
		body.show()
		Audio.play(&"lob")
	var k: float = minf((_t - windup) / flight, 1.0)
	var ground: Vector3 = global_position
	body.global_position = _start.lerp(ground + Vector3.UP * 0.1, k) + Vector3.UP * arc_height * 4.0 * k * (1.0 - k)
	body.rotate_x(6.0 * delta)
	marker.scale = Vector3.ONE * hit_radius * (1.0 + 0.06 * sin(_t * 18.0))
	if k < 1.0:
		return
	var player: Player = GameState.player
	var to_player: Vector3 = player.global_position - ground
	if Vector2(to_player.x, to_player.z).length() < hit_radius + player.body_radius:
		player.take_damage(damage)
	Poof.spawn(ground, Color("9B4FD1"), 6, 3.0)
	Poof.spawn(ground, Color("C9DAF0"), 6, 3.0)
	Audio.play(&"splash", 0.8)
	queue_free()
