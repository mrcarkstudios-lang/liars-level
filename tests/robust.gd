extends SceneTree
## Fairness probe: jitter every positional step of each solution by +/-6 and +/-12 px and count how many variants still win.
##   godot --headless --path . --script res://tests/robust.gd

func _initialize() -> void:
	var n := LevelData.LEVELS.size()
	var only := 0
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		only = int(args[0])
	for i in n:
		if only > 0 and i + 1 != only:
			continue
		var lv: Dictionary = LevelData.LEVELS[i]
		var sol: Array = lv.sol
		var total := 0
		var ok := 0
		var worst := []
		for si in sol.size():
			var tok: String = sol[si]
			var prefix := ""
			var num := 0.0
			var has := false
			for pf in ["JR", "JL", "R", "L", "Z", "Y"]:
				if tok.begins_with(pf) and tok.substr(pf.length()).is_valid_float() and not tok.contains("/"):
					prefix = pf
					num = float(tok.substr(pf.length()))
					has = true
					break
			if not has:
				continue
			var step_ok := 0
			var step_total := 0
			for d in [-12, -6, 6, 12]:
				var v := sol.duplicate()
				v[si] = prefix + str(num + d)
				step_total += 1
				if _run(lv, v):
					step_ok += 1
			total += step_total
			ok += step_ok
			if step_ok < step_total:
				worst.append("%s(%d/%d)" % [tok, step_ok, step_total])
		print("L%02d %-20s robust %3d%%  weak: %s" % [i + 1, lv.name, int(100.0 * ok / maxf(1.0, total)), ", ".join(worst)])
	quit()

func _run(lv: Dictionary, steps: Array) -> bool:
	var w := World.new()
	w.load_level(PackedStringArray(lv.map), lv.signs)
	var bot := Bot.new(steps)
	for f in 4000:
		var inp := bot.next_input(w)
		if bot.error != "":
			return false
		if bot.exhausted() and bot.tail > 90:
			return false
		w.step(1.0 / 60.0, inp)
		w.events.clear()
		if w.state == "won":
			return true
		if w.state == "dead":
			return false
	return false
