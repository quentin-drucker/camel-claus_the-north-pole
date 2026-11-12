class_name CosmeticData
extends Resource
## One customization choice for Claus (main menu > Customize). Cosmetic only: no gameplay effect.
## - SKIN: recolors the body by swapping the camel swatches (`swap_from`) for `swap_to`.
## - HAT / OUTFIT: a model piece built around Claus's head / neck / torso (no offsets needed); its main
##   color pair (`swap_from`, light then dark) can be recolored with any of `color_options`.
## Every color is an ART_DIRECTION palette swatch, so all combinations stay on-style.
## Adding one = a .tres in resources/cosmetics/ + its line in Profile.COSMETICS.

## Enum order is saved in the .tres files: only append.
enum Slot { SKIN, HAT, OUTFIT }

## Recolor options for hats and outfits: name -> [light, dark]. No purple (= danger in this game).
const COLORS: Dictionary = {
	"red": [Color("D9343F"), Color("8E1F2E")],
	"green": [Color("3E9A5B"), Color("1F5A43")],
	"blue": [Color("4E6A9E"), Color("22304F")],
	"gold": [Color("F2B53B"), Color("C98F55")],
	"ice": [Color("7FD6F2"), Color("4E6A9E")],
}

@export var id: String = ""
@export var title: String = ""
@export var slot: Slot = Slot.HAT
## Wrapper scene of the piece; empty for skins and for "no hat" / "no outfit".
@export var model: PackedScene
## Coins to buy it once; 0 = free from the start.
@export var price: int = 0
@export var swap_from: PackedColorArray = PackedColorArray()
## Skins only: what each `swap_from` swatch becomes.
@export var swap_to: PackedColorArray = PackedColorArray()
## Hats/outfits: names from COLORS the player can pick; the first is the piece's own color.
@export var color_options: PackedStringArray = PackedStringArray()


## The swatches to write for a color choice (skins ignore `color`).
func swap_targets(color: String) -> PackedColorArray:
	if slot == Slot.SKIN:
		return swap_to
	if color == "" or color == (color_options[0] if not color_options.is_empty() else "") or not COLORS.has(color):
		return PackedColorArray()  # its own colors: no swap
	return PackedColorArray(COLORS[color])
