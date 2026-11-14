extends SceneTree
## Ads policy test (mock mode): interstitial pacing, remove-ads, rewarded fallback.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var ok := true
	var ads = root.get_node("Ads")
	var game = root.get_node("Game")
	ads.mode = "mock"
	game.autoplay = false
	game.data["ads_removed"] = false
	var called := [0]
	# fewer than 3 cleared levels: never an ad
	game.data.done = {"0": true}
	for i in 6:
		ads.level_cleared_then(func(): called[0] += 1)
	ok = ok and called[0] == 6 and not ads.busy
	print("early levels no ads: ", ok)
	# 3+ cleared: the 3rd clear triggers an ad (busy), others pass straight through
	game.data.done = {"0": true, "1": true, "2": true, "3": true}
	ads.clears_since_ad = 0
	ads.last_ad_msec = -999999
	called[0] = 0
	ads.level_cleared_then(func(): called[0] += 1)
	ads.level_cleared_then(func(): called[0] += 1)
	var passthrough: bool = called[0] == 2 and not ads.busy
	ads.level_cleared_then(func(): called[0] += 1)
	var shown: bool = ads.busy and called[0] == 2
	print("pacing: passthrough=", passthrough, " ad_on_3rd=", shown)
	ok = ok and passthrough and shown
	ads.busy = false
	# remove ads
	game.data["ads_removed"] = true
	ads.clears_since_ad = 5
	ads.last_ad_msec = -999999
	called[0] = 0
	ads.level_cleared_then(func(): called[0] += 1)
	ok = ok and called[0] == 1 and not ads.busy
	print("remove ads respected: ", called[0] == 1)
	# mode off: rewards free
	ads.mode = "off"
	var granted := [false]
	ads.show_rewarded(func(r): granted[0] = r)
	ok = ok and granted[0]
	print("off-mode reward free: ", granted[0])
	print("ADS TEST ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)
