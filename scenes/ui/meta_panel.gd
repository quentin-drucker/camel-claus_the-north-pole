extends PanelContainer
## Main-menu page for meta-progression, one script for three pages (set `page`):
## - WORKSHOP: permanent upgrades (level, effect now > next, price) and weapons to buy once their
##   achievement is earned.
## - ACHIEVEMENTS: every goal with progress and reward, as a postcard (style guide): stamps, postmarks
##   and "Delivered" on earned goals.
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
	theme_type_variation = &"PlateTight"
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	add_child(column)
	_coins = Tin.label("", &"HeaderLabel")
	_coins.add_theme_color_override(&"font_color", Color("F2B53B"))
	var band := Tin.header(["Workshop", "Achievements", "Stats"][page], _coins)
	_title = band.get_child(0).get_child(0)
	_title.theme_type_variation = &"TitleLabel"
	column.add_child(band)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := MarginContainer.new()  # room for the scrollbar on the right
	pad.add_theme_constant_override(&"margin_right", 16)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_list)
	scroll.add_child(pad)
	if page == Page.ACHIEVEMENTS:  # the list is a postcard: paper inside an airmail border
		var card := PanelContainer.new()
		card.theme_type_variation = &"AirmailPanel"
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override(&"separation", 6)
		card.add_child(inner)
		var label := Tin.label("Camel Post  -  North Pole 90°N", &"InkSmall")
		label.add_theme_color_override(&"font_color", Color("C42F3A"))
		inner.add_child(label)
		inner.add_child(scroll)
		scroll.custom_minimum_size = Vector2(1000, 380)
		column.add_child(Tin.body(card, 18))
	else:
		column.add_child(Tin.body(scroll, 18))
	_back = Button.new()
	_back.text = "Back"
	_back.theme_type_variation = &"PrimaryButton"
	_back.size_flags_horizontal = Control.SIZE_SHRINK_END
	_back.pressed.connect(close)
	column.add_child(Tin.body(_back, 18))
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


## Postcard rows: stamp (postmarked when earned), title + description in ink, progress, reward or
## "Delivered". Earned goals first, like Megabonk's quest list.
func _fill_achievements() -> void:
	var p: Dictionary = Profile.progress()
	var done: int = 0
	var goals: Array[AchievementData] = Profile.ACHIEVEMENTS.duplicate()
	goals.sort_custom(func(a: AchievementData, b: AchievementData) -> bool:
		return Profile.has_achievement(a.id) and not Profile.has_achievement(b.id))
	for goal in goals:
		var earned: bool = Profile.has_achievement(goal.id)
		done += int(earned)
		# Run-only stats reset after a run, so an earned goal shows its target, not today's count.
		var have: float = goal.target if earned else minf(p.get(goal.stat, 0.0), goal.target)
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 16)
		_list.add_child(row)
		row.add_child(Tin.stamp(Describe.icon("trophy"), "evo" if earned else "common", 30, earned))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override(&"separation", 0)
		row.add_child(text)
		text.add_child(Tin.label(goal.title, &"InkTitle"))
		var sub: String = goal.description
		if goal.unlocks_weapon:
			sub += "  -  unlocks " + Profile.weapon_card(goal.unlocks_weapon).title
		text.add_child(Tin.label(sub, &"InkSmall"))
		var meter := VBoxContainer.new()
		meter.custom_minimum_size = Vector2(190, 0)
		meter.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(meter)
		var count := Tin.label("%d / %d" % [have, goal.target], &"InkLabel")
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		meter.add_child(count)
		meter.add_child(Tin.bar(&"GoodBar", have, goal.target, 8))
		var reward := Tin.label("Delivered" if earned else "+%d coins" % goal.reward_coins, &"InkTitle" if earned else &"InkLabel")
		if earned:
			reward.add_theme_color_override(&"font_color", Color("3A8FBF"))
		reward.custom_minimum_size = Vector2(140, 0)
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(reward)
		var rule := ColorRect.new()  # the postcard's ruled line
		rule.color = Color(0.133, 0.188, 0.31, 0.2)
		rule.custom_minimum_size = Vector2(0, 2)
		_list.add_child(rule)
	_title.text = "Achievements  %d / %d" % [done, Profile.ACHIEVEMENTS.size()]


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
	text.text = "\n".join(lines)
	_list.add_child(text)


## One list row: icon, two lines of BBCode text, and a button (or a plain note on the right).
func _row(icon: Texture2D, text: String, button_text: String, note: String = "") -> Button:
	var card := PanelContainer.new()  # knit row card (style guide 4.1/4.4)
	card.theme_type_variation = &"KnitCard"
	_list.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	card.add_child(row)
	var picture := Tin.tile(icon, "common", ROW_ICON - 12)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(picture)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = text
	row.add_child(label)
	if note:
		var side := Label.new()
		side.text = note
		side.add_theme_color_override(&"font_color", Color("E8C48E"))
		row.add_child(side)
	if button_text == "":
		return null
	var button := Button.new()
	button.text = button_text
	button.theme_type_variation = &"SmallButton"
	button.custom_minimum_size = Vector2(170, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
