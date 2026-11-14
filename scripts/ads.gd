extends Node
## Autoload "Ads": monetization layer. Game code only talks to this file.
##
## Modes:
##   "mock"  - debug builds / `--mock-ads`: a fake "TEST AD" screen so the whole flow can be played and tested.
##   "off"   - release builds with no ad SDK wired: no ads are shown and rewards (skip / hint) are free.
##   "admob" - TODO: wire the Godot AdMob plugin inside _sdk_* below (needs plugin + your AdMob IDs, see README "Monetization").
##
## Policy (kept gentle on purpose, the game's hook is instant retry):
##   rewarded: optional, player-initiated (skip level, hint).
##   interstitial: only on the level-clear -> next-level step, never after a death,
##                 not before 3 levels are cleared, every 3rd clear, at least 90 s apart.
##   "Remove Ads" removes interstitials only; rewarded stays optional.

# Google's public TEST ad unit IDs. Replace with your own AdMob IDs before release.
const TEST_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/1033173712"
# Your real AdMob ad units (the app id lives in project.godot -> [admob] general/android/app_id).
const LIVE_REWARDED := "ca-app-pub-6221264275692660/7044787355"
const LIVE_INTERSTITIAL := "ca-app-pub-6221264275692660/5176016964"

const MIN_CLEARED_FOR_INTERSTITIAL := 3
const EVERY_N_CLEARS := 3
const MIN_GAP_SEC := 90.0

var mode := "off"
var clears_since_ad := 0
var last_ad_msec := -999999
var layer: CanvasLayer
var busy := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var args := OS.get_cmdline_user_args()
	if OS.get_name() == "Android" and not "--mock-ads" in args:
		mode = "admob"   # debug builds use Google's TEST ad units, release builds use the live ones
	elif OS.is_debug_build() or "--mock-ads" in args:
		mode = "mock"
	if "--no-ads" in args or Game.autoplay:
		mode = "off"
	if mode == "admob":
		_sdk_start()
	if OS.get_name() == "Android" and not Game.autoplay:
		_billing_start()

func ads_removed() -> bool:
	return bool(Game.data.get("ads_removed", false))

func rewarded_available() -> bool:
	return mode != "off" and not Game.autoplay and not busy

func billing_available() -> bool:
	return mode == "mock"   # becomes true for "admob" once Play Billing is wired

## Rewarded ad. `done` is called with true if the reward should be granted.
## With no ad SDK ("off") the reward is granted for free so players are never blocked.
func show_rewarded(done: Callable) -> void:
	if mode == "off" or Game.autoplay:
		done.call(true)
		return
	if busy:
		return
	if mode == "mock":
		_mock_ad("WATCH TO UNLOCK", 3.0, true, done)
	else:
		_sdk_rewarded(done)

## Call when the player is about to go from a cleared level to the next one. `proceed` is always called.
func level_cleared_then(proceed: Callable) -> void:
	clears_since_ad += 1
	var due := mode != "off" and not Game.autoplay and not ads_removed() \
		and Game.cleared_count() >= MIN_CLEARED_FOR_INTERSTITIAL \
		and clears_since_ad >= EVERY_N_CLEARS \
		and Time.get_ticks_msec() - last_ad_msec >= int(MIN_GAP_SEC * 1000.0)
	if not due or busy:
		proceed.call()
		return
	clears_since_ad = 0
	last_ad_msec = Time.get_ticks_msec()
	if mode == "mock":
		_mock_ad("ADVERTISEMENT", 2.0, false, func(_ok): proceed.call())
	else:
		_sdk_interstitial(proceed)

func buy_remove_ads() -> void:
	if mode == "mock":
		Game.data["ads_removed"] = true
		Game.save()
	elif billing != null and billing_ready and product_found:
		var r: Dictionary = billing.purchase(PRODUCT_REMOVE_ADS)
		if int(r.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
			print("[Billing] purchase launch failed: ", r)

# ---------------------------------------------------------------- Google Play Billing ("Remove Ads", one-time product)
const PRODUCT_REMOVE_ADS := "remove_ads"
var billing: BillingClient
var billing_ready := false
var product_found := false

func _billing_start() -> void:
	billing = BillingClient.new()
	billing.connected.connect(func() -> void:
		billing_ready = true
		billing.query_product_details([PRODUCT_REMOVE_ADS], BillingClient.ProductType.INAPP)
		billing.query_purchases(BillingClient.ProductType.INAPP))
	billing.disconnected.connect(func() -> void: billing_ready = false)
	billing.connect_error.connect(func(code: int, msg: String) -> void: print("[Billing] connect error ", code, " ", msg))
	billing.query_product_details_response.connect(func(r: Dictionary) -> void:
		product_found = int(r.get("response_code", -1)) == BillingClient.BillingResponseCode.OK and r.get("product_details", []).size() > 0)
	billing.query_purchases_response.connect(func(r: Dictionary) -> void:
		if int(r.get("response_code", -1)) == BillingClient.BillingResponseCode.OK:
			for p in r.get("purchases", []):
				_billing_process(p))
	billing.on_purchase_updated.connect(func(r: Dictionary) -> void:
		if int(r.get("response_code", -1)) == BillingClient.BillingResponseCode.OK:
			for p in r.get("purchases", []):
				_billing_process(p))
	billing.acknowledge_purchase_response.connect(func(r: Dictionary) -> void:
		print("[Billing] acknowledge: ", r.get("response_code", -1)))
	billing.start_connection()

func _billing_process(p: Dictionary) -> void:
	if PRODUCT_REMOVE_ADS in p.get("product_ids", []) and int(p.get("purchase_state", 0)) == BillingClient.PurchaseState.PURCHASED:
		Game.data["ads_removed"] = true
		Game.save()
		if not bool(p.get("is_acknowledged", false)):
			billing.acknowledge_purchase(p.get("purchase_token", ""))

# ---------------------------------------------------------------- real AdMob (Poing Studios plugin 5.x)
var sdk_ready := false
var rewarded_ad: RewardedAd
var interstitial_ad: InterstitialAd
var rewarded_loader: RewardedAdLoader
var interstitial_loader: InterstitialAdLoader

func _rewarded_id() -> String:
	return TEST_REWARDED if OS.is_debug_build() else LIVE_REWARDED

func _interstitial_id() -> String:
	return TEST_INTERSTITIAL if OS.is_debug_build() else LIVE_INTERSTITIAL

## Consent (UMP, needed for EEA/UK players) first, then initialize the SDK, then preload both ads.
func _sdk_start() -> void:
	var info := UserMessagingPlatform.consent_information
	info.update(ConsentRequestParameters.new(),
		func() -> void:
			if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED and info.get_is_consent_form_available():
				UserMessagingPlatform.load_consent_form(
					func(form: ConsentForm) -> void:
						form.show(func(_e) -> void: _sdk_init()),
					func(_e) -> void: _sdk_init())
			else:
				_sdk_init(),
		func(_e) -> void: _sdk_init())

func _sdk_init() -> void:
	if sdk_ready:
		return
	var on_init := OnInitializationCompleteListener.new()
	on_init.on_initialization_complete = func(_s: InitializationStatus) -> void:
		sdk_ready = true
		print("[Ads] AdMob ready (", "TEST" if OS.is_debug_build() else "LIVE", " units)")
		_load_rewarded()
		_load_interstitial()
	MobileAds.set_request_configuration(RequestConfiguration.new())
	MobileAds.initialize(on_init)

func _load_rewarded() -> void:
	if not sdk_ready or rewarded_ad != null:
		return
	if rewarded_loader == null:
		rewarded_loader = RewardedAdLoader.new()
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		rewarded_ad = ad
	cb.on_ad_failed_to_load = func(e: LoadAdError) -> void:
		print("[Ads] rewarded load failed: ", e.message)
		get_tree().create_timer(30.0).timeout.connect(_load_rewarded)
	rewarded_loader.load(_rewarded_id(), AdRequest.new(), cb)

func _load_interstitial() -> void:
	if not sdk_ready or interstitial_ad != null:
		return
	if interstitial_loader == null:
		interstitial_loader = InterstitialAdLoader.new()
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_ad = ad
	cb.on_ad_failed_to_load = func(e: LoadAdError) -> void:
		print("[Ads] interstitial load failed: ", e.message)
		get_tree().create_timer(30.0).timeout.connect(_load_interstitial)
	interstitial_loader.load(_interstitial_id(), AdRequest.new(), cb)

## No ad ready (no fill / offline): the player is never blocked, the reward is granted.
func _sdk_rewarded(done: Callable) -> void:
	if rewarded_ad == null:
		_load_rewarded()
		done.call(true)
		return
	busy = true
	var ad := rewarded_ad
	rewarded_ad = null
	var earned := [false]
	var finish := func() -> void:
		ad.destroy()
		busy = false
		_load_rewarded()
		done.call_deferred(earned[0])
	var fs := FullScreenContentCallback.new()
	fs.on_ad_dismissed_full_screen_content = func() -> void:
		finish.call()
	fs.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		earned[0] = true   # our failure, not the player's: still reward
		finish.call()
	ad.full_screen_content_callback = fs
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		earned[0] = true
	ad.show(listener)

func _sdk_interstitial(proceed: Callable) -> void:
	if interstitial_ad == null:
		_load_interstitial()
		proceed.call()
		return
	busy = true
	var ad := interstitial_ad
	interstitial_ad = null
	var finish := func() -> void:
		ad.destroy()
		busy = false
		_load_interstitial()
		proceed.call_deferred()
	var fs := FullScreenContentCallback.new()
	fs.on_ad_dismissed_full_screen_content = func() -> void:
		finish.call()
	fs.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		finish.call()
	ad.full_screen_content_callback = fs
	ad.show()

# ---------------------------------------------------------------- mock ad screen
func _mock_ad(title: String, secs: float, rewarded: bool, done: Callable) -> void:
	busy = true
	var prev_pause := get_tree().paused
	get_tree().paused = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.12, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(box)
	box.add_child(UI.label("TEST AD", 64, Color("ffd45e")))
	box.add_child(UI.label(title, 30, Color(0.85, 0.8, 1.0)))
	var count := UI.label("", 40)
	box.add_child(count)
	var btn := UI.button("CLAIM" if rewarded else "CLOSE", Color("34c38f"), Vector2(260, 64), 30)
	btn.visible = false
	box.add_child(btn)
	var x_btn: Button = null
	if rewarded:
		x_btn = UI.button("NO THANKS", Color("6b6490"), Vector2(220, 48), 22)
		box.add_child(x_btn)
	var state := {"left": secs, "finished": false}
	var finish := func(ok: bool):
		if state.finished:
			return
		state.finished = true
		root.queue_free()
		get_tree().paused = prev_pause
		busy = false
		done.call(ok)
	btn.pressed.connect(func(): finish.call(true))
	if x_btn != null:
		x_btn.pressed.connect(func(): finish.call(false))
	var tm := Timer.new()
	tm.wait_time = 0.1
	tm.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(tm)
	tm.timeout.connect(func():
		state.left -= 0.1
		if state.left <= 0.0:
			count.text = "Done!"
			btn.visible = true
			tm.stop()
		else:
			count.text = "%.0f" % ceilf(state.left))
	tm.start()
	count.text = "%.0f" % ceilf(secs)
