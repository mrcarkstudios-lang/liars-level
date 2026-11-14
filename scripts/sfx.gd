extends Node
## Autoload "Sfx": sound effects pool + looping music with ducking.

const SFX_NAMES := ["jump", "land", "die", "win", "coin", "spring", "crumble", "pop", "whoosh", "sting", "button", "fake",
	"click", "back", "unlock", "thud", "reverse", "sign", "laugh", "tick", "rumble"]
const MUSIC_NAMES := ["music_menu", "music_w1", "music_w2", "music_w3", "music_w4", "music_w5", "music_boss"]

var sounds := {}
var music_streams := {}
var pool: Array[AudioStreamPlayer] = []
var pool_i := 0
var mp: AudioStreamPlayer
var current := ""
var sfx_on := true
var music_on := true
var music_base_db := -7.0
var _duck_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX_NAMES:
		var path := "res://audio/sfx_%s.wav" % n
		if ResourceLoader.exists(path):
			sounds[n] = load(path)
	for n in MUSIC_NAMES:
		var path2 := "res://audio/%s.wav" % n
		if ResourceLoader.exists(path2):
			var s: AudioStreamWAV = load(path2).duplicate()
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = s.data.size() / 2
			music_streams[n] = s
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -3.0
		add_child(p)
		pool.append(p)
	mp = AudioStreamPlayer.new()
	mp.volume_db = music_base_db
	add_child(mp)

func play(n: String, pitch := 1.0, db := 0.0) -> void:
	if not sfx_on or not sounds.has(n):
		return
	var p := pool[pool_i]
	pool_i = (pool_i + 1) % pool.size()
	p.stream = sounds[n]
	p.pitch_scale = pitch
	p.volume_db = -3.0 + db
	p.play()

func music(n: String) -> void:
	if n == current:
		return
	current = n
	if not music_streams.has(n):
		mp.stop()
		return
	mp.stream = music_streams[n]
	mp.volume_db = music_base_db
	if music_on:
		mp.play()

func stop_music() -> void:
	current = ""
	mp.stop()

func set_music_on(v: bool) -> void:
	music_on = v
	if v:
		mp.volume_db = music_base_db
		if mp.stream != null and not mp.playing:
			mp.play()
	else:
		mp.stop()

func set_sfx_on(v: bool) -> void:
	sfx_on = v

## quick volume dip so sound effects (and the Liar's jokes) cut through the music
func duck(db := -12.0, secs := 0.5) -> void:
	if not music_on:
		return
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	mp.volume_db = music_base_db + db
	_duck_tween = create_tween()
	_duck_tween.tween_property(mp, "volume_db", music_base_db, secs).set_delay(0.05)
