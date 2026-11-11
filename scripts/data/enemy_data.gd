class_name EnemyData
extends Resource

@export var display_name: String = "Chaser"
@export var max_hp: float = 10.0
@export var speed: float = 3.6
## Damage per hit on the player (the player is briefly invulnerable after each hit).
@export var contact_damage: float = 10.0
@export var xp_value: int = 1
## Ground-plane radius used for hits, contact and separation.
@export var radius: float = 0.4

@export_group("Spawning")
## Run time (seconds) before this type starts spawning.
@export var spawn_after: float = 0.0
## Relative chance among the types that are unlocked.
@export var spawn_weight: float = 1.0

@export_group("Look")
## Wrapper scene of the baked model (e.g. chaser_model.tscn). Empty = tinted greybox capsule.
@export var model: PackedScene
## Capsule tint when there's no model.
@export var color: Color = Color("9b4fd1")
## Uniform scale of the model or capsule.
@export var size: float = 1.0
