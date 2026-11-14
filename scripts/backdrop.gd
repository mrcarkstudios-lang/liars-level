class_name Backdrop
extends RefCounted
## The in-game world look (parallax forest/frog backgrounds + real grass/dirt tiles) for menus, level select and ending,
## so every screen shares the art of the actual game.

const PlayScript := preload("res://scripts/play.gd")
const SETS := {
	1: [["forest_back", 4.5, 4.0, 0.55], ["forest_mid", 4.5, 8.0, 0.42], ["forest_front", 4.5, 14.0, 0.3], ["forest_lights", 4.5, 6.0, 0.22]],
	2: [["frog_9", 4.5, 5.0, 0.42], ["frog_8", 4.5, 9.0, 0.36]],
	3: [["frog_10", 6.6, 3.0, 0.4], ["frog_8", 4.5, 8.0, 0.26]],
	4: [["frog_9", 4.5, 5.0, 0.42], ["frog_7", 4.5, 10.0, 0.34]],
	5: [["frog_5", 2.9, 3.0, 0.4], ["frog_10", 6.6, 7.0, 0.36]],
}
const GRASS := {1: [0, 20], 2: [40, 60], 3: [80, 100], 4: [0, 20], 5: [0, 20]}

## Draw the background in the local 1280x720 space of `ci` (extends to -700..1980 so wide screens are covered).
## ground_y < 0 = no ground strip. `shade` darkens it so UI stays readable.
static func draw(ci: CanvasItem, t: float, world := 1, ground_y := -1.0, shade := 0.25) -> void:
	var pal: Dictionary = PlayScript.PALS[clampi(world - 1, 0, 4)]
	var pts := PackedVector2Array([Vector2(-700, 0), Vector2(1980, 0), Vector2(1980, 720), Vector2(-700, 720)])
	ci.draw_polygon(pts, PackedColorArray([pal.bg1, pal.bg1, pal.bg2, pal.bg2]))
	var tint: Color = Color(pal.bg2).lightened(0.55)
	for L in SETS[clampi(world, 1, 5)]:
		var tex: Texture2D = Art.bg(L[0])
		var sc: float = L[1]
		var wpx := tex.get_width() * sc
		var hpx := tex.get_height() * sc
		var xx := -fposmod(t * float(L[2]), wpx) - wpx * (1.0 + floorf(700.0 / wpx))
		var col := Color(tint.r, tint.g, tint.b, L[3])
		while xx < 1980.0:
			ci.draw_texture_rect(tex, Rect2(xx, 720.0 - hpx, wpx + 1.0, hpx), false, col)
			xx += wpx
	if ground_y >= 0.0:
		var g: Array = GRASS[clampi(world, 1, 5)]
		var c0 := -18
		for c in range(c0, 50):
			ci.draw_texture_rect(Art.tile(g[0] + 2), Rect2(c * 40, ground_y, 40, 40), false)
			var y := ground_y + 40.0
			while y < 720.0:
				ci.draw_texture_rect(Art.tile(g[1] + 2), Rect2(c * 40, y, 40, 40), false)
				y += 40.0
	if shade > 0.0:
		ci.draw_rect(Rect2(-700, 0, 2680, 720), Color(0.03, 0.02, 0.08, shade))
