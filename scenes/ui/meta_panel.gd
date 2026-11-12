extends PanelContainer
## Main-menu page for meta-progression, one script for three pages (set `page`):
## - WORKSHOP: permanent upgrades (level, effect now > next, price) and weapons to buy once their
##   achievement is earned.
## - ACHIEVEMENTS: every goal with progress and reward; earned ones in gold.
## - STATS: lifetime totals, personal bests and the build of the best run.
## Rebuilt every time it opens, so it always shows the saved Profile.

signal closed

enum Page { WORKSHOP, ACHIEVEMENTS, STATS }

const ROW_ICON: int = 56

@export var page: Page = Page.WORKSHOP

var _title: Label
var _coins: Label
var _list: VBoxContainer
var _back: Button


func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 10)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.text = ["Workshop", "Achievements", "Stats"][page]
	_title.add_theme_font_size_override(&"font_size", 64)
	_title.add_theme_color_override(&"font_color", Color("F2B53B"))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_coins = Label.new()
	_coins.add_theme_font_size_override(&"font_size", 48)
	_coins.add_theme_color_override(&"font_color", Color("F2B53B"))
	header.add_child(_coins)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1060, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_back = Button.new()
	_back.text = "Back"
	_back.custom_minimum_size = Vector2(220, 64)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_END
	_back.pressed.connect(close)
	column.add_child(_back)
	visibility_changed.connect(func() -> void:
		if visible:
			refresh()
			_back.grab_focus())


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	Audio.play(&"click")
	hide()
	closed.emit()


func refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	_coins.text = "%d coins" % Profile.coins()
	_coins.visible = page == Page.WORKSHOP
	match page:
		Page.WORKSHOP:
			_fill_workshop()
		Page.ACHIEVEMENTS:
			_fill_achievements()
		Page.STATS:
			_fill_stats()


func _fill_workshop() -> void:
	for item in Profile.WORKSHOP:
		var level: int = Profile.workshop_level(item)
		var cost: int = Profile.workshop_cost(item)
		var now: String = item.describe(level) if level > 0 else "nothing yet"
		var text: String = "%s  %s\n%s" % [item.title, Describe.c(Describe.MUTED, "Lv %d/%d" % [level, item.max_level()]),
			("Now %s" % now) + (("  >  " + Describe.c(Describe.GOOD, item.describe(level + 1))) if cost >= 0 else "")]
		var buy: Button = _row(Describe.icon(item.icon), text, "MAX" if cost < 0 else "Buy  %d" % cost)
		buy.disabled = cost < 0 or Profile.coins() < cost
		buy.pressed.connect(func() -> void:
			if Profile.buy_workshop(item):
				Audio.play(&"chest")
				refresh())
	for card in Profile.WEAPON_CARDS:
		var id: String = Profile.weapon_id(card)
		if Profile.is_unlocked(id) or Profile.unlock_goal(id) == null:
			continue
		var price: int = Profile.WEAPON_PRICES.get(id, 0)
		var buyable: bool = Profile.is_buyable(id)
		var text: String = "%s  %s\n%s" % [card.title, Describe.c(Describe.ICE, "NEW WEAPON"),
			Describe.c(Describe.GOOD if buyable else Describe.MUTED, Profile.unlock_hint(id))]
		var buy: Button = _row(Describe.icon_for(card) if buyable else Describe.icon("lock"), text,
			"Buy  %d" % price if buyable else "Locked")
		buy.disabled = not buyable or Profile.coins() < price
		buy.pressed.connect(func() -> void:
			if Profile.buy_weapon(id):
				Audio.play(&"evolve")
				refresh())


func _fill_achievements() -> void:
	var p: Dictionary = Profile.progress()
	var done: int = 0
	for goal in Profile.ACHIEVEMENTS:
		var earned: bool = Profile.has_achievement(goal.id)
		done += int(earned)
		var have: float = minf(p.get(goal.stat, 0.0), goal.target)
		var reward: String = ("+%d coins" % goal.reward_coins) + \
			(", unlocks " + Profile.weapon_card(goal.unlocks_weapon).title if goal.unlocks_weapon else "")
		var text: String = "%s\n%s  %s" % [Describe.c(Describe.GOLD, goal.title) if earned else goal.title,
			goal.description, Describe.c(Describe.MUTED, "DONE" if earned else "%d/%d" % [have, goal.target])]
		_row(Describe.icon("trophy" if earned else "lock"), text, "", reward)
	_title.text = "Achievements  %d/%d" % [done, Profile.ACHIEVEMENTS.size()]


func _fill_stats() -> void:
	var bests: Dictionary = Profile.data["bests"]
	var lines: PackedStringArray = [Describe.c(Describe.GOLD, "Personal bests")]
	for key: String in Profile.BEST_LABELS:
		var v: float = float(bests.get(key, 0.0))
		lines.append("%s  %s" % [Profile.BEST_LABELS[key], _clock(v) if key == "time" else str(int(v))])
	if bests.has("build"):
		lines.append(Describe.c(Describe.MUTED, "Best run's build: " + ", ".join(PackedStringArray(bests["build"]))))
	lines.append("")
	lines.append(Describe.c(Describe.GOLD, "All runs"))
	for key: String in Profile.STAT_LABELS:
		var v: float = Profile.stat(key)
		lines.append("%s  %s" % [Profile.STAT_LABELS[key], _clock(v) if key == "time" else str(int(v))])
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.add_theme_font_size_override(&"normal_font_size", 32)
	text.text = "\n".join(lines)
	_list.add_child(text)


## One list row: icon, two lines of BBCode text, and a button (or a plain note on the right).
func _row(icon: Texture2D, text: String, button_text: String, note: String = "") -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	_list.add_child(row)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(ROW_ICON, ROW_ICON)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(picture)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override(&"normal_font_size", 32)
	label.text = text
	row.add_child(label)
	if note:
		var side := Label.new()
		side.text = note
		side.add_theme_font_size_override(&"font_size", 32)
		side.add_theme_color_override(&"font_color", Color("E8C48E"))
		row.add_child(side)
	if button_text == "":
		return null
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(200, 56)
	button.add_theme_font_size_override(&"font_size", 32)
	button.mouse_entered.connect(button.grab_focus)
	row.add_child(button)
	return button


static func _clock(seconds: float) -> String:
	var s: int = int(seconds)
	if s >= 3600:
		@warning_ignore("integer_division")
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	@warning_ignore("integer_division")
	return "%d:%02d" % [s / 60, s % 60]
