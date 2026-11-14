class_name Intro
extends Control
## Opening cinematic (about 7 s, skippable): a trusting hero walks past a "SAFE" sign into a hidden spike,
## the Liar drops in laughing, and the title slams in. Tap / click / any key skips.

signal request(screen: String, arg: int)

const T_DIE := 2.25
const SPIKE_X := 640.0
const FLOOR_Y := 600.0
const AUTO_END := 8.4

var t := 0.0
var fired := {}
var parts: Array = []
var shake := 0.0
var done := false
var bubble_box: StyleBoxFlat

func _ready() -> void:
	UI.fit_screen(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_box = StyleBoxFlat.new()
	bubble_box.bg_color = Color("fff4d6")
	bubble_box.set_corner_radius_all(18)
	bubble_box.border_width_bottom = 5
	bubble_box.border_color = Color("d9b878")
	Sfx.music("music_menu")

func _once(key: String, at: float) -> bool:
	if t >= at and not fired.has(key):
		fired[key] = true
		return true
	return false

func _hero_x() -> float:
	return -70.0 + clampf((t - 0.5) / (T_DIE - 0.5), 0.0, 1.0) * (SPIKE_X + 30.0 + 70.0)

func _process(delta: float) -> void:
	t += delta
	shake = maxf(0.0, shake - delta * 30.0)
	if _once("sign", 0.9):
		Sfx.play("sign")
	if _once("pop", T_DIE - 0.1):
		Sfx.play("pop")
	if _once("die", T_DIE):
		Sfx.play("die")
		shake = 10.0
		for i in 26:
			var a := randf() * TAU
			var sp := randf_range(100.0, 420.0)
			parts.append({"p": Vector2(SPIKE_X + 10.0, FLOOR_Y - 26.0), "v": Vector2(cos(a), sin(a)) * sp + Vector2(0, -160), "life": 0.9, "max": 0.9, "s": 34.0 + randf() * 22.0, "t": "spark_05" if i % 2 == 0 else "star_04"})
	if _once("laugh", 2.75):
		Sfx.play("laugh")
	if _once("slam1", 3.7):
		Sfx.play("thud")
		shake = 12.0
	if _once("slam2", 4.1):
		Sfx.play("thud")
		shake = 12.0
		for i in 20:
			var a2 := randf_range(-PI, 0.0)
			parts.append({"p": Vector2(480, 330), "v": Vector2(cos(a2), sin(a2)) * randf_range(120, 380), "life": 1.0, "max": 1.0, "s": 40.0, "t": "star_01"})
	if _once("tag", 4.9):
		Sfx.play("sign")
	var keep: Array = []
	for p in parts:
		p.life -= delta
		if p.life > 0.0:
			p.v.y += 900.0 * delta
			p.p += p.v * delta
			keep.append(p)
	parts = keep
	if t >= AUTO_END:
		_finish()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if t < 0.5:
		return
	var press := false
	if event is InputEventKey and event.pressed and not event.echo:
		press = true
	elif event is InputEventMouseButton and event.pressed:
		press = true
	elif event is InputEventScreenTouch and event.pressed:
		press = true
	elif event is InputEventJoypadButton and event.pressed:
		press = true
	if press:
		_finish()

func _finish() -> void:
	if done:
		return
	done = true
	request.emit("menu", 0)

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

func _draw() -> void:
	var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	draw_set_transform(off, 0.0, Vector2.ONE)
	var pts := PackedVector2Array([Vector2(-700, 0), Vector2(1980, 0), Vector2(1980, 720), Vector2(-700, 720)])
	draw_polygon(pts, PackedColorArray([Color("1d1744"), Color("1d1744"), Color("4a2f8a"), Color("4a2f8a")]))
	# dusk forest
	var tex: Texture2D = Art.bg("forest_back")
	var x0 := -fposmod(t * 6.0, tex.get_width() * 4.5) - tex.get_width() * 4.5 * 2.0
	var xx := x0
	while xx < 1980.0:
		draw_texture_rect(tex, Rect2(xx, 0, tex.get_width() * 4.5 + 1.0, 720), false, Color(0.7, 0.55, 1.0, 0.35))
		xx += tex.get_width() * 4.5
	# ground
	for c in range(-18, 50):
		draw_texture_rect(Art.tile(2), Rect2(c * 40, FLOOR_Y, 40, 40), false)
		draw_texture_rect(Art.tile(122), Rect2(c * 40, FLOOR_Y + 40, 40, 40), false, Color(0.6, 0.58, 0.68))
		draw_texture_rect(Art.tile(122), Rect2(c * 40, FLOOR_Y + 80, 40, 40), false, Color(0.5, 0.48, 0.58))
	# the "SAFE" sign
	var sign_alpha := clampf((t - 0.7) / 0.3, 0.0, 1.0)
	draw_texture_rect(Art.tile(86), Rect2(440, FLOOR_Y - 40, 40, 40), false, Color(1, 1, 1, sign_alpha))
	if t > 0.9 and t < T_DIE + 0.1:
		var msg := "Welcome! Nothing here will hurt you."
		var f := UI.font()
		var sz := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
		var br := Rect2(460.0 - sz.x * 0.5 - 18.0, FLOOR_Y - 130.0, sz.x + 36.0, 54.0)
		draw_style_box(bubble_box, br)
		draw_colored_polygon(PackedVector2Array([Vector2(452, br.end.y - 1), Vector2(472, br.end.y - 1), Vector2(460, br.end.y + 14)]), Color("fff4d6"))
		draw_string(f, br.position + Vector2(18, 37), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("3b2a14"))
	# the spike pops
	var spike_t := clampf((t - (T_DIE - 0.12)) / 0.1, 0.0, 1.0)
	if t < T_DIE - 0.12:
		for i in 3:
			draw_circle(Vector2(SPIKE_X - 6.0 + i * 10.0, FLOOR_Y - 3.0), 1.8, Color(1, 1, 1, 0.3))
	else:
		for i in 3:
			var bx := SPIKE_X - 14.0 + i * 11.0
			draw_colored_polygon(PackedVector2Array([Vector2(bx, FLOOR_Y), Vector2(bx + 5.5, FLOOR_Y - 30.0 * spike_t), Vector2(bx + 11.0, FLOOR_Y)]), Color("ff4d6d"))
	# the hero (walks in, then pops)
	if t > 0.5 and t < T_DIE:
		var hx := _hero_x()
		var frames: Array = Game.SKIN_SPRITES[clampi(int(Game.data.skin), 0, Game.SKIN_SPRITES.size() - 1)]
		var fi := int(t * 9.0) % 2
		draw_circle(Vector2(hx, FLOOR_Y + 1.0), 18.0, Color(0, 0, 0, 0.2))
		draw_texture_rect(Art.chr(frames[fi]), Rect2(hx - 34.0, FLOOR_Y - 66.0 + absf(sin(t * 18.0)) * -4.0, 68, 68), false)
	# the Liar drops in
	var lt := clampf((t - 2.55) / 0.9, 0.0, 1.0)
	if lt > 0.0:
		var end_pos := Vector2(1010.0, 330.0)
		var lp := Vector2(end_pos.x, lerpf(-220.0, end_pos.y, _bounce(lt)))
		var look := (Vector2(500, 400) - lp).normalized()
		Liar.draw(self, lp, 125.0, look, t, 1.2)
		if t > 3.05 and t < 4.4:
			var msg2 := "I lied."
			var f2 := UI.font()
			var sz2 := f2.get_string_size(msg2, HORIZONTAL_ALIGNMENT_LEFT, -1, 44)
			var br2 := Rect2(lp.x - sz2.x * 0.5 - 24.0, lp.y - 270.0, sz2.x + 48.0, 74.0)
			draw_style_box(bubble_box, br2)
			draw_colored_polygon(PackedVector2Array([Vector2(lp.x - 12, br2.end.y - 1), Vector2(lp.x + 12, br2.end.y - 1), Vector2(lp.x, br2.end.y + 20)]), Color("fff4d6"))
			draw_string(f2, br2.position + Vector2(24, 54), msg2, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("3b2a14"))
	# title slam (art-kit logo, whole-number scale so pixels stay square)
	var t1 := clampf((t - 3.7) / 0.7, 0.0, 1.0)
	if t1 > 0.0:
		var logo := Art.menu("logo_title")
		var lsz := Vector2(logo.get_width(), logo.get_height()) * 5.0
		var ly := roundf(lerpf(-340.0, 66.0, _bounce(t1)))
		draw_texture_rect(logo, Rect2(Vector2(480.0 - lsz.x * 0.5, ly).round(), lsz), false)
	if t > 4.9:
		var a := clampf((t - 4.9) / 0.5, 0.0, 1.0)
		UI.ctext(self, "A GAME THAT LIES TO YOU.", Vector2(480, 412), 34, Color(0.85, 0.8, 1.0, a), 6)
	if t > 5.6:
		var pulse := 0.6 + 0.4 * sin(t * 5.0)
		UI.ctext(self, "TAP TO PLAY", Vector2(480, 500), 42, Color(1, 1, 1, pulse), 8)
	# particles
	for p in parts:
		var al := clampf(p.life / p.max, 0.0, 1.0)
		var sz3: float = p.s * (0.5 + 0.5 * al)
		draw_texture_rect(Art.fx(p.t), Rect2(p.p - Vector2(sz3, sz3) * 0.5, Vector2(sz3, sz3)), false, Color(1.0, 0.85, 0.4, al))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# fade in from black, tiny skip hint
	if t < 0.6:
		draw_rect(Rect2(-700, 0, 2680, 720), Color(0.03, 0.02, 0.08, 1.0 - t / 0.6))
	if t > 1.2 and t < 5.6:
		UI.text(self, "TAP TO SKIP", Vector2(1070, 706), 18, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_RIGHT, 200.0, 3)
