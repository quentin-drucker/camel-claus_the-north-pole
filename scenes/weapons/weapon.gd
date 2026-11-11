class_name Weapon
extends Node3D
## Base for Claus's weapons: level 1-5, an optional evolution, and the player's global stats.
## Subclasses attack in _process and deal damage through Player.deal_damage() (so items proc).

@export var data: WeaponData

var level: int = 1
var evolved: bool = false


func title() -> String:
	return data.evolved_name if evolved else data.display_name


func damage() -> float:
	var d: float = data.damage * (1.0 + data.level_damage_bonus * (level - 1)) * GameState.player.damage_mult
	return d * (data.evolved_damage_mult if evolved else 1.0)


func cooldown() -> float:
	return data.cooldown / (1.0 + GameState.player.attack_speed_bonus)


func count() -> int:
	var level_bonus: int = 0
	if data.count_every_levels > 0:
		@warning_ignore("integer_division")
		level_bonus = (level - 1) / data.count_every_levels
	return data.projectile_count + GameState.player.extra_projectiles + level_bonus


func can_evolve() -> bool:
	return not evolved and level >= 5 and data.evolution_item != null \
		and GameState.player.items.has(data.evolution_item)
