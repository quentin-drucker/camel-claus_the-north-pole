class_name SantaSleigh
extends Node3D
## Santa's Sleigh, the kill-charged special (GameState holds the meter). Space / E with a full meter:
## the sleigh flies across the sky over Claus trailing gold sparkles and, halfway, drops Santa's
## present a few steps from him. The present (SantaPresent) does the landing blast and the homing,
## so it can never land out of reach. The sky pass is purely visual: no gameplay waits on it.

const SLEIGH: PackedScene = preload("res://scenes/santa/sleigh_model.tscn")
const PRESENT: PackedScene = preload("res://scenes/santa/santa_present.tscn")

@export var height: float = 3.2  # low enough to stay inside the narrow game camera
@export var fly_time: float = 2.2
## Distance flown, centred on Claus.
@export var span: float = 30.0
@export var sleigh_scale: float = 1.1
## How far from Claus the present lands.
@export var drop_distance: float = 2.5
## The present always lands inside this square (the arena walls are at 59).
@export var arena_half_size: float = 55.0


func _ready() -> void:
	GameState.santa_called.connect(_fly)
	GameState.santa_changed.connect(func(_p: int, _n: int, is_ready: bool) -> void:
		if is_ready:
			Audio.play(&"santa_ready"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("call_santa") and not get_tree().paused and GameState.call_santa():
		get_viewport().set_input_as_handled()


func _fly() -> void:
	Audio.play(&"sleigh")
	Audio.duck(2.0)
	# The camera looks down at ~55 deg: something `height` up shows ~0.7 x height further up the screen,
	# so fly that much closer to the camera (+Z) to pass right over Claus on screen.
	var claus: Vector3 = GameState.player.global_position + Vector3(0.0, 0.0, height * 0.7)
	var dir: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, randf_range(-0.6, 0.6)) * (1.0 if randf() < 0.5 else -1.0)
	var sleigh: Node3D = SLEIGH.instantiate()
	add_child(sleigh)
	sleigh.scale = Vector3.ONE * sleigh_scale
	sleigh.rotation.y = atan2(-dir.x, -dir.z)  # models face -Z
	sleigh.global_position = claus - dir * span * 0.5 + Vector3.UP * height
	sleigh.add_child(Poof.trail(Color("F2B53B"), 12))
	var tween: Tween = create_tween()
	tween.tween_property(sleigh, "global_position", claus + dir * span * 0.5 + Vector3.UP * height, fly_time)
	tween.tween_callback(sleigh.queue_free)
	get_tree().create_timer(fly_time * 0.5, false).timeout.connect(func() -> void: _drop(sleigh))


func _drop(sleigh: Node3D) -> void:
	if not is_instance_valid(sleigh) or not GameState.is_running:
		return
	var claus: Vector3 = GameState.player.global_position
	var spot: Vector3 = claus + Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * drop_distance
	spot.x = clampf(spot.x, -arena_half_size, arena_half_size)
	spot.z = clampf(spot.z, -arena_half_size, arena_half_size)
	spot.y = 0.0
	var present: SantaPresent = PRESENT.instantiate()
	present.drop_from = sleigh.global_position
	present.position = spot  # before add_child: _ready() measures the fall from here (parent sits at the origin)
	get_parent().add_child(present)
