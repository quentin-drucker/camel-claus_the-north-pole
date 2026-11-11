class_name Player
extends Node3D
## Claus. Moves on the ground plane with code (no physics body); stats change via upgrades.

signal health_changed(hp: float, max_hp: float)
signal died

@export var speed: float = 5.0
@export var max_hp: float = 100.0
@export var pickup_radius: float = 2.5
@export var body_radius: float = 0.4
## Invisible walls: the player can't leave this square around the origin.
@export var arena_half_size: float = 59.0

var hp: float
## ponytail: debug-only god mode for the stress test (F2); remove before ship.
var invincible: bool = false

@onready var gift_toss: GiftToss = $GiftToss


func _enter_tree() -> void:
	GameState.player = self


func _ready() -> void:
	hp = max_hp


func _process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += Vector3(input.x, 0.0, input.y) * speed * delta
	position.x = clampf(position.x, -arena_half_size, arena_half_size)
	position.z = clampf(position.z, -arena_half_size, arena_half_size)


func take_damage(amount: float) -> void:
	if hp <= 0.0 or invincible:
		return
	hp = maxf(hp - amount, 0.0)
	health_changed.emit(hp, max_hp)
	if hp == 0.0:
		died.emit()
		GameState.end_run(false)


func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.stat:
		UpgradeData.Stat.MOVE_SPEED:
			speed += upgrade.amount
		UpgradeData.Stat.MAX_HP:
			max_hp += upgrade.amount
			hp += upgrade.amount
			health_changed.emit(hp, max_hp)
		UpgradeData.Stat.PICKUP_RADIUS:
			pickup_radius += upgrade.amount
		_:
			gift_toss.apply_upgrade(upgrade)
