class_name CandyCaneOrbit
extends Weapon
## Candy canes circle Claus and smack every enemy they pass (each enemy at most every `rehit_time`).
## Spins faster with attack speed; one cane per count(). The orbit radius grows a little per level.
## Evolved (Peppermint Cyclone): a wider, faster ring of big canes with candy trails; every cooldown()
## each cane flings straight outward through enemies (pierce) and regrows on the ring.

const CANE: PackedScene = preload("res://scenes/weapons/candy_cane_model.tscn")
const PROJECTILE: PackedScene = preload("res://scenes/weapons/gift_projectile.tscn")

## Radians per second at +0% attack speed.
@export var spin_speed: float = 2.6
@export var evolved_spin_mult: float = 1.5
@export var hit_radius: float = 0.5
@export var rehit_time: float = 0.5
@export var cane_scale: float = 1.5
@export var evolved_cane_scale: float = 2.1
## Seconds a flung cane takes to grow back on the ring.
@export var regrow_time: float = 0.7

var _angle: float = 0.0
var _canes: Array[Node3D] = []
var _last_hit: Dictionary = {}  # enemy instance id -> run time of last hit
var _fling_left: float = 1.0
var _regrow: Array[float] = []  # per cane: seconds until it's back (it doesn't hit meanwhile)


func _init() -> void:
	data = preload("res://resources/weapons/candy_cane_orbit.tres")


func _ready() -> void:
	evolved_changed.connect(func() -> void:
		for cane in _canes:
			cane.queue_free()
		_canes.clear())  # rebuilt bigger, with trails, next frame


func _process(delta: float) -> void:
	_sync_canes()
	var spin: float = spin_speed * (evolved_spin_mult if evolved else 1.0)
	_angle += spin * (1.0 + GameState.player.attack_speed_bonus) * delta
	var now: float = GameState.run_time
	if _last_hit.size() > 600:  # ponytail: forget dead enemies in bulk instead of tracking frees
		_last_hit.clear()
	var dmg: float = damage()
	var orbit: float = radius()
	var full_scale: float = evolved_cane_scale if evolved else cane_scale
	for i in _canes.size():
		var a: float = _angle + TAU * i / _canes.size()
		var cane: Node3D = _canes[i]
		cane.position = Vector3(cos(a), 0.0, sin(a)) * orbit
		cane.rotation.y = -a  # hook leads the swing
		if _regrow[i] > 0.0:
			_regrow[i] -= delta
			cane.scale = Vector3.ONE * full_scale * clampf(1.0 - _regrow[i] / regrow_time, 0.05, 1.0)
			continue
		cane.scale = Vector3.ONE * full_scale
		var pos: Vector3 = cane.global_position
		for enemy: Enemy in GameState.enemies.duplicate():
			var reach: float = enemy.radius + hit_radius * (full_scale / cane_scale)
			var e_pos: Vector3 = enemy.global_position
			if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() > reach * reach:
				continue
			var id: int = enemy.get_instance_id()
			if now - _last_hit.get(id, -99.0) >= rehit_time:
				_last_hit[id] = now
				GameState.player.deal_damage(enemy, dmg)
	if evolved:
		_fling_left -= delta
		if _fling_left <= 0.0:
			_fling_left = cooldown()
			_fling(dmg)


func _sync_canes() -> void:
	var wanted: int = count()
	while _canes.size() < wanted:
		var cane: Node3D = CANE.instantiate()
		add_child(cane)
		if evolved:
			cane.add_child(Poof.trail(Color("D9343F"), 4))
		_canes.append(cane)
		_regrow.append(0.0)
	while _canes.size() > wanted:
		_canes.pop_back().queue_free()
		_regrow.pop_back()


## Every cane on the ring shoots straight out, piercing, then regrows.
func _fling(dmg: float) -> void:
	Audio.play(&"throw", 0.8)
	for i in _canes.size():
		if _regrow[i] > 0.0:
			continue
		var cane: Node3D = _canes[i]
		var out: Vector3 = cane.position.normalized()
		var projectile: GiftProjectile = PROJECTILE.instantiate()
		projectile.direction = out
		projectile.speed = data.projectile_speed
		projectile.damage = dmg
		projectile.pierce = data.evolved_pierce
		projectile.lifetime = 1.0
		projectile.hit_radius = 0.5
		projectile.body_scene = CANE
		projectile.body_scale = evolved_cane_scale
		projectile.trail_color = Color("F4F8FF")
		projectile.hit_burst = Burst.RED
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = cane.global_position
		_regrow[i] = regrow_time
