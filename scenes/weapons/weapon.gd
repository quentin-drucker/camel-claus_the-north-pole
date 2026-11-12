class_name Weapon
extends Node3D
## Base for Claus's weapons: level 1-5, an evolution at level 5, and the player's global stats.
## Numbers come from WeaponData's formulas (shared with the UI). Subclasses attack in _process and
## deal damage through Player.deal_damage() so items proc. evolve() triggers the evolution look.

signal evolved_changed

@export var data: WeaponData

var level: int = 1
var evolved: bool = false


func title() -> String:
	return data.evolved_name if evolved else data.display_name


func damage() -> float:
	return data.damage_at(level, evolved, GameState.player.damage_mult)


func cooldown() -> float:
	return data.cooldown_at(evolved, GameState.player.attack_speed_bonus)


func count() -> int:
	return data.count_at(level, evolved, GameState.player.extra_projectiles)


func radius() -> float:
	return data.radius_at(level, evolved)


func can_evolve() -> bool:
	return not evolved and level >= WeaponData.MAX_LEVEL and data.evolved_name != ""


func evolve() -> void:
	evolved = true
	evolved_changed.emit()
