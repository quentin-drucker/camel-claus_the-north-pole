extends CanvasLayer
## Autoload "Transition": every scene change (menu -> run, restart, -> menu) goes behind the knitted
## curtain from the style guide: a knit panel with a Fair Isle band drops over the screen, the scene swaps,
## and it lifts again. Also asks the browser (web builds) to let the game keep Esc while fullscreen,
## see _lock_escape().

const DROP: float = 0.27
const LIFT: float = 0.3
const BAND_FROM_BOTTOM: float = 56.0
const OVERHANG: float = 60.0  # the curtain is taller than the screen so its band never shows mid-screen
const KNIT: Texture2D = preload("res://assets/ui/tin/knit_red.png")
const BAND: Texture2D = preload("res://assets/ui/tin/fair_isle_big.png")
## Keyboard Lock API: in fullscreen, Esc reaches the game (pause) and the browser shows "Press and hold
## Esc to exit full screen". Chrome/Edge only, and only when the game is the top-level page (not inside
## an iframe, e.g. itch.io's embed); elsewhere the promise rejects quietly and Esc exits fullscreen as
## usual (the pause menu then opens on its own, see PauseMenu). The lock only applies while fullscreen.
const LOCK_ESCAPE_JS: String = "if (navigator.keyboard && navigator.keyboard.lock) { navigator.keyboard.lock(['Escape']).catch(function () {}); }"

var _curtain: Control
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain = Control.new()
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_curtain)
	var knit := TextureRect.new()
	knit.texture = KNIT
	knit.stretch_mode = TextureRect.STRETCH_TILE
	knit.set_anchors_preset(Control.PRESET_FULL_RECT)
	knit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.add_child(knit)
	var band := TextureRect.new()
	band.texture = BAND
	band.stretch_mode = TextureRect.STRETCH_TILE
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 1.0
	band.anchor_bottom = 1.0
	band.offset_top = -BAND_FROM_BOTTOM - BAND.get_height()
	band.offset_bottom = -BAND_FROM_BOTTOM
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.add_child(band)
	var hem := ColorRect.new()  # dark hem line along the bottom edge
	hem.color = Color("0D1322")
	hem.anchor_top = 1.0
	hem.anchor_right = 1.0
	hem.anchor_bottom = 1.0
	hem.offset_top = -4.0
	hem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.add_child(hem)
	get_viewport().size_changed.connect(_fit)
	_fit()
	_curtain.position.y = _hidden_y()
	_lock_escape()


func _fit() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	_curtain.size = Vector2(view.x, view.y + OVERHANG)
	if not _busy:
		_curtain.position.y = _hidden_y()


func _hidden_y() -> float:
	return -_curtain.size.y - 4.0


func _lock_escape() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(LOCK_ESCAPE_JS, true)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP  # swallow clicks while the curtain moves
	await create_tween().tween_property(_curtain, "position:y", -OVERHANG + 20.0, DROP) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await create_tween().tween_property(_curtain, "position:y", _hidden_y(), LIFT) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
