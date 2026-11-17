extends SceneTree
## Control-layout settings: defaults, left-handed mirror, custom positions, clamping, and the Continue/skip fix.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var g = root.get_node("Game")
	g.autoplay = true   # never write the real save file from a test
	var ok := true
	g.data.erase("controls")
	var lay: Dictionary = g.touch_layout(Vector2(1600, 720))
	ok = ok and lay.l.x < lay.r.x and lay.j.x > 1400.0 and is_equal_approx(lay.scale, 1.0)
	g.set_controls({"scale": 1.3, "alpha": 0.5, "lefty": true, "pos": {}})
	var lh: Dictionary = g.touch_layout(Vector2(1600, 720))
	ok = ok and lh.j.x < 200.0 and lh.l.x > 1300.0 and lh.l.x < lh.r.x and is_equal_approx(lh.scale, 1.3)
	g.set_controls({"scale": 9.0, "alpha": 0.0, "lefty": false, "pos": {"j": [0.5, 0.5]}})
	var cu: Dictionary = g.touch_layout(Vector2(1600, 720))
	ok = ok and is_equal_approx(cu.scale, 1.6) and is_equal_approx(cu.alpha, 0.15) and cu.j.is_equal_approx(Vector2(800, 360))
	print("layout ", ok)
	# Continue never returns to a level that was just skipped
	g.data.erase("controls")
	g.data.done = {}
	g.data.skipped = {}
	for i in 4:
		g.data.done[str(i)] = {"time": 1.0}
	g.data.skipped["4"] = true
	var nxt: int = g.next_unfinished()
	var cont_ok: bool = nxt == 5
	g.data.done["5"] = {"time": 1.0}
	for i in range(6, g.level_count()):
		g.data.done[str(i)] = {"time": 1.0}
	cont_ok = cont_ok and g.next_unfinished() == 4   # only the skipped level is left: offered again
	print("continue skips skipped levels: ", cont_ok, " (got ", nxt, ")")
	ok = ok and cont_ok
	g.data.erase("controls")
	print("CONTROLS TEST ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)
