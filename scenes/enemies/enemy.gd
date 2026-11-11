class_name Enemy
extends Node3D
## One enemy. Movement is done in bulk by EnemySpawner; this holds HP and death.

const XP_ORNAMENT: PackedScene = preload("res://scenes/pickups/xp_ornament.tscn")

@export var data: EnemyData = preload("res://resources/enemies/chaser.tres")

var hp: float


func _enter_tree() -> void:
	GameState.enemies.append(self)


func _exit_tree() -> void:
	GameState.enemies.erase(self)


func _ready() -> void:
	hp = data.max_hp


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	if hp <= 0.0:
		_die()


func _die() -> void:
	GameState.enemies.erase(self)
	var ornament: XpOrnament = XP_ORNAMENT.instantiate()
	ornament.value = data.xp_value
	get_parent().add_child(ornament)
	ornament.global_position = Vector3(global_position.x, 0.0, global_position.z)
	queue_free()
