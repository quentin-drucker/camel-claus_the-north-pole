class_name UpgradeData
extends Resource

## What the upgrade changes. `amount` is added to that stat (cooldown: subtracted).
enum Stat { MOVE_SPEED, MAX_HP, PICKUP_RADIUS, WEAPON_DAMAGE, WEAPON_COOLDOWN, WEAPON_PROJECTILES }

@export var title: String = ""
@export_multiline var description: String = ""
@export var stat: Stat = Stat.MOVE_SPEED
@export var amount: float = 1.0
