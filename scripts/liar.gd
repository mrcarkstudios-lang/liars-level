class_name Liar
extends RefCounted
## "The Liar": the game's mascot/narrator, now a pixel-art sprite (art/menu/liar_*.png) so it matches the levels.
## Poses: 1 smirk, 2 laughing, 3 looks left, 4 looks right, 5 fake-innocent.

const SRC := Vector2(24, 28)   # native sprite size in art pixels; the round body is ~22 art pixels wide

## c = centre of the body, r = body radius in pixels. grin > 1 laughs, grin < 0.5 plays innocent.
static func draw(ci: CanvasItem, c: Vector2, r: float, look: Vector2 = Vector2.ZERO, t: float = 0.0, grin: float = 1.0) -> void:
	var pose := 1
	if grin > 1.05:
		pose = 2
	elif grin < 0.5:
		pose = 5
	elif look.x < -0.35:
		pose = 3
	elif look.x > 0.35:
		pose = 4
	var k := float(maxi(1, roundi(r * 2.0 / 22.0)))   # whole-number scale keeps the pixels square
	var sz := SRC * k
	var bob := roundf(sin(t * 2.0) * 2.0) * k * 0.5
	ci.draw_texture_rect(Art.menu("liar_%d" % pose), Rect2((c - Vector2(sz.x * 0.5, sz.y * 0.52) + Vector2(0, bob)).round(), sz), false)
