extends CanvasLayer
## Autoload "Transition": one fade overlay for every scene change (menu -> run, restart, -> menu).
## change_scene() fades to navy, swaps the scene (unpausing first), then fades back in.

const FADE_OUT: float = 0.3
const FADE_IN: float = 0.35

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
