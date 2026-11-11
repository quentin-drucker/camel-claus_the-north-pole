class_name WeaponData
extends Resource

@export var display_name: String = "Gift Toss"
@export var damage: float = 5.0
## Seconds between volleys.
@export var cooldown: float = 0.8
@export var projectile_speed: float = 14.0
@export var projectile_count: int = 1
## Only targets enemies within this distance.
@export var attack_range: float = 14.0
