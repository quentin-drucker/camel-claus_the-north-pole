class_name PickupData
extends Resource
## A ground pickup that enemies sometimes drop. No menu: walking into it applies it at once
## (Pickup._apply). Each kind has a drop chance per kill and a cooldown so they never clutter.

## Enum order is saved in the .tres files: only append.
enum Kind {
	MAGNET,  ## every XP ornament on the map rushes to Claus
	HEAL,  ## heals `amount` x max HP (waits on the ground while HP is full)
	BOMB,  ## pops normal enemies within `amount` m, freezes the rest nearby, chips elites/boss
}

@export var title: String = ""
@export var kind: Kind = Kind.MAGNET
## Wrapper scene of the baked model.
@export var model: PackedScene
## Chance per enemy kill.
@export var drop_chance: float = 0.004
## Seconds after a drop of this kind before it can drop again.
@export var cooldown: float = 30.0
@export var amount: float = 0.0
