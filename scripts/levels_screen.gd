class_name LevelsScreen
extends Control
## Level select: 4 worlds x 5 levels.

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
		var col_i: int = i % 5
		var row_i: int = i / 5
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
		var b := UI.button("%d\n%s\n%s" % [i + 1, name_s.to_upper(), sub], col, Vector2(196, 118), 22)
		b.position = Vector2(300 + col_i * 190.0, 82 + row_i * 126.0)
		b.size = Vector2(180, 114)
		b.custom_minimum_size = Vector2(180, 114)
		b.disabled = not unlocked
		b.clip_text = false
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var idx := i
		b.pressed.connect(func(): request.emit("play", idx))
		add_child(b)
		if i == daily:
			var tag := UI.label("DAILY", 18, Color("ffd45e"), 4)
			tag.position = b.position + Vector2(0, -2)
			tag.size = Vector2(180, 24)
			add_child(tag)
		if Game.data.stars.has(str(i)):
			var tr := TextureRect.new()
			tr.texture = Art.chr(13)
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.position = b.position + Vector2(146, 8)
			tr.size = Vector2(28, 28)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(tr)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	Backdrop.draw(self, t, 1, -1.0, 0.5)
	UI.ctext(self, "LEVELS", Vector2(640, 62), 48, Color.WHITE, 8)
	for wi in 5:
		var y := 82 + wi * 126
		var c: Color = WORLD_COLORS[wi]
		var r := Rect2(24, y + 4, 258, 100)
		var sb := UI.box(c.darkened(0.2), 18, 5)
		draw_style_box(sb, r)
		UI.text(self, "WORLD %d" % (wi + 1), r.position + Vector2(18, 36), 24, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
		draw_multiline_string(UI.font(), r.position + Vector2(18, 66), String(LevelData.WORLD_NAMES[wi]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 224.0, 24, 2, Color.WHITE)
	UI.text(self, "CLEARED %d/%d   STARS %d" % [Game.cleared_count(), Game.level_count(), Game.total_stars()], Vector2(836, 62), 24, Color("cfc6ff"), HORIZONTAL_ALIGNMENT_RIGHT, 400.0, 4)
