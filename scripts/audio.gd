extends Node
## Autoload "Audio": sound effects and music. Runs while the game is paused (menus).
## SFX: one pooled player per sound (max_polyphony caps overlap), small random pitch, and a minimum
## interval so 300 enemies can't stack 300 copies. Music: two synced stems; the "drive" stem fades
## in for the final stretch. Volumes are bus-based and saved in user://settings.cfg.

const SFX_DIR: String = "res://assets/audio/sfx/"
## name -> [file, volume_db, min_interval_s, polyphony]
const SFX: Dictionary = {
	&"throw": ["sfx_throw.ogg", -14.0, 0.07, 3],
	&"hit": ["sfx_hit.ogg", -16.0, 0.05, 3],
	&"pop": ["sfx_pop.ogg", -12.0, 0.04, 4],
	&"xp": ["sfx_xp.ogg", -14.0, 0.035, 4],
	&"hurt": ["sfx_hurt.ogg", -4.0, 0.2, 1],
	&"explode": ["sfx_explode.ogg", -12.0, 0.08, 3],
	&"freeze": ["sfx_freeze.ogg", -12.0, 0.12, 2],
	&"pulse": ["sfx_jingle_pulse.wav", -8.0, 0.1, 2],
	&"click": ["sfx_click.ogg", -6.0, 0.03, 2],
	&"menu": ["sfx_menu.ogg", -8.0, 0.1, 1],
	&"charge": ["sfx_charge.ogg", -6.0, 0.5, 1],
	&"splash": ["sfx_splash.wav", -10.0, 0.06, 3],
	&"mine": ["sfx_mine.wav", -12.0, 0.1, 2],
	&"magnet": ["sfx_magnet.wav", -4.0, 0.5, 1],
	&"heal": ["sfx_heal.wav", -6.0, 0.3, 1],
	&"lob": ["sfx_lob.wav", -10.0, 0.15, 2],
	&"sleigh": ["sfx_sleigh.wav", -3.0, 1.0, 1],
	&"santa_ready": ["sfx_santa_ready.wav", -5.0, 1.0, 1],
	&"levelup": ["jingle_levelup.wav", -4.0, 0.2, 1],
	&"chest": ["jingle_chest.wav", -4.0, 0.2, 1],
	&"evolve": ["jingle_evolve.wav", -2.0, 0.5, 1],
	&"boss": ["jingle_boss.wav", -2.0, 1.0, 1],
	&"win": ["jingle_win.wav", -2.0, 1.0, 1],
	&"lose": ["jingle_lose.wav", -2.0, 1.0, 1],
}
const SETTINGS_PATH: String = "user://settings.cfg"

var _players: Dictionary = {}  # name -> AudioStreamPlayer
var _last_played: Dictionary = {}  # name -> engine time (s)
var _music_base: AudioStreamPlayer
var _music_drive: AudioStreamPlayer
const SILENT_DB: float = -60.0

var _drive_db: float = SILENT_DB
var _drive_target_db: float = SILENT_DB
var _duck_db: float = 0.0
var _duck_until: float = 0.0
var _pause_duck: bool = false
## Extra dip while the Blizzard event howls (dB, 0 = none).
var blizzard_db: float = 0.0
var _xp_combo: int = 0
var _xp_last: float = -10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sfx_name: StringName in SFX:
		var entry: Array = SFX[sfx_name]
		var player := AudioStreamPlayer.new()
		player.stream = load(SFX_DIR + entry[0])
		player.volume_db = entry[1]
		player.max_polyphony = entry[3]
		player.bus = &"SFX"
		add_child(player)
		_players[sfx_name] = player
	_music_base = _music_player("res://assets/audio/music/music_base.wav")
	_music_drive = _music_player("res://assets/audio/music/music_drive.wav")
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		set_volume(&"Music", config.get_value("audio", "music", 0.8))
		set_volume(&"SFX", config.get_value("audio", "sfx", 0.8))


func play(sfx_name: StringName, pitch: float = 1.0, jitter: float = 0.06) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(sfx_name, -10.0) < SFX[sfx_name][2]:
		return
	_last_played[sfx_name] = now
	var player: AudioStreamPlayer = _players[sfx_name]
	player.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	player.play()


## XP pickups chain into a rising scale (resets after a short gap).
func play_xp() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_xp_combo = _xp_combo + 1 if now - _xp_last < 0.6 else 0
	_xp_last = now
	play(&"xp", 1.0 + mini(_xp_combo, 12) * 0.05, 0.0)


## Start the music if it isn't already playing (menus, restarts and runs share one continuous track),
## and drop back to the calm mix.
func play_music() -> void:
	_drive_target_db = SILENT_DB
	if not _music_base.playing:
		_drive_db = SILENT_DB
		_music_base.play()
		_music_drive.play()


func stop_music() -> void:
	_music_base.stop()
	_music_drive.stop()


## Fade the drive stem in (final stretch) or out.
func set_intensity(on: bool) -> void:
	_drive_target_db = 0.0 if on else SILENT_DB


## Dip the music for a moment (boss, evolution) without touching the player's Music slider.
func duck(seconds: float = 1.5) -> void:
	_duck_until = Time.get_ticks_msec() / 1000.0 + seconds


## Softer music while a pause menu is open.
func set_paused_duck(on: bool) -> void:
	_pause_duck = on


func _process(delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var duck_db: float = -10.0 if now < _duck_until else (-8.0 if _pause_duck else blizzard_db)
	_duck_db = move_toward(_duck_db, duck_db, delta * 40.0)
	_drive_db = move_toward(_drive_db, _drive_target_db, delta * 20.0)  # ~3 s fade in
	_music_base.volume_db = _duck_db
	_music_drive.volume_db = _drive_db + _duck_db


## 0..1 slider value -> bus gain (squared so the slider feels even), saved for next time.
func set_volume(bus_name: StringName, value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(idx, value <= 0.0)
	AudioServer.set_bus_volume_linear(idx, value * value)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music" if bus_name == &"Music" else "sfx", value)
	config.save(SETTINGS_PATH)


func get_volume(bus_name: StringName) -> float:
	return sqrt(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus_name)))


func _music_player(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.bus = &"Music"
	add_child(player)
	return player
