extends SceneTree
## Verifies the real keyboard path: inject key events, check the player actually moves/jumps and the death+respawn loop works.
##   godot --headless --path . --script res://tests/input_test.gd

func _key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := root.get_node("Game")
	game.level = 0
	var play: Node2D = load("res://scripts/play.gd").new()
	root.add_child(play)
	for i in 5:
		await physics_frame
	var x0: float = play.w.pos.x
	_key(KEY_RIGHT, true)
	for i in 30:
		await physics_frame
	var x1: float = play.w.pos.x
	print("move right: %.0f -> %.0f  %s" % [x0, x1, "OK" if x1 > x0 + 30.0 else "FAIL"])
	_key(KEY_SPACE, true)
	for i in 6:
		await physics_frame
	var y_air: float = play.w.pos.y
	print("jump: y=%.0f vy=%.0f  %s" % [y_air, play.w.vel.y, "OK" if play.w.vel.y < 0.0 or y_air < 600.0 else "FAIL"])
	_key(KEY_SPACE, false)
	# run right into the first spike (col 15) -> must die, then respawn at start
	var died := false
	for i in 600:
		await physics_frame
		if play.w.state == "dead":
			died = true
			break
	print("dies on spike: %s (cause=%s)" % ["OK" if died else "FAIL", play.w.cause])
	_key(KEY_RIGHT, false)
	for i in 40:
		await physics_frame
	print("respawn: x=%.0f state=%s deaths=%d  %s" % [play.w.pos.x, play.w.state, play.deaths_here, "OK" if play.w.state == "play" and play.deaths_here == 1 else "FAIL"])
	_key(KEY_LEFT, true)
	for i in 20:
		await physics_frame
	_key(KEY_LEFT, false)
	# pause toggles with ESC and unpauses again
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await physics_frame
	await physics_frame
	var p1: bool = play.paused
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	await physics_frame
	await physics_frame
	print("pause toggle: paused=%s then paused=%s  %s" % [p1, play.paused, "OK" if p1 and not play.paused else "FAIL"])
	quit()
