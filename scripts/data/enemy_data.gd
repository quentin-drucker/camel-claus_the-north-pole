class_name EnemyData
extends Resource

@export var display_name: String = "Chaser"
@export var max_hp: float = 10.0
@export var speed: float = 3.0
## Damage per second while touching the player.
@export var contact_damage: float = 10.0
@export var xp_value: int = 1
## Ground-plane radius used for hits, contact and separation.
@export var radius: float = 0.4
