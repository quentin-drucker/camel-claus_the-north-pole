extends CanvasLayer
## Pauses the game on level-up and offers 3 random upgrades that aren't maxed yet.
## Each card rolls a rarity that multiplies its bonus (Megabonk-style).

const RARITIES: Array[Dictionary] = [
	{"name": "", "mult": 1.0, "weight": 75.0, "color": Color(1, 1, 1)},
	{"name": "RARE", "mult": 1.5, "weight": 20.0, "color": Color(0.55, 0.75, 1.0)},
	{"name": "EPIC", "mult": 2.0, "weight": 5.0, "color": Color(0.85, 0.6, 1.0)},
]

@export var upgrades: Array[UpgradeData] = []

var _offered: Array[UpgradeData] = []
var _rarities: Array[Dictionary] = []

@onready var buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]


func _ready() -> void:
	hide()
	GameState.leveled_up.connect(_on_leveled_up)
	for i in buttons.size():
		buttons[i].pressed.connect(_on_choice.bind(i))


func _on_leveled_up(_level: int) -> void:
	if not visible:
		_offer()


func _offer() -> void:
	var player: Player = GameState.player
	_offered = upgrades.filter(func(u: UpgradeData) -> bool: return player.upgrade_level(u) < u.max_level)
	if _offered.is_empty():  # everything maxed: nothing to pick
		GameState.pending_level_ups = 0
		return
	_offered.shuffle()
	_offered.resize(mini(buttons.size(), _offered.size()))
	_rarities.clear()
	for i in buttons.size():
		buttons[i].visible = i < _offered.size()
		if not buttons[i].visible:
			continue
		var upgrade: UpgradeData = _offered[i]
		var rarity: Dictionary = _roll_rarity() if upgrade.scales_with_rarity else RARITIES[0]
		_rarities.append(rarity)
		var header: String = (rarity["name"] + "  ") if rarity["name"] else ""
		buttons[i].text = "%s%s  (Lv %d)\n\n%s" % [
			header, upgrade.title, player.upgrade_level(upgrade) + 1, upgrade.describe(rarity["mult"])
		]
		buttons[i].modulate = rarity["color"]
	show()
	get_tree().paused = true
	buttons[0].grab_focus()


func _roll_rarity() -> Dictionary:
	var roll: float = randf() * 100.0
	for rarity in RARITIES:
		roll -= rarity["weight"]
		if roll <= 0.0:
			return rarity
	return RARITIES[0]


func _on_choice(index: int) -> void:
	GameState.player.apply_upgrade(_offered[index], _rarities[index]["mult"])
	GameState.pending_level_ups -= 1
	if GameState.pending_level_ups > 0:
		_offer()
	if GameState.pending_level_ups <= 0:
		hide()
		get_tree().paused = false
