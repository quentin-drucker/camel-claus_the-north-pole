extends Node3D
## Spawns enemies in a ring around the player and moves all of them in one loop:
## chase the player, push apart from neighbours (spatial grid), deal contact damage, tick poison
## and freeze. Difficulty grows on exponential curves; elites, the boss and a final surge are the
## fixed beats of the five-minute arc (docs/PLAN.md).

const ENEMY: PackedScene = preload("res://scenes/enemies/enemy.tscn")

## Enemy types; each unlocks at its own `spawn_after` time and is picked by `spawn_weight`.
@export var enemy_types: Array[EnemyData] = [
	preload("res://resources/enemies/chaser.tres"),
	preload("res://resources/enemies/zoomer.tres"),
	preload("res://resources/enemies/chonk.tres"),
]
## Distance from the player where enemies appear (just outside the camera view).
@export var spawn_radius: float = 18.0
## Enemies this far from the player are moved back to the ring, ahead of where Claus is going.
@export var recycle_distance: float = 30.0
## Enemies per second at 0:00; doubles every `spawn_rate_doubling_time` seconds.
@export var spawn_rate_start: float = 1.0
@export var spawn_rate_doubling_time: float = 130.0
## Enemy HP doubles every this many seconds (x4.9 by 5:00 at 130 s).
@export var hp_doubling_time: float = 130.0
@export var max_enemies: int = 400
## Enemies closer than this push each other apart.
@export var separation_radius: float = 0.8
@export var separation_strength: float = 8.0
@export var stress_test_count: int = 300

@export_group("Beats")
## Run times (s) when an elite spawns; it drops a gift chest.
@export var elite_times: Array[float] = [60.0, 120.0, 180.0, 240.0]
@export var elite_hp_mult: float = 15.0
@export var elite_size: float = 1.6
@export var boss_data: EnemyData = preload("res://resources/enemies/yeti.tres")
@export var boss_time: float = 255.0
## From this time on, spawn rate is multiplied by `surge_mult`.
@export var surge_time: float = 270.0
@export var surge_mult: float = 2.0

var _spawn_budget: float = 0.0
var _next_elite: int = 0
var _boss_spawned: bool = false


func _process(delta: float) -> void:
	if not GameState.is_running:
		return
	var t: float = GameState.run_time
	var hp_mult: float = pow(2.0, t / hp_doubling_time)
	var rate: float = spawn_rate_start * pow(2.0, t / spawn_rate_doubling_time)
	if t >= surge_time:
		rate *= surge_mult
	_spawn_budget += rate * delta
	while _spawn_budget >= 1.0:
		_spawn_budget -= 1.0
		if GameState.enemies.size() < max_enemies:
			_spawn(_pick_type(t), hp_mult)
	if _next_elite < elite_times.size() and t >= elite_times[_next_elite]:
		_next_elite += 1
		_spawn(_pick_type(t), hp_mult * elite_hp_mult, elite_size, true)
	if not _boss_spawned and t >= boss_time:
		_boss_spawned = true
		_spawn(boss_data, 1.0, 1.0, false, true)
		Audio.play(&"boss")
		Audio.duck(2.0)
		get_tree().call_group(&"camera", &"shake", 0.5)
	_move_enemies(delta)


func _unhandled_input(event: InputEvent) -> void:
	# ponytail: debug keys (F2 stress test, F3 skip 30 s); remove before ship.
	if event.is_action_pressed("debug_skip_time"):
		GameState.run_time += 30.0
	if event.is_action_pressed("debug_stress_test"):
		GameState.player.invincible = true
		for i in stress_test_count:
			_spawn(enemy_types[0], 1.0)


func _pick_type(t: float) -> EnemyData:
	var unlocked: Array[EnemyData] = enemy_types.filter(
		func(d: EnemyData) -> bool: return t >= d.spawn_after and d.spawn_weight > 0.0
	)
	var roll: float = randf() * unlocked.reduce(func(sum: float, d: EnemyData) -> float: return sum + d.spawn_weight, 0.0)
	for d in unlocked:
		roll -= d.spawn_weight
		if roll <= 0.0:
			return d
	return unlocked[0]


func _spawn(type: EnemyData, hp_mult: float, size_mult: float = 1.0, elite: bool = false, boss: bool = false) -> void:
	var enemy: Enemy = ENEMY.instantiate()
	enemy.setup(type, hp_mult, size_mult, elite, boss)
	add_child(enemy)
	enemy.global_position = _ring_position(randf() * TAU)


func _ring_position(angle: float) -> Vector3:
	return GameState.player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * spawn_radius


func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / separation_radius), floori(pos.z / separation_radius))


func _move_enemies(delta: float) -> void:
	var player: Player = GameState.player
	var player_pos: Vector3 = player.global_position
	var heading: float = atan2(player.velocity.z, player.velocity.x)
	var moving: bool = player.velocity.length_squared() > 0.01
	var positions: Dictionary = {}  # Enemy -> Vector3, read once per frame
	var grid: Dictionary = {}  # Vector2i cell -> Array of enemies in it
	for enemy in GameState.enemies:
		var pos: Vector3 = enemy.global_position
		positions[enemy] = pos
		var cell: Vector2i = _cell(pos)
		if grid.has(cell):
			grid[cell].append(enemy)
		else:
			grid[cell] = [enemy]

	var poisoned: Array[Enemy] = []
	var min_dist_sq: float = separation_radius * separation_radius
	for enemy in GameState.enemies:
		enemy.update_look(delta)
		if enemy.poison_left > 0.0:
			enemy.poison_left -= delta
			poisoned.append(enemy)
		if enemy.frozen_left > 0.0:
			enemy.frozen_left -= delta
			continue
		var pos: Vector3 = positions[enemy]
		var to_player: Vector3 = Vector3(player_pos.x - pos.x, 0.0, player_pos.z - pos.z)
		var dist: float = to_player.length()
		if dist > recycle_distance and not enemy.is_boss:
			var angle: float = heading + randf_range(-1.0, 1.0) if moving else randf() * TAU
			enemy.global_position = _ring_position(angle)
			continue
		var velocity: Vector3 = to_player / maxf(dist, 0.001) * enemy.data.speed * enemy.speed_mult
		var push: Vector3 = Vector3.ZERO
		var cell: Vector2i = _cell(pos)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				for other in grid.get(cell + Vector2i(dx, dz), []):
					if other == enemy:
						continue
					var away: Vector3 = pos - positions[other]
					var d_sq: float = away.length_squared()
					if d_sq < min_dist_sq and d_sq > 0.0001:
						var d: float = sqrt(d_sq)
						push += away / d * (separation_radius - d)
		enemy.global_position = pos + (velocity + push * separation_strength) * delta
		enemy.rotation.y = atan2(-to_player.x, -to_player.z)  # models face -Z: look at Claus
		if dist < enemy.radius + player.body_radius:
			player.take_damage(enemy.contact_damage)

	# Poison after the loop: a death erases the enemy from GameState.enemies.
	for enemy in poisoned:
		enemy.take_damage(enemy.poison_dps * delta)
		if enemy.poison_left <= 0.0:
			enemy.poison_dps = 0.0
