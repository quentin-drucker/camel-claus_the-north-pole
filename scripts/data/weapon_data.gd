class_name WeaponData
extends Resource
## Weapon stats + the formulas that turn them into in-game numbers. Gameplay (Weapon) and the UI
## (cards, pause menu) both call these, so what the player reads is what the game does.

const MAX_LEVEL: int = 5

@export var display_name: String = "Gift Toss"
@export var damage: float = 5.0
## Seconds between attacks (divided by 1 + the player's attack speed bonus).
@export var cooldown: float = 0.8
@export var projectile_speed: float = 14.0
## Projectiles / canes per attack before bonuses.
@export var projectile_count: int = 1
## Targeting range, or the orbit / pulse radius for area weapons.
@export var attack_range: float = 14.0
## Word for one projectile in UI text ("gift", "cane"); empty = no count shown (area weapons).
@export var count_noun: String = ""
## Show `attack_range` as a radius in UI text (orbit / pulse weapons).
@export var show_radius: bool = false
## Show the attack interval in UI text (off for always-on weapons like the orbit).
@export var show_cooldown: bool = true

@export_group("Levels")
## Extra damage per weapon level above 1 (0.25 = +25% per level).
@export var level_damage_bonus: float = 0.25
## +1 projectile at every this-many levels (0 = never).
@export var count_every_levels: int = 2

@export_group("Evolution")
## Owning this item while the weapon is level 5 offers the evolution in a gift chest.
@export var evolution_item: ItemData
@export var evolved_name: String = ""
@export var evolved_description: String = ""
@export var evolved_damage_mult: float = 1.5
@export var evolved_extra_count: int = 0
@export var evolved_pierce: int = 0
@export var evolved_area_mult: float = 1.0
@export var evolved_cooldown_mult: float = 1.0


func damage_at(level: int, evolved: bool, damage_mult: float) -> float:
	var d: float = damage * (1.0 + level_damage_bonus * (level - 1)) * damage_mult
	return d * (evolved_damage_mult if evolved else 1.0)


func cooldown_at(evolved: bool, attack_speed_bonus: float) -> float:
	return cooldown * (evolved_cooldown_mult if evolved else 1.0) / (1.0 + attack_speed_bonus)


func count_at(level: int, evolved: bool, extra_projectiles: int) -> int:
	var level_bonus: int = 0
	if count_every_levels > 0:
		@warning_ignore("integer_division")
		level_bonus = (level - 1) / count_every_levels
	return projectile_count + extra_projectiles + level_bonus + (evolved_extra_count if evolved else 0)


func radius_at(evolved: bool) -> float:
	return attack_range * (evolved_area_mult if evolved else 1.0)
