class_name Pickup
extends Node3D
## A ground pickup (Christmas Magnet, Cookies & Milk, Snow Bomb) configured by a PickupData.
## Bobs and spins so it stands out from XP; flies to Claus inside his pickup reach like XP does;
## blinks during its last seconds, then melts away. Enemy._die() calls try_drop().

const DROPS: Array[PickupData] = [
	preload("res://resources/pickups/christmas_magnet.tres"),
	preload("res://resources/pickups/cookies_milk.tres"),
	preload("res://resources/pickups/snow_bomb.tres"),
]
const SCENE_PATH: String = "res://scenes/pickups/pickup.tscn"

## PickupData -> run time of its last drop (per-kind cooldown).
static var _last_drop: Dictionary = {}

@export var collect_distance: float = 0.7
@export var lifetime: float = 40.0
@export var attract_speed: float = 10.0
## Enemies get this much damage from a Snow Bomb as a fraction of max HP if elite or boss.
@export var bomb_big_damage: float = 0.1

var data: PickupData

var _age: float = 0.0
var _attracted: bool = false
var _body: Node3D


## Roll every kind once per kill; at most one pickup per kill.
static func try_drop(pos: Vector3, parent: Node) -> void:
	var now: float = GameState.run_time
	for kind in DROPS:
		var last: float = _last_drop.get(kind, -999.0)
		if last > now:  # left over from an earlier run
			last = -999.0
		if now - last < kind.cooldown or randf() >= kind.drop_chance:
			continue
		_last_drop[kind] = now
		var pickup: Pickup = (load(SCENE_PATH) as PackedScene).instantiate()
		pickup.data = kind
		parent.add_child(pickup)
		pickup.global_position = Vector3(pos.x, 0.0, pos.z)
		return


func _ready() -> void:
	add_to_group(&"pickups")
	_body = data.model.instantiate()
	add_child(_body)


func _process(delta: float) -> void:
	_age += delta
	if _age > lifetime:
		Poof.spawn(global_position, Color("C9DAF0"), 6, 2.0)
		queue_free()
		return
	_body.rotate_y(1.8 * delta)
	_body.position.y = 0.15 + absf(sin(_age * 3.0)) * 0.2
	_body.visible = _age < lifetime - 5.0 or fmod(_age, 0.3) < 0.2
	var player: Player = GameState.player
	if data.kind == PickupData.Kind.HEAL and player.hp >= player.max_hp:
		return  # keep the cookies for when Claus is hurt
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	if dist < collect_distance:
		_apply(player)
		queue_free()
		return
	if dist < player.get_pickup_radius():
		_attracted = true
	if _attracted:
		global_position += to_player / dist * minf(attract_speed * delta, dist)


func _apply(player: Player) -> void:
	var pos: Vector3 = player.global_position
	match data.kind:
		PickupData.Kind.MAGNET:
			get_tree().call_group(&"xp_ornaments", &"attract")
			Audio.play(&"magnet")
			Burst.spawn(Burst.GOLD, pos, 6.0)
			Poof.spawn(pos, Color("F2B53B"), 14, 5.0)
		PickupData.Kind.HEAL:
			player.heal(player.max_hp * data.amount)
			Audio.play(&"heal")
			Poof.spawn(pos, Color("D9343F"), 10, 3.0)
			Poof.spawn(pos, Color("F4F8FF"), 8, 3.0)
		PickupData.Kind.BOMB:
			_snow_bomb(pos)


func _snow_bomb(pos: Vector3) -> void:
	var reach: float = data.amount
	for enemy: Enemy in GameState.enemies.duplicate():
		var d: float = enemy.global_position.distance_to(pos)
		if d < reach + enemy.radius:
			var big: bool = enemy.is_elite or enemy.is_boss
			# deal_damage only scales damage up, so hp * 1.01 always pops a normal enemy.
			GameState.player.deal_damage(enemy, enemy.max_hp * bomb_big_damage if big else enemy.hp * 1.01, false, "Snow bomb")
			enemy.freeze(2.0)
		elif d < reach * 1.5:
			enemy.freeze(2.0)
	Burst.spawn(Burst.ICE, pos, reach)
	Burst.spawn(Burst.ICE, pos, reach * 1.5)
	Poof.spawn(pos, Color("F4F8FF"), 24, 7.0)
	Audio.play(&"explode", 0.8)
	Audio.play(&"freeze")
	get_tree().call_group(&"camera", &"shake", 0.5)
