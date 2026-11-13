extends SceneTree
## Builds the "Workshop Tin" A+ hybrid theme (art_reference/GUI_Style_Guide) from the textures made by
## make_ui_textures.py and saves res://assets/ui/workshop_tin_theme.tres.
## Run:  godot --headless --path . -s <abs path>/art_src/tools/build_ui_theme.gd
## Every text/button/panel role is a theme TYPE VARIATION: nodes set theme_type_variation, never sizes.
## Tiny5 is a pixel font on an 8 px em (1 pixel = 128 of 1024 units): only multiples of 8 stay crisp.

const OUT := "res://assets/ui/workshop_tin_theme.tres"
const TIN := "res://assets/ui/tin/"

const TEXT := Color("F4F8FF")
const MUTED := Color("A9BDDC")
const DARK := Color("0D1322")
const NAVY := Color("22304F")
const GOLD := Color("F2B53B")
const TITLE_GOLD := Color("FFD64F")
const LABEL := Color("E8C48E")
const GOOD := Color("8DE09F")
const ICE := Color("7FD6F2")
const POST_RED := Color("C42F3A")
const STEEL := Color("5C77AB")

var t := Theme.new()
var tiny5: FontFile = load("res://assets/fonts/Tiny5.ttf")
var rocker: FontFile = load("res://assets/fonts/NewRocker-Regular.ttf")
var bowlby: FontFile = load("res://assets/fonts/BowlbyOne-Regular.ttf")


func _initialize() -> void:
	t.default_font = tiny5
	t.default_font_size = 16
	labels()
	buttons()
	panels()
	bars()
	controls()
	var err := ResourceSaver.save(t, OUT)
	print("saved ", OUT, " err=", err)
	quit(err)


# ---------------------------------------------------------------- helpers
func tex(name: String) -> Texture2D:
	return load(TIN + name + ".png")


## StyleBoxTexture: margins/content/expand are [left, top, right, bottom].
func sbt(name: String, margins: Array, content: Array, expand: Array = [0, 0, 0, 0], tile: bool = false) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex(name)
	for i in 4:
		s.set_texture_margin(i, margins[i])
		s.set_content_margin(i, content[i])
		s.set_expand_margin(i, expand[i])
	if tile:
		s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return s


func flat(bg: Color, border := 0, border_color := DARK, content := [0, 0, 0, 0], expand := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(border)
	s.border_color = border_color
	for i in 4:
		s.set_content_margin(i, content[i])
	s.set_expand_margin_all(expand)
	return s


## A Label variation: font, size, color, outline thickness (≈ outline/2 px each side), drop (y offset).
func label(name: String, font: Font, size: int, color: Color, outline := 0, drop := 0, base := &"Label") -> void:
	if name != "Label":
		t.set_type_variation(name, base)
	t.set_font(&"font", name, font)
	t.set_font_size(&"font_size", name, size)
	t.set_color(&"font_color", name, color)
	t.set_constant(&"outline_size", name, outline)
	t.set_color(&"font_outline_color", name, DARK)
	t.set_color(&"font_shadow_color", name, DARK)
	t.set_constant(&"shadow_offset_x", name, 0 if drop >= 3 else drop)
	t.set_constant(&"shadow_offset_y", name, drop)
	t.set_constant(&"shadow_outline_size", name, outline)


# ---------------------------------------------------------------- roles
func labels() -> void:
	label("Label", tiny5, 16, TEXT, 0, 2)  # body on plates: a 2 px dark drop
	label("MutedLabel", tiny5, 16, MUTED, 0, 2)
	label("SmallLabel", tiny5, 16, MUTED, 0, 2)
	label("GoldLabel", tiny5, 16, GOLD, 0, 2)
	label("GoodLabel", tiny5, 16, GOOD, 0, 2)
	label("BadLabel", tiny5, 16, Color("F28890"), 0, 2)  # a stat worse than base
	label("StatLabel", tiny5, 16, LABEL, 0, 2)
	label("TitleLabel", rocker, 36, TEXT, 4, 3)  # dialog titles
	label("HeaderLabel", rocker, 27, TEXT, 4, 3)  # panel titles, names
	label("TagLabel", rocker, 20, TEXT, 4, 2)  # rarity tags, small display text
	label("GoalTitle", rocker, 20, TITLE_GOLD, 4, 2)
	label("SubLabel", rocker, 22, LABEL, 4, 2)  # section headings inside a panel ("Sound", "Items")
	label("TabName", rocker, 22, MUTED, 4, 2)  # inactive tab name
	label("NameLabel", rocker, 22, TEXT, 4, 2)  # names in rows and lists (weapons, unlocks, cosmetics)
	# Rarity tags that sit on an offer row's top border: row fill behind, rarity line color text.
	for r in [["Common", "263450", "8FA9D1"], ["Rare", "17425C", "7FD6F2"], ["Epic", "37204F", "B47BE6"], ["Evo", "4A3A12", "F2B53B"]]:
		label("Tag" + r[0], rocker, 20, Color(r[2]), 4, 2)
		t.set_stylebox(&"normal", "Tag" + r[0], flat(Color(r[1]), 0, DARK, [8, 0, 8, 1]))
	label("SubtitleLabel", rocker, 36, GOLD, 4, 3)  # "The North Pole" under the logo
	label("LogoLabel", bowlby, 76, TEXT, 14, 9)
	label("LogoBigLabel", bowlby, 112, TEXT, 18, 10)  # intro logo
	label("BigNumber", tiny5, 24, TEXT, 0, 2)
	label("HudLabel", tiny5, 24, TEXT, 5, 3)  # HUD: outlined, no panel behind
	label("HudSmall", tiny5, 16, TEXT, 4, 2)
	label("HudTimer", tiny5, 48, TEXT, 8, 4)
	label("HudLevel", tiny5, 40, TEXT, 6, 4)
	label("BannerLabel", bowlby, 52, TEXT, 10, 6)
	t.set_color(&"font_outline_color", "BannerLabel", Color("4A1F6E"))
	label("InkLabel", tiny5, 16, NAVY)  # on paper (postcards, stamps, tags)
	label("InkSmall", tiny5, 16, Color("4E6A9E"))
	label("InkTitle", rocker, 22, NAVY)
	label("PostRedLabel", rocker, 30, POST_RED)
	label("ToastTitle", rocker, 20, POST_RED)
	# Key hints: a small outlined box around Tiny5 13.
	label("KeyLabel", tiny5, 16, MUTED)
	label("KeyCapLabel", tiny5, 16, NAVY)  # text on a KeyCap
	label("HintLabel", tiny5, 16, TEXT, 0, 2)  # what a key does, next to its KeyCap
	label("BadgeLabel", tiny5, 16, TEXT, 0, 0)  # count in a red Badge bubble
	t.set_stylebox(&"normal", "KeyLabel", flat(Color(DARK, 0.6), 1, Color(MUTED, 0.7), [5, 1, 5, 2]))
	t.set_font(&"normal_font", "RichTextLabel", tiny5)
	t.set_font_size(&"normal_font_size", "RichTextLabel", 16)
	t.set_font(&"bold_font", "RichTextLabel", rocker)
	t.set_font_size(&"bold_font_size", "RichTextLabel", 20)
	t.set_color(&"default_color", "RichTextLabel", TEXT)
	t.set_color(&"font_shadow_color", "RichTextLabel", DARK)
	t.set_constant(&"shadow_offset_x", "RichTextLabel", 2)
	t.set_constant(&"shadow_offset_y", "RichTextLabel", 2)
	t.set_type_variation("SmallRich", &"RichTextLabel")
	t.set_font_size(&"normal_font_size", "SmallRich", 16)
	t.set_color(&"default_color", "SmallRich", MUTED)
	t.set_type_variation("InkRich", &"RichTextLabel")
	t.set_color(&"default_color", "InkRich", NAVY)
	t.set_constant(&"shadow_offset_x", "InkRich", 0)
	t.set_constant(&"shadow_offset_y", "InkRich", 0)


## Slab buttons: normal/hover/pressed/disabled textures, brackets instead of a focus box.
func slab(variant: String, normal_name: String) -> void:
	var n := [6, 6, 6, 14]
	var c := [28, 7, 28, 12]
	var e := [3, 3, 3, 8]
	t.set_stylebox(&"normal", variant, sbt("btn_%s_normal" % normal_name, n, c, e))
	t.set_stylebox(&"hover", variant, sbt("btn_%s_hover" % normal_name, n, c, e))
	t.set_stylebox(&"hover_pressed", variant, sbt("btn_%s_pressed" % normal_name, [6, 10, 6, 6], [28, 11, 28, 8], e))
	t.set_stylebox(&"pressed", variant, sbt("btn_%s_pressed" % normal_name, [6, 10, 6, 6], [28, 11, 28, 8], e))
	t.set_stylebox(&"disabled", variant, sbt("btn_disabled_normal", n, c, e))
	t.set_stylebox(&"focus", variant, StyleBoxEmpty.new())


func buttons() -> void:
	slab("Button", "default")
	t.set_font(&"font", "Button", rocker)
	t.set_font_size(&"font_size", "Button", 27)
	for k in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		t.set_color(k, "Button", TEXT)
	t.set_color(&"font_disabled_color", "Button", Color("6F80A3"))
	t.set_color(&"font_outline_color", "Button", DARK)
	t.set_constant(&"outline_size", "Button", 4)
	t.set_constant(&"h_separation", "Button", 10)
	t.set_constant(&"icon_max_width", "Button", 28)
	for v in [["PrimaryButton", "primary"], ["RerollButton", "reroll"], ["DangerButton", "danger"]]:
		t.set_type_variation(v[0], &"Button")
		slab(v[0], v[1])
	for k in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		t.set_color(k, "PrimaryButton", NAVY)
	t.set_constant(&"outline_size", "PrimaryButton", 0)
	t.set_type_variation("BigPrimaryButton", &"PrimaryButton")
	t.set_font_size(&"font_size", "BigPrimaryButton", 36)
	t.set_type_variation("SmallButton", &"Button")
	t.set_font_size(&"font_size", "SmallButton", 19)
	for state in [&"normal", &"hover", &"disabled"]:
		var s: StyleBoxTexture = t.get_stylebox(state, "Button").duplicate()
		s.set_content_margin(SIDE_LEFT, 18); s.set_content_margin(SIDE_RIGHT, 18)
		s.set_content_margin(SIDE_TOP, 5); s.set_content_margin(SIDE_BOTTOM, 9)
		t.set_stylebox(state, "SmallButton", s)
	for state in [&"pressed", &"hover_pressed"]:
		var s: StyleBoxTexture = t.get_stylebox(state, "Button").duplicate()
		s.set_content_margin(SIDE_LEFT, 18); s.set_content_margin(SIDE_RIGHT, 18)
		s.set_content_margin(SIDE_TOP, 9); s.set_content_margin(SIDE_BOTTOM, 5)
		t.set_stylebox(state, "SmallButton", s)
	t.set_stylebox(&"focus", "SmallButton", StyleBoxEmpty.new())
	# Tabs: flat, a steel wash when active.
	t.set_type_variation("TabButton", &"Button")
	t.set_font_size(&"font_size", "TabButton", 19)
	var tab_c := [12, 6, 12, 6]
	t.set_stylebox(&"normal", "TabButton", flat(Color(0, 0, 0, 0), 0, DARK, tab_c))
	t.set_stylebox(&"hover", "TabButton", flat(Color(STEEL, 0.18), 0, DARK, tab_c))
	t.set_stylebox(&"pressed", "TabButton", flat(Color(STEEL, 0.3), 0, DARK, tab_c))
	t.set_stylebox(&"hover_pressed", "TabButton", flat(Color(STEEL, 0.34), 0, DARK, tab_c))
	t.set_stylebox(&"disabled", "TabButton", flat(Color(0, 0, 0, 0), 0, DARK, tab_c))
	t.set_stylebox(&"focus", "TabButton", StyleBoxEmpty.new())
	t.set_color(&"font_color", "TabButton", MUTED)
	t.set_color(&"font_pressed_color", "TabButton", TEXT)
	t.set_color(&"font_hover_pressed_color", "TabButton", TEXT)
	# Offer rows: rarity plates with knit; content leaves room for the rarity tag on the top border.
	for r in ["common", "rare", "epic", "evo"]:
		var v: String = "Row" + str(r).capitalize()
		t.set_type_variation(v, &"Button")
		var m := [22, 22, 22, 29]
		var c := [16, 14, 20, 12]
		var e := [0, 0, 0, 7]
		t.set_stylebox(&"normal", v, sbt("row_" + r, m, c, e, true))
		t.set_stylebox(&"hover", v, sbt("row_%s_hover" % r, m, c, e, true))
		t.set_stylebox(&"pressed", v, sbt("row_%s_hover" % r, m, c, e, true))
		t.set_stylebox(&"hover_pressed", v, sbt("row_%s_hover" % r, m, c, e, true))
		t.set_stylebox(&"disabled", v, sbt("row_" + r, m, c, e, true))
		t.set_stylebox(&"focus", v, StyleBoxEmpty.new())
		# Compact grid card in the same rarity plate (loadout, workshop): smaller text, tight content.
		var card: String = "Card" + str(r).capitalize()
		t.set_type_variation(card, &"Button")
		t.set_font_size(&"font_size", card, 19)
		for state in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
			var sb: StyleBoxTexture = t.get_stylebox(state, v).duplicate()
			for i in 4:
				sb.set_content_margin(i, 10)
			t.set_stylebox(state, card, sb)
		t.set_stylebox(&"focus", card, StyleBoxEmpty.new())
	# Nameplate tiles (customize grid): knit plate, knit-hover.
	t.set_type_variation("KnitTileButton", &"Button")
	t.set_font_size(&"font_size", "KnitTileButton", 17)
	t.set_stylebox(&"normal", "KnitTileButton", sbt("row_common", [22, 22, 22, 29], [8, 8, 8, 8], [0, 0, 0, 7], true))
	t.set_stylebox(&"hover", "KnitTileButton", sbt("row_common_hover", [22, 22, 22, 29], [8, 8, 8, 8], [0, 0, 0, 7], true))
	t.set_stylebox(&"pressed", "KnitTileButton", sbt("row_evo", [22, 22, 22, 29], [8, 8, 8, 8], [0, 0, 0, 7], true))
	t.set_stylebox(&"hover_pressed", "KnitTileButton", sbt("row_evo_hover", [22, 22, 22, 29], [8, 8, 8, 8], [0, 0, 0, 7], true))
	t.set_stylebox(&"disabled", "KnitTileButton", sbt("row_common", [22, 22, 22, 29], [8, 8, 8, 8], [0, 0, 0, 7], true))
	t.set_stylebox(&"focus", "KnitTileButton", StyleBoxEmpty.new())
	# Header close X (icon set by Tin.close_button): no plate, a faint wash on hover.
	t.set_type_variation("CloseButton", &"Button")
	t.set_stylebox(&"normal", "CloseButton", flat(Color(0, 0, 0, 0), 0, DARK, [6, 6, 6, 6]))
	t.set_stylebox(&"hover", "CloseButton", flat(Color(TEXT, 0.12), 0, DARK, [6, 6, 6, 6]))
	t.set_stylebox(&"pressed", "CloseButton", flat(Color(DARK, 0.3), 0, DARK, [6, 7, 6, 5]))
	t.set_stylebox(&"hover_pressed", "CloseButton", flat(Color(DARK, 0.3), 0, DARK, [6, 7, 6, 5]))
	t.set_stylebox(&"focus", "CloseButton", StyleBoxEmpty.new())


func panels() -> void:
	var plate := sbt("plate", [22, 22, 22, 29], [20, 18, 20, 20], [0, 0, 0, 7])
	t.set_stylebox(&"panel", "PanelContainer", plate)
	t.set_stylebox(&"panel", "Panel", plate)
	t.set_type_variation("PlateTight", &"PanelContainer")  # panels with a HeaderBand on top
	t.set_stylebox(&"panel", "PlateTight", sbt("plate", [22, 22, 22, 29], [8, 8, 8, 10], [0, 0, 0, 7]))
	t.set_type_variation("PlateTightKnit", &"PanelContainer")  # PlateTight with the knit (settings, customize)
	t.set_stylebox(&"panel", "PlateTightKnit", sbt("plate_knit", [22, 22, 22, 29], [8, 8, 8, 10], [0, 0, 0, 7], true))
	t.set_type_variation("PinePlate", &"PanelContainer")  # intro subtitle plate
	t.set_stylebox(&"panel", "PinePlate", sbt("plate_pine", [22, 22, 22, 29], [34, 8, 34, 12], [0, 0, 0, 7]))
	t.set_type_variation("PlateKnit", &"PanelContainer")
	t.set_stylebox(&"panel", "PlateKnit", sbt("plate_knit", [22, 22, 22, 29], [20, 18, 20, 20], [0, 0, 0, 7], true))
	t.set_type_variation("KnitCard", &"PanelContainer")  # goal cards: knit row plate
	t.set_stylebox(&"panel", "KnitCard", sbt("row_common", [22, 22, 22, 29], [12, 10, 24, 10], [0, 0, 0, 7], true))
	t.set_type_variation("HeaderBand", &"PanelContainer")  # pine band + Fair Isle trim under it
	t.set_stylebox(&"panel", "HeaderBand", sbt("header_band", [2, 2, 2, 34], [20, 10, 20, 38], [0, 0, 0, 0], true))
	for r in ["common", "rare", "epic", "evo"]:
		t.set_type_variation("Tile" + r.capitalize(), &"PanelContainer")
		t.set_stylebox(&"panel", "Tile" + r.capitalize(), sbt("tile_" + r, [5, 5, 5, 5], [4, 4, 4, 4], [2, 2, 2, 2]))
		t.set_type_variation("Stamp" + r.capitalize(), &"PanelContainer")
		t.set_stylebox(&"panel", "Stamp" + r.capitalize(), sbt("stamp_" + r, [12, 12, 12, 12], [10, 10, 10, 10], [0, 0, 0, 0], true))
	t.set_type_variation("TileHud", &"PanelContainer")
	t.set_stylebox(&"panel", "TileHud", sbt("tile_hud", [5, 5, 5, 5], [3, 3, 3, 3]))
	t.set_type_variation("PaperPanel", &"PanelContainer")
	t.set_stylebox(&"panel", "PaperPanel", flat(TEXT, 3, DARK, [16, 12, 16, 12]))
	t.set_type_variation("AirmailPanel", &"PanelContainer")
	t.set_stylebox(&"panel", "AirmailPanel", sbt("airmail", [12, 12, 12, 12], [20, 14, 20, 14], [0, 0, 0, 0], true))
	t.set_type_variation("DarkBox", &"PanelContainer")
	t.set_stylebox(&"panel", "DarkBox", flat(Color(DARK, 0.82), 0, DARK, [10, 4, 10, 6]))
	t.set_type_variation("DoneRow", &"PanelContainer")  # completed list rows (Megabonk blue)
	t.set_stylebox(&"panel", "DoneRow", flat(Color(0.23, 0.56, 0.75, 0.13), 0, DARK, [8, 6, 8, 6]))
	t.set_type_variation("LuggageTag", &"PanelContainer")
	t.set_stylebox(&"panel", "LuggageTag", sbt("luggage_tag", [20, 5, 5, 5], [24, 3, 12, 4]))
	t.set_type_variation("KeyCap", &"PanelContainer")  # keyboard key in control hints
	t.set_stylebox(&"panel", "KeyCap", sbt("keycap", [4, 4, 4, 7], [8, 1, 8, 6]))
	t.set_type_variation("Badge", &"PanelContainer")  # red count bubble (Workshop: affordable upgrades)
	var badge := flat(Color("C42F3A"), 2, DARK, [7, 1, 7, 2])
	badge.set_corner_radius_all(12)
	t.set_stylebox(&"panel", "Badge", badge)
	t.set_type_variation("Pill", &"PanelContainer")  # results postcard: "5:00 survived"
	t.set_stylebox(&"panel", "Pill", flat(NAVY, 0, DARK, [12, 4, 12, 6]))
	t.set_type_variation("PillRed", &"PanelContainer")  # results postcard: "New best run"
	t.set_stylebox(&"panel", "PillRed", flat(POST_RED, 2, Color("E2636B"), [12, 2, 12, 4]))
	t.set_type_variation("HintBar", &"PanelContainer")  # dark strip behind control hints
	t.set_stylebox(&"panel", "HintBar", flat(Color(DARK, 0.88), 2, STEEL, [16, 8, 16, 8]))
	t.set_stylebox(&"panel", "TooltipPanel", sbt("plate", [22, 22, 22, 29], [16, 12, 16, 14], [0, 0, 0, 7]))
	t.set_font(&"font", "TooltipLabel", tiny5)
	t.set_font_size(&"font_size", "TooltipLabel", 16)
	t.set_color(&"font_color", "TooltipLabel", TEXT)


func bar(name: String, bg: Color, fill: StyleBox) -> void:
	if name != "ProgressBar":
		t.set_type_variation(name, &"ProgressBar")
	t.set_stylebox(&"background", name, flat(bg, 0, DARK, [0, 0, 0, 0], 2))
	t.set_stylebox(&"fill", name, fill)
	t.set_font(&"font", name, tiny5)
	t.set_font_size(&"font_size", name, 16)
	t.set_color(&"font_color", name, TEXT)
	t.set_color(&"font_outline_color", name, DARK)
	t.set_constant(&"outline_size", name, 4)


func bars() -> void:
	bar("ProgressBar", DARK, flat(GOLD))
	bar("HpBar", Color("3A1218"), flat(Color("E5222F")))
	bar("XpBar", DARK, flat(GOLD))
	bar("GoodBar", DARK, flat(Color("4CC25E")))
	bar("TabProgress", DARK, flat(Color("E08A2C")))
	bar("BossBar", Color("200F2E"), flat(Color("9B4FD1")))
	var grad := Gradient.new()
	grad.set_color(0, Color("D9343F"))
	grad.set_color(1, GOLD)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 64
	gt.height = 4
	var santa := StyleBoxTexture.new()
	santa.texture = gt
	bar("SantaBar", DARK, santa)


func controls() -> void:
	# Slider: dark track + steel hairline, yarn-striped fill, sewn wooden sweater button as the knob.
	t.set_stylebox(&"slider", "HSlider", flat(DARK, 1, Color(STEEL, 0.8), [0, 7, 0, 7], 2))
	var yarn := sbt("yarn_fill", [0, 0, 0, 0], [0, 7, 0, 7], [0, 0, 0, 0])
	yarn.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	t.set_stylebox(&"grabber_area", "HSlider", yarn)
	t.set_stylebox(&"grabber_area_highlight", "HSlider", yarn)
	for icon in [&"grabber", &"grabber_highlight", &"grabber_disabled"]:
		t.set_icon(icon, "HSlider", tex("knob_slider"))
	# Toggles: CheckButton/CheckBox share the sweater-button switch.
	for type in ["CheckButton", "CheckBox"]:
		t.set_icon(&"checked", type, tex("toggle_on"))
		t.set_icon(&"unchecked", type, tex("toggle_off"))
		t.set_icon(&"checked_disabled", type, tex("toggle_on"))
		t.set_icon(&"unchecked_disabled", type, tex("toggle_off"))
		# Right-to-left toggles (switch first, then "On"/"Off") draw the *_mirrored icons: same art.
		t.set_icon(&"checked_mirrored", type, tex("toggle_on"))
		t.set_icon(&"unchecked_mirrored", type, tex("toggle_off"))
		t.set_icon(&"checked_disabled_mirrored", type, tex("toggle_on"))
		t.set_icon(&"unchecked_disabled_mirrored", type, tex("toggle_off"))
		for state in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
			t.set_stylebox(state, type, StyleBoxEmpty.new())
		t.set_font(&"font", type, tiny5)
		t.set_font_size(&"font_size", type, 16)
		for k in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
			t.set_color(k, type, TEXT)
		t.set_constant(&"h_separation", type, 12)
		t.set_constant(&"icon_max_width", type, 0)  # Button's 28 px cap would shrink the switch art
	# Scrollbars: thin steel.
	t.set_stylebox(&"scroll", "VScrollBar", flat(Color(DARK, 0.5), 0, DARK, [3, 0, 3, 0]))
	t.set_stylebox(&"grabber", "VScrollBar", flat(STEEL))
	t.set_stylebox(&"grabber_highlight", "VScrollBar", flat(Color("6A86BD")))
	t.set_stylebox(&"grabber_pressed", "VScrollBar", flat(Color("6A86BD")))
	# Option menus / line edits (rare, but keep them on-style).
	t.set_stylebox(&"normal", "LineEdit", flat(DARK, 2, STEEL, [8, 4, 8, 4]))
	t.set_font(&"font", "LineEdit", tiny5)
