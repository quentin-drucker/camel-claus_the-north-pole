class_name BlessingData
extends Resource
## A Santa's present reward when no weapon is ready to evolve: a strong, short bonus (or an instant
## effect when `duration` is 0). Applied by Player.bless(); timed ones show a countdown in the HUD.
## The icon is assets/ui/icons/<file name>.png.

## Enum order is saved in the .tres files: only append.
enum Effect {
	DAMAGE,  ## all damage x(1 + amount)
	RUSH,  ## +amount move speed and attack speed
	XP,  ## XP x(1 + amount)
	MAGNET,  ## every XP ornament flies in now, and +amount pickup reach
	SHIELD,  ## Claus can't be hurt
	BLIZZARD,  ## instant: freeze everything near Claus for `duration` s, normal enemies lose `amount` of max HP
}

@export var title: String = ""
@export var description: String = ""
@export var effect: Effect = Effect.DAMAGE
@export var amount: float = 1.0
## Seconds the bonus lasts.
@export var duration: float = 20.0
