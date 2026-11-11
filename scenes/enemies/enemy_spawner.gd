extends Node3D
## Spawns enemies in a ring around the player and moves all of them in one loop:
## chase the player, push apart from neighbours (spatial grid), deal contact damage.

const ENEMY: PackedScene = preload("res://scenes/enemies/enemy.tscn")

@export var enemy_data: EnemyData = preload("res://resources/enemies/chaser.tres")
## Distance from the player where enemies appear (just outside the camera view).
@export var spawn_radius: float = 18.0
## Enemies per second at the start and at the end of the run (linear ramp).
@export var spawn_rate_start: float = 1.0
@export var spawn_rate_end: float = 8.0
## Enemy HP multiplier grows from 1 to 1 + hp_growth over the run.
@export var hp_growth: float = 2.0
@export var max_enemies: int = 400
## Enemies closer than this push each other apart.
@export var separation_radius: float = 0.8
@export var separation_strength: float = 8.0
@export var stress_test_count: int = 300

var _spawn_budget: float = 0.0


func _process(delta: float) -> void:
	if not GameState.is_running:
		return
	var progress: float = GameState.run_time / GameState.RUN_LENGTH
	_spawn_budget += lerpf(spawn_rate_start, spawn_rate_end, progress) * delta
	while _spawn_budget >= 1.0:
		_spawn_budget -= 1.0
		if GameState.enemies.size() < max_enemies:
			_spawn(progress)
	_move_enemies(delta)


func _unhandled_input(event: InputEvent) -> void:
	# ponytail: debug stress test for the 300-enemy performance gate; remove before ship.
	if event.is_action_pressed("debug_stress_test"):
		GameState.player.invincible = true
		for i in stress_test_count:
			_spawn(0.0)


func _spawn(progress: float) -> void:
	var enemy: Enemy = ENEMY.instantiate()
	enemy.data = enemy_data
	add_child(enemy)
	enemy.hp *= 1.0 + hp_growth * progress
	var angle: float = randf() * TAU
	enemy.global_position = GameState.player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * spawn_radius


func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / separation_radius), floori(pos.z / separation_radius))


func _move_enemies(delta: float) -> void:
	var player: Player = GameState.player
	var player_pos: Vector3 = player.global_position
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

	var min_dist_sq: float = separation_radius * separation_radius
	for enemy in GameState.enemies:
		var pos: Vector3 = positions[enemy]
		var to_player: Vector3 = Vector3(player_pos.x - pos.x, 0.0, player_pos.z - pos.z)
		var dist: float = to_player.length()
		var velocity: Vector3 = to_player / maxf(dist, 0.001) * enemy.data.speed
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
		if dist < enemy.data.radius + player.body_radius:
			player.take_damage(enemy.data.contact_damage * delta)
