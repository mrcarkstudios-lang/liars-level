class_name Art
extends RefCounted
## Texture loader for the CC0 art packs (see art_src/SOURCES.md and art/USED.md).

static var _c := {}

static func _ld(path: String) -> Texture2D:
	if not _c.has(path):
		_c[path] = load(path)
	return _c[path]

static func tile(i: int) -> Texture2D:
	return _ld("res://art/tiles/tile_%04d.png" % i)

static func chr(i: int) -> Texture2D:
	return _ld("res://art/chars/tile_%04d.png" % i)

static func fx(n: String) -> Texture2D:
	return _ld("res://art/fx/%s.png" % n)

static func menu(n: String) -> Texture2D:
	return _ld("res://art/menu/%s.png" % n)

static func bg(n: String) -> Texture2D:
	return _ld("res://art/bg/%s.png" % n)

## the Blocks pack sheet is 9 tiles wide, 18 px with 1 px spacing
static func rock_src(col: int, row: int) -> Rect2:
	return Rect2(col * 19, row * 19, 18, 18)
