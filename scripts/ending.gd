class_name Ending
extends Control
## You beat the Liar. (Or did you?)

signal request(screen: String, arg: int)

var t := 0.0
var confetti: Array = []
var bubble_box: StyleBoxFlat

func _ready() -> void:
	UI.fit_screen(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Sfx.music("music_menu")
	Sfx.play("win")
	if Game.autoplay:
		print("AUTOPLAY COMPLETE: all levels cleared, ending reached. deaths=%d cleared=%d" % [int(Game.data.deaths), Game.cleared_count()])
		get_tree().quit(0)
	for i in 90:
		confetti.append({"p": Vector2(randf() * 1280.0, randf() * -720.0), "v": randf_range(90.0, 260.0), "c": [Color("ffd45e"), Color("5ee6c1"), Color("ff7ac6"), Color("8a7dff")][i % 4], "r": randf() * TAU})
	bubble_box = StyleBoxFlat.new()
	bubble_box.bg_color = Color("fff4d6")
	bubble_box.set_corner_radius_all(22)
	bubble_box.border_width_bottom = 6
	bubble_box.border_color = Color("d9b878")
	var again := UI.button("MENU", Color("34c38f"), Vector2(260, 70), 36)
	again.position = Vector2(150, 560)
	again.pressed.connect(func(): request.emit("menu", 0))
	add_child(again)
	var lv := UI.button("LEVELS", Color("8a5bff"), Vector2(220, 70), 36)
	lv.position = Vector2(430, 560)
	lv.pressed.connect(func(): request.emit("levels", 0))
	add_child(lv)
	var brag := UI.button("COPY BRAG", Color("ff7ac6"), Vector2(260, 70), 34)
	brag.position = Vector2(670, 560)
	brag.pressed.connect(func():
		DisplayServer.clipboard_set("I beat Liar's Level with %d deaths. Rank: %s. The Liar is shook." % [int(Game.data.deaths), Game.rank()])
		brag.text = "COPIED!")
	add_child(brag)

func _process(delta: float) -> void:
	t += delta
	for c in confetti:
		c.p.y += c.v * delta
		c.p.x += sin(t * 2.0 + c.r) * 40.0 * delta
		if c.p.y > 740.0:
			c.p.y = -20.0
	queue_redraw()

func _draw() -> void:
	Backdrop.draw(self, t, 5, -1.0, 0.25)
	for c in confetti:
		draw_rect(Rect2(c.p, Vector2(10, 10)), c.c)
	UI.ctext(self, "YOU BEAT THE LIAR", Vector2(640, 110), 80, Color("ffd45e"), 12)
	var lc := Vector2(980, 380) + Vector2(0, sin(t * 2.0) * 8.0)
	Liar.draw(self, lc, 125.0, Vector2(-0.4, 0.1), t, 0.2)
	var lines := ["Fine. You win.", "Everything I said was true.", "(That was a lie.)"]
	var rect := Rect2(150, 170, 640, 140)
	draw_style_box(bubble_box, rect)
	for i in lines.size():
		draw_string(UI.font(), rect.position + Vector2(0, 52 + i * 38), lines[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 32, Color("3b2a14"))
	var s1 := "TOTAL DEATHS  %d" % int(Game.data.deaths)
	UI.text(self, s1, Vector2(150, 380), 40, Color("ff9db0"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 6)
	UI.text(self, "RANK  %s" % Game.rank().to_upper(), Vector2(150, 440), 40, Color("5ee6c1"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 6)
	UI.text(self, "STARS  %d   /   DAILY BEST STREAK  %d" % [Game.total_stars(), int(Game.data.best_streak)], Vector2(150, 500), 30, Color("cfc6ff"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 5)
