class_name Tin
extends RefCounted
## Builders for the "Workshop Tin" style pieces (art_reference/GUI_Style_Guide). Everything visual lives in
## the theme (assets/ui/workshop_tin_theme.tres, built by art_src/tools/build_ui_theme.gd); these only
## assemble nodes and pick theme type variations, so screens that build UI in code stay on-style.

const POSTMARK: Texture2D = preload("res://assets/ui/tin/postmark.png")
const POSTMARK_WAVY: Texture2D = preload("res://assets/ui/tin/postmark_wavy.png")
const RAYS: Texture2D = preload("res://assets/ui/tin/rays.png")
const INK: Color = Color(0.133, 0.188, 0.31, 0.78)  # navy postmark ink on paper
const INK_LIGHT: Color = Color(0.957, 0.973, 1.0, 0.9)  # white postmark ink on dark plates
## Rarity keys used by Row*/Tile*/Stamp* variations.
const RARITIES: Array[String] = ["common", "rare", "epic", "evo"]


static func label(text: String, variation: StringName = &"", wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Pine header band with the Fair Isle trim and a title (for PlateTight panels).
static func header(title: String, extra: Control = null) -> PanelContainer:
	var band := PanelContainer.new()
	band.theme_type_variation = &"HeaderBand"
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	band.add_child(row)
	var t := label(title, &"HeaderLabel")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if extra:
		row.add_child(extra)
	return band


## A body margin for content under a header inside a PlateTight panel.
static func body(child: Control, margin: int = 14) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin)
	m.add_child(child)
	return m


static func _icon_rect(texture: Texture2D, size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Icon in a rarity tile (rarity: common/rare/epic/evo).
static func tile(texture: Texture2D, rarity: String = "common", icon_size: int = 40) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = StringName("Tile" + rarity.capitalize())
	p.add_child(_icon_rect(texture, icon_size))
	return p


## Icon on a perforated postage stamp; `postmarked` adds a navy cancellation over its corner.
static func stamp(texture: Texture2D, rarity: String = "common", icon_size: int = 30, postmarked: bool = false) -> Control:
	var p := PanelContainer.new()
	p.theme_type_variation = StringName("Stamp" + rarity.capitalize())
	p.add_child(_icon_rect(texture, icon_size))
	if not postmarked:
		return p
	# A plain Control holds the stamp and the mark, so no container resizes the mark.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(icon_size + 20, icon_size + 20)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(p)
	var mark := postmark(false, INK)
	mark.size = Vector2(44, 44)
	mark.position = Vector2(icon_size - 8, icon_size - 6)
	mark.pivot_offset = mark.size / 2.0
	mark.rotation_degrees = -16.0
	holder.add_child(mark)
	return holder


## A cancellation mark (tint with `ink`); wavy = with the three wave lines.
static func postmark(wavy: bool, ink: Color = INK) -> TextureRect:
	var mark := TextureRect.new()
	mark.texture = POSTMARK_WAVY if wavy else POSTMARK
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.modulate = ink
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark


## Slam a postmark onto `parent` (picked upgrade, earned goal): scale 2.4 -> 1 with overshoot.
static func stamp_onto(parent: Control, at: Vector2, size: float = 112.0, ink: Color = INK_LIGHT) -> TextureRect:
	var mark := postmark(false, ink)
	mark.size = Vector2(size, size)
	mark.pivot_offset = mark.size / 2.0
	mark.position = at - mark.size / 2.0
	mark.rotation_degrees = -14.0
	mark.scale = Vector2.ONE * 2.4
	mark.modulate.a = 0.0
	parent.add_child(mark)
	var tw := mark.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mark, "scale", Vector2.ONE, 0.32)
	tw.tween_property(mark, "modulate:a", ink.a, 0.12)
	return mark


static func bar(variation: StringName, value: float, max_value: float, min_height: float = 8.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.theme_type_variation = variation
	b.max_value = maxf(max_value, 0.001)
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, min_height)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Row/tile/stamp rarity key from a card tag such as "RARE STAT UPGRADE" or "EVOLUTION".
static func rarity_of(tag: String) -> String:
	if "EPIC" in tag:
		return "epic"
	if "RARE" in tag:
		return "rare"
	if "EVOLUTION" in tag or "BLESSING" in tag:
		return "evo"
	return "common"


## "RARE STAT UPGRADE" -> "Rare stat upgrade" (the style guide uses sentence case, never all caps).
static func sentence(text: String) -> String:
	var low := text.to_lower()
	return low.substr(0, 1).to_upper() + low.substr(1)
