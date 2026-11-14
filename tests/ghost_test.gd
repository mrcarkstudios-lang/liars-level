extends SceneTree
## Ghost determinism: record a winning run the way play.gd does (bytes), replay it into a fresh World (6 idle frames first,
## like _start_ghost) and require the replay to win at the same frame count. Run: godot --headless --path . --script res://tests/ghost_test.gd

func _initialize() -> void:
	var bad := 0
	for i in LevelData.LEVELS.size():
		var lv: Dictionary = LevelData.LEVELS[i]
		var w := World.new()
		w.load_level(PackedStringArray(lv.map), lv.signs)
		var bot := Bot.new(lv.sol)
		var rec := PackedByteArray()
		var started := false
		var frames_run := 0
		var idle := 0
		for k in 6:   # a human always spends a few frames settling before the first input
			w.step(1.0 / 60.0, {"dir": 0, "jump_pressed": false, "jump_held": false})
		while frames_run < 7000:
			var inp := bot.next_input(w)
			if not started and (inp.dir != 0 or inp.jump_pressed):
				started = true
			if (w.state == "play" or w.state == "fake") and started:
				rec.append((int(inp.dir) + 1) | (4 if inp.jump_pressed else 0) | (8 if inp.jump_held else 0))
			elif not started:
				idle += 1
			w.step(1.0 / 60.0, inp)
			w.events.clear()
			frames_run += 1
			if w.state == "won":
				break
		# replay
		var g := World.new()
		g.load_level(PackedStringArray(lv.map), lv.signs)
		for k in 6:
			g.step(1.0 / 60.0, {"dir": 0, "jump_pressed": false, "jump_held": false})
		var n := 0
		for b in rec:
			var v: int = b
			g.step(1.0 / 60.0, {"dir": (v & 3) - 1, "jump_pressed": (v & 4) != 0, "jump_held": (v & 8) != 0})
			g.events.clear()
			n += 1
			if g.state == "won" or g.state == "dead":
				break
		var ok := g.state == "won" and n >= rec.size() - 1
		if not ok:
			bad += 1
		print("%s L%02d rec=%4d bytes replay=%s after %d frames" % ["OK  " if ok else "FAIL", i + 1, rec.size(), g.state, n])
	print("GHOST DONE bad=%d" % bad)
	quit(1 if bad > 0 else 0)
