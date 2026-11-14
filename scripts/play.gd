extends Node2D
## Gameplay screen: runs the World, draws everything, handles input (keyboard / gamepad / touch), HUD and overlays.

signal request(screen: String, arg: int)

const T := World.T
const HAZARD := Color("ff4d6d")
const HAZARD_HI := Color("ffc2cf")
const PALS := [
	{"bg1": Color("1d1744"), "bg2": Color("3d2c78"), "tile": Color("37336e"), "hi": Color("8a7dff"), "dark": Color("262250"), "acc": Color("5ee6c1")},
	{"bg1": Color("0d2b30"), "bg2": Color("1f5c57"), "tile": Color("236160"), "hi": Color("ffc857"), "dark": Color("173f3f"), "acc": Color("ffc857")},
	{"bg1": Color("360e2d"), "bg2": Color("6e2057"), "tile": Color("5c2352"), "hi": Color("ff7ac6"), "dark": Color("40163a"), "acc": Color("5be9ff")},
	{"bg1": Color("121a38"), "bg2": Color("2b407c"), "tile": Color("2f4a8a"), "hi": Color("ffa94d"), "dark": Color("1c2a58"), "acc": Color("ffa94d")},
	{"bg1": Color("0b0b11"), "bg2": Color("2c1322"), "tile": Color("2e2836"), "hi": Color("ffb347"), "dark": Color("1c1823"), "acc": Color("ff4d6d")},
]
const COMPLETE_LINES := ["Fine. You win. This time.", "Lucky. Very lucky.", "I let you win. Obviously.", "Okay, that was actually good.", "Don't get cocky.", "I'm not mad. (I'm mad.)", "Impressive. Suspicious, but impressive."]

var w := World.new()
var idx := 0
var info: Dictionary = {}
var pal: Dictionary = {}
var deaths_here := 0
var run_time := 0.0
var started := false
var t_anim := 0.0
var shake := 0.0
var banner := ""
var banner_t := 0.0
var particles: Array = []
var blobs: Array = []
var title_t := 3.0
var complete_shown := false
var paused := false
var touch_visible := false
var touch := {"left": false, "right": false, "jump": false}
var touches := {}
var prev_jump := false
var blink_t := 2.0
var save_counter := 0
var body_box: StyleBoxFlat
var bubble_box: StyleBoxFlat
var ui: CanvasLayer
var overlay: Control = null
var skip_btn: Button
var hint_btn: Button
var hint_ok := false
var hud_btns: Array[Button] = []
var cur_off := Vector2.ZERO
var ox := 0.0
var vp_w := 1280.0
var touch_l := Vector2(110, 540)
var touch_r := Vector2(250, 540)
var touch_j := Vector2(1170, 520)
var q_reveal_t := 99.0
var fake_age := 0.0
# ghost of the best run + recording of this run
var rec := PackedByteArray()
var ghost: World = null
var ghost_rec := PackedByteArray()
var ghost_i := 0
var ghost_active := false
var best_t := -1.0
# juice + Liar reactions
var hitstop := 0.0
var react_cd := 4.0
var death_spots: Array = []
var idle_t := 0.0
var still_t := 0.0
var last_px := 0.0
var retry_stamps: Array = []
var coin_react := false
var moved_once := false
var jumped_once := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# fill the whole screen: centre the 1280x720 playfield, anchor buttons to the real screen edges
	vp_w = get_viewport_rect().size.x
	ox = maxf(0.0, (vp_w - 1280.0) * 0.5)
	position.x = ox
	if ox >= 90.0:
		touch_l = Vector2(66, 598)
		touch_r = Vector2(176, 598)
		touch_j = Vector2(vp_w - 92, 580)
	else:
		touch_l = Vector2(110, 540)
		touch_r = Vector2(250, 540)
		touch_j = Vector2(vp_w - 110, 520)
	idx = clampi(Game.level, 0, Game.level_count() - 1)
	info = Game.level_info(idx)
	pal = PALS[clampi(int(info.world) - 1, 0, 4)]
	w.load_level(PackedStringArray(info.map), info.signs)
	Game.data.plays = int(Game.data.plays) + 1
	touch_visible = DisplayServer.is_touchscreen_available() or Game.force_touch
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + idx
	for i in 9:
		blobs.append({"p": Vector2(rng.randf() * 1280.0, rng.randf() * 720.0), "r": 40.0 + rng.randf() * 120.0, "s": 6.0 + rng.randf() * 14.0, "a": 0.035 + rng.randf() * 0.05})
	body_box = StyleBoxFlat.new()
	body_box.set_corner_radius_all(9)
	bubble_box = StyleBoxFlat.new()
	bubble_box.bg_color = Color("fff4d6")
	bubble_box.set_corner_radius_all(14)
	bubble_box.border_width_bottom = 5
	bubble_box.border_color = Color("d9b878")
	ui = CanvasLayer.new()
	ui.layer = 10
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	var b1 := UI.button("RETRY", Color("5b6bff"), Vector2(104, 44), 20)
	b1.position = Vector2(vp_w - 230, 10)
	b1.pressed.connect(func(): _restart_level())
	ui.add_child(b1)
	var b2 := UI.button("PAUSE", Color("8a5bff"), Vector2(104, 44), 20)
	b2.position = Vector2(vp_w - 118, 10)
	b2.pressed.connect(func(): _set_pause(true))
	ui.add_child(b2)
	skip_btn = UI.button("SKIP LEVEL", Color("ff8a3d"), Vector2(220, 50), 24)
	skip_btn.position = Vector2(vp_w * 0.5 - 110, 650)
	skip_btn.visible = false
	skip_btn.pressed.connect(_skip)
	ui.add_child(skip_btn)
	hint_btn = UI.button("HINT", Color("ffb43d"), Vector2(180, 50), 24)
	hint_btn.position = Vector2(vp_w * 0.5 - 110 - 200, 650)
	hint_btn.visible = false
	hint_btn.pressed.connect(func(): Ads.show_rewarded(func(ok): if ok: hint_ok = true))
	ui.add_child(hint_btn)
	if Game.seed_ghost:
		var gw := World.new()
		gw.load_level(PackedStringArray(info.map), info.signs)
		var gb := Bot.new(info.sol)
		var gr := PackedByteArray()
		for k in 6:
			gw.step(STEP, {"dir": 0, "jump_pressed": false, "jump_held": false})
		var gs := false
		for f in 4000:
			var gi := gb.next_input(gw)
			if not gs and (gi.dir != 0 or gi.jump_pressed):
				gs = true
			if gs and (gw.state == "play" or gw.state == "fake"):
				gr.append((int(gi.dir) + 1) | (4 if gi.jump_pressed else 0) | (8 if gi.jump_held else 0))
			gw.step(STEP, gi)
			if gw.state == "won":
				break
		Game.data.ghosts[str(idx)] = Marshalls.raw_to_base64(gr)
		Game.data.done[str(idx)] = {"time": float(gr.size()) / 60.0}
	best_t = Game.best_time(idx)
	if not Game.autoplay:
		ghost_rec = Game.ghost_get(idx)
		if ghost_rec.size() > 0:
			ghost = World.new()
			ghost.load_level(PackedStringArray(info.map), info.signs)
	Sfx.music(Game.world_music(idx))
	Sfx.duck(-10.0, 0.7)

# ------------------------------------------------------------------ input
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_visible = true
		var pos: Vector2 = event.position
		if event is InputEventScreenTouch and not event.pressed:
			touches.erase(event.index)
		else:
			touches[event.index] = pos
		_recalc_touch()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				if overlay == null:
					_restart_level()
			KEY_ESCAPE, KEY_P:
				if overlay == null or paused:
					_set_pause(not paused)
			KEY_ENTER, KEY_KP_ENTER:
				if complete_shown:
					_next()
			KEY_N:
				if complete_shown:
					_next()

func _recalc_touch() -> void:
	touch.left = false
	touch.right = false
	touch.jump = false
	var mid := (touch_l.x + touch_r.x) * 0.5
	for k in touches:
		var p: Vector2 = touches[k]
		if p.distance_to(touch_l) < 90.0 or (p.x < mid and p.y > 430.0):
			touch.left = true
		if p.distance_to(touch_r) < 90.0 or (p.x >= mid and p.x < touch_r.x + 75.0 and p.y > 430.0):
			touch.right = true
		if p.distance_to(touch_j) < 115.0 or (p.x > vp_w - 330.0 and p.y > 400.0):
			touch.jump = true

func _read_input() -> Dictionary:
	var l: bool = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or touch.left
	var r: bool = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or touch.right
	var j: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or touch.jump
	var joys := Input.get_connected_joypads()
	if joys.size() > 0:
		var jd: int = joys[0]
		var ax := Input.get_joy_axis(jd, JOY_AXIS_LEFT_X)
		l = l or ax < -0.4 or Input.is_joy_button_pressed(jd, JOY_BUTTON_DPAD_LEFT)
		r = r or ax > 0.4 or Input.is_joy_button_pressed(jd, JOY_BUTTON_DPAD_RIGHT)
		j = j or Input.is_joy_button_pressed(jd, JOY_BUTTON_A) or Input.is_joy_button_pressed(jd, JOY_BUTTON_DPAD_UP)
	var dir := int(r) - int(l)
	var jp := j and not prev_jump
	prev_jump = j
	return {"dir": dir, "jump_pressed": jp, "jump_held": j}

# ------------------------------------------------------------------ loop
const STEP := 1.0 / 60.0
var bot: Bot = null
var auto_wait := 0.0
var shot_wait := 0

func _physics_process(_delta: float) -> void:
	if Game.dev_pause_shot != "":
		shot_wait += 1
		if shot_wait == 30:
			_set_pause(true)
		if shot_wait == 40:
			get_viewport().get_texture().get_image().save_png(Game.dev_pause_shot)
			get_tree().quit()
	if paused:
		return
	var reps := 8 if Game.autoplay else 1
	for _k in reps:
		_sim_step(STEP)
	t_anim += STEP
	title_t = maxf(0.0, title_t - STEP)
	q_reveal_t += STEP
	banner_t = maxf(0.0, banner_t - STEP)
	shake = maxf(0.0, shake - STEP * 40.0)
	skip_btn.visible = Game.level_deaths(idx) >= Game.SKIP_AFTER and w.state != "won" and not Ads.busy
	skip_btn.text = "SKIP LEVEL (AD)" if Ads.mode != "off" and not Game.autoplay else "SKIP LEVEL"
	skip_btn.custom_minimum_size.x = 260 if Ads.mode != "off" else 220
	hint_btn.visible = Game.level_deaths(idx) >= 6 and String(info.hint) != "" and not hint_ok and w.state == "play" and not Ads.busy
	hint_btn.text = "HINT (AD)" if Ads.mode != "off" and not Game.autoplay else "HINT"
	_tick_reactions()
	_update_particles(STEP)
	blink_t -= STEP
	if blink_t < -0.13:
		blink_t = 2.0 + randf() * 2.5
	if Game.autoplay and complete_shown:
		auto_wait += STEP * reps
		if Game.complete_shot != "":
			shot_wait += 1
			if shot_wait == 8:
				get_viewport().get_texture().get_image().save_png(Game.complete_shot)
				get_tree().quit()
		elif auto_wait > 0.6:
			_next()

	queue_redraw()

func _sim_step(dt: float) -> void:
	var inp: Dictionary
	if Game.autoplay:
		if bot == null:
			bot = Bot.new(info.sol)
		inp = bot.next_input(w)
	else:
		inp = _read_input()
		if Game.hold_right:
			inp = {"dir": 1, "jump_pressed": false, "jump_held": false}
	if hitstop > 0.0:
		hitstop -= dt
		return
	if inp.dir != 0:
		moved_once = true
	if inp.jump_pressed:
		jumped_once = true
	if not started and (inp.dir != 0 or inp.jump_pressed):
		started = true
		_start_ghost()
	if (w.state == "play" or w.state == "fake") and started:
		if w.state == "play":
			run_time += dt
		rec.append((int(inp.dir) + 1) | (4 if inp.jump_pressed else 0) | (8 if inp.jump_held else 0))
		_step_ghost(dt)
	w.step(dt, inp)
	_drain_events()
	if Game.state_shot != "":
		var hit := false
		match Game.state_shot_cond:
			"fake":
				hit = w.state == "fake" and w.fake_t > 1.2
			"fakeend":
				hit = w.state == "play" and q_reveal_t > 0.12 and q_reveal_t < 0.4
			"lava":
				hit = w.has_lava and w.lava_y < 690.0
			"flip":
				hit = w.gdir < 0.0 and w.on_ground
			"ghost":
				hit = ghost_active and ghost != null and ghost.pos.x > 420.0
		if hit:
			shot_wait += 1
			if shot_wait == 3:
				get_viewport().get_texture().get_image().save_png(Game.state_shot)
				get_tree().quit()
	if w.state == "dead" and w.dead_t >= World.RESPAWN_DELAY:
		if Game.autoplay:
			print("AUTOPLAY FAIL: level %d died (%s)" % [idx + 1, w.cause])
			get_tree().quit(1)
			return
		w.reset()
		_reset_run()
		prev_jump = true
	if w.state == "won" and w.win_t > 0.6 and not complete_shown:
		_show_complete()

func _drain_events() -> void:
	for ev in w.events:
		match ev.t:
			"sfx":
				var n: String = ev.n
				var pitch := 1.0
				if n == "jump":
					pitch = randf_range(0.96, 1.06)
				Sfx.play(n, pitch)
			"death":
				Game.add_death(idx)
				deaths_here += 1
				save_counter += 1
				if save_counter % 4 == 0:
					Game.save()
				_burst(ev.pos, 26)
				Input.vibrate_handheld(35)
				banner = Game.taunt(ev.cause, Game.level_deaths(idx))
				banner_t = 2.4
				hitstop = 0.08
				_death_reaction(ev.pos, ev.cause)
				Sfx.duck(-14.0, 0.8)
				if ev.cause == "fake":
					Sfx.play("laugh")
				elif Game.session_deaths % 9 == 0:
					Sfx.play("sting")
			"dust":
				for i in 4:
					_particle(ev.pos + Vector2(randf_range(-8, 8), 0), Vector2(randf_range(-60, 60), randf_range(-60, -10)), 0.35, Color(1, 1, 1, 0.55), 16.0, 0.0, "smoke_05")
			"shake":
				shake = maxf(shake, ev.a)
			"msg":
				banner = ev.text
				banner_t = 1.8
			"coin":
				if not coin_react and idx > 0:
					coin_react = true
					_react("Greedy.", 5.0)
				for i in 8:
					var a := randf() * TAU
					_particle(ev.pos, Vector2(cos(a), sin(a)) * randf_range(60, 150), 0.5, Color("ffd45e"), 18.0, 0.0, "star_06")
			"flip":
				for i in 14:
					var a3 := TAU * float(i) / 14.0
					_particle(w.player_center(), Vector2(cos(a3), sin(a3)) * 160.0, 0.45, Color("5be9ff"), 24.0, 0.0, "circle_05")
			"fakeclear":
				for i in 40:
					var a4 := randf_range(-PI, 0.0)
					var cols2 := [Color("ffd45e"), Color("5ee6c1"), Color("ff7ac6"), Color("8a7dff")]
					_particle(w.player_center(), Vector2(cos(a4), sin(a4)) * randf_range(120, 420), 1.1, cols2[randi() % 4], 16.0, 700.0, "star_01")
			"fakeend":
				shake = 14.0
				q_reveal_t = 0.0
				Input.vibrate_handheld(120)
				Sfx.duck(-12.0, 1.0)
				for i in 70:
					var a5 := randf() * TAU
					var cc3 := Color("34c38f") if i % 3 == 0 else (Color("fff4d6") if i % 3 == 1 else Color("1d1744"))
					_particle(Vector2(randf_range(300, 980), randf_range(120, 520)), Vector2(cos(a5), sin(a5)) * randf_range(80, 420), 1.0, cc3, 18.0, 900.0, "dirt_01")
				banner = "NOPE. Did you really think it was that easy?"
				banner_t = 4.0
			"lava_start":
				shake = maxf(shake, 7.0)
				banner = "The floor really is lava. Surprise!"
				banner_t = 3.0
			"win":
				Input.vibrate_handheld(90)
				Sfx.duck(-16.0, 1.2)
				for i in 46:
					var a2 := randf_range(-PI, 0.0)
					var cols := [Color("ffd45e"), Color("5ee6c1"), Color("ff7ac6"), Color("8a7dff")]
					_particle(w.win_pos, Vector2(cos(a2), sin(a2)) * randf_range(120, 420), 1.1, cols[randi() % 4], 16.0, 700.0, "star_01")
	w.events.clear()

func _particle(p: Vector2, v: Vector2, life: float, col: Color, size: float, grav: float, tex := "") -> void:
	particles.append({"p": p, "v": v, "life": life, "max": life, "c": col, "s": size, "g": grav, "t": Art.fx(tex) if tex != "" else null})

func _burst(c: Vector2, n: int) -> void:
	var skin := Game.skin_color()
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(80, 420)
		var col := skin if i % 3 != 0 else Color.WHITE
		_particle(c, Vector2(cos(a), sin(a)) * sp + Vector2(0, -120), 0.7 + randf() * 0.4, col, 12.0 + randf() * 12.0, 1200.0, "spark_05" if i % 2 == 0 else "star_04")

func _update_particles(dt: float) -> void:
	var keep: Array = []
	for p in particles:
		p.life -= dt
		if p.life > 0.0:
			p.v.y += p.g * dt
			p.p += p.v * dt
			keep.append(p)
	particles = keep

# ------------------------------------------------------------------ actions
func _restart_level() -> void:
	if complete_shown:
		return
	w.reset()
	_reset_run()
	prev_jump = true
	Sfx.play("back")
	var now := Time.get_ticks_msec() / 1000.0
	retry_stamps.append(now)
	while retry_stamps.size() > 0 and now - float(retry_stamps[0]) > 15.0:
		retry_stamps.remove_at(0)
	if retry_stamps.size() >= 4:
		_react("Rage restart detected. I respect it.")
		retry_stamps.clear()

func _set_pause(v: bool) -> void:
	if complete_shown:
		return
	paused = v
	get_tree().paused = v
	if v:
		_build_pause()
	elif overlay != null:
		overlay.queue_free()
		overlay = null

func _skip() -> void:
	Ads.show_rewarded(func(ok):
		if not ok:
			return
		Game.skip_level(idx)
		Sfx.play("whoosh")
		if idx + 1 < Game.level_count():
			request.emit("play", idx + 1)
		else:
			request.emit("menu", 0))

func _next() -> void:
	if Game.daily_mode:
		request.emit("menu", 0)
	elif idx + 1 < Game.level_count():
		Ads.level_cleared_then(func(): request.emit("play", idx + 1))
	else:
		request.emit("ending", 0)

func _show_complete() -> void:
	complete_shown = true
	Game.save()
	var res := Game.complete_level(idx, run_time, deaths_here, w.coins, w.coins_total)
	if res.new_best and not Game.autoplay:
		Game.ghost_set(idx, rec)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	overlay = dim
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 12)
	cc.add_child(box)
	var title := "DAILY LIE CLEARED!" if Game.daily_mode else "LEVEL CLEARED!"
	box.add_child(UI.label(title, 56, Color("ffd45e"), 10))
	box.add_child(UI.label("%d. %s" % [idx + 1, info.name], 30, Color("cfc6ff")))
	var tline := "Time  %s" % UI.fmt_time(run_time)
	if res.new_best:
		tline += "   NEW BEST!"
	box.add_child(UI.label(tline, 34, Color("5ee6c1") if res.new_best else Color.WHITE))
	box.add_child(UI.label("Deaths on this level: %d" % Game.level_deaths(idx), 28))
	if w.coins_total > 0:
		var cl := "Coins  %d / %d" % [w.coins, w.coins_total]
		if w.coins >= w.coins_total:
			cl += "   PERFECT"
		box.add_child(UI.label(cl, 28, Color("ffd45e")))
	if res.streak_up:
		box.add_child(UI.label("Daily streak: %d day%s" % [Game.data.streak, "" if int(Game.data.streak) == 1 else "s"], 30, Color("ff9d4d")))
	var cline: String = COMPLETE_LINES[randi() % COMPLETE_LINES.size()]
	if deaths_here == 0 and idx >= 3:
		cline = "No deaths? That's suspicious."
	elif deaths_here >= 15:
		cline = "%d deaths. And yet, here you are." % deaths_here
	var liar_line := UI.label("The Liar: \"%s\"" % cline, 26, Color("c9b8ff"))
	box.add_child(liar_line)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	box.add_child(spacer)
	var nxt_text := "NEXT LEVEL"
	if Game.daily_mode:
		nxt_text = "BACK TO MENU"
	elif idx + 1 >= Game.level_count():
		nxt_text = "FINISH"
	var nxt := UI.button(nxt_text, Color("34c38f"), Vector2(560, 74), 38)
	nxt.pressed.connect(_next)
	box.add_child(nxt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var retry := UI.button("RETRY", Color("5b6bff"), Vector2(176, 56), 26)
	retry.pressed.connect(func(): request.emit("retry", idx))
	row.add_child(retry)
	var brag := UI.button("COPY BRAG", Color("ff7ac6"), Vector2(196, 56), 26)
	brag.pressed.connect(func():
		DisplayServer.clipboard_set("I cleared level %d of Liar's Level after %d deaths. The Liar says I'm \"%s\". Beat that." % [idx + 1, Game.level_deaths(idx), Game.rank()])
		brag.text = "COPIED!")
	row.add_child(brag)
	var menu := UI.button("MENU", Color("8a5bff"), Vector2(160, 56), 26)
	menu.pressed.connect(func(): request.emit("menu", 0))
	row.add_child(menu)
	Sfx.play("unlock")

func _build_pause() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(dim)
	overlay = dim
	var box := VBoxContainer.new()
	box.position = Vector2(vp_w * 0.5 - 190, 130)
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 14)
	dim.add_child(box)
	box.add_child(UI.label("PAUSED", 64, Color("ffd45e"), 10))
	var resume := UI.button("RESUME", Color("34c38f"), Vector2(380, 66), 34)
	resume.pressed.connect(func(): _set_pause(false))
	box.add_child(resume)
	var retry := UI.button("RESTART LEVEL", Color("5b6bff"), Vector2(380, 56), 28)
	retry.pressed.connect(func():
		_set_pause(false)
		_restart_level())
	box.add_child(retry)
	var mus := UI.button("MUSIC: %s" % ("ON" if Sfx.music_on else "OFF"), Color("ff7ac6"), Vector2(380, 56), 28)
	mus.pressed.connect(func():
		Game.data.music = not Sfx.music_on
		Sfx.set_music_on(Game.data.music)
		Game.save()
		mus.text = "MUSIC: %s" % ("ON" if Sfx.music_on else "OFF"))
	box.add_child(mus)
	var sf := UI.button("SOUND: %s" % ("ON" if Sfx.sfx_on else "OFF"), Color("ff9d4d"), Vector2(380, 56), 28)
	sf.pressed.connect(func():
		Game.data.sfx = not Sfx.sfx_on
		Sfx.set_sfx_on(Game.data.sfx)
		Game.save()
		sf.text = "SOUND: %s" % ("ON" if Sfx.sfx_on else "OFF"))
	box.add_child(sf)
	var lv := UI.button("LEVEL SELECT", Color("8a5bff"), Vector2(380, 56), 28)
	lv.pressed.connect(func(): request.emit("levels", 0))
	box.add_child(lv)
	var mn := UI.button("MAIN MENU", Color("6b6b9a"), Vector2(380, 56), 28)
	mn.pressed.connect(func(): request.emit("menu", 0))
	box.add_child(mn)

# ------------------------------------------------------------------ drawing
func _draw() -> void:
	var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	cur_off = off
	draw_set_transform(off, 0.0, Vector2.ONE)
	_draw_bg()
	_draw_tiles()
	_draw_ents()
	_draw_lava()
	_draw_particles()
	_draw_ghost()
	_draw_player()
	_draw_sign_bubble()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_hud()
	_draw_fake_clear()
	if touch_visible:
		_draw_touch()

const BG_SETS := {
	1: [["forest_back", 4.5, 4.0, 0.55], ["forest_mid", 4.5, 8.0, 0.42], ["forest_front", 4.5, 14.0, 0.3], ["forest_lights", 4.5, 6.0, 0.22]],
	2: [["frog_9", 4.5, 5.0, 0.42], ["frog_8", 4.5, 9.0, 0.36]],
	3: [["frog_10", 6.6, 3.0, 0.4], ["frog_8", 4.5, 8.0, 0.26]],
	4: [["frog_9", 4.5, 5.0, 0.42], ["frog_7", 4.5, 10.0, 0.34]],
	5: [["frog_5", 2.9, 3.0, 0.4], ["frog_10", 6.6, 7.0, 0.36]],
}

func _draw_bg() -> void:
	var pts := PackedVector2Array([Vector2(-700, 0), Vector2(1980, 0), Vector2(1980, 720), Vector2(-700, 720)])
	var cols := PackedColorArray([pal.bg1, pal.bg1, pal.bg2, pal.bg2])
	draw_polygon(pts, cols)
	for b in blobs:
		var p: Vector2 = b.p
		var x := fposmod(p.x + t_anim * b.s, 1400.0) - 60.0
		draw_circle(Vector2(x, p.y + sin(t_anim * 0.4 + p.x) * 12.0), b.r, Color(1, 1, 1, b.a * 0.6))
	var wi := clampi(int(info.world), 1, 5)
	var tint: Color = Color(pal.bg2).lightened(0.55)
	for L in BG_SETS[wi]:
		var tex: Texture2D = Art.bg(L[0])
		var sc: float = L[1]
		var wpx := tex.get_width() * sc
		var hpx := tex.get_height() * sc
		var x0 := -fposmod(t_anim * float(L[2]), wpx) - wpx * (1.0 + floorf(ox / wpx))
		var col := Color(tint.r, tint.g, tint.b, L[3])
		var xx := x0
		while xx < 1280.0 + ox + wpx:
			draw_texture_rect(tex, Rect2(xx, 720.0 - hpx, wpx + 1.0, hpx), false, col)
			xx += wpx
	if wi == 3 or wi == 5:
		for i in 3:
			var bx := fposmod(float(i) * 470.0 + t_anim * (60.0 + i * 25.0), 1500.0) - 110.0
			var by := 130.0 + i * 70.0 + sin(t_anim * 2.0 + i) * 14.0
			draw_texture_rect(Art.chr(24 + int(t_anim * 8.0 + i) % 3), Rect2(bx, by, 40, 40), false, Color(1, 1, 1, 0.45))
	if ox > 0.0:
		draw_rect(Rect2(-ox - 10.0, 0, ox + 10.0, 720), Color(0.02, 0.01, 0.06, 0.45))
		draw_rect(Rect2(1280.0, 0, ox + 10.0, 720), Color(0.02, 0.01, 0.06, 0.45))
	if idx == Game.level_count() - 1:
		# the Liar watches the final level
		var lc := Vector2(640, 250)
		var look := (w.player_center() - lc).normalized()
		Liar.draw(self, lc, 125.0, look, t_anim)
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.02, 0.08, 0.55))

func _tile_col(c: int, r: int) -> bool:
	return w.tile_solid(c, r)

func _ground_cfg() -> Dictionary:
	match int(info.world):
		1:
			return {"top": 0, "body": 20, "tint": Color.WHITE, "rock": false}
		2:
			return {"top": 40, "body": 60, "tint": Color.WHITE, "rock": false}
		3:
			return {"top": 80, "body": 100, "tint": Color(1.0, 0.74, 0.95), "rock": false}
	return {"top": 0, "body": 0, "tint": Color.WHITE, "rock": true}

func _gset(base: int, left: bool, right: bool) -> int:
	if not left and not right:
		return base
	if not left:
		return base + 1
	if not right:
		return base + 3
	return base + 2

func _draw_tiles() -> void:
	var cfg := _ground_cfg()
	var hi: Color = pal.hi
	var dark: Color = pal.dark
	var rock_mod: Color = Color(pal.tile).lightened(0.6)
	for r in World.ROWS:
		for c in World.COLS:
			if w.grid[r * World.COLS + c] != 1:
				continue
			var x := float(c * T)
			var y := float(r * T)
			var exposed := not _tile_col(c, r - 1)
			var left := _tile_col(c - 1, r)
			var right := _tile_col(c + 1, r)
			if cfg.rock:
				var ci := 3 + ((c * 7 + r * 13) % 2)
				draw_texture_rect_region(Art.bg("rock_blocks"), Rect2(x, y, T, T), Art.rock_src(ci, 0), rock_mod)
				if exposed:
					draw_rect(Rect2(x, y, T, 6), hi)
					draw_rect(Rect2(x, y + 6, T, 2), hi.darkened(0.4))
				if not left:
					draw_rect(Rect2(x, y, 2, T), Color(0, 0, 0, 0.3))
				if not right:
					draw_rect(Rect2(x + T - 2, y, 2, T), Color(0, 0, 0, 0.3))
			else:
				var base: int
				if exposed:
					base = int(cfg.top)
				elif not _tile_col(c, r - 2):
					base = int(cfg.body)
				else:
					base = 120
				var tcol: Color = cfg.tint
				if base == 120:
					tcol = Color(tcol.r * 0.58, tcol.g * 0.56, tcol.b * 0.66)   # deep ground recedes
				draw_texture_rect(Art.tile(_gset(base, left, right)), Rect2(x, y, T, T), false, tcol)

func _ground_block(x: float, y: float, a: float) -> void:
	var cfg := _ground_cfg()
	if cfg.rock:
		var m: Color = Color(pal.tile).lightened(0.6)
		m.a = a
		draw_texture_rect_region(Art.bg("rock_blocks"), Rect2(x, y, T, T), Art.rock_src(3, 0), m)
		draw_rect(Rect2(x, y, T, 6), Color(pal.hi.r, pal.hi.g, pal.hi.b, a))
	else:
		var t: Color = cfg.tint
		t.a = a
		draw_texture_rect(Art.tile(int(cfg.top) + 2), Rect2(x, y, T, T), false, t)

func _block(x: float, y: float, col: Color, top: Color) -> void:
	_ground_block(x, y, col.a)

func _spike(x: float, y: float, up: bool, h := 22.0) -> void:
	for i in 3:
		var x0 := x + 6.0 + i * 9.4
		var pts: PackedVector2Array
		if up:
			pts = PackedVector2Array([Vector2(x0, y + T), Vector2(x0 + 4.7, y + T - h), Vector2(x0 + 9.4, y + T)])
		else:
			pts = PackedVector2Array([Vector2(x0, y), Vector2(x0 + 4.7, y + h), Vector2(x0 + 9.4, y)])
		draw_colored_polygon(pts, HAZARD)
		var hp: PackedVector2Array
		if up:
			hp = PackedVector2Array([Vector2(x0 + 1.5, y + T), Vector2(x0 + 4.7, y + T - h), Vector2(x0 + 4.7, y + T)])
		else:
			hp = PackedVector2Array([Vector2(x0 + 1.5, y), Vector2(x0 + 4.7, y + h), Vector2(x0 + 4.7, y)])
		draw_colored_polygon(hp, HAZARD_HI)

func _door(rect: Rect2, fake: bool, eyes: bool, state: int) -> void:
	var glow := 0.5 + 0.5 * sin(t_anim * 3.0)
	if not fake:
		draw_circle(rect.get_center(), 46.0, Color(1.0, 0.85, 0.3, 0.10 + 0.05 * glow))
		draw_circle(rect.get_center(), 32.0, Color(1.0, 0.9, 0.4, 0.14 + 0.08 * glow))
	var tint := Color(1.0, 0.88, 0.5) if not fake else Color(1.0, 0.5, 0.62)
	var dr := Rect2(rect.position.x - 2.0, rect.end.y - 60.0, 32.0, 60.0)
	draw_texture_rect(Art.tile(130), Rect2(dr.position, Vector2(32, 30)), false, tint)
	draw_texture_rect(Art.tile(150), Rect2(dr.position + Vector2(0, 30), Vector2(32, 30)), false, tint)
	if eyes:
		var pc := w.player_center()
		var c := rect.get_center() + Vector2(0, -8)
		var l := (pc - c).normalized() * 1.8
		var wide := 4.6 if state == 1 else 3.6
		for sd in [-1.0, 1.0]:
			draw_circle(c + Vector2(6.0 * sd, 0), wide, Color.WHITE)
			draw_circle(c + Vector2(6.0 * sd, 0) + l, 1.9, Color("1c1238"))

func _draw_ents() -> void:
	var hi: Color = pal.hi
	var acc: Color = pal.acc
	for e: World.Ent in w.ents:
		var p := e.pos
		match e.k:
			"^":
				_spike(p.x, p.y, true)
			"v":
				_spike(p.x, p.y, false)
			"h":
				if e.st == 0:
					var near := absf(w.player_center().x - e.center().x) < 110.0
					var jit := randf_range(-0.8, 0.8) if near else 0.0
					for i in 3:
						draw_circle(Vector2(p.x + 10 + i * 10 + jit, p.y + T - 3), 1.7, Color(1, 1, 1, 0.45 if near else 0.22))
				else:
					var k := minf(1.0, e.t / 0.08) if e.st == 1 else 1.0
					_spike(p.x, p.y, true, 22.0 * k)
			"o":
				if e.st == 2:
					_ground_block(p.x, p.y, clampf(1.0 - e.vel.y / 900.0, 0.0, 1.0))
				else:
					var sx := randf_range(-1.5, 1.5) if e.st == 1 else 0.0
					_ground_block(p.x + sx, p.y, 1.0)
					var cc := Color(0, 0, 0, 0.5)
					draw_polyline(PackedVector2Array([Vector2(p.x + sx + 8, p.y + 8), Vector2(p.x + sx + 16, p.y + 18), Vector2(p.x + sx + 13, p.y + 26), Vector2(p.x + sx + 22, p.y + 36)]), cc, 2.0)
					draw_polyline(PackedVector2Array([Vector2(p.x + sx + 32, p.y + 7), Vector2(p.x + sx + 27, p.y + 16), Vector2(p.x + sx + 31, p.y + 24)]), cc, 2.0)
			"p":
				if e.st == 2:
					_ground_block(p.x, p.y, clampf(1.0 - e.vel.y / 900.0, 0.0, 1.0))
				else:
					var sx2 := randf_range(-1.2, 1.2) if e.st == 1 else 0.0
					_ground_block(p.x + sx2, p.y, 1.0)
					draw_rect(Rect2(p.x + sx2, p.y + 8, 2, T - 12), Color(0, 0, 0, 0.4))
					draw_rect(Rect2(p.x + sx2 + T - 2, p.y + 8, 2, T - 12), Color(0, 0, 0, 0.4))
					var dy := fposmod(t_anim * 14.0, 6.0)
					draw_colored_polygon(PackedVector2Array([Vector2(p.x + 30, p.y + 12 + dy), Vector2(p.x + 33, p.y + 18 + dy), Vector2(p.x + 27, p.y + 18 + dy)]), Color("6fd3ff"))
					draw_circle(Vector2(p.x + 30, p.y + 19 + dy), 3.2, Color("6fd3ff"))
			"c":
				var sx3 := randf_range(-2.0, 2.0) if e.st == 1 else 0.0
				draw_texture_rect(Art.chr(12 if e.st >= 1 else 11), Rect2(p.x + sx3, p.y, T, T), false)
			"i":
				if e.st == 0:
					draw_rect(Rect2(p.x + 1, p.y + 1, T - 2, T - 2), Color(1, 1, 1, 0.05 + 0.02 * sin(t_anim * 2.0)), false, 1.5)
				else:
					_ground_block(p.x, p.y, 1.0)
			"G":
				var a3 := 1.0 - e.t if e.st == 1 else 1.0
				if a3 > 0.02:
					for i in 3:
						draw_rect(Rect2(p.x + 5 + i * 13, p.y, 7, T), Color(acc.r, acc.g, acc.b, a3))
						draw_rect(Rect2(p.x + 5 + i * 13, p.y, 2.5, T), Color(1, 1, 1, 0.5 * a3))
			"D":
				_door(e.rect(), false, false, 0)
			"F":
				_door(e.rect(), true, false, 0)
			"E":
				_door(e.rect(), false, true, e.st)
			"S":
				draw_texture_rect(Art.tile(86), Rect2(p.x, p.y, T, T), false)
			"b", "d":
				var pressed: bool = e.st == 1
				var origin := Vector2(p.x - 4.0, p.y + 12.0 - T)
				var tc := Color.WHITE if e.k == "b" else Color(1.0, 0.35, 0.42)
				draw_texture_rect(Art.tile(149 if pressed else 148), Rect2(origin, Vector2(T, T)), false, tc)
			"C":
				if e.st == 0:
					var bob := sin(t_anim * 3.0 + p.x * 0.1) * 2.5
					var cc2 := e.center() + Vector2(0, bob)
					var spin := absf(cos(t_anim * 3.5 + p.x * 0.05)) * 0.75 + 0.25
					draw_texture_rect(Art.tile(151), Rect2(cc2.x - 13.0 * spin, cc2.y - 13.0, 26.0 * spin, 26.0), false)
			"q":
				if e.st == 0:
					var cc3 := e.center() + Vector2(0, sin(t_anim * 3.0) * 2.5)
					draw_circle(cc3, 12.0, Color("4a1d8f"))
					draw_circle(cc3, 9.5, Color("b36bff"))
					draw_arc(cc3, 5.0, t_anim * 4.0, t_anim * 4.0 + 4.5, 12, Color.WHITE, 2.0)
			"B":
				var sq := 1.0 - (e.t / 0.2) * 0.45 if e.t > 0.0 else 1.0
				var origin2 := Vector2(p.x - 2.0, p.y - 22.0)
				var hh := T * sq
				draw_texture_rect(Art.tile(107), Rect2(origin2.x, origin2.y + (T - hh), T, hh), false)
			"w", "W", "x", "X":
				_draw_saw(e)
			"m", "n", "M", "N":
				_draw_plat(e)
			"K":
				_door(e.rect(), false, false, 0)
				if e.st != 0:
					var r2 := e.rect()
					draw_rect(r2, Color(0.05, 0.03, 0.12, 0.7))
					draw_line(r2.position + Vector2(3, 6), r2.end - Vector2(3, 6), Color("ff4d6d"), 4.0)
					draw_line(Vector2(r2.end.x - 3, r2.position.y + 6), Vector2(r2.position.x + 3, r2.end.y - 6), Color("ff4d6d"), 4.0)
			"Q":
				if e.st == 1:
					_door(e.rect(), false, false, 0)
					if q_reveal_t < 1.0:
						draw_arc(e.center(), 10.0 + q_reveal_t * 70.0, 0.0, TAU, 32, Color(1, 0.9, 0.4, 1.0 - q_reveal_t), 4.0)
			"Y":
				_draw_pad(e)
	draw_set_transform(cur_off, 0.0, Vector2.ONE)

func _draw_plat(e: World.Ent) -> void:
	var r := e.rect()
	var acc: Color = pal.acc
	draw_rect(Rect2(r.position.x + 2, r.position.y + 4, r.size.x, r.size.y), Color(0, 0, 0, 0.25))
	var pb := StyleBoxFlat.new()
	pb.bg_color = Color("c9d1ff")
	pb.set_corner_radius_all(6)
	pb.border_width_bottom = 3
	pb.border_color = Color("6f7bd0")
	draw_style_box(pb, r)
	var d: Vector2 = e.dir
	var perp := Vector2(-d.y, d.x)
	for i in 3:
		var c := r.position + Vector2(20.0 + i * 20.0, 7.0)
		var tip := c + d * 5.0
		var b1 := c - d * 3.0 + perp * 4.0
		var b2 := c - d * 3.0 - perp * 4.0
		draw_colored_polygon(PackedVector2Array([tip, b1, b2]), Color(acc.r, acc.g, acc.b, 0.9))

func _draw_pad(e: World.Ent) -> void:
	var p := e.pos
	var up := w.gdir > 0.0
	var ph := fposmod(t_anim * 1.4, 1.0)
	draw_rect(Rect2(p.x + 3, p.y + 3, T - 6, T - 6), Color(0.36, 0.91, 1.0, 0.14))
	draw_rect(Rect2(p.x + 3, p.y + 3, T - 6, T - 6), Color(0.36, 0.91, 1.0, 0.7), false, 2.0)
	for i in 3:
		var k := fposmod(ph + float(i) / 3.0, 1.0)
		var y := p.y + (T - 8.0 - k * (T - 16.0)) if up else p.y + (8.0 + k * (T - 16.0))
		var dy := -6.0 if up else 6.0
		var a := sin(k * PI)
		draw_polyline(PackedVector2Array([Vector2(p.x + 10, y - dy), Vector2(p.x + 20, y), Vector2(p.x + 30, y - dy)]), Color(0.7, 1.0, 1.0, a), 3.0)

func _draw_lava() -> void:
	if not w.has_lava:
		return
	var top := w.lava_y
	if w.moved and w.since_move < World.LAVA_DELAY:
		var a := w.since_move / World.LAVA_DELAY
		for i in 5:
			draw_rect(Rect2(0, 720 - 10 - i * 12, 1280, 12), Color(1.0, 0.3, 0.1, 0.18 * a * (1.0 - float(i) / 5.0)))
	if top > 730.0:
		return
	for i in 7:
		draw_rect(Rect2(0, top - 12 - i * 14, 1280, 14), Color(1.0, 0.3, 0.1, 0.12 * (1.0 - float(i) / 7.0)))
	var pts := PackedVector2Array()
	var edge := PackedVector2Array()
	for xi in range(0, 1301, 20):
		var y := top + sin(float(xi) * 0.035 + t_anim * 3.0) * 5.0
		pts.append(Vector2(xi, y))
		edge.append(Vector2(xi, y))
	pts.append(Vector2(1300, 800))
	pts.append(Vector2(0, 800))
	draw_colored_polygon(pts, Color("e8421a"))
	draw_polyline(edge, Color("ffd45e"), 5.0)
	for i in 9:
		var bx := fposmod(float(i) * 151.0 + t_anim * 20.0, 1280.0)
		var by := top + 20.0 + fposmod(float(i) * 37.0 - t_anim * 30.0, 90.0)
		draw_circle(Vector2(bx, by), 4.0 + float(i % 3) * 2.0, Color(1.0, 0.75, 0.3, 0.7))

func _draw_fake_clear() -> void:
	if w.state != "fake":
		return
	fake_age = w.fake_t
	var a := clampf(fake_age / 0.2, 0.0, 1.0)
	draw_rect(Rect2(-ox - 10.0, 0, vp_w + 20.0, 720), Color(0.03, 0.02, 0.08, 0.72 * a))
	UI.ctext(self, "LEVEL CLEARED!", Vector2(640, 160), 56, Color(1.0, 0.83, 0.37, a), 10)
	UI.ctext(self, "%d. %s" % [idx + 1, info.name], Vector2(640, 208), 30, Color(0.81, 0.78, 1.0, a))
	UI.ctext(self, "Time  %s   NEW BEST!" % UI.fmt_time(run_time), Vector2(640, 262), 34, Color(0.37, 0.9, 0.76, a))
	UI.ctext(self, "Deaths on this level: %d" % Game.level_deaths(idx), Vector2(640, 304), 28, Color(1, 1, 1, a))
	UI.ctext(self, "The Liar: \"Fine. You win. This time.\"", Vector2(640, 342), 26, Color(0.79, 0.72, 1.0, a))
	draw_style_box(UI.box(Color("34c38f"), 18, 6), Rect2(360, 372, 560, 74))
	UI.ctext(self, "NEXT LEVEL", Vector2(640, 424), 38, Color(1, 1, 1, a))
	draw_style_box(UI.box(Color("5b6bff"), 18, 6), Rect2(360, 460, 176, 56))
	draw_style_box(UI.box(Color("ff7ac6"), 18, 6), Rect2(548, 460, 196, 56))
	draw_style_box(UI.box(Color("8a5bff"), 18, 6), Rect2(756, 460, 164, 56))
	UI.ctext(self, "RETRY", Vector2(448, 498), 26, Color.WHITE, 5)
	UI.ctext(self, "COPY BRAG", Vector2(646, 498), 26, Color.WHITE, 5)
	UI.ctext(self, "MENU", Vector2(838, 498), 26, Color.WHITE, 5)

func _draw_saw(e: World.Ent) -> void:
	var c := e.pos
	var horiz := e.k == "w" or e.k == "W"
	var h := e.home
	if horiz:
		var row := int(floor(h.y / T))
		var cx := int(floor(h.x / T))
		var a := cx
		while not w.tile_solid(a - 1, row):
			a -= 1
		var b := cx
		while not w.tile_solid(b + 1, row):
			b += 1
		draw_rect(Rect2(a * T, h.y - 2, (b + 1 - a) * T, 4), Color(1, 1, 1, 0.14))
	else:
		var col := int(floor(h.x / T))
		var cr := int(floor(h.y / T))
		var a2 := cr
		while not w.tile_solid(col, a2 - 1):
			a2 -= 1
		var b2 := cr
		while not w.tile_solid(col, b2 + 1):
			b2 += 1
		draw_rect(Rect2(h.x - 2, a2 * T, 4, (b2 + 1 - a2) * T), Color(1, 1, 1, 0.14))
	draw_set_transform(c + cur_off, e.t * 5.0, Vector2.ONE)
	draw_texture_rect(Art.chr(8), Rect2(-20, -20, 40, 40), false)
	draw_set_transform(cur_off, 0.0, Vector2.ONE)

func _draw_particles() -> void:
	for p in particles:
		var a: float = clampf(p.life / p.max, 0.0, 1.0)
		var col: Color = p.c
		col.a *= a
		var sz: float = p.s * (0.5 + 0.5 * a)
		if p.t != null:
			draw_texture_rect(p.t, Rect2(p.p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, col)
		else:
			draw_rect(Rect2(p.p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col)

func _draw_player(tint := Color.WHITE) -> void:
	if w.state == "dead":
		return
	var skin_i := clampi(int(Game.data.skin), 0, Game.SKIN_SPRITES.size() - 1)
	var frames: Array = Game.SKIN_SPRITES[skin_i]
	var moving := absf(w.vel.x) > 40.0 and w.on_ground
	var fi := 0
	if not w.on_ground:
		fi = 1
	elif moving:
		fi = int(t_anim * 10.0) % 2
	var tex: Texture2D = Art.chr(frames[fi])
	var feet := Vector2(w.pos.x + World.PW * 0.5, w.pos.y + World.PH)
	var scl := Vector2.ONE
	if w.state == "won":
		var k := clampf(w.win_t / 0.4, 0.0, 1.0)
		feet = feet.lerp(Vector2(w.win_pos.x, w.win_pos.y + 26.0), k)
		scl = Vector2.ONE * (1.0 - k * 0.9)
	var base := 38.0
	var size := Vector2(base * w.sq.x * scl.x, base * w.sq.y * scl.y)
	var xf := Transform2D(0.0, cur_off)
	if w.gdir < 0.0:
		var cy := w.pos.y + World.PH * 0.5
		xf = xf * Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2(0, 2.0 * cy))
	var rot := clampf(w.vel.x / 275.0, -1.0, 1.0) * 0.1
	xf = xf * Transform2D(rot, feet) * Transform2D(0.0, -feet)
	draw_set_transform_matrix(xf)
	draw_circle(Vector2(feet.x, feet.y + 1.0), 12.0 * scl.x, Color(0, 0, 0, 0.2))
	var mod := Color.WHITE
	if w.reversed:
		mod = Color(0.82, 0.62, 1.0)
	elif skin_i == 5:
		mod = Color(0.85, 0.82, 1.0, 0.8)
	draw_texture_rect(tex, Rect2(feet.x - size.x * 0.5, feet.y - size.y + 3.0, size.x, size.y), false, mod * tint)
	draw_set_transform(cur_off, 0.0, Vector2.ONE)

func _draw_sign_bubble() -> void:
	if w.near_sign == "" or w.state != "play":
		return
	var sp := Vector2.ZERO
	for e: World.Ent in w.ents:
		if e.k == "S" and e.idx == w.sign_idx:
			sp = e.pos + Vector2(20, 0)
	var f := UI.font()
	var fs := 24
	var maxw := 380.0
	var sz := f.get_multiline_string_size(w.near_sign, HORIZONTAL_ALIGNMENT_LEFT, maxw, fs)
	var rect := Rect2(sp.x - sz.x * 0.5 - 14, sp.y - sz.y - 38, sz.x + 28, sz.y + 20)
	rect.position.x = clampf(rect.position.x, 8.0, 1272.0 - rect.size.x)
	rect.position.y = maxf(rect.position.y, 60.0)
	draw_style_box(bubble_box, rect)
	var tip := PackedVector2Array([Vector2(sp.x - 8, rect.end.y - 1), Vector2(sp.x + 8, rect.end.y - 1), Vector2(sp.x, rect.end.y + 11)])
	draw_colored_polygon(tip, Color("fff4d6"))
	draw_multiline_string(f, rect.position + Vector2(14, 10 + fs * 0.85), w.near_sign, HORIZONTAL_ALIGNMENT_LEFT, maxw, fs, -1, Color("3b2a14"))

func _draw_hud() -> void:
	var rx := 1280.0 + ox
	draw_rect(Rect2(-ox, 0, vp_w, 64), Color(0, 0, 0, 0.28))
	var acc: Color = pal.acc
	draw_circle(Vector2(34 - ox, 34), 17.0, acc)
	UI.ctext(self, str(idx + 1), Vector2(34 - ox, 44), 26, Color("1c1238"), 0)
	draw_string(UI.font(), Vector2(34 - 17 - ox, 44), str(idx + 1), HORIZONTAL_ALIGNMENT_CENTER, 34.0, 26, Color("1c1238"))
	UI.text(self, String(info.name).to_upper(), Vector2(64 - ox, 44), 28, Color.WHITE)
	UI.text(self, "DEATHS %d" % deaths_here, Vector2(rx - 580.0, 44), 26, Color("ff9db0"), HORIZONTAL_ALIGNMENT_RIGHT, 200.0)
	UI.text(self, UI.fmt_time(run_time), Vector2(rx - 350.0, 40), 26, Color("cfc6ff"), HORIZONTAL_ALIGNMENT_RIGHT, 100.0)
	if best_t > 0.0:
		UI.text(self, "BEST %s" % UI.fmt_time(best_t), Vector2(rx - 350.0, 61), 16, Color(0.55, 0.92, 1.0, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 3)
	_draw_tutorial()
	if w.coins_total > 0:
		UI.ctext(self, "COINS %d/%d" % [w.coins, w.coins_total], Vector2(560, 44), 24, Color("ffd45e"))
	if w.reversed:
		var pulse := 0.6 + 0.4 * sin(t_anim * 8.0)
		UI.ctext(self, "CONTROLS REVERSED", Vector2(640, 100), 30, Color(0.78, 0.5, 1.0, pulse))
	# title card
	if title_t > 0.0 and overlay == null and w.state != "fake":
		var a := clampf(title_t / 0.6, 0.0, 1.0)
		var wn: String = LevelData.WORLD_NAMES[clampi(int(info.world) - 1, 0, 4)]
		UI.ctext(self, "WORLD %d  -  %s" % [info.world, wn.to_upper()], Vector2(640, 300), 28, Color(0.85, 0.82, 1.0, a))
		UI.ctext(self, "%d. %s" % [idx + 1, String(info.name).to_upper()], Vector2(640, 360), 56, Color(1, 1, 1, a))
		UI.ctext(self, "The Liar: \"%s\"" % String(info.quip), Vector2(640, 412), 28, Color(0.8, 0.72, 1.0, a), 5)
	# Liar banner
	if banner_t > 0.0 and banner != "":
		var a2 := clampf(banner_t / 0.4, 0.0, 1.0)
		var f := UI.font()
		var sz := f.get_string_size(banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		var bw := sz.x + 100.0
		var rect := Rect2(640 - bw * 0.5, 74, bw, 54)
		var bb := StyleBoxFlat.new()
		bb.bg_color = Color(0.12, 0.08, 0.28, 0.9 * a2)
		bb.set_corner_radius_all(18)
		bb.border_width_bottom = 4
		bb.border_color = Color(0.5, 0.35, 1.0, a2)
		draw_style_box(bb, rect)
		Liar.draw(self, rect.position + Vector2(30, 27), 20.0, Vector2(0.3, 0.1), t_anim)
		draw_string(f, rect.position + Vector2(62, 35), banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, a2))
	var lvl_deaths := Game.level_deaths(idx)
	if hint_ok and String(info.hint) != "" and w.state == "play":
		UI.ctext(self, "HINT: " + String(info.hint), Vector2(640, 706), 22, Color(1, 0.92, 0.6, 0.85), 4)

func _start_ghost() -> void:
	ghost_i = 0
	ghost_active = false
	if ghost != null:
		ghost.reset()
		for k in 6:
			ghost.step(STEP, {"dir": 0, "jump_pressed": false, "jump_held": false})
		ghost.events.clear()
		ghost_active = true

func _step_ghost(dt: float) -> void:
	if not ghost_active or ghost == null:
		return
	var b := 1
	var jp := false
	var jh := false
	if ghost_i < ghost_rec.size():
		var v: int = ghost_rec[ghost_i]
		b = (v & 3) - 1
		jp = (v & 4) != 0
		jh = (v & 8) != 0
	else:
		b = 0
	ghost_i += 1
	if ghost.state == "play" or ghost.state == "fake":
		ghost.step(dt, {"dir": b, "jump_pressed": jp, "jump_held": jh})
		ghost.events.clear()

func _reset_run() -> void:
	run_time = 0.0
	started = false
	rec = PackedByteArray()
	ghost_active = false
	ghost_i = 0
	still_t = 0.0
	idle_t = 0.0
	if ghost != null:
		ghost.reset()

func _draw_ghost() -> void:
	if ghost == null or not ghost_active:
		return
	if ghost.state == "won" and ghost.win_t > 0.5:
		return
	if ghost.state == "dead":
		return
	var real := w
	w = ghost
	_draw_player(Color(0.55, 0.9, 1.0, 0.42))
	w = real

func _react(text: String, cd := 6.0) -> void:
	if react_cd > 0.0 or banner_t > 1.0 or w.state != "play":
		return
	banner = text
	banner_t = 3.2
	react_cd = cd
	Sfx.play("sign")

func _death_reaction(pos: Vector2, cause: String) -> void:
	death_spots.append(pos.x)
	var near := 0
	for x in death_spots:
		if absf(float(x) - pos.x) < 70.0:
			near += 1
	react_cd = 0.0
	if int(Game.data.deaths) == 1:
		banner = "Oh. Already? Wow."
		react_cd = 8.0
	elif near == 4:
		banner = "You keep dying right there. Fascinating."
		react_cd = 8.0
	elif w.coins > 0 and cause != "fake" and randf() < 0.5:
		banner = "Was the coin worth it?"
		react_cd = 6.0

func _tick_reactions() -> void:
	react_cd = maxf(0.0, react_cd - STEP)
	if w.state != "play" or title_t > 0.0:
		return
	if not started:
		idle_t += STEP
		if idle_t > 9.0:
			idle_t = -60.0
			_react("Are you scared? It's only a game. (It's not.)")
		return
	var px := w.pos.x
	if absf(px - last_px) < 1.5 and w.on_ground:
		still_t += STEP
	else:
		still_t = 0.0
	last_px = px
	if still_t > 8.0:
		still_t = -40.0
		_react("Planning something? I'm intrigued.")

func _draw_tutorial() -> void:
	if idx != 0 or Game.is_done(0) or (moved_once and jumped_once) or w.state != "play" or title_t > 0.0:
		return
	var a := 0.55 + 0.35 * sin(t_anim * 4.0)
	if touch_visible:
		UI.ctext(self, "USE THE ON-SCREEN BUTTONS TO MOVE AND JUMP", Vector2(640, 520), 26, Color(1, 1, 1, a), 5)
		return
	var f := UI.font()
	var keys := [["A", 330.0], ["D", 396.0], ["SPACE", 600.0]]
	for k in keys:
		var w2 := 54.0 if String(k[0]).length() == 1 else 130.0
		var r := Rect2(float(k[1]), 452.0, w2, 52.0)
		draw_style_box(UI.box(Color(0.2, 0.18, 0.38, 0.9), 12, 5), r)
		var sz := f.get_string_size(String(k[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		draw_string(f, Vector2(r.position.x + (r.size.x - sz.x) * 0.5, r.position.y + 34), String(k[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, a + 0.2))
	UI.text(self, "MOVE", Vector2(458, 488), 24, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
	UI.text(self, "JUMP", Vector2(746, 488), 24, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)

func _draw_touch() -> void:
	var col := Color(1, 1, 1, 0.12)
	var on := Color(1, 1, 1, 0.30)
	var ring := Color(1, 1, 1, 0.32)
	var o := Vector2(ox, 0)
	var l := touch_l - o
	var r := touch_r - o
	var j := touch_j - o
	var pts := [[l, 50.0, touch.left], [r, 50.0, touch.right], [j, 64.0, touch.jump]]
	for p in pts:
		draw_circle(p[0], p[1], on if p[2] else col)
		draw_arc(p[0], p[1], 0.0, TAU, 40, ring, 3.0, true)
	var wcol := Color(1, 1, 1, 0.6)
	draw_colored_polygon(PackedVector2Array([l + Vector2(-20, 0), l + Vector2(14, -20), l + Vector2(14, 20)]), wcol)
	draw_colored_polygon(PackedVector2Array([r + Vector2(20, 0), r + Vector2(-14, -20), r + Vector2(-14, 20)]), wcol)
	draw_colored_polygon(PackedVector2Array([j + Vector2(0, -26), j + Vector2(26, 14), j + Vector2(-26, 14)]), wcol)
