extends SceneTree
## Headless solver check: every level must be beatable by its scripted bot solution.
##   godot --headless --path . --script res://tests/run_tests.gd [-- <level> [v]]

var verbose := false

func _initialize() -> void:
	var only := 0
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		only = int(args[0])
	verbose = args.size() > 1
	var fails := 0
	var n := LevelData.LEVELS.size()
	for i in n:
		if only > 0 and i + 1 != only:
			continue
		var res := run_level(i)
		if res.ok:
			print("PASS L%02d %-22s %5.2fs" % [i + 1, LevelData.LEVELS[i].name, res.time])
		else:
			fails += 1
			print("FAIL L%02d %-22s %s" % [i + 1, LevelData.LEVELS[i].name, res.msg])
	print("DONE fails=%d / %d" % [fails, n])
	quit(1 if fails > 0 else 0)

func run_level(idx: int) -> Dictionary:
	var lv: Dictionary = LevelData.LEVELS[idx]
	var w := World.new()
	w.load_level(PackedStringArray(lv.map), lv.signs)
	var bot := Bot.new(lv.sol)
	var frames := 0
	while frames < 7000:
		var inp := bot.next_input(w)
		if bot.error != "":
			return {"ok": false, "msg": bot.error, "time": w.time}
		if bot.exhausted() and bot.tail > 90:
			return {"ok": false, "msg": "ran out of steps at x=%d y=%d" % [w.pos.x, w.pos.y], "time": w.time}
		w.step(1.0 / 60.0, inp)
		if verbose and frames % 4 == 0:
			print("f%04d step=%s x=%d y=%d vy=%d gnd=%s" % [frames, bot.cur, w.pos.x, w.pos.y, w.vel.y, w.on_ground])
		w.events.clear()
		frames += 1
		if w.state == "won":
			return {"ok": true, "msg": "", "time": w.time}
		if w.state == "dead":
			return {"ok": false, "msg": "died (%s) at x=%d y=%d during step '%s' (#%d)" % [w.cause, w.pos.x, w.pos.y, bot.cur, bot.si], "time": w.time}
	return {"ok": false, "msg": "too many frames", "time": w.time}
