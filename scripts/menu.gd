class_name Menu
extends Control
## Title screen: the Liar greets you with lies.

signal request(screen: String, arg: int)

const LINES := [
	"Welcome! Nothing here will hurt you.",
	"Press PLAY. It's totally safe.",
	"I never lie. Never. (I lie.)",
	"Trust me. I'm a professional.",
	"Whatever the sign says: do the opposite.",
	"Or don't. Surprises are fun!",
	"Level 1 is honest. Enjoy it.",
	"Spikes are friends. Pointy friends.",
	"Nobody has ever beaten this game. (Probably.)",
]

var t := 0.0
var line_i := 0
var line_t := 0.0
var btn_play: Button
var btn_daily: Button
var btn_skin: Button
var btn_music: Button
var btn_sfx: Button
var btn_ads: Button
var look := Vector2.ZERO

func _ready() -> void:
	UI.fit_screen(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_i = randi() % LINES.size()
	Sfx.music("music_menu")
	var started: bool = Game.cleared_count() > 0
	var nxt := Game.next_unfinished()
	var ptxt := "CONTINUE  (LEVEL %d)" % (nxt + 1) if started else "PLAY"
	btn_play = UI.art_button(ptxt, "btn_large_green", Vector2(400, 84), 40)
	btn_play.position = Vector2(80, 322)
	btn_play.pressed.connect(func(): request.emit("play", nxt))
	add_child(btn_play)
	var lv := UI.art_button("LEVELS", "btn_medium_violet", Vector2(400, 64), 32)
	lv.position = Vector2(80, 420)
	lv.pressed.connect(func(): request.emit("levels", 0))
	add_child(lv)
	var dtxt := "DAILY LIE"
	if Game.daily_done_today():
		dtxt = "DAILY LIE  -  DONE"
	btn_daily = UI.art_button(dtxt, "btn_medium_orange", Vector2(400, 64), 32)
	btn_daily.position = Vector2(80, 496)
	btn_daily.pressed.connect(func(): request.emit("daily", 0))
	add_child(btn_daily)
	btn_skin = UI.art_button("", "btn_small_pink", Vector2(170, 52), 20)
	btn_skin.position = Vector2(80, 580)
	btn_skin.pressed.connect(_on_skin)
	add_child(btn_skin)
	btn_music = UI.art_button("", "btn_small_blue", Vector2(122, 52), 20)
	btn_music.position = Vector2(258, 580)
	btn_music.pressed.connect(_on_music)
	add_child(btn_music)
	btn_sfx = UI.art_button("", "btn_small_blue", Vector2(92, 52), 20)
	btn_sfx.position = Vector2(388, 580)
	btn_sfx.pressed.connect(_on_sfx)
	add_child(btn_sfx)
	var btn_ctl := UI.art_button("CONTROLS", "btn_small_blue", Vector2(130, 52), 18)
	btn_ctl.position = Vector2(646, 580)
	btn_ctl.pressed.connect(func():
		var ed := ControlsEditor.new()
		add_child(ed))
	add_child(btn_ctl)
	btn_ads = UI.art_button("REMOVE ADS", "btn_small_green", Vector2(150, 52), 18)
	btn_ads.position = Vector2(488, 580)
	btn_ads.pressed.connect(func():
		Ads.buy_remove_ads()
		btn_ads.visible = false)
	add_child(btn_ads)
	btn_ads.visible = Ads.billing_available() and not Ads.ads_removed()
	if Game.dev_controls:
		add_child(ControlsEditor.new())
	if OS.is_debug_build() and OS.get_name() == "Android":   # debug-only ad test panel (never in release builds)
		var tr := UI.art_button("TEST REWARDED", "btn_small_pink", Vector2(190, 46), 16)
		tr.position = Vector2(1060, 520)
		tr.pressed.connect(func(): Ads.show_rewarded(func(ok): print("[Ads] reward result ", ok)))
		add_child(tr)
		var ti := UI.art_button("TEST INTERSTITIAL", "btn_small_pink", Vector2(190, 46), 16)
		ti.position = Vector2(1060, 572)
		ti.pressed.connect(func(): Ads._sdk_interstitial(func(): print("[Ads] interstitial closed")))
		add_child(ti)
	_refresh()

func _refresh() -> void:
	btn_skin.text = "HERO: %s" % Game.SKIN_NAMES[int(Game.data.skin)].to_upper()
	btn_music.text = "MUSIC %s" % ("ON" if Sfx.music_on else "OFF")
	btn_sfx.text = "SFX %s" % ("ON" if Sfx.sfx_on else "OFF")

func _on_skin() -> void:
	Game.cycle_skin()
	_refresh()

func _on_music() -> void:
	Game.data.music = not Sfx.music_on
	Sfx.set_music_on(Game.data.music)
	Game.save()
	_refresh()

func _on_sfx() -> void:
	Game.data.sfx = not Sfx.sfx_on
	Sfx.set_sfx_on(Game.data.sfx)
	Game.save()
	_refresh()

func _process(delta: float) -> void:
	t += delta
	line_t += delta
	btn_ads.visible = Ads.billing_available() and not Ads.ads_removed()
	if line_t > 3.6:
		line_t = 0.0
		line_i = (line_i + 1) % LINES.size()
	var mp := get_local_mouse_position()
	look = look.lerp((mp - Vector2(1010, 350)).normalized(), minf(1.0, delta * 8.0))
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			btn_play.pressed.emit()

func _draw() -> void:
	# art-kit background: scaled to cover the screen width, anchored to the bottom so the ground stays put
	var vp_w := get_viewport_rect().size.x
	var k := maxf(1.0, vp_w / 1280.0)
	draw_texture_rect(Art.menu("bg_menu"), Rect2(640.0 - 640.0 * k, 720.0 - 720.0 * k, 1280.0 * k, 720.0 * k), false)
	var ground := 720.0 - 88.0 * k
	draw_rect(Rect2(-700, 688, 2680, 32), Color(0.03, 0.02, 0.08, 0.55))
	# the hero patrols the floor (same sprite as in the levels)
	var frames: Array = Game.SKIN_SPRITES[clampi(int(Game.data.skin), 0, Game.SKIN_SPRITES.size() - 1)]
	var hx := 930.0 + sin(t * 0.7) * 170.0
	var hf := int(t * 8.0) % 2
	draw_texture_rect(Art.chr(frames[hf]), Rect2(hx - 24.0, ground - 44.0, 48.0, 48.0), false)
	# title logo (art kit)
	var lt := Art.menu("logo_title")
	var lk := 5.0
	var lsz := Vector2(lt.get_width(), lt.get_height()) * lk
	var lbob := roundf(sin(t * 1.6) * 3.0) * 1.0
	draw_texture_rect(lt, Rect2(Vector2(60.0, 12.0 + lbob).round(), lsz), false)
	# the Liar + bubble
	var lc := Vector2(1010, 390) + Vector2(0, sin(t * 1.8) * 6.0)
	var laugh := 1.3 if line_t < 0.8 else 1.0
	Liar.draw(self, lc, 121.0, look, t, laugh)
	var line: String = LINES[line_i]
	var f := UI.font()
	var br := Rect2(800, 36, 440, 140)
	draw_texture_rect(Art.menu("bubble_left"), br, false)
	var fs := 28
	var sz := f.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, 400.0, fs)
	if sz.y > 76.0:
		fs = 23
		sz = f.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, 400.0, fs)
	draw_multiline_string(f, br.position + Vector2(20, 12 + (88.0 - sz.y) * 0.5 + fs * 0.85), line, HORIZONTAL_ALIGNMENT_CENTER, 400.0, fs, -1, Color("3b2a14"))
	if OS.is_debug_build() and OS.get_name() == "Android":
		UI.text(self, "ADS mode=%s sdk=%s rewarded=%s inter=%s" % [Ads.mode, Ads.sdk_ready, Ads.rewarded_ad != null, Ads.interstitial_ad != null], Vector2(20, 24), 18, Color("ffd45e"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
	# stats
	var y := 704.0
	var info := "RANK: %s     CLEARED %d/%d     DEATHS %d" % [Game.rank().to_upper(), Game.cleared_count(), Game.level_count(), int(Game.data.deaths)]
	UI.ctext(self, info, Vector2(640, y), 24, Color("cfc6ff"), 4)
	var streak := Game.streak_now()
	if streak > 0:
		UI.ctext(self, "DAILY STREAK: %d" % streak, Vector2(280, 654), 22, Color("ff9d4d"), 4)
	else:
		UI.ctext(self, Game.next_skin_hint().to_upper(), Vector2(280, 654), 20, Color(1, 1, 1, 0.55), 4)
