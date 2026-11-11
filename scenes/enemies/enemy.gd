class_name Enemy
extends Node3D
## One enemy. Movement is done in bulk by EnemySpawner; this holds HP, status effects and death.
## Elites (bigger, crowned) and the boss drop a gift chest.

const XP_ORNAMENT: PackedScene = preload("res://scenes/pickups/xp_ornament.tscn")
const CHEST: PackedScene = preload("res://scenes/pickups/chest.tscn")

const WADDLE: Shader = preload("res://assets/materials/enemy_waddle.gdshader")

## Looks: [tint, amount, waddle] per status. Each EnemyData gets one shared material per look.
const LOOKS: Dictionary = {
	&"normal": [Color(1, 1, 1), 0.0, 1.0],
	&"flash": [Color("F4F8FF"), 0.75, 1.0],
	&"frozen": [Color("7FD6F2"), 0.55, 0.0],
	&"poison": [Color("3E9A5B"), 0.4, 1.0],
}

## Shared materials: EnemyData -> {look name: ShaderMaterial} (or a greybox tint material).
static var _materials: Dictionary = {}

@export var data: EnemyData = preload("res://resources/enemies/chaser.tres")

var hp: float
var max_hp: float
## Ground-plane radius for hits and contact (data.radius x elite/boss size).
var radius: float
var contact_damage: float
var xp_value: int
var is_elite: bool = false
var is_boss: bool = false
## Multiplies data.speed; the boss uses it for its charge.
var speed_mult: float = 1.0
var poison_dps: float = 0.0
var poison_left: float = 0.0
var frozen_left: float = 0.0

var _size: float = 1.0
var _mesh_node: MeshInstance3D
var _look: StringName = &"normal"
var _flash_left: float = 0.0
var _charge_timer: float = 0.0


func _enter_tree() -> void:
	GameState.enemies.append(self)


func _exit_tree() -> void:
	GameState.enemies.erase(self)
	if GameState.boss == self:
		GameState.boss = null


## Call before add_child. `hp_mult` scales HP; `size_mult` scales look, radius and (for elites) rewards.
func setup(type: EnemyData, hp_mult: float, size_mult: float = 1.0, elite: bool = false, boss: bool = false) -> void:
	data = type
	is_elite = elite
	is_boss = boss
	_size = size_mult
	max_hp = data.max_hp * hp_mult
	hp = max_hp
	radius = data.radius * size_mult
	contact_damage = data.contact_damage * (1.5 if elite else 1.0)
	xp_value = data.xp_value * (10 if elite else 1)


func _ready() -> void:
	if max_hp == 0.0:  # placed without setup()
		setup(data, 1.0)
	var body: MeshInstance3D = $Body
	if data.model:
		body.queue_free()
		var model: Node3D = data.model.instantiate()
		model.scale = Vector3.ONE * data.size * _size
		add_child(model)
		_mesh_node = model.find_children("*", "MeshInstance3D", true, false)[0]
		if not _materials.has(data):
			var looks: Dictionary = {}
			for look: StringName in LOOKS:
				var material := ShaderMaterial.new()
				material.shader = WADDLE
				material.set_shader_parameter(&"albedo_tex", _mesh_node.mesh.surface_get_material(0).albedo_texture)
				# Bigger enemies waddle slower.
				material.set_shader_parameter(&"waddle_speed", 9.0 / maxf(data.radius * 2.5, 1.0))
				material.set_shader_parameter(&"tint", LOOKS[look][0])
				material.set_shader_parameter(&"tint_amount", LOOKS[look][1])
				material.set_shader_parameter(&"waddle", LOOKS[look][2])
				looks[look] = material
			_materials[data] = looks
		_mesh_node.material_override = _materials[data][&"normal"]
	else:
		body.scale = Vector3.ONE * data.size * _size
		body.position.y *= data.size * _size
		if not _materials.has(data):
			var material := StandardMaterial3D.new()
			material.albedo_color = data.color
			_materials[data] = material
		body.material_override = _materials[data]
	$BlobShadow.scale = Vector3.ONE * radius * 2.4
	$Crown.visible = is_elite
	$Crown.position.y = data.crown_height * data.size * _size
	$Crown.scale = Vector3.ONE * data.size * _size * 1.2
	set_process(is_boss)
	if is_boss:
		GameState.boss = self


func _process(delta: float) -> void:
	# Boss: walk 4 s, stop and wind up 0.7 s, then charge at 3.5x speed for 0.9 s.
	_charge_timer += delta
	if _charge_timer < 4.0:
		speed_mult = 1.0
	elif _charge_timer < 4.7:
		if speed_mult != 0.0:
			Audio.play(&"charge")
		speed_mult = 0.0
		scale = Vector3.ONE * (1.0 + 0.08 * sin(_charge_timer * 40.0))  # telegraph wobble
	elif _charge_timer < 5.6:
		speed_mult = 3.5
		scale = Vector3.ONE
	else:
		_charge_timer = 0.0


## Called by EnemySpawner every frame: swap to the material for the current status (only on change).
func update_look(delta: float) -> void:
	_flash_left -= delta
	if _mesh_node == null:
		return
	var look: StringName = &"normal"
	if _flash_left > 0.0:
		look = &"flash"
	elif frozen_left > 0.0:
		look = &"frozen"
	elif poison_left > 0.0:
		look = &"poison"
	if look != _look:
		_look = look
		_mesh_node.material_override = _materials[data][look]


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	_flash_left = 0.07
	hp -= amount
	if hp <= 0.0:
		_die()


func poison(dps: float, duration: float) -> void:
	poison_dps += dps
	poison_left = duration


func freeze(duration: float) -> void:
	if not is_boss:
		frozen_left = maxf(frozen_left, duration)


func _die() -> void:
	GameState.enemies.erase(self)
	GameState.kills += 1
	Audio.play(&"pop")
	var big: bool = is_elite or is_boss
	Poof.spawn(global_position, Color("F4F8FF"), 16 if big else 6, 5.0 if big else 3.0)
	if big:
		get_tree().call_group(&"camera", &"shake", 0.6 if is_boss else 0.35)
	var drops: int = 12 if is_boss else 1
	for i in drops:
		var ornament: XpOrnament = XP_ORNAMENT.instantiate()
		ornament.value = xp_value if not is_boss else 8
		get_parent().add_child(ornament)
		var scatter: Vector3 = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * (1.5 if is_boss else 0.0)
		ornament.global_position = Vector3(global_position.x, 0.0, global_position.z) + scatter
	if is_elite or is_boss:
		var chest: Node3D = CHEST.instantiate()
		get_parent().add_child(chest)
		chest.global_position = Vector3(global_position.x, 0.0, global_position.z)
	queue_free()
