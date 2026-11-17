extends Node
## Screen manager with a quick fade between screens.

var current: Node = null
var fade: ColorRect
var busy := false
var shot_path := ""
var shot_frames := 0
var frame_n := 0
var demo_keys := ""

func _ready() -> void:
	randomize()
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)
	fade = ColorRect.new()
	fade.color = Color(0.03, 0.02, 0.08, 1.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(fade)
	var start := "brand"
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--level="):
			Game.level = int(a.substr(8)) - 1
			start = "play"
		if a == "--intro":
			start = "intro"
		if a == "--controls":
			start = "menu"
			Game.dev_controls = true
		if a == "--menu":
			start = "menu"
		if a == "--levels":
			start = "levels"
		if a == "--ending":
			start = "ending"
		if a.begins_with("--complete-shot="):
			Game.complete_shot = a.substr(16)
			Game.autoplay = true
			Game.level = 0
			start = "play"
		if a.begins_with("--pause-shot="):
			Game.dev_pause_shot = a.substr(13)
		if a.begins_with("--state-shot="):
			var parts := a.substr(13).split("@")
			Game.state_shot = parts[0]
			Game.state_shot_cond = parts[1]
		if a == "--seed-ghost":
			Game.seed_ghost = true
		if a == "--hold-right":
			Game.hold_right = true
		if a == "--touch":
			Game.force_touch = true
		if a == "--autoplay":
			Game.autoplay = true
			Game.level = 0
			start = "play"
		if a.begins_with("--shot="):
			shot_path = a.substr(7)
		if a.begins_with("--frames="):
			shot_frames = int(a.substr(9))
	_show(start, Game.level, true)

func _on_request(screen: String, arg: int) -> void:
	_show(screen, arg, false)

func _show(screen: String, arg: int, instant: bool) -> void:
	if busy:
		return
	busy = true
	if not instant:
		var t := create_tween()
		t.tween_property(fade, "modulate:a", 1.0, 0.16)
		await t.finished
	get_tree().paused = false
	if current != null:
		current.queue_free()
		current = null
	var node: Node = null
	match screen:
		"brand":
			node = Brand.new()
		"intro":
			node = Intro.new()
		"menu":
			node = Menu.new()
		"levels":
			node = LevelsScreen.new()
		"ending":
			node = Ending.new()
		"daily":
			Game.daily_mode = true
			Game.level = Game.daily_index()
			node = preload("res://scripts/play.gd").new()
		"retry":
			Game.level = clampi(arg, 0, Game.level_count() - 1)
			node = preload("res://scripts/play.gd").new()
		_:
			Game.daily_mode = false
			Game.level = clampi(arg, 0, Game.level_count() - 1)
			node = preload("res://scripts/play.gd").new()
	node.request.connect(_on_request)
	add_child(node)
	current = node
	fade.modulate.a = 1.0 if instant else fade.modulate.a
	var t2 := create_tween()
	t2.tween_property(fade, "modulate:a", 0.0, 0.2)
	busy = false


func _process(_d: float) -> void:
	if shot_path == "":
		return
	frame_n += 1
	if frame_n == shot_frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot_path)
		print("saved ", shot_path)
		get_tree().quit()
