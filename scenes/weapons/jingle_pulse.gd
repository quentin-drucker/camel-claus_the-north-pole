class_name JinglePulse
extends Weapon
## Every cooldown, a jingling burst hits everything within `data.attack_range` and pushes it back.
## Evolved (Carol of the Bells): bigger radius and pulses 30% more often.

@export var knockback: float = 1.2

var _cooldown_left: float = 0.5


func _init() -> void:
	data = preload("res://resources/weapons/jingle_pulse.tres")


func _process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown() * (0.7 if evolved else 1.0)
	var radius: float = data.attack_range * (1.4 if evolved else 1.0)
	var origin: Vector3 = global_position
	var dmg: float = damage()
	for enemy: Enemy in GameState.enemies.duplicate():
		var away: Vector3 = enemy.global_position - origin
		away.y = 0.0
		if away.length() > radius + enemy.radius:
			continue
		if not enemy.is_boss:
			enemy.global_position += away.normalized() * knockback
		GameState.player.deal_damage(enemy, dmg)
	Burst.spawn(Burst.GOLD, origin, radius)
