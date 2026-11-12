class_name SnowballShell
extends Node3D
## One lobbed snowball: flies a parabola from `start` to `target` in `flight_time`, then splashes
## every enemy within `splash_radius`. Its blob shadow slides along the ground under it (the landing
## spot). With `fragments` > 0 (Avalanche) it bursts into that many small snowballs that hop outward.

@export var arc_height: float = 3.0
@export var fragment_hop: float = 2.4

var start: Vector3
var target: Vector3
var flight_time: float = 0.65
var damage: float = 10.0
var splash_radius: float = 1.6
## Visual scale (Avalanche 1.4, fragments 0.6).
var size: float = 1.0
var fragments: int = 0
var fragment_damage: float = 0.4

var _t: float = 0.0

@onready var body: Node3D = $Body
@onready var shadow: Node3D = $BlobShadow


func _ready() -> void:
	body.scale *= size
	shadow.scale *= size
	global_position = start


func _process(delta: float) -> void:
	_t += delta
	var k: float = minf(_t / flight_time, 1.0)
	var ground: Vector3 = start.lerp(target, k)
	ground.y = 0.0
	global_position = ground
	body.position.y = lerpf(start.y, 0.2, k) + arc_height * size * 4.0 * k * (1.0 - k)
	body.rotate_x(8.0 * delta)
	if k >= 1.0:
		_splash()


func _splash() -> void:
	var pos: Vector3 = global_position
	for enemy: Enemy in GameState.enemies.duplicate():
		var e_pos: Vector3 = enemy.global_position
		var reach: float = splash_radius + enemy.radius
		if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() < reach * reach:
			GameState.player.deal_damage(enemy, damage)
	if size >= 1.0:  # fragments only puff: a ring each would blanket the screen with Avalanche
		Burst.spawn(Burst.ICE, pos, splash_radius)
	Poof.spawn(pos, Color("F4F8FF"), 8 if size >= 1.0 else 4, 3.5 * size)
	Audio.play(&"splash", 1.0 / sqrt(size))
	if fragments > 0:
		var scene: PackedScene = load(scene_file_path)
		var turn: float = randf() * TAU
		for i in fragments:
			var piece: SnowballShell = scene.instantiate()
			var dir: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, turn + TAU * i / fragments)
			piece.start = pos + Vector3.UP * 0.4
			piece.target = pos + dir * fragment_hop
			piece.flight_time = 0.4
			piece.arc_height = 1.0
			piece.damage = damage * fragment_damage
			piece.splash_radius = splash_radius * 0.55
			piece.size = 0.6
			get_parent().add_child(piece)
		get_tree().call_group(&"camera", &"shake", 0.06)
	queue_free()
