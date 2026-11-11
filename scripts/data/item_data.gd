class_name ItemData
extends Resource
## A chest item. Effects are applied by Player.add_item(); copies stack additively.

## Enum order is saved in the .tres files: only append.
enum Effect {
	DAMAGE,  ## +amount damage multiplier (0.25 = +25%)
	ATTACK_SPEED,  ## +amount attack speed (fraction)
	PROJECTILES,  ## +amount projectiles for every weapon
	MAX_HP,  ## +amount max HP (and heals it)
	POISON_CHANCE,  ## hits poison: deal 60% of the hit again over 3 s
	EXPLODE_CHANCE,  ## hits explode for 60% damage around the target
	FREEZE_CHANCE,  ## hits freeze the target for 1 s
	DAMAGE_PER_KILL,  ## +amount damage per kill this run, capped at +60%
	CHEAT_DEATH,  ## survive one fatal hit per copy
	XP_PULL,  ## every 20 s, every XP ornament flies to Claus
	ELITE_DAMAGE,  ## +amount damage against elites and the boss
}

@export var title: String = ""
@export var description: String = ""
@export var effect: Effect = Effect.DAMAGE
@export var amount: float = 0.0
## Unique items are offered only until you own one.
@export var unique: bool = false
## Card tint in the chest menu.
@export var color: Color = Color(1, 1, 1)
