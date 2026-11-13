class_name SantaPresent
extends Node3D
## Santa's present: falls from the sleigh, lands with a snow blast (pushes back, freezes and nicks
## every normal enemy within `blast_radius`, so the spot is safe to walk to), then hops and sparkles.
## Inside Claus's pickup reach, or after `home_after` seconds anyway, it flies to him; touching it
## opens the Santa's present menu (evolutions, or blessings when no weapon is Lv 5).

@export var fall_time: float = 0.6
@export var blast_radius: float = 4.0
@export var blast_damage: float = 10.0
@export var freeze_time: float = 1.5
@export var home_after: float = 3.0
@export var home_speed: float = 9.0
@export var collect_distance: float = 0.9

## World position it falls from (the sleigh).
var drop_from: Vector3

var _t: float = 0.0
var _landed: bool = false
var _homing: bool = false

@onready var body: Node3D = $Body


func _ready() -> void:
	add_to_group(&"santa_presents")
	body.position = drop_from - global_position


func _process(delta: float) -> void:
	_t += delta
	if not _landed:
		var k: float = minf(_t / fall_time, 1.0)
		body.position = (drop_from - global_position).lerp(Vector3.ZERO, k * k)
		if k >= 1.0:
			_land()
		return
	body.rotate_y(2.0 * delta)
	body.position.y = absf(sin(_t * 4.0)) * 0.2
	var player: Player = GameState.player
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < collect_distance:
		Poof.spawn(global_position, Color("F2B53B"), 18, 6.0)
		Poof.spawn(global_position, Color("3E9A5B"), 10, 4.0)
		GameState.add_santa_present()
		queue_free()
		return
	if _t > fall_time + home_after or dist < player.get_pickup_radius():
		_homing = true
	if _homing:
		global_position += to_player / dist * minf(home_speed * delta, dist)


func _land() -> void:
	_landed = true
	_t = fall_time
	var pos: Vector3 = global_position
	for enemy: Enemy in GameState.enemies.duplicate():
		var away: Vector3 = enemy.global_position - pos
		away.y = 0.0
		var d: float = away.length()
		if d > blast_radius + enemy.radius or enemy.is_boss:
			continue
		if not enemy.is_elite:
			enemy.global_position = pos + away / maxf(d, 0.01) * (blast_radius + 0.5)
		GameState.player.deal_damage(enemy, blast_damage, false, "Santa's Sleigh")
		enemy.freeze(freeze_time)
	Burst.spawn(Burst.ICE, pos, blast_radius)
	Burst.spawn(Burst.GOLD, pos, blast_radius * 0.5)
	Poof.spawn(pos, Color("F4F8FF"), 22, 6.0)
	Audio.play(&"splash", 0.7)
	get_tree().call_group(&"camera", &"shake", 0.3)
	add_child(Poof.trail(Color("F2B53B"), 8))
