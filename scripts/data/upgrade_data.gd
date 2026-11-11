class_name UpgradeData
extends Resource
## A level-up card. Stats are global: they apply to every weapon Claus carries.

## Enum order is saved in the .tres files: only append.
enum Stat { MOVE_SPEED, MAX_HP, PICKUP_RADIUS, DAMAGE, ATTACK_SPEED, PROJECTILES }

@export var title: String = ""
## Card text; "{v}" is replaced by the (rarity-scaled) amount.
@export var description: String = ""
@export var stat: Stat = Stat.MOVE_SPEED
## Added to the stat per pick. Percent stats use fractions (0.2 = +20%).
@export var amount: float = 1.0
@export var is_percent: bool = false
## Rare/epic cards multiply `amount`; off for whole-number stats like projectiles.
@export var scales_with_rarity: bool = true
@export var max_level: int = 5


func describe(rarity_mult: float) -> String:
	var v: float = amount * rarity_mult * (100.0 if is_percent else 1.0)
	return description.format({"v": ("%.1f" % v).trim_suffix(".0")})
