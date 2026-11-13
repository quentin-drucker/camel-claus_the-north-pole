class_name CosmeticData
extends Resource
## One customization choice for Claus (main menu > Customize). Cosmetic only: no gameplay effect.
## - SKIN: recolors the body by swapping the camel swatches (`swap_from`) for `swap_to`.
## - HAT / OUTFIT: a model piece built around Claus's head / neck / torso (no offsets needed), always in
##   its own baked colors. (Recoloring pieces was dropped: their baked shading has more shades than a
##   two-swatch swap catches, so a recolor left the default color showing through.)
## Adding one = a .tres in resources/cosmetics/ + its line in Profile.COSMETICS.

## Enum order is saved in the .tres files: only append.
enum Slot { SKIN, HAT, OUTFIT }

@export var id: String = ""
@export var title: String = ""
## One line under the title in the Customize detail panel.
@export var description: String = ""
## Tile picture (a render of the piece); null for skins (they show swatches) and "none" pieces.
@export var picture: Texture2D
@export var slot: Slot = Slot.HAT
## Wrapper scene of the piece; empty for skins and for "no hat" / "no outfit".
@export var model: PackedScene
## Coins to buy it once; 0 = free from the start.
@export var price: int = 0
@export var swap_from: PackedColorArray = PackedColorArray()
## Skins only: what each `swap_from` swatch becomes.
@export var swap_to: PackedColorArray = PackedColorArray()



## The swatches a skin writes over the camel's fur (hats and outfits: none; they keep their colors).
func swap_targets() -> PackedColorArray:
	return swap_to if slot == Slot.SKIN else PackedColorArray()
