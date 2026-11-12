extends CanvasLayer
## Autoload "Transition": one fade overlay for every scene change (menu -> run, restart, -> menu).
## change_scene() fades to navy, swaps the scene (unpausing first), then fades back in.
## Also asks the browser (web builds) to let the game keep Esc while fullscreen, see _lock_escape().

const FADE_OUT: float = 0.3
const FADE_IN: float = 0.35
## Keyboard Lock API: in fullscreen, Esc reaches the game (pause) and the browser shows "Press and hold
## Esc to exit full screen". Chrome/Edge only, and only when the game is the top-level page (not inside
## an iframe, e.g. itch.io's embed); elsewhere the promise rejects quietly and Esc exits fullscreen as
## usual (the pause menu then opens on its own, see PauseMenu). The lock only applies while fullscreen.
const LOCK_ESCAPE_JS: String = "if (navigator.keyboard && navigator.keyboard.lock) { navigator.keyboard.lock(['Escape']).catch(function () {}); }"

var _rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color("22304F")
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)
	_lock_escape()


func _lock_escape() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(LOCK_ESCAPE_JS, true)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # swallow clicks mid-fade
	await create_tween().tween_property(_rect, "modulate:a", 1.0, FADE_OUT).finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await create_tween().tween_property(_rect, "modulate:a", 0.0, FADE_IN).finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
