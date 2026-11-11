class_name Player
extends Node3D
## Claus. Moves on the ground plane with code (no physics body).
## Holds the global stats that upgrades raise; every weapon reads them.

signal health_changed(hp: float, max_hp: float)
signal died

@export var base_speed: float = 5.0
@export var max_hp: float = 100.0
@export var base_pickup_radius: float = 2.5
@export var body_radius: float = 0.4
## Seconds of invulnerability after taking a hit (Claus blinks meanwhile).
@export var hurt_invulnerability: float = 0.75
## Invisible walls: the player can't leave this square around the origin.
@export var arena_half_size: float = 59.0

var hp: float
## Ground-plane velocity this frame (the spawner uses it to recycle enemies ahead of Claus).
var velocity: Vector3 = Vector3.ZERO
## Global stats raised by upgrades (Megabonk-"tome" style: shared by all weapons).
var damage_mult: float = 1.0
var attack_speed_bonus: float = 0.0
var extra_projectiles: int = 0
var move_speed_bonus: float = 0.0
var pickup_bonus: float = 0.0
## UpgradeData -> times picked, for level caps.
var upgrade_levels: Dictionary = {}
## ponytail: debug-only god mode for the stress test (F2); remove before ship.
var invincible: bool = false

var _invulnerable_left: float = 0.0

@onready var body: MeshInstance3D = $Body


func _enter_tree() -> void:
	GameState.player = self


func _ready() -> void:
	hp = max_hp


func _process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector3(input.x, 0.0, input.y) * base_speed * (1.0 + move_speed_bonus)
	position += velocity * delta
	position.x = clampf(position.x, -arena_half_size, arena_half_size)
	position.z = clampf(position.z, -arena_half_size, arena_half_size)
	if _invulnerable_left > 0.0:
		_invulnerable_left -= delta
		body.visible = _invulnerable_left <= 0.0 or fmod(_invulnerable_left, 0.1) < 0.05


func get_pickup_radius() -> float:
	return base_pickup_radius * (1.0 + pickup_bonus)


func take_damage(amount: float) -> void:
	if hp <= 0.0 or invincible or _invulnerable_left > 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_invulnerable_left = hurt_invulnerability
	health_changed.emit(hp, max_hp)
	if hp == 0.0:
		died.emit()
		GameState.end_run(false)


func upgrade_level(upgrade: UpgradeData) -> int:
	return upgrade_levels.get(upgrade, 0)


func apply_upgrade(upgrade: UpgradeData, rarity_mult: float = 1.0) -> void:
	upgrade_levels[upgrade] = upgrade_level(upgrade) + 1
	var amount: float = upgrade.amount * (rarity_mult if upgrade.scales_with_rarity else 1.0)
	match upgrade.stat:
		UpgradeData.Stat.MOVE_SPEED:
			move_speed_bonus += amount
		UpgradeData.Stat.MAX_HP:
			max_hp += amount
			hp += amount
			health_changed.emit(hp, max_hp)
		UpgradeData.Stat.PICKUP_RADIUS:
			pickup_bonus += amount
		UpgradeData.Stat.DAMAGE:
			damage_mult += amount
		UpgradeData.Stat.ATTACK_SPEED:
			attack_speed_bonus += amount
		UpgradeData.Stat.PROJECTILES:
			extra_projectiles += int(amount)
