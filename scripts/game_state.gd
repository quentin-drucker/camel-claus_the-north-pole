extends Node
## Autoload: run timer, XP and level, and shared references for the current run.

signal xp_changed(xp: int, xp_needed: int)
signal leveled_up(level: int)
signal run_ended(won: bool)

const RUN_LENGTH: float = 300.0
## XP for level 1 -> 2, and how much more each following level needs.
const XP_BASE: int = 5
const XP_GROWTH: int = 3

var player: Player
var enemies: Array[Enemy] = []
var run_time: float = 0.0
var level: int = 1
var xp: int = 0
## Level-ups earned but not yet picked in the menu (one big XP grab can give several).
var pending_level_ups: int = 0
var kills: int = 0
var is_running: bool = false


func _process(delta: float) -> void:
	if not is_running:
		return
	run_time += delta
	if run_time >= RUN_LENGTH:
		end_run(true)


func start_run() -> void:
	run_time = 0.0
	level = 1
	xp = 0
	pending_level_ups = 0
	kills = 0
	is_running = true
	xp_changed.emit(xp, xp_needed())


func xp_needed() -> int:
	return XP_BASE + (level - 1) * XP_GROWTH


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_level_ups += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed())


func end_run(won: bool) -> void:
	if not is_running:
		return
	is_running = false
	run_ended.emit(won)
