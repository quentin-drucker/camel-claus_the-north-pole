class_name WorkshopData
extends Resource
## A permanent Workshop upgrade bought with Christmas Coins between runs (main menu > Workshop).
## Level n costs costs[n-1]; the number of costs is the max level. Applied at run start by
## Profile.apply_workshop(). Kept small and capped so skill and build choices still decide runs.

## Enum order is saved in the .tres files: only append.
enum Stat {
	MAX_HP,  ## +amount max HP per level
	MOVE_SPEED,  ## +amount move speed (fraction) per level
	DAMAGE,  ## +amount damage multiplier per level
	XP,  ## +amount XP multiplier per level
	PICKUP,  ## +amount pickup reach (fraction) per level
	REROLLS,  ## +amount rerolls per run per level
	BANISHES,  ## +amount banishes per run per level
}

@export var id: String = ""
@export var title: String = ""
## "{v}" is replaced by the total bonus at a level (percent stats as %).
@export var description: String = ""
## Icon file name in assets/ui/icons (without .png).
@export var icon: String = ""
@export var stat: Stat = Stat.MAX_HP
@export var amount: float = 1.0
@export var is_percent: bool = false
@export var costs: Array[int] = []


func max_level() -> int:
	return costs.size()


func describe(level: int) -> String:
	var v: float = amount * level * (100.0 if is_percent else 1.0)
	return description.format({"v": ("%.1f" % v).trim_suffix(".0")})
