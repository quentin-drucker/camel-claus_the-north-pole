extends CanvasLayer
## Autoload "FocusBrackets": the style guide's selection marker. Four white L-brackets (with a dark drop)
## around whatever the mouse hovers, else whatever has keyboard/gamepad focus: buttons, sliders, toggles,
## and any Control with meta "brackets". They slide in from 26 px out to 12 px (0.16 s, slight overshoot).
## Opt out per control with meta "no_brackets". One node for the whole game, so screens never wire this.

const ARM: float = 15.0
const THICK: float = 3.0
const FAR: float = 26.0
const NEAR: float = 12.0
const NEAR_SMALL: float = 7.0  # targets under 70 px (tiles, small toggles)
const WHITE: Color = Color("F4F8FF")
const SHADOW: Color = Color("0D1322")

var _target: Control
var _inset: float = FAR
var _alpha: float = 0.0
var _tween: Tween
var _canvas: Control


func _ready() -> void:
	layer = 99  # above every menu; the Transition curtain (100) still covers it
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_brackets)
	add_child(_canvas)


func _process(_delta: float) -> void:
	var target: Control = _pick(get_viewport().gui_get_hovered_control())
	if target == null:
		target = _pick(get_viewport().gui_get_focus_owner())
	if target != _target:
		_target = target
		if _tween:
			_tween.kill()
		if target:
			var near: float = NEAR_SMALL if minf(target.size.x, target.size.y) * target.get_global_transform().get_scale().x < 70.0 else NEAR
			_inset = FAR
			_alpha = 0.0
			_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween.tween_property(self, "_inset", near, 0.16)
			_tween.tween_property(self, "_alpha", 1.0, 0.08)
	_canvas.queue_redraw()


## The bracketable control at or above `node`, or null.
func _pick(node: Control) -> Control:
	while node:
		if node.has_meta(&"no_brackets") or not node.is_visible_in_tree():
			return null
		if node is BaseButton:
			return null if (node as BaseButton).disabled else node
		if node is Range or node.has_meta(&"brackets"):
			return node
		node = node.get_parent() as Control
	return null


func _draw_brackets() -> void:
	if not is_instance_valid(_target) or not _target.is_visible_in_tree():
		return
	var r: Rect2 = _target.get_global_rect().grow(_inset)
	for pass_i in 2:  # dark drop first, then white
		var off := Vector2(2, 2) if pass_i == 0 else Vector2.ZERO
		var col: Color = SHADOW if pass_i == 0 else WHITE
		col.a *= _alpha
		for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
			var sx: float = 1.0 if corner.x == r.position.x else -1.0
			var sy: float = 1.0 if corner.y == r.position.y else -1.0
			var x0: float = corner.x if sx > 0 else corner.x - THICK
			var y0: float = corner.y if sy > 0 else corner.y - THICK
			_canvas.draw_rect(Rect2(Vector2(x0 if sx > 0 else corner.x - ARM, y0) + off, Vector2(ARM, THICK)), col)
			_canvas.draw_rect(Rect2(Vector2(x0, y0 if sy > 0 else corner.y - ARM) + off, Vector2(THICK, ARM)), col)
