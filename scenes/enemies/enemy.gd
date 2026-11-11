class_name Enemy
extends Node3D
## One enemy. Movement is done in bulk by EnemySpawner; this holds HP and death.

const XP_ORNAMENT: PackedScene = preload("res://scenes/pickups/xp_ornament.tscn")

## One shared greybox material per EnemyData, so enemies of a type don't each get a copy.
static var _materials: Dictionary = {}

@export var data: EnemyData = preload("res://resources/enemies/chaser.tres")

var hp: float


func _enter_tree() -> void:
	GameState.enemies.append(self)


func _exit_tree() -> void:
	GameState.enemies.erase(self)


func _ready() -> void:
	hp = data.max_hp
	var body: MeshInstance3D = $Body
	body.scale = Vector3.ONE * data.size
	body.position.y *= data.size
	if not _materials.has(data):
		var material := StandardMaterial3D.new()
		material.albedo_color = data.color
		_materials[data] = material
	body.material_override = _materials[data]


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp -= amount
	if hp <= 0.0:
		_die()


func _die() -> void:
	GameState.enemies.erase(self)
	GameState.kills += 1
	var ornament: XpOrnament = XP_ORNAMENT.instantiate()
	ornament.value = data.xp_value
	get_parent().add_child(ornament)
	ornament.global_position = Vector3(global_position.x, 0.0, global_position.z)
	queue_free()
