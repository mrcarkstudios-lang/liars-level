extends Node
## Autoload "Game": save data, progression, daily streak, taunts.

const SAVE_PATH := "user://liars_level_save.json"
const SKIN_NAMES := ["Cream", "Mint", "Coral", "Sky", "Gold", "Ghost"]
const SKIN_COLORS := [Color("fff1d6"), Color("8cf5c6"), Color("ff8f8f"), Color("7cc8ff"), Color("ffd45e"), Color("d9d4ff")]
const SKIN_SPRITES := [[9, 10], [0, 1], [4, 5], [2, 3], [6, 7], [0, 1]]   # Kenney astronaut frames per skin
const SKIN_UNLOCK := [0, 3, 7, 12, 18, 24]   # levels cleared needed
const SKIP_AFTER := 10

var data := {}
var level := 0          # current level index (0-based)
var daily_mode := false
var session_deaths := 0
var complete_shot := ""   # dev: screenshot path after level-complete overlay
var dev_pause_shot := ""
var force_touch := false
var seed_ghost := false   # dev: save a ghost made by the test bot for the level being opened
var hold_right := false   # dev: hero walks right by itself
var state_shot := ""
var state_shot_cond := ""
var autoplay := false   # dev: --autoplay drives the real game with the test bot

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_defaults()
	load_save()
	Sfx.set_music_on(data.music)
	Sfx.set_sfx_on(data.sfx)

func _defaults() -> void:
	data = {"done": {}, "skipped": {}, "deaths": 0, "stars": {}, "skin": 0, "music": true, "sfx": true,
		"streak": 0, "last_daily": -1, "best_streak": 0, "plays": 0, "level_deaths": {}, "ghosts": {}}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed:
			data[k] = parsed[k]

func save() -> void:
	if autoplay:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))

func level_count() -> int:
	return LevelData.LEVELS.size()

func level_info(i: int) -> Dictionary:
	return LevelData.LEVELS[clampi(i, 0, level_count() - 1)]

func is_done(i: int) -> bool:
	return data.done.has(str(i))

func is_unlocked(i: int) -> bool:
	if i <= 0:
		return true
	return is_done(i - 1) or data.skipped.has(str(i - 1))

func cleared_count() -> int:
	return data.done.size()

func next_unfinished() -> int:
	for i in level_count():
		if not is_done(i) and is_unlocked(i):
			return i
	return level_count() - 1

func level_deaths(i: int) -> int:
	return int(data.level_deaths.get(str(i), 0))

func add_death(i: int) -> void:
	data.deaths += 1
	session_deaths += 1
	data.level_deaths[str(i)] = level_deaths(i) + 1

## returns stats about the clear (new best?, streak, ...)
func complete_level(i: int, time: float, deaths: int, coins: int, coins_total: int) -> Dictionary:
	var key := str(i)
	var prev: Dictionary = data.done.get(key, {})
	var best_time := time
	var new_best := true
	if prev.has("time"):
		best_time = minf(float(prev.time), time)
		new_best = time < float(prev.time)
	data.done[key] = {"time": best_time}
	if coins_total > 0 and coins >= coins_total:
		data.stars[key] = true
	data.skipped.erase(key)
	var res := {"new_best": new_best, "best": best_time, "streak_up": false}
	if daily_mode and i == daily_index():
		var today := day_number()
		if int(data.last_daily) != today:
			if int(data.last_daily) == today - 1:
				data.streak = int(data.streak) + 1
			else:
				data.streak = 1
			data.last_daily = today
			data.best_streak = maxi(int(data.best_streak), int(data.streak))
			res.streak_up = true
	save()
	return res

func ghost_get(i: int) -> PackedByteArray:
	var k := str(i)
	if data.ghosts.has(k):
		return Marshalls.base64_to_raw(String(data.ghosts[k]))
	return PackedByteArray()

func ghost_set(i: int, bytes: PackedByteArray) -> void:
	data.ghosts[str(i)] = Marshalls.raw_to_base64(bytes)
	save()

func best_time(i: int) -> float:
	if is_done(i):
		return float(data.done[str(i)].time)
	return -1.0

func skip_level(i: int) -> void:
	data.skipped[str(i)] = true
	save()

func day_number() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

func daily_index() -> int:
	return int((day_number() * 7 + 3) % level_count())

func daily_done_today() -> bool:
	return int(data.last_daily) == day_number()

func streak_now() -> int:
	if int(data.last_daily) >= day_number() - 1:
		return int(data.streak)
	return 0

func skin_unlocked(i: int) -> bool:
	return cleared_count() >= SKIN_UNLOCK[i]

func skin_color() -> Color:
	return SKIN_COLORS[clampi(int(data.skin), 0, SKIN_COLORS.size() - 1)]

func cycle_skin() -> void:
	var n := SKIN_COLORS.size()
	var s := int(data.skin)
	for k in n:
		s = (s + 1) % n
		if skin_unlocked(s):
			break
	data.skin = s
	save()

func next_skin_hint() -> String:
	for i in SKIN_COLORS.size():
		if not skin_unlocked(i):
			return "%s skin at %d levels" % [SKIN_NAMES[i], SKIN_UNLOCK[i]]
	return "All skins unlocked"

func total_stars() -> int:
	return data.stars.size()

func rank() -> String:
	var c := cleared_count()
	if c >= 24:
		return "Master of Lies"
	if c >= 19:
		return "Lie Detector"
	if c >= 13:
		return "Professional Skeptic"
	if c >= 7:
		return "Trust Issues"
	if c >= 2:
		return "Slightly Suspicious"
	return "Gullible"

func world_music(i: int) -> String:
	if i >= level_count() - 1:
		return "music_boss"
	return "music_w%d" % clampi(int(level_info(i).world), 1, 5)

# ------------------------------------------------------------------ taunts
const TAUNTS := {
	"spike": ["Ouch. Pointy things are pointy.", "It was a spike. You saw it. Right?", "Spikes: 1. You: 0.", "Told you spikes hurt.", "That one was honest, too."],
	"hidden": ["Surprise! The floor lies.", "I never said that floor was safe.", "That spike was just shy.", "Floors lie. Write that down.", "Did you check the floor? Rude of me to ask."],
	"fall": ["Gravity wins again.", "Bottomless means bottomless.", "The floor was never there.", "Look down. Next time."],
	"crush": ["Look up. Always look up.", "Ceilings are not your friends.", "Crushed it. Literally.", "I said take your time. I lied."],
	"saw": ["Sliced.", "Wrong place, wrong time.", "Saws gonna saw.", "That's a lot of ouch."],
	"lava": ["Hot take: lava is hot.", "The floor really was lava.", "I did warn you. (I did not.)", "Toasty."],
	"fake": ["That door was fake. LOL.", "You trusted a door?", "Doors can lie too.", "Nice try. Wrong door."],
}
const GENERIC := ["Try again.", "Almost! (Not really.)", "Again. Again. Again.", "Pain is just learning.", "You'll get it. Probably.", "Everyone dies here. Everyone."]
const MILESTONES := {
	3: "Try reading the signs. Or don't.",
	5: "Fun fact: the signs lie.",
	8: "Hint: the thing that looks suspicious IS suspicious.",
	12: "Your persistence is adorable.",
	15: "You can skip this level. I won't judge. (I will.)",
	25: "Okay, now it's personal.",
	40: "You're still here? Respect.",
	60: "I'm running out of insults.",
	99: "Legend. Or stubborn. Same thing.",
}

func taunt(cause: String, deaths_level: int) -> String:
	if MILESTONES.has(deaths_level):
		return MILESTONES[deaths_level]
	var pool: Array = TAUNTS.get(cause, GENERIC)
	if randf() < 0.25:
		pool = GENERIC
	return pool[randi() % pool.size()]
