class_name Bot
extends RefCounted
## Scripted "player" used by the headless tests and the --autoplay smoke test.
## Steps (strings):  R<x> / L<x> run until x | J<R|L|N><x|/frames> jump while holding a direction
##  G wait until grounded | W<n> wait n frames | T<n> keep direction n frames | I wait for reversed controls
##  Z<x> / Y<x> run right / left but wait for vertical saws | R/<n> hold n frames

var steps: Array = []
var si := 0
var cur := ""
var step_f := 0
var inv := false
var dir := 0
var jump_held := false
var jump_press := false
var last_dir := 0
var tail := 0
var error := ""

func _init(s: Array = []) -> void:
	steps = s

func exhausted() -> bool:
	return si >= steps.size() and cur == ""

func next_input(w: World) -> Dictionary:
	if cur == "":
		if si >= steps.size():
			tail += 1
			dir = 0
			jump_held = false
			jump_press = false
		else:
			cur = steps[si]
			si += 1
			step_f = 0
			jump_press = cur.begins_with("J")
	if cur != "":
		var cx := w.player_center().x
		var done := false
		var c := cur
		if c == "I":
			dir = last_dir
			jump_held = false
			if w.reversed:
				inv = true
				done = true
		elif c == "G":
			dir = 0
			jump_held = false
			done = w.on_ground and step_f > 1
		elif c.begins_with("W"):
			dir = 0
			done = step_f >= int(c.substr(1))
		elif c.begins_with("Z"):
			jump_held = false
			dir = 1
			for e: World.Ent in w.ents:
				if (e.k == "x" or e.k == "X") and e.pos.x - cx > -34.0 and e.pos.x - cx < 95.0 and absf(e.pos.y - (w.pos.y + 16.0)) < 62.0:
					dir = 0
			done = cx >= float(c.substr(1))
		elif c.begins_with("Y"):
			jump_held = false
			dir = -1
			for e: World.Ent in w.ents:
				if (e.k == "x" or e.k == "X") and cx - e.pos.x > -34.0 and cx - e.pos.x < 95.0 and absf(e.pos.y - (w.pos.y + 16.0)) < 62.0:
					dir = 0
			done = cx <= float(c.substr(1))
		elif c.begins_with("P"):
			# wait for a moving platform: PU<y> top<=y | PD<y> top>=y | PX<x> left edge>=x | PL<x> left edge<=x
			dir = 0
			jump_held = false
			var kind := c[1]
			var val := float(c.substr(2))
			for e: World.Ent in w.ents:
				if e.k in ["M", "N"]:
					if kind == "U" and e.pos.y <= val:
						done = true
					elif kind == "D" and e.pos.y >= val:
						done = true
				elif e.k in ["m", "n"]:
					if kind == "X" and e.pos.x >= val:
						done = true
					elif kind == "L" and e.pos.x <= val:
						done = true
		elif c.begins_with("T"):
			dir = last_dir
			done = step_f >= int(c.substr(1))
		elif c.begins_with("J"):
			jump_held = true
			var dch := c[1] if c.length() > 1 else "N"
			dir = 1 if dch == "R" else (-1 if dch == "L" else 0)
			var rest := c.substr(2) if c.length() > 2 else ""
			if rest == "":
				done = w.on_ground and step_f > 3
			elif rest.begins_with("/"):
				done = step_f >= int(rest.substr(1))
			else:
				var tx := float(rest)
				done = (cx >= tx) if dir >= 0 else (cx <= tx)
			if done:
				jump_held = false
		elif c.begins_with("R") or c.begins_with("L"):
			jump_held = false
			dir = 1 if c[0] == "R" else -1
			var rest2 := c.substr(1)
			if rest2.begins_with("/"):
				done = step_f >= int(rest2.substr(1))
			else:
				var tx2 := float(rest2)
				done = (cx >= tx2) if dir > 0 else (cx <= tx2)
		if step_f > 700:
			error = "step '%s' timed out at x=%d y=%d" % [cur, w.pos.x, w.pos.y]
		if dir != 0:
			last_dir = dir
		step_f += 1
		if done:
			cur = ""
	var phys := dir * (-1 if inv else 1)
	var out := {"dir": phys, "jump_pressed": jump_press, "jump_held": jump_held}
	jump_press = false
	return out
