class_name ControlsEditor
extends Control
## "CONTROLS" screen: drag the on-screen buttons anywhere, change their size and opacity, switch to left-handed.
## Works as an overlay (opened from the menu and from the pause menu). Settings are saved in Game.data.controls.

signal closed

const RAD := {"l": 50.0, "r": 50.0, "j": 64.0}

var vp := Vector2(1280, 720)
var cfg: Dictionary
var pos := {}          # key -> screen position
var drag := ""         # which button is being dragged
var drag_off := Vector2.ZERO
var slider_drag := ""  # "size" or "alpha"
var lefty_btn: Button
var t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = get_viewport_rect().size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = vp
	global_position = Vector2.ZERO
	cfg = Game.controls()
	_reload_positions()
	var cx := vp.x * 0.5
	lefty_btn = UI.button("", Color("5b6bff"), Vector2(330, 54), 24)
	lefty_btn.position = Vector2(cx - 165, 430)
	lefty_btn.pressed.connect(func():
		cfg.lefty = not bool(cfg.lefty)
		cfg.pos = {}
		_reload_positions()
		_refresh())
	add_child(lefty_btn)
	var reset := UI.button("RESET", Color("ff8a3d"), Vector2(160, 54), 24)
	reset.position = Vector2(cx - 175, 506)
	reset.pressed.connect(func():
		cfg = Game.CTRL_DEFAULT.duplicate(true)
		_reload_positions()
		_refresh())
	add_child(reset)
	var done := UI.button("DONE", Color("34c38f"), Vector2(160, 54), 28)
	done.position = Vector2(cx + 15, 506)
	done.pressed.connect(_close)
	add_child(done)
	_refresh()

func _reload_positions() -> void:
	var lay := _layout()
	pos = {"l": lay.l, "r": lay.r, "j": lay.j}

func _layout() -> Dictionary:
	return Game.touch_layout(vp, cfg)

func _refresh() -> void:
	lefty_btn.text = "LEFT-HANDED: %s" % ("ON" if bool(cfg.lefty) else "OFF")

func _close() -> void:
	var c: Dictionary = cfg.duplicate(true)
	var p := {}
	for k in pos:
		p[k] = [pos[k].x / vp.x, pos[k].y / vp.y]
	c.pos = p
	Game.set_controls(c)
	closed.emit()
	queue_free()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

# slider rectangles (size / opacity)
func _bar(which: String) -> Rect2:
	var cx := vp.x * 0.5
	return Rect2(cx - 200.0, 300.0 if which == "size" else 370.0, 400.0, 14.0)

func _slider_value_from_x(which: String, x: float) -> void:
	var b := _bar(which)
	var u := clampf((x - b.position.x) / b.size.x, 0.0, 1.0)
	if which == "size":
		cfg.scale = snappedf(lerpf(0.7, 1.6, u), 0.05)
	else:
		cfg.alpha = snappedf(lerpf(0.15, 0.8, u), 0.05)

func _slider_u(which: String) -> float:
	if which == "size":
		return (float(cfg.scale) - 0.7) / 0.9
	return (float(cfg.alpha) - 0.15) / 0.65

func _input(event: InputEvent) -> void:
	var p := Vector2.ZERO
	var down := false
	var up := false
	var move := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		p = event.position
		down = event.pressed
		up = not event.pressed
	elif event is InputEventMouseMotion:
		p = event.position
		move = true
	else:
		return
	if down:
		for which in ["size", "alpha"]:
			var b := _bar(which).grow(26.0)
			if b.has_point(p):
				slider_drag = which
				_slider_value_from_x(which, p.x)
				get_viewport().set_input_as_handled()
				return
		var best := ""
		var best_d := 1e9
		for k in pos:
			var d: float = p.distance_to(pos[k])
			if d < float(RAD[k]) * float(cfg.scale) * 1.5 and d < best_d:
				best = k
				best_d = d
		if best != "":
			drag = best
			drag_off = pos[best] - p
			get_viewport().set_input_as_handled()
	elif move:
		if slider_drag != "":
			_slider_value_from_x(slider_drag, p.x)
		elif drag != "":
			var r: float = float(RAD[drag]) * float(cfg.scale)
			pos[drag] = Vector2(clampf(p.x + drag_off.x, r, vp.x - r), clampf(p.y + drag_off.y, r + 60.0, vp.y - r))
	elif up:
		drag = ""
		slider_drag = ""

func _draw() -> void:
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.03, 0.02, 0.08, 0.92))
	var cx := vp.x * 0.5
	UI.ctext(self, "CONTROLS", Vector2(cx, 80), 58, Color("ffd45e"), 10)
	UI.ctext(self, "DRAG THE BUTTONS WHERE YOU WANT THEM", Vector2(cx, 130), 24, Color(0.85, 0.8, 1.0), 4)
	# a little floor + hero so the layout can be judged
	draw_rect(Rect2(0, vp.y - 40, vp.x, 40), Color("37336e"))
	draw_rect(Rect2(0, vp.y - 40, vp.x, 6), Color("34c38f"))
	for which in ["size", "alpha"]:
		var b := _bar(which)
		UI.text(self, "SIZE" if which == "size" else "OPACITY", Vector2(b.position.x, b.position.y - 14.0), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
		draw_rect(b, Color(1, 1, 1, 0.25))
		var u := _slider_u(which)
		draw_rect(Rect2(b.position, Vector2(b.size.x * u, b.size.y)), Color("8a5bff"))
		draw_circle(Vector2(b.position.x + b.size.x * u, b.position.y + b.size.y * 0.5), 20.0, Color.WHITE)
		draw_circle(Vector2(b.position.x + b.size.x * u, b.position.y + b.size.y * 0.5), 14.0, Color("8a5bff"))
	# preview of the three buttons (same drawing as in the game)
	var a := float(cfg.alpha)
	var sc := float(cfg.scale)
	for k in pos:
		var c: Vector2 = pos[k]
		var r: float = float(RAD[k]) * sc
		var held: bool = drag == k
		draw_circle(c, r, Color(1, 1, 1, a * (0.9 if held else 0.34)))
		draw_arc(c, r, 0.0, TAU, 40, Color(1, 1, 1, minf(1.0, a * 1.2 + 0.2)), 3.0, true)
		var g := Color(1, 1, 1, minf(1.0, a * 1.7 + 0.15))
		match k:
			"l":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 0) * sc, c + Vector2(14, -20) * sc, c + Vector2(14, 20) * sc]), g)
			"r":
				draw_colored_polygon(PackedVector2Array([c + Vector2(20, 0) * sc, c + Vector2(-14, -20) * sc, c + Vector2(-14, 20) * sc]), g)
			"j":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -26) * sc, c + Vector2(26, 14) * sc, c + Vector2(-26, 14) * sc]), g)
