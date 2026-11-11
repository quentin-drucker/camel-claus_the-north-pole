extends CanvasLayer
## Pauses the game on level-up and offers 3 random upgrades.

@export var upgrades: Array[UpgradeData] = []

var _offered: Array[UpgradeData] = []

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
	_offered = upgrades.duplicate()
	_offered.shuffle()
	_offered.resize(mini(buttons.size(), _offered.size()))
	for i in buttons.size():
		buttons[i].visible = i < _offered.size()
		if buttons[i].visible:
			buttons[i].text = "%s\n\n%s" % [_offered[i].title, _offered[i].description]
	show()
	get_tree().paused = true
	buttons[0].grab_focus()


func _on_choice(index: int) -> void:
	GameState.player.apply_upgrade(_offered[index])
	GameState.pending_level_ups -= 1
	if GameState.pending_level_ups > 0:
		_offer()
	else:
		hide()
		get_tree().paused = false
