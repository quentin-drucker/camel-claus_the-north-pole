class_name Player
extends Node3D
## Claus. Moves on the ground plane with code (no physics body).
## Holds the global stats that upgrades and items raise; every weapon reads them.
## All weapon damage goes through deal_damage(), which applies item bonuses and on-hit procs.

signal health_changed(hp: float, max_hp: float)
signal died

## Weapons Claus can carry in one run (level-ups stop offering new ones once his hands are full).
const MAX_WEAPONS: int = 3

@export var base_speed: float = 5.0
@export var max_hp: float = 100.0
@export var base_pickup_radius: float = 2.5
@export var body_radius: float = 0.4
## Seconds of invulnerability after taking a hit (Claus blinks meanwhile).
@export var hurt_invulnerability: float = 0.75
## How fast the model turns to face the walking direction.
@export var turn_speed: float = 12.0
## Invisible walls: the player can't leave this square around the origin.
@export var arena_half_size: float = 59.0
@export var explosion_radius: float = 1.8
## Seconds between Chimney Draft pulls.
@export var xp_pull_interval: float = 20.0

var hp: float
## max_hp before any upgrades (pause-menu comparisons).
var base_max_hp: float
## Ground-plane velocity this frame (the spawner uses it to recycle enemies ahead of Claus).
var velocity: Vector3 = Vector3.ZERO
## Global stats raised by upgrades and items (Megabonk-"tome" style: shared by all weapons).
var damage_mult: float = 1.0
var attack_speed_bonus: float = 0.0
var extra_projectiles: int = 0
var move_speed_bonus: float = 0.0
var pickup_bonus: float = 0.0
## Item effects.
var poison_chance: float = 0.0
var explode_chance: float = 0.0
var freeze_chance: float = 0.0
var damage_per_kill: float = 0.0
var elite_damage_bonus: float = 0.0
var cheat_deaths: int = 0
var xp_pull: bool = false
## UpgradeData -> times picked, for level caps (weapon cards use the weapon's level instead).
var upgrade_levels: Dictionary = {}
## ItemData -> copies owned.
var items: Dictionary = {}
## Active Santa blessings: BlessingData -> seconds left (HUD timers).
var blessings: Dictionary = {}
## Hot Cocoa's damage multiplier (1 = none); kept apart from damage_mult so it doubles everything.
var blessing_damage: float = 1.0
## ponytail: debug-only god mode for the stress test (F2); remove before ship.
var invincible: bool = false

var _invulnerable_left: float = 0.0
var _base_scale: Vector3
var _anim_time: float = 0.0
var _squash: float = 0.0  # 1 right after a hit, eases back to 0
var _xp_pull_left: float = 0.0
var _shielded: int = 0
var _shield_fx_left: float = 0.0

@onready var body: Node3D = $Body


func _enter_tree() -> void:
	GameState.player = self


func _ready() -> void:
	base_max_hp = max_hp
	hp = max_hp
	# The run's starting weapon (picked on the loadout screen).
	var card: UpgradeData = Profile.weapon_card(GameState.starter)
	if card:
		add_child(card.weapon_scene.instantiate())
	Profile.apply_workshop(self)  # permanent Workshop bonuses (after base_max_hp, so they show as gains)
	GameState.weapon_evolved.connect(_on_weapon_evolved)
	body.rotation.y = PI  # start facing the camera (models face -Z)
	_base_scale = body.scale


func _process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector3(input.x, 0.0, input.y) * base_speed * (1.0 + move_speed_bonus)
	position += velocity * delta
	position.x = clampf(position.x, -arena_half_size, arena_half_size)
	position.z = clampf(position.z, -arena_half_size, arena_half_size)
	if input != Vector2.ZERO:
		var facing: float = atan2(-velocity.x, -velocity.z)
		body.rotation.y = lerp_angle(body.rotation.y, facing, 1.0 - exp(-turn_speed * delta))
	_animate(delta, input != Vector2.ZERO)
	if _invulnerable_left > 0.0:
		_invulnerable_left -= delta
		body.visible = _invulnerable_left <= 0.0 or fmod(_invulnerable_left, 0.1) < 0.05
	_tick_blessings(delta)
	if xp_pull:
		_xp_pull_left -= delta
		if _xp_pull_left <= 0.0:
			_xp_pull_left = xp_pull_interval
			get_tree().call_group(&"xp_ornaments", &"attract")


func _on_weapon_evolved(_weapon: Weapon) -> void:
	Audio.play(&"evolve")
	Audio.duck(1.5)
	Burst.spawn(Burst.GOLD, global_position, 4.0)
	Burst.spawn(Burst.ICE, global_position, 2.5)
	Poof.spawn(global_position, Color("F2B53B"), 20, 6.0)
	_squash = -0.6  # little stretch-up "power pose"
	get_tree().call_group(&"camera", &"shake", 0.3)


## Hop + squash-and-stretch while walking, slow breathing when idle, squash on hits.
func _animate(delta: float, moving: bool) -> void:
	_anim_time += delta * (14.0 if moving else 3.0)
	_squash = move_toward(_squash, 0.0, delta * 4.0)
	var wave: float = sin(_anim_time)
	var stretch: float = (absf(wave) * 0.08 if moving else wave * 0.02) - _squash * 0.25
	body.scale = _base_scale * Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
	body.position.y = absf(wave) * 0.12 if moving else 0.0


func get_pickup_radius() -> float:
	return base_pickup_radius * (1.0 + pickup_bonus)


func weapons() -> Array[Weapon]:
	var found: Array[Weapon] = []
	for child in get_children():
		if child is Weapon:
			found.append(child)
	return found


func find_weapon(scene: PackedScene) -> Weapon:
	for w in weapons():
		if w.scene_file_path == scene.resource_path:
			return w
	return null


## `source` names who hit (a weapon's display name, an item or event) for the results damage table.
func deal_damage(enemy: Enemy, amount: float, can_proc: bool = true, source: String = "Other") -> void:
	var dmg: float = amount * (1.0 + minf(GameState.kills * damage_per_kill, 0.6)) * blessing_damage
	if enemy.is_elite or enemy.is_boss:
		dmg *= 1.0 + elite_damage_bonus
	var pos: Vector3 = enemy.global_position
	var dealt: float = minf(dmg, maxf(enemy.hp, 0.0))
	GameState.damage_dealt += dealt
	GameState.damage_by[source] = GameState.damage_by.get(source, 0.0) + dealt
	enemy.take_damage(dmg)
	DamageNumber.spawn(pos, dmg, Color("F4F8FF") if can_proc else Color("F2B53B"))
	if not can_proc:
		return
	Audio.play(&"hit")
	if poison_chance > 0.0 and randf() < poison_chance:
		enemy.poison(dmg * 0.6 / 3.0, 3.0)
	if freeze_chance > 0.0 and randf() < freeze_chance:
		enemy.freeze(1.0)
		Audio.play(&"freeze")
	if explode_chance > 0.0 and randf() < explode_chance:
		for other: Enemy in GameState.enemies.duplicate():
			if other != enemy and other.global_position.distance_to(pos) < explosion_radius + other.radius:
				deal_damage(other, dmg * 0.6, false, "Christmas Cracker")
		Burst.spawn(Burst.RED, pos, explosion_radius)
		Audio.play(&"explode")
		get_tree().call_group(&"camera", &"shake", 0.12)


func take_damage(amount: float) -> void:
	if hp <= 0.0 or invincible or _invulnerable_left > 0.0 or _shielded > 0:
		return
	GameState.damage_taken += minf(amount, hp)
	hp = maxf(hp - amount, 0.0)
	_invulnerable_left = hurt_invulnerability
	_squash = 1.0
	Audio.play(&"hurt")
	get_tree().call_group(&"camera", &"shake", 0.4)
	if hp == 0.0 and cheat_deaths > 0:
		_cheat_death()
	health_changed.emit(hp, max_hp)
	if hp == 0.0:
		died.emit()
		GameState.end_run(false)


func _cheat_death() -> void:
	cheat_deaths -= 1
	hp = max_hp * 0.3
	_invulnerable_left = 2.0
	for enemy: Enemy in GameState.enemies:
		if enemy.global_position.distance_to(global_position) < 7.0:
			enemy.freeze(2.5)
	Burst.spawn(Burst.GOLD, global_position, 7.0)


func upgrade_level(upgrade: UpgradeData) -> int:
	if upgrade.stat == UpgradeData.Stat.WEAPON:
		var weapon: Weapon = find_weapon(upgrade.weapon_scene)
		return weapon.level if weapon else 0
	return upgrade_levels.get(upgrade, 0)


func apply_upgrade(upgrade: UpgradeData, rarity_mult: float = 1.0) -> void:
	upgrade_levels[upgrade] = upgrade_levels.get(upgrade, 0) + 1
	var amount: float = upgrade.amount * (rarity_mult if upgrade.scales_with_rarity else 1.0)
	match upgrade.stat:
		UpgradeData.Stat.MOVE_SPEED:
			move_speed_bonus += amount
		UpgradeData.Stat.MAX_HP:
			_add_max_hp(amount)
		UpgradeData.Stat.PICKUP_RADIUS:
			pickup_bonus += amount
		UpgradeData.Stat.DAMAGE:
			damage_mult += amount
		UpgradeData.Stat.ATTACK_SPEED:
			attack_speed_bonus += amount
		UpgradeData.Stat.PROJECTILES:
			extra_projectiles += int(amount)
		UpgradeData.Stat.WEAPON:
			var weapon: Weapon = find_weapon(upgrade.weapon_scene)
			if weapon:
				weapon.level += 1
			else:
				add_child(upgrade.weapon_scene.instantiate())


func add_item(item: ItemData) -> void:
	items[item] = items.get(item, 0) + 1
	match item.effect:
		ItemData.Effect.DAMAGE:
			damage_mult += item.amount
		ItemData.Effect.ATTACK_SPEED:
			attack_speed_bonus += item.amount
		ItemData.Effect.PROJECTILES:
			extra_projectiles += int(item.amount)
		ItemData.Effect.MAX_HP:
			_add_max_hp(item.amount)
		ItemData.Effect.POISON_CHANCE:
			poison_chance += item.amount
		ItemData.Effect.EXPLODE_CHANCE:
			explode_chance += item.amount
		ItemData.Effect.FREEZE_CHANCE:
			freeze_chance += item.amount
		ItemData.Effect.DAMAGE_PER_KILL:
			damage_per_kill += item.amount
		ItemData.Effect.CHEAT_DEATH:
			cheat_deaths += 1
		ItemData.Effect.XP_PULL:
			xp_pull = true
		ItemData.Effect.ELITE_DAMAGE:
			elite_damage_bonus += item.amount


## Weapons at level 5 whose evolution item Claus owns.
func evolvable_weapons() -> Array[Weapon]:
	var found: Array[Weapon] = []
	found.assign(weapons().filter(func(w: Weapon) -> bool: return w.can_evolve()))
	return found


## Santa's blessing: instant effects happen now; timed ones refresh if already active.
func bless(blessing: BlessingData) -> void:
	match blessing.effect:
		BlessingData.Effect.MAGNET:
			get_tree().call_group(&"xp_ornaments", &"attract")
			Audio.play(&"magnet")
		BlessingData.Effect.BLIZZARD:
			_blizzard(blessing)
			return
	Burst.spawn(Burst.GOLD, global_position, 3.0)
	if not blessings.has(blessing):
		_blessing_apply(blessing, 1.0)
	blessings[blessing] = blessing.duration


func _tick_blessings(delta: float) -> void:
	for blessing: BlessingData in blessings.keys():
		blessings[blessing] -= delta
		if blessings[blessing] <= 0.0:
			blessings.erase(blessing)
			_blessing_apply(blessing, -1.0)
	if _shielded > 0:  # Snow Angel: a soft ice ring every half second
		_shield_fx_left -= delta
		if _shield_fx_left <= 0.0:
			_shield_fx_left = 0.5
			Burst.spawn(Burst.ICE, global_position, 1.4)


## Add (on = 1) or take back (on = -1) a timed blessing's bonus.
func _blessing_apply(blessing: BlessingData, on: float) -> void:
	var a: float = blessing.amount * on
	match blessing.effect:
		BlessingData.Effect.DAMAGE:
			blessing_damage += a
		BlessingData.Effect.RUSH:
			move_speed_bonus += a
			attack_speed_bonus += a
		BlessingData.Effect.XP:
			GameState.xp_mult += a
		BlessingData.Effect.MAGNET:
			pickup_bonus += a
		BlessingData.Effect.SHIELD:
			_shielded += int(on)


func _blizzard(blessing: BlessingData) -> void:
	for enemy: Enemy in GameState.enemies.duplicate():
		if enemy.global_position.distance_to(global_position) > 18.0:
			continue
		var big: bool = enemy.is_elite or enemy.is_boss
		deal_damage(enemy, enemy.max_hp * (0.05 if big else blessing.amount), false, "Blizzard")
		enemy.freeze(blessing.duration)
	Burst.spawn(Burst.ICE, global_position, 9.0)
	Burst.spawn(Burst.ICE, global_position, 14.0)
	Poof.spawn(global_position, Color("F4F8FF"), 30, 8.0)
	Audio.play(&"freeze")
	get_tree().call_group(&"camera", &"shake", 0.5)


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


func _add_max_hp(amount: float) -> void:
	max_hp += amount
	hp += amount
	health_changed.emit(hp, max_hp)
