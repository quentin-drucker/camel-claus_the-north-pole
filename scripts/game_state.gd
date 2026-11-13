extends Node
## Autoload: everything about the current run — timer, XP and level, the loadout, Santa's Sleigh
## charge, reroll/banish charges, and the run totals the results screen and lifetime stats read.
## Meta-progression (coins, unlocks, saved loadout) lives in the Profile autoload.

signal xp_changed(xp: int, xp_needed: int)
signal leveled_up(level: int)
signal chest_found
## A weapon just evolved (HUD banner, effects).
signal weapon_evolved(weapon: Weapon)
signal run_ended(won: bool)
## Santa's Sleigh meter moved (HUD).
signal santa_changed(progress: int, needed: int, ready: bool)
## The player called the sleigh (SantaSleigh flies over and drops a present).
signal santa_called
## Santa's present was picked up: the reward menu opens.
signal santa_present_found
## The player chose "Keep going" after surviving 5:00 (HUD banner, music).
signal endless_started

const RUN_LENGTH: float = 300.0
## XP for level 1 -> 2, and how much more each following level needs.
const XP_BASE: int = 5
const XP_GROWTH: int = 4
## Kills needed for each Santa's Sleigh charge: a quick first one that teaches the mechanic, then
## steps sized to the kill curve (≈90 kills by 1:00, 410 by 3:00, 1000 by 5:00): calls land around
## 0:10, 1:50, 3:20 and 4:45 for an average player (a strong one kills faster and gets them earlier).
## After the list, each charge needs SANTA_KILLS_GROWTH more than the last.
const SANTA_KILLS: Array[int] = [8, 180, 300, 420]
const SANTA_KILLS_GROWTH: int = 100
const REROLLS: int = 2
const BANISHES: int = 1

var player: Player
var enemies: Array[Enemy] = []
## The final boss while it's alive (HUD shows its HP bar), else null.
var boss: Enemy
var run_time: float = 0.0
var level: int = 1
var xp: int = 0
## Level-ups earned but not yet picked in the menu (one big XP grab can give several).
var pending_level_ups: int = 0
## Chests opened but not yet picked from.
var pending_chests: int = 0
## Santa's presents picked up but not yet opened.
var pending_santa: int = 0
var kills: int = 0
var is_running: bool = false

## This run's weapon pool (ids, see Profile) and the one Claus starts with.
var loadout: Array[String] = []
var starter: String = "gift_toss"
## Multiplies XP from ornaments (Christmas Spirit blessing, Workshop upgrade).
var xp_mult: float = 1.0
## Multiplies every enemy's walking speed (the Blizzard event).
var enemy_speed_mult: float = 1.0
## Multiplies enemy contact and snowball damage (grows during Endless).
var enemy_damage_mult: float = 1.0
var rerolls: int = REROLLS
var banishes: int = BANISHES
## Level-up cards removed from this run's pool.
var banished: Array[UpgradeData] = []

## Santa's Sleigh: kills toward the next charge; a full meter holds (no stockpiling) until called.
var santa_progress: int = 0
var santa_ready: bool = false
var santa_calls: int = 0

## Run totals (results screen, lifetime stats, achievements).
var damage_dealt: float = 0.0
## Damage by source for the results table: weapon display name (or "Christmas Cracker", "Snow bomb",
## "Santa's Sleigh", "Blizzard") -> damage.
var damage_by: Dictionary = {}
var damage_taken: float = 0.0
var elites_killed: int = 0
var bosses_killed: int = 0
var evolutions: int = 0
var xp_collected: int = 0
var won: bool = false
## Set once Profile.record_run() has added this run to the lifetime stats (never counted twice).
var recorded: bool = false
## Run totals at the last record (empty = never recorded); an Endless continuation records only the rest.
var record_base: Dictionary = {}
## Endless mode: the run went on past 5:00 and ends only when Claus faints.
var endless: bool = false

var _xp_carry: float = 0.0


func _process(delta: float) -> void:
	if not is_running:
		return
	run_time += delta
	if run_time >= RUN_LENGTH and not endless:
		end_run(true)


func start_run() -> void:
	run_time = 0.0
	level = 1
	xp = 0
	_xp_carry = 0.0
	pending_level_ups = 0
	pending_chests = 0
	pending_santa = 0
	kills = 0
	boss = null
	loadout = Profile.loadout()
	starter = Profile.starter()
	xp_mult = 1.0 + Profile.workshop_bonus(WorkshopData.Stat.XP)
	rerolls = REROLLS + int(Profile.workshop_bonus(WorkshopData.Stat.REROLLS))
	banishes = BANISHES + int(Profile.workshop_bonus(WorkshopData.Stat.BANISHES))
	banished.clear()
	santa_progress = 0
	santa_ready = false
	santa_calls = 0
	damage_dealt = 0.0
	damage_by = {}
	damage_taken = 0.0
	elites_killed = 0
	bosses_killed = 0
	evolutions = 0
	xp_collected = 0
	won = false
	recorded = false
	record_base = {}
	endless = false
	enemy_speed_mult = 1.0
	enemy_damage_mult = 1.0
	is_running = true
	xp_changed.emit(xp, xp_needed())
	santa_changed.emit(santa_progress, santa_needed(), santa_ready)


func xp_needed() -> int:
	return XP_BASE + (level - 1) * XP_GROWTH


func add_xp(amount: int) -> void:
	_xp_carry += amount * xp_mult  # fractional multipliers carry over instead of rounding away
	var whole: int = floori(_xp_carry)
	_xp_carry -= whole
	xp += whole
	xp_collected += whole
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_level_ups += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed())


func add_chest() -> void:
	pending_chests += 1
	chest_found.emit()


## Every enemy death goes through here (Enemy._die).
func register_kill(enemy: Enemy) -> void:
	kills += 1
	if enemy.is_elite:
		elites_killed += 1
	if enemy.is_boss:
		bosses_killed += 1
	if santa_ready:
		return  # full meter holds; extra kills don't bank
	santa_progress += 1
	if santa_progress >= santa_needed():
		santa_progress = santa_needed()
		santa_ready = true
	santa_changed.emit(santa_progress, santa_needed(), santa_ready)


## Kills the current charge needs.
func santa_needed() -> int:
	if santa_calls < SANTA_KILLS.size():
		return SANTA_KILLS[santa_calls]
	return SANTA_KILLS[-1] + SANTA_KILLS_GROWTH * (santa_calls - SANTA_KILLS.size() + 1)


## Spend a full meter: the sleigh flies (SantaSleigh listens). Returns false if not ready.
func call_santa() -> bool:
	if not santa_ready or not is_running:
		return false
	santa_ready = false
	santa_progress = 0
	santa_calls += 1
	santa_called.emit()
	santa_changed.emit(santa_progress, santa_needed(), santa_ready)
	return true


func add_santa_present() -> void:
	pending_santa += 1
	santa_present_found.emit()


func evolve_weapon(weapon: Weapon) -> void:
	weapon.evolve()
	evolutions += 1
	weapon_evolved.emit(weapon)


## After a win: keep the same run going with no time limit (results screen "Keep going").
func continue_endless() -> void:
	if is_running or not won:
		return
	endless = true
	recorded = false
	is_running = true
	endless_started.emit()


## Leaving mid-run (pause menu -> restart / main menu): stop the run without the end screen.
func end_run_silently() -> void:
	is_running = false


func end_run(did_win: bool) -> void:
	if not is_running:
		return
	is_running = false
	won = did_win
	run_ended.emit(did_win)
