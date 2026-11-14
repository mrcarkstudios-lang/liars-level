class_name Brand
extends Control
## GAMICS brand opening, played in the world of Liar's Level (about 4.6 s, skippable):
## an ember falls through the dusk forest, hits the ground, the GAMICS emblem slams in with a light sweep and "PRESENTS" -
## then the Liar pops up and vouches for the studio ("Totally trustworthy.") and gives itself away.
## Timeline matches the studio sound (art/brand + audio/gamics_intro.wav): impact at 0.75 s.

signal request(screen: String, arg: int)

const IMPACT := 0.75
const SWEEP_1 := 1.6
const SWEEP_2 := 2.85
const PRESENTS_AT := 1.75
const LIAR_AT := 2.55
const LAUGH_AT := 3.55
const FADE_AT := 4.2
const END_AT := 4.7
const C := Vector2(520.0, 292.0)         # emblem centre
const EMBLEM_H := 300.0
const GROUND_Y := 640.0
const EMBLEM := preload("res://art/brand/emblem.png")
const EMBLEM_HOT := preload("res://art/brand/emblem_hot.png")
const GOLD := Color(1.0, 0.78, 0.42)
const EMBER := Color(1.0, 0.55, 0.18)

var t := 0.0
var fired := {}
var shake := 0.0
var flash := 0.0
var parts: Array = []
var done := false
var audio: AudioStreamPlayer

func _ready() -> void:
	UI.fit_screen(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	audio = AudioStreamPlayer.new()
	audio.stream = load("res://audio/gamics_intro.wav")
	audio.volume_db = -3.0
	add_child(audio)
	if Game.data.get("sfx", true):
		audio.play()

func _once(key: String, at: float) -> bool:
	if t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false

func _ember_pos() -> Vector2:
	var u := clampf((t - 0.15) / (IMPACT - 0.15), 0.0, 1.0)
	return Vector2(C.x + sin(u * 6.0) * 10.0 * (1.0 - u), lerpf(-30.0, C.y, u * u))

func _process(delta: float) -> void:
	t += delta
	shake = maxf(0.0, shake - delta * 28.0)
	flash = maxf(0.0, flash - delta * 2.4)
	if t > 0.15 and t < IMPACT:
		var ep := _ember_pos()
		parts.append({"p": ep, "v": Vector2(randf_range(-30, 30), randf_range(-20, 40)), "life": 0.45, "max": 0.45, "s": randf_range(8.0, 18.0), "t": "spark_05"})
	if _once("impact", IMPACT):
		shake = 12.0
		flash = 0.85
		for i in 34:
			var a := randf() * TAU
			var sp := randf_range(120.0, 520.0)
			parts.append({"p": C, "v": Vector2(cos(a), sin(a)) * sp, "life": randf_range(0.7, 1.3), "max": 1.3, "s": randf_range(26.0, 54.0), "t": "star_04" if i % 2 == 0 else "spark_05"})
	if _once("liar_sfx", LIAR_AT):
		Sfx.play("pop")
	if _once("laugh_sfx", LAUGH_AT):
		Sfx.play("laugh")
	var keep: Array = []
	for p in parts:
		p.life -= delta
		if p.life > 0.0:
			p.v.y += 260.0 * delta
			p.p += p.v * delta
			keep.append(p)
	parts = keep
	if t >= END_AT:
		_finish()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if t < 0.5 or done:
		return
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		_finish()

func _finish() -> void:
	if done:
		return
	done = true
	if audio != null:
		audio.stop()
	request.emit("intro", 0)

func _bounce(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	var n1 := 7.5625
	var d1 := 2.75
	if x < 1.0 / d1:
		return n1 * x * x
	if x < 2.0 / d1:
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	if x < 2.5 / d1:
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	x -= 2.625 / d1
	return n1 * x * x + 0.984375

func _spaced(ci: CanvasItem, s: String, centre: Vector2, size: int, col: Color, gap: float) -> void:
	var f := UI.font()
	var total := 0.0
	for ch in s:
		total += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + gap
	total -= gap
	var x := centre.x - total * 0.5
	for ch in s:
		ci.draw_string(f, Vector2(x, centre.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		x += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + gap

func _draw() -> void:
	var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	draw_set_transform(off, 0.0, Vector2.ONE)
	# the game's dusk forest + ground, darkened so the brand glows
	Backdrop.draw(self, t, 1, GROUND_Y, 0.74)
	# warm light pool from the emblem
	var glow := clampf((t - IMPACT) / 0.6, 0.0, 1.0) * (0.85 + 0.15 * sin(t * 3.0))
	if glow > 0.0:
		for i in 9:
			var rr := 330.0 - i * 34.0
			draw_circle(C + Vector2(0, 10), rr, Color(EMBER.r, EMBER.g, EMBER.b, 0.028 * glow))
	# ember falling
	if t > 0.15 and t < IMPACT:
		var ep := _ember_pos()
		draw_circle(ep, 26.0, Color(EMBER.r, EMBER.g, EMBER.b, 0.18))
		draw_circle(ep, 14.0, Color(1.0, 0.7, 0.3, 0.55))
		draw_circle(ep, 7.0, Color(1.0, 0.95, 0.8, 1.0))
	# shock ring on impact
	var rt := (t - IMPACT) / 0.7
	if rt > 0.0 and rt < 1.0:
		draw_arc(C, 40.0 + rt * 380.0, 0.0, TAU, 72, Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * (1.0 - rt)), 6.0 * (1.0 - rt) + 1.0)
	# emblem
	var et := clampf((t - IMPACT) / 0.4, 0.0, 1.0)
	if et > 0.0:
		var tex: Texture2D = EMBLEM
		var sc := lerpf(0.55, 1.0, _bounce(et)) * EMBLEM_H / tex.get_height()
		var sz := Vector2(tex.get_width(), tex.get_height()) * sc
		var rect := Rect2(C - sz * 0.5, sz)
		draw_texture_rect(tex, rect, false, Color(1, 1, 1, clampf(et * 3.0, 0.0, 1.0)))
		# light sweeps (a lightened copy of the emblem, revealed through a moving window)
		for st in [SWEEP_1, SWEEP_2]:
			var u: float = (t - st) / 0.55
			if u > 0.0 and u < 1.0:
				var hot: Texture2D = EMBLEM_HOT
				var wx := lerpf(-0.2, 1.2, u)
				var x0 := clampf(wx - 0.09, 0.0, 1.0)
				var x1 := clampf(wx + 0.09, 0.0, 1.0)
				if x1 > x0:
					var src := Rect2(x0 * hot.get_width(), 0, (x1 - x0) * hot.get_width(), hot.get_height())
					var dst := Rect2(rect.position + Vector2(x0 * sz.x, 0), Vector2((x1 - x0) * sz.x, sz.y))
					draw_texture_rect_region(hot, dst, src, Color(1, 1, 1, 0.9))
		# divider + PRESENTS
		var lt := clampf((t - PRESENTS_AT) / 0.5, 0.0, 1.0)
		if lt > 0.0:
			var ly := C.y + EMBLEM_H * 0.5 + 26.0
			var half := 130.0 * lt
			draw_line(Vector2(C.x - half, ly), Vector2(C.x + half, ly), Color(GOLD.r, GOLD.g, GOLD.b, 0.8), 3.0)
			_spaced(self, "PRESENTS", Vector2(C.x, ly + 40.0), 28, Color(GOLD.r, GOLD.g, GOLD.b, lt), 10.0)
	# the Liar vouches for the studio
	var lu := clampf((t - LIAR_AT) / 0.7, 0.0, 1.0)
	if lu > 0.0:
		var lp := Vector2(1130.0, lerpf(GROUND_Y + 120.0, GROUND_Y - 78.0, _bounce(lu)))
		var laugh := t >= LAUGH_AT
		Liar.draw(self, lp, 70.0, Vector2(-1.0, 0.0), t, 1.3 if laugh else 0.3)
		if t > LIAR_AT + 0.6:
			var msg := "Don't trust a word." if laugh else "Totally trustworthy studio."
			var f := UI.font()
			var br := Rect2(Vector2(lp.x + 62.0 - 372.0, lp.y - 252.0), Vector2(440, 140))
			draw_texture_rect(Art.menu("bubble_right"), br, false)
			var sz2 := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
			draw_string(f, br.position + Vector2(220.0 - sz2.x * 0.5, 62.0), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("3b2a14"))
	# particles (white-on-transparent fx textures, tinted ember)
	for p in parts:
		var al := clampf(p.life / p.max, 0.0, 1.0)
		var s3: float = p.s * (0.5 + 0.5 * al)
		draw_texture_rect(Art.fx(p.t), Rect2(p.p - Vector2(s3, s3) * 0.5, Vector2(s3, s3)), false, Color(1.0, 0.72, 0.35, al))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if flash > 0.0:
		draw_rect(Rect2(-700, 0, 2680, 720), Color(1.0, 0.85, 0.6, flash * 0.45))
	# fade in from / out to black
	if t < 0.45:
		draw_rect(Rect2(-700, 0, 2680, 720), Color(0, 0, 0, 1.0 - t / 0.45))
	if t > FADE_AT:
		draw_rect(Rect2(-700, 0, 2680, 720), Color(0, 0, 0, clampf((t - FADE_AT) / (END_AT - FADE_AT), 0.0, 1.0)))
	if t > 1.0 and t < FADE_AT:
		UI.text(self, "TAP TO SKIP", Vector2(20, 706), 18, Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_LEFT, 200.0, 3)
