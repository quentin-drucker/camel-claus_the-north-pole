class_name WeaponData
extends Resource

@export var display_name: String = "Gift Toss"
@export var damage: float = 5.0
## Seconds between attacks (divided by 1 + the player's attack speed bonus).
@export var cooldown: float = 0.8
@export var projectile_speed: float = 14.0
## Projectiles / canes / pulses per attack before bonuses.
@export var projectile_count: int = 1
## Only targets enemies within this distance (also the pulse/orbit radius for area weapons).
@export var attack_range: float = 14.0

@export_group("Levels")
## Extra damage per weapon level above 1 (0.25 = +25% per level).
@export var level_damage_bonus: float = 0.25
## +1 projectile at every this-many levels (0 = never).
@export var count_every_levels: int = 2

@export_group("Evolution")
## Owning this item while the weapon is level 5 offers the evolution in a chest.
@export var evolution_item: ItemData
@export var evolved_name: String = ""
@export var evolved_description: String = ""
@export var evolved_damage_mult: float = 1.5
