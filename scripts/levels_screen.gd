class_name LevelsScreen
extends Control
## Level select: 5 worlds x 10 levels (sorted by difficulty).

signal request(screen: String, arg: int)

const WORLD_COLORS := [Color("6a5cff"), Color("1f9d8f"), Color("c0408f"), Color("d9822b"), Color("8c2f3f")]
var t := 0.0

func _ready() -> void:
	UI.fit_screen(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Sfx.music("music_menu")
	var back := UI.button("BACK", Color("6b6b9a"), Vector2(150, 54), 28)
	back.position = Vector2(30, 18)
	back.pressed.connect(func(): request.emit("menu", 0))
	add_child(back)
	var daily := Game.daily_index()
	for i in Game.level_count():
		var wi: int = int(Game.level_info(i).world) - 1
		var in_world: int = i % 10          # 10 levels per world, shown as 2 rows of 5
		var col_i: int = in_world % 5
		var row_i: int = wi * 2 + in_world / 5
		var unlocked := Game.is_unlocked(i)
		var done := Game.is_done(i)
		var base: Color = WORLD_COLORS[wi]
		var col := base
		if done:
			col = Color("2fae7a")
		elif not unlocked:
			col = Color("45415e")
		var name_s := String(Game.level_info(i).name)
		var sub := ""
		if done:
			sub = "best " + UI.fmt_time(float(Game.data.done[str(i)].time))
		elif not unlocked:
			sub = "locked"
		elif Game.level_deaths(i) > 0:
			sub = "%d deaths" % Game.level_deaths(i)
		else:
			sub = "new"
		var b := UI.button("", col, Vector2(176, 54), 14)
		b.position = Vector2(298 + col_i * 184.0, 80 + row_i * 60.0)
		b.size = Vector2(176, 54)
		b.custom_minimum_size = Vector2(176, 54)
		b.disabled = not unlocked
		var idx := i
		b.pressed.connect(func(): request.emit("play", idx))
		add_child(b)
		# text lives in a label so long names can never stretch the card
		var fs := clampi(int(150.0 / (float(name_s.length()) * 0.72)), 9, 15)
		var txt := UI.label("%d  %s\n%s" % [i + 1, name_s.to_upper(), sub], fs, Color.WHITE if unlocked else Color(1, 1, 1, 0.5), 3)
		txt.custom_minimum_size = Vector2(166, 46)
		txt.position = b.position + Vector2(5, 1)
		txt.size = Vector2(166, 46)
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(txt)
		if i == daily:
			var tag := UI.label("DAILY", 12, Color("ffd45e"), 3)
			tag.position = b.position + Vector2(116, 36)
			tag.size = Vector2(56, 16)
			add_child(tag)
		if Game.data.stars.has(str(i)):
			var tr := TextureRect.new()
			tr.texture = Art.chr(13)
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.position = b.position + Vector2(148, 24)
			tr.size = Vector2(22, 22)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(tr)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	Backdrop.draw(self, t, 1, -1.0, 0.5)
	UI.ctext(self, "LEVELS", Vector2(640, 62), 48, Color.WHITE, 8)
	for wi in 5:
		var y := 80 + wi * 120
		var c: Color = WORLD_COLORS[wi]
		var r := Rect2(24, y, 258, 114)
		var sb := UI.box(c.darkened(0.2), 18, 5)
		draw_style_box(sb, r)
		UI.text(self, "WORLD %d" % (wi + 1), r.position + Vector2(18, 36), 24, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
		draw_multiline_string(UI.font(), r.position + Vector2(18, 66), String(LevelData.WORLD_NAMES[wi]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 224.0, 24, 2, Color.WHITE)
	UI.text(self, "CLEARED %d/%d   STARS %d" % [Game.cleared_count(), Game.level_count(), Game.total_stars()], Vector2(836, 62), 24, Color("cfc6ff"), HORIZONTAL_ALIGNMENT_RIGHT, 400.0, 4)
