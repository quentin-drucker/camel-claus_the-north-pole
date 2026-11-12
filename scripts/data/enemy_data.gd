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
## Relative chance among the types that are unlocked (0 = never spawns randomly, e.g. the boss).
@export var spawn_weight: float = 1.0
## Most of this type alive at once (0 = no limit). Keeps ranged enemies from turning into bullet hell.
@export var max_alive: int = 0

@export_group("Ranged")
## Stops walking in at this distance from Claus and backs off when closer (0 = melee, walks in).
@export var keep_distance: float = 0.0
## Seconds between lobbed snowballs (0 = no ranged attack).
@export var throw_interval: float = 0.0
## Only throws when Claus is this close.
@export var throw_range: float = 11.0
@export var throw_damage: float = 12.0
## Wind-up before the snowball leaves (the landing ring shows meanwhile) and its flight time.
@export var throw_windup: float = 0.6
@export var throw_flight: float = 1.0

@export_group("Look")
## Wrapper scene of the baked model (e.g. chaser_model.tscn). Empty = tinted greybox capsule.
@export var model: PackedScene
## Capsule tint when there's no model.
@export var color: Color = Color("9b4fd1")
## Uniform scale of the model or capsule.
@export var size: float = 1.0
## Height of the top of the head at size 1 (where an elite's crown sits).
@export var crown_height: float = 0.75
