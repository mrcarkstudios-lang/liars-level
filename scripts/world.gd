class_name World
extends RefCounted
## Deterministic simulation of one level: player physics + every lie in the game.
## No rendering and no engine nodes in here, so it can be unit-tested headless.

const T := 40
const COLS := 32
const ROWS := 18

const GRAV := 2300.0
const MAX_FALL := 1150.0
const RUN := 275.0
const ACC_G := 3200.0
const ACC_A := 2100.0
const FRICTION := 3600.0
const JUMP_V := 790.0
const SPRING_V := 1150.0
const COYOTE := 0.09
const BUFFER := 0.12
const PW := 24.0
const PH := 32.0
const RESPAWN_DELAY := 0.38
const CRUMBLE_DELAY := 0.28
const PIT_DELAY := 0.10
const BLOCK_SHAKE := 0.28
const DODGE_RANGE := 125.0
const SAW_R := 15.0
const SAW_SPEED := 130.0
const PLAT_SPEED := 100.0
const PLAT_HEAD := 34.0
const LAVA_SPEED := 30.0
const LAVA_DELAY := 2.5
const FAKE_TIME := 2.8

class Ent:
	var k: String
	var pos: Vector2 = Vector2.ZERO   # top-left (saws: centre)
	var size: Vector2 = Vector2.ZERO
	var st: int = 0
	var t: float = 0.0
	var vel: Vector2 = Vector2.ZERO
	var home: Vector2 = Vector2.ZERO
	var idx: int = 0
	var dir: Vector2 = Vector2.ZERO
	var dir0: Vector2 = Vector2.ZERO
	var flag: bool = false
	func rect() -> Rect2:
		return Rect2(pos, size)
	func center() -> Vector2:
		return pos + size * 0.5

# ---- level data
var map: PackedStringArray = PackedStringArray()
var sign_texts: Array = []
var grid: PackedByteArray = PackedByteArray()
var ents: Array = []
var dests: Array = []
var start: Vector2 = Vector2.ZERO

# ---- player state
var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var on_ground: bool = false
var coyote: float = 0.0
var buffer: float = 0.0
var face: int = 1
var reversed: bool = false
var boosted: bool = false
var gdir: float = 1.0          # +1 gravity down, -1 gravity up (gravity pads)
var pad_cd: float = 0.0
var has_lava: bool = false
var lava_y: float = 0.0
var moved: bool = false
var since_move: float = 0.0
var fake_t: float = 0.0
var sq: Vector2 = Vector2.ONE
var state: String = "play"   # play | dead | won
var cause: String = ""
var dead_t: float = 0.0
var win_t: float = 0.0
var win_pos: Vector2 = Vector2.ZERO
var time: float = 0.0
var coins: int = 0
var coins_total: int = 0
var sign_idx: int = -1
var near_sign: String = ""
var events: Array = []
var _solids: Array = []

func load_level(m: PackedStringArray, signs: Array) -> void:
	map = m
	sign_texts = signs
	grid = PackedByteArray()
	grid.resize(COLS * ROWS)
	ents = []
	dests = []
	coins_total = 0
	has_lava = false
	var sign_n := 0
	var dest_chars := {}
	for r in ROWS:
		var row := m[r]
		for c in COLS:
			var ch := row[c]
			var cell := Vector2(c * T, r * T)
			var e: Ent = null
			match ch:
				"#":
					grid[r * COLS + c] = 1
				"P":
					start = Vector2(c * T + (T - PW) * 0.5, (r + 1) * T - PH)
				"D", "F", "E":
					e = _mk(ch, Vector2(c * T + 6, (r + 1) * T - 52), Vector2(28, 52))
				"e", "f", "g":
					dest_chars[ch] = Vector2(c * T + 6, (r + 1) * T - 52)
				"^", "h":
					e = _mk(ch, cell, Vector2(T, T))
				"v":
					e = _mk(ch, cell, Vector2(T, T))
				"o", "p", "c", "i", "G":
					e = _mk(ch, cell, Vector2(T, T))
				"S":
					e = _mk(ch, cell, Vector2(T, T))
					e.idx = sign_n
					sign_n += 1
				"b", "d":
					e = _mk(ch, Vector2(c * T + 4, (r + 1) * T - 12), Vector2(T - 8, 12))
				"C", "q":
					e = _mk(ch, cell + Vector2(8, 8), Vector2(24, 24))
					if ch == "C":
						coins_total += 1
				"B":
					e = _mk(ch, Vector2(c * T + 2, r * T + 22), Vector2(T - 4, 18))
				"m", "n", "M", "N":
					e = _mk(ch, Vector2(c * T, r * T), Vector2(80, 14))
					e.dir = {"m": Vector2.RIGHT, "n": Vector2.LEFT, "M": Vector2.UP, "N": Vector2.DOWN}[ch]
				"K", "Q":
					e = _mk(ch, Vector2(c * T + 6, (r + 1) * T - 52), Vector2(28, 52))
				"Y":
					e = _mk(ch, cell, Vector2(T, T))
				"L":
					has_lava = true
				"w", "W", "x", "X":
					e = _mk(ch, cell + Vector2(20, 20), Vector2(SAW_R, SAW_R))
					e.dir = {"w": Vector2.RIGHT, "W": Vector2.LEFT, "x": Vector2.DOWN, "X": Vector2.UP}[ch]
			if e != null:
				e.dir0 = e.dir
				ents.append(e)
	for k in ["e", "f", "g"]:
		if dest_chars.has(k):
			dests.append(dest_chars[k])
	reset()

func _mk(k: String, p: Vector2, s: Vector2) -> Ent:
	var e := Ent.new()
	e.k = k
	e.pos = p
	e.size = s
	e.home = p
	return e

func reset() -> void:
	# restore all entities to their initial state
	for e: Ent in ents:
		e.pos = e.home
		e.st = 0
		e.t = 0.0
		e.vel = Vector2.ZERO
		e.dir = e.dir0
		if e.k in ["m", "n", "M", "N"]:
			e.vel.x = 1.0
		e.flag = false
		e.idx = e.idx if e.k == "S" else 0
	pos = start
	vel = Vector2.ZERO
	on_ground = false
	coyote = 0.0
	buffer = 0.0
	face = 1
	reversed = false
	boosted = false
	gdir = 1.0
	pad_cd = 0.0
	lava_y = ROWS * T + 60.0
	moved = false
	since_move = 0.0
	fake_t = 0.0
	sq = Vector2.ONE
	state = "play"
	cause = ""
	dead_t = 0.0
	win_t = 0.0
	time = 0.0
	coins = 0
	sign_idx = -1
	near_sign = ""
	events = []

func sfx(n: String) -> void:
	events.append({"t": "sfx", "n": n})

func tile_solid(c: int, r: int) -> bool:
	if c < 0 or c >= COLS:
		return true
	if r < 0:
		return true
	if r >= ROWS:
		return false
	return grid[r * COLS + c] == 1

func player_rect() -> Rect2:
	return Rect2(pos, Vector2(PW, PH))

func player_center() -> Vector2:
	return pos + Vector2(PW, PH) * 0.5

# ------------------------------------------------------------------ main step
func step(dt: float, inp: Dictionary) -> void:
	if state == "dead":
		dead_t += dt
		return
	if state == "won":
		win_t += dt
		return
	if state == "fake":
		fake_t += dt
		if fake_t >= FAKE_TIME:
			state = "play"
			for e: Ent in ents:
				if e.k == "Q":
					e.st = 1
				elif e.k == "K":
					e.st = 2
			events.append({"t": "fakeend"})
			sfx("fake")
			sfx("laugh")
		return
	if not moved and (inp.get("dir", 0) != 0 or inp.get("jump_pressed", false)):
		moved = true
	time += dt
	pad_cd = maxf(0.0, pad_cd - dt)
	_update_ents(dt)
	if state != "play":
		return
	if has_lava and moved:
		var before := since_move
		since_move += dt
		if since_move > LAVA_DELAY:
			if before <= LAVA_DELAY:
				events.append({"t": "lava_start"})
				sfx("rumble")
			lava_y -= LAVA_SPEED * dt
	_player_move(dt, inp)
	_interactions(dt)

func _player_move(dt: float, inp: Dictionary) -> void:
	var dir := float(inp.get("dir", 0))
	if reversed:
		dir = -dir
	var target := dir * RUN
	var acc := ACC_G if on_ground else ACC_A
	if dir == 0.0:
		acc = FRICTION if on_ground else 500.0
	vel.x = move_toward(vel.x, target, acc * dt)
	if dir != 0.0:
		face = 1 if dir > 0.0 else -1
	if inp.get("jump_pressed", false):
		buffer = BUFFER
	else:
		buffer = maxf(0.0, buffer - dt)
	coyote = COYOTE if on_ground else maxf(0.0, coyote - dt)
	if buffer > 0.0 and coyote > 0.0:
		vel.y = -JUMP_V * gdir
		buffer = 0.0
		coyote = 0.0
		on_ground = false
		sq = Vector2(0.78, 1.28)
		sfx("jump")
		events.append({"t": "dust", "pos": Vector2(pos.x + PW * 0.5, pos.y + (PH if gdir > 0.0 else 0.0))})
	var g := GRAV
	if vel.y * gdir >= 0.0:
		boosted = false
	if vel.y * gdir < 0.0 and not boosted and not inp.get("jump_held", false):
		g *= 2.6
	vel.y += g * gdir * dt
	if gdir > 0.0:
		vel.y = minf(vel.y, MAX_FALL)
	else:
		vel.y = maxf(vel.y, -MAX_FALL)
	_solids = _entity_solids()
	_move_x(vel.x * dt)
	var was_ground := on_ground
	var vy_before := vel.y
	on_ground = false
	_move_y(vel.y * dt)
	if on_ground and not was_ground and vy_before * gdir > 380.0:
		sq = Vector2(1.3, 0.72)
		sfx("land")
		events.append({"t": "dust", "pos": Vector2(pos.x + PW * 0.5, pos.y + (PH if gdir > 0.0 else 0.0))})
	sq = sq.lerp(Vector2.ONE, minf(1.0, dt * 14.0))

func _entity_solids() -> Array:
	var out := []
	for e: Ent in ents:
		match e.k:
			"o", "p":
				if e.st < 2:
					out.append(e.rect())
			"c":
				if e.st != 2:
					out.append(e.rect())
			"i":
				out.append(e.rect())
			"G":
				if e.st == 0:
					out.append(e.rect())
			"m", "n", "M", "N":
				out.append(e.rect())
	return out

func _tile_rects(r: Rect2) -> Array:
	var out := []
	var c0 := int(floor(r.position.x / T))
	var c1 := int(floor((r.end.x - 0.001) / T))
	var r0 := int(floor(r.position.y / T))
	var r1 := int(floor((r.end.y - 0.001) / T))
	for cy in range(r0, r1 + 1):
		for cx in range(c0, c1 + 1):
			if tile_solid(cx, cy):
				out.append(Rect2(cx * T, cy * T, T, T))
	return out

func _move_x(dx: float) -> void:
	if dx == 0.0:
		return
	pos.x += dx
	var r := player_rect()
	var all := _tile_rects(r)
	for s in _solids:
		if r.intersects(s):
			all.append(s)
	for s in all:
		r = player_rect()
		if r.intersects(s):
			if dx > 0.0:
				pos.x = s.position.x - PW
			else:
				pos.x = s.end.x
			vel.x = 0.0

func _move_y(dy: float) -> void:
	if dy == 0.0:
		return
	pos.y += dy
	var r := player_rect()
	var all := _tile_rects(r)
	for s in _solids:
		if r.intersects(s):
			all.append(s)
	for s in all:
		r = player_rect()
		if r.intersects(s):
			if dy > 0.0:
				pos.y = s.position.y - PH
				if gdir > 0.0:
					on_ground = true
			else:
				pos.y = s.end.y
				if gdir < 0.0:
					on_ground = true
			vel.y = 0.0

# ------------------------------------------------------------------ entities
func _update_ents(dt: float) -> void:
	var pc := player_center()
	var pr := player_rect()
	for e: Ent in ents:
		match e.k:
			"o":
				if e.st == 0:
					if on_ground and absf((pos.y + PH) - e.pos.y) < 1.5 and pr.position.x < e.pos.x + e.size.x - 2.0 and pr.end.x > e.pos.x + 2.0:
						e.st = 1
						e.t = 0.0
						sfx("crumble")
				elif e.st == 1:
					e.t += dt
					if e.t >= CRUMBLE_DELAY:
						e.st = 2
						e.vel.y = 0.0
				elif e.st == 2:
					e.vel.y += 2000.0 * dt
					e.pos.y += e.vel.y * dt
			"p":
				if e.st == 0:
					var ec := e.center()
					if absf(pc.x - ec.x) < 58.0 and pos.y + PH <= e.pos.y + 6.0 and pos.y > e.pos.y - 170.0:
						e.st = 1
						e.t = 0.0
						sfx("crumble")
				elif e.st == 1:
					e.t += dt
					if e.t >= PIT_DELAY:
						e.st = 2
				elif e.st == 2:
					e.vel.y += 2000.0 * dt
					e.pos.y += e.vel.y * dt
			"c":
				if e.st == 0:
					var ec2 := e.center()
					if absf(pc.x - ec2.x) < 34.0 and pc.y > e.pos.y + e.size.y:
						e.st = 1
						e.t = 0.0
						sfx("tick")
				elif e.st == 1:
					e.t += dt
					if e.t >= BLOCK_SHAKE:
						e.st = 2
						e.vel.y = 0.0
				elif e.st == 2:
					e.vel.y = minf(e.vel.y + 2800.0 * dt, 1500.0)
					var ny: float = e.pos.y + e.vel.y * dt
					var col := int(floor((e.pos.x + 20.0) / T))
					var row := int(floor((ny + e.size.y) / T))
					var land_y := INF
					if tile_solid(col, row):
						land_y = row * T - e.size.y
					for o: Ent in ents:
						if o != e and o.k == "c" and o.st == 3 and absf(o.pos.x - e.pos.x) < 1.0 and o.pos.y >= e.pos.y + e.size.y - 1.0 and ny + e.size.y >= o.pos.y:
							land_y = minf(land_y, o.pos.y - e.size.y)
					if land_y < INF:
						e.pos.y = land_y
						e.st = 3
						sfx("thud")
						events.append({"t": "shake", "a": 6.0})
					else:
						e.pos.y = ny
			"h":
				if e.st == 0:
					var ec3 := e.center()
					if absf(pc.x - ec3.x) < 52.0 and pc.y > e.pos.y - 75.0 and pc.y < e.pos.y + T:
						e.st = 1
						e.t = 0.0
						sfx("pop")
				elif e.st == 1:
					e.t += dt
					if e.t >= 0.08:
						e.st = 2
			"E":
				if e.st == 0 and e.idx < dests.size() and e.t <= 0.0:
					if pc.distance_to(e.center()) < DODGE_RANGE:
						e.st = 1
						sfx("whoosh")
				elif e.st == 1:
					var target: Vector2 = dests[e.idx]
					var d := target - e.pos
					var stp := 1100.0 * dt
					if d.length() <= stp:
						e.pos = target
						e.st = 0
						e.idx += 1
						e.t = 0.35
					else:
						e.pos += d.normalized() * stp
				if e.t > 0.0 and e.st == 0:
					e.t = maxf(0.0, e.t - dt)
			"G":
				if e.st == 1:
					e.t = minf(1.0, e.t + dt * 4.0)
			"B":
				if e.t > 0.0:
					e.t = maxf(0.0, e.t - dt)
			"w", "W", "x", "X":
				if moved:
					_move_saw(e, dt)
			"m", "n", "M", "N":
				_move_plat(e, dt)

func _move_plat(e: Ent, dt: float) -> void:
	if e.vel.x > 0.0:   # dwell at the ends so players can board
		if moved:
			e.vel.x -= dt
		return
	var delta: Vector2 = e.dir * PLAT_SPEED * dt
	var nr := Rect2(e.pos + delta, e.size)
	var probe := Rect2(nr.position + Vector2(0, -PLAT_HEAD), nr.size + Vector2(0, PLAT_HEAD))
	if not _tile_rects(probe).is_empty():
		e.dir = -e.dir
		e.vel.x = 1.0
		return
	var pr := player_rect()
	var riding := on_ground and absf((pos.y + PH) - e.pos.y) < 2.5 and pr.end.x > e.pos.x + 1.0 and pr.position.x < e.pos.x + e.size.x - 1.0
	e.pos += delta
	e.t += dt
	if riding:
		pos += delta
		if not _tile_rects(player_rect()).is_empty():
			_die("crush")
	elif player_rect().intersects(e.rect()):
		if delta.x != 0.0:
			pos.x = e.pos.x + e.size.x if delta.x > 0.0 else e.pos.x - PW
		elif delta.y < 0.0:
			pos.y = e.pos.y - PH
			on_ground = true
		else:
			pos.y = e.pos.y + e.size.y

func _move_saw(e: Ent, dt: float) -> void:
	var np: Vector2 = e.pos + e.dir * SAW_SPEED * dt
	var lead := np + e.dir * (SAW_R + 1.0)
	var c := int(floor(lead.x / T))
	var r := int(floor(lead.y / T))
	var blocked := tile_solid(c, r)
	if not blocked:
		for g: Ent in ents:
			if g.k == "G" and g.st == 0 and g.rect().has_point(lead):
				blocked = true
	if blocked:
		e.dir = -e.dir
	else:
		e.pos = np
	e.t += dt

# ------------------------------------------------------------------ interactions
func _interactions(dt: float) -> void:
	var pr := player_rect()
	var pc := player_center()
	if pos.y > ROWS * T + 60.0 or pos.y < -140.0:
		_die("fall")
		return
	if has_lava and pos.y + PH > lava_y + 4.0:
		_die("lava")
		return
	var near := -1
	for e: Ent in ents:
		match e.k:
			"^":
				if pr.intersects(Rect2(e.pos.x + 8, e.pos.y + 20, 24, 20)):
					_die("spike")
					return
			"v":
				if pr.intersects(Rect2(e.pos.x + 8, e.pos.y, 24, 20)):
					_die("spike")
					return
			"h":
				if e.st == 2 or (e.st == 1 and e.t >= 0.05):
					if pr.intersects(Rect2(e.pos.x + 8, e.pos.y + 20, 24, 20)):
						_die("hidden")
						return
			"c":
				if e.st == 2 and pr.intersects(e.rect().grow(-2)):
					_die("crush")
					return
			"w", "W", "x", "X":
				if _circle_rect(e.pos, SAW_R - 1.0, pr):
					_die("saw")
					return
			"F":
				if pr.intersects(e.rect()):
					sfx("fake")
					_die("fake")
					return
			"D", "E":
				if e.st != 1 and pr.intersects(e.rect()):
					_win(e)
					return
			"Q":
				if e.st == 1 and pr.intersects(e.rect()):
					_win(e)
					return
			"K":
				if e.st == 0 and pr.intersects(e.rect()):
					state = "fake"
					fake_t = 0.0
					sfx("win")
					events.append({"t": "fakeclear"})
					return
			"Y":
				if pad_cd <= 0.0 and pr.intersects(e.rect()):
					gdir = -gdir
					pad_cd = 0.6
					vel.y = 0.0
					on_ground = false
					sq = Vector2(0.8, 1.25)
					sfx("reverse")
					events.append({"t": "flip"})
					events.append({"t": "shake", "a": 4.0})
			"i":
				if e.st == 0 and pr.grow(2.0).intersects(e.rect()):
					e.st = 1
					sfx("sign")
					events.append({"t": "shake", "a": 3.0})
			"b":
				if e.st == 0 and pr.intersects(e.rect()):
					e.st = 1
					sfx("button")
					for g: Ent in ents:
						if g.k == "G" and g.st == 0:
							g.st = 1
							g.t = 0.0
					events.append({"t": "msg", "text": "click."})
			"d":
				if e.st == 0 and pr.intersects(e.rect()):
					e.st = 1
					sfx("button")
					_chaos()
			"C":
				if e.st == 0 and pr.intersects(e.rect().grow(2.0)):
					e.st = 1
					coins += 1
					sfx("coin")
					events.append({"t": "coin", "pos": e.center()})
			"q":
				if e.st == 0 and pr.intersects(e.rect().grow(2.0)):
					e.st = 1
					reversed = true
					sfx("reverse")
					events.append({"t": "msg", "text": "CONTROLS: REVERSED"})
			"B":
				if vel.y * gdir >= 0.0 and pr.intersects(e.rect()):
					vel.y = -SPRING_V * gdir
					boosted = true
					on_ground = false
					e.t = 0.2
					sq = Vector2(0.75, 1.35)
					sfx("spring")
			"S":
				if absf(pc.x - (e.pos.x + 20.0)) < 70.0 and absf(pc.y - (e.pos.y + 20.0)) < 70.0:
					near = e.idx
	if near != sign_idx:
		sign_idx = near
		if near >= 0 and near < sign_texts.size():
			near_sign = sign_texts[near]
			sfx("sign")
		else:
			near_sign = ""

func _chaos() -> void:
	events.append({"t": "msg", "text": "you pressed it."})
	events.append({"t": "shake", "a": 8.0})
	for e: Ent in ents:
		match e.k:
			"h":
				if e.st == 0:
					e.st = 1
					e.t = 0.0
			"c":
				if e.st == 0:
					e.st = 1
					e.t = 0.0
			"p":
				if e.st == 0:
					e.st = 1
					e.t = 0.0
			"G":
				if e.st == 0:
					e.st = 1
					e.t = 0.0
	sfx("pop")

func _circle_rect(c: Vector2, r: float, rect: Rect2) -> bool:
	var q := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
	return q.distance_to(c) < r

func _die(why: String) -> void:
	if state != "play":
		return
	state = "dead"
	cause = why
	dead_t = 0.0
	events.append({"t": "death", "cause": why, "pos": player_center()})
	events.append({"t": "shake", "a": 9.0})
	sfx("die")

func _win(door: Ent) -> void:
	state = "won"
	win_t = 0.0
	win_pos = door.center()
	sfx("win")
	events.append({"t": "win"})
