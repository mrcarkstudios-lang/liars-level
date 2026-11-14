class_name UI
extends RefCounted
## Shared look-and-feel helpers (chunky rounded buttons, font).

static var _font: Font = null

static func font() -> Font:
	if _font == null:
		_font = load("res://fonts/LilitaOne-Regular.ttf")
	return _font

static func box(col: Color, radius := 18, border := 6, border_col := Color(-1, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.border_width_bottom = border
	sb.border_color = border_col if border_col.r >= 0.0 else col.darkened(0.35)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8 + border
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	return sb

static func button(text: String, col: Color, size := Vector2(260, 64), fsize := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	b.add_theme_color_override("font_outline_color", col.darkened(0.55))
	b.add_theme_constant_override("outline_size", 6)
	b.add_theme_stylebox_override("normal", box(col))
	b.add_theme_stylebox_override("hover", box(col.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", box(col.darkened(0.12), 18, 2))
	b.add_theme_stylebox_override("disabled", box(Color(0.27, 0.25, 0.36)))
	b.add_theme_stylebox_override("focus", box(col.lightened(0.12)))
	b.pressed.connect(func(): Sfx.play("click"))
	return b

## Pixel-art button from art/menu/<name>.png and <name>_pressed.png (the art kit). Stretches as a 9-patch.
static func art_button(text: String, name: String, size: Vector2, fsize := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", fsize)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color("0d0820"))
	b.add_theme_constant_override("outline_size", 6)
	var up := _art_box(Art.menu(name), 0.0)
	var down := _art_box(Art.menu(name + "_pressed"), 4.0)
	b.add_theme_stylebox_override("normal", up)
	b.add_theme_stylebox_override("hover", up)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("focus", up)
	b.pressed.connect(func(): Sfx.play("click"))
	return b

static func _art_box(tex: Texture2D, press_shift: float) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 14
	sb.texture_margin_right = 14
	sb.texture_margin_top = 14
	sb.texture_margin_bottom = 14
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4 + press_shift
	sb.content_margin_bottom = 8 - press_shift
	return sb

static func label(text: String, fsize := 28, col := Color.WHITE, outline := 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.12, 0.95))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 6) -> void:
	var f := font()
	if outline > 0:
		ci.draw_string_outline(f, pos, s, align, width, size, outline, Color(0.05, 0.03, 0.12, 0.95))
	ci.draw_string(f, pos, s, align, width, size, col)

static func ctext(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, outline := 6) -> void:
	var f := font()
	var sz := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var p := Vector2(pos.x - sz.x * 0.5, pos.y)
	if outline > 0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0.05, 0.03, 0.12, 0.95))
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

## Centre a 1280x720 screen (menus) inside a wider viewport so nothing hugs the left edge.
static func fit_screen(c: Control) -> void:
	var vp := c.get_viewport_rect().size
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.size = Vector2(1280, 720)
	c.position = Vector2((vp.x - 1280.0) * 0.5, 0.0)

static func fmt_time(t: float) -> String:
	var m := int(t) / 60
	var s := fmod(t, 60.0)
	if m > 0:
		return "%d:%05.2f" % [m, s]
	return "%.2fs" % s
