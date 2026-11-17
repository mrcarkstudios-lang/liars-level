extends SceneTree
## Level set checks: unique levels, difficulty strictly increasing, tutorial first / the Liar last, and old saves migrate by name.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var g = root.get_node("Game")
	g.autoplay = true   # never write the real save from a test
	var ok := true
	var n: int = LevelData.LEVELS.size()
	var names := {}
	var maps := {}
	var prev := -1.0
	var inc := true
	for i in n:
		var lv: Dictionary = LevelData.LEVELS[i]
		names[lv.name] = true
		maps["|".join(PackedStringArray(lv.map))] = true
		if float(lv.diff) <= prev:
			inc = false
			print("NOT INCREASING at level ", i + 1, " ", lv.name)
		prev = float(lv.diff)
	ok = ok and names.size() == n and maps.size() == n and inc
	ok = ok and LevelData.LEVELS[0].name == "Honest Start" and LevelData.LEVELS[n - 1].name == "The Liar"
	print("levels=", n, " unique_names=", names.size(), " unique_maps=", maps.size(), " strictly_increasing=", inc)
	# old save (24-level order) -> remapped by name
	g.data = {"done": {"0": {"time": 5.0}, "4": {"time": 9.0}, "23": {"time": 30.0}}, "skipped": {"2": true}, "stars": {"1": true}, "level_deaths": {"3": 7}, "ghosts": {}}
	g.migrate_order()
	var idx_hs := -1
	var idx_bc := -1
	var idx_liar := -1
	for i in n:
		match String(LevelData.LEVELS[i].name):
			"Honest Start": idx_hs = i
			"Bouncy Castle": idx_bc = i
			"The Liar": idx_liar = i
	var mig: bool = g.data.done.has(str(idx_hs)) and g.data.done.has(str(idx_bc)) and g.data.done.has(str(idx_liar)) and g.data.done.size() == 3 and int(g.data.order_v) == 2
	print("migration ok: ", mig)
	ok = ok and mig
	print("LEVELS TEST ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)
