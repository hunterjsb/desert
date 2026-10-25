class_name Readout
extends RefCounted
## What the line under the aim dot says (Hands): why take or use did nothing,
## why what you hold won't stick where it's shown or what to mind, else what
## you look at; and under it, a line you're untying or gathering at your waist.


## What the look-at line says now: why take or use did nothing, why what you
## hold won't stick where it's shown or what to mind, else what you look at.
static func line(hands: Hands, player: Player) -> String:
	if player.world.arrival != null:
		var opening := player.world.arrival.hint()
		if opening != "":
			return opening
	if hands.notice != "":
		return hands.notice
	var sticking := hands.sticking
	if hands.phase == Hands.Phase.HELD and hands.held is Part and hands.held.has_meta(&"line") and hands.look_hook() != null:
		var laid: Line = hands.held.get_meta(&"line")
		return Controls.key_for(&"interact") + " · " + ("remove line from hook" if laid.rope != null \
			and laid.rope.through == hands.look_hook().guide else "pass line through hook")
	var through := hands._cable_at_stake()
	if not through.is_empty():
		return Controls.key_for(&"interact") + " · " + ("take cable off stake" \
			if (through.cable as Cable).through == through.stake else "pass cable through stake")
	if not sticking.is_empty() and (sticking.why != "" or sticking.warn != ""):
		return sticking.why if sticking.why != "" else sticking.warn
	if not sticking.is_empty() and (hands.held is CrowsNest or hands.grasp.body is CrowsNest) \
			and sticking.deck is Mast and sticking.face == Mast.MASTHEAD:
		return "Crow's nest on masthead"
	if hands.look_wreck != null and (hands.look_work != null or hands.look_scrap != null):
		return hands.look_wreck.describe(hands.look_work if hands.look_work != null else hands.look_scrap)
	if hands.look_line != null:
		return Controls.key_for(&"hands_grab") + " · gather rope · %.1f m" % hands.look_line.full
	if hands.look_part != null:
		return describe(hands.look_part.label, _part_stats(hands.look_part))
	if hands.look_socket != null and hands.look_socket.part != null:
		return describe(hands.look_socket.part.label, _part_stats(hands.look_socket.part))
	if hands.look_device == null:
		return "Bed" if hands.look_bed else ""
	if hands.look_device is ManualWinch:
		return "%s · %s / %s" % [hands.look_device.label, Controls.key_for(&"reel_in"), Controls.key_for(&"pay_out")]
	var stats := hands.look_device.stats()
	# A device's charge is on its light.
	stats.erase("charge_wh")
	stats["in_w"] = hands.look_device.production_w()
	stats["out_w"] = hands.look_device.demand_w() if hands.look_device.powered else 0.0
	stats["dark"] = not hands.look_device.powered and hands.look_device.demand_w() > 0.0
	return describe(hands.look_device.label, stats)


## The look-at line and, under it, a line you're untying or gathering at your waist.
static func said(hands: Hands, player: Player) -> String:
	var text := line(hands, player)
	var waisted := player.waist.release_readout()
	if waisted == "" and player.waist.untying >= 0.0:
		waisted = ("Gathering line · %.1f s" if player.waist.gathering() else "Untying line · %.1f s") % player.waist.untying
	if waisted != "":
		text += ("\n" if text != "" else "") + waisted
	return text


## One line: what it is and, at most, the one thing you need about it now
## (Hunter, 2026-10-18: "almost everything is overload"). The rest shows
## another way or isn't said: weight in what you carry, a device's charge on
## its light, a line's strain in its creak, floating by where it hangs, what
## take would move by its highlight.
static func describe(label: String, stats: Dictionary) -> String:
	var now := _state(stats)
	return label if now == "" else "%s · %s" % [label, now]


## The first of these a thing has: a crop ripe or why it isn't growing, a
## device that would run but has no power, a radio's frequency, what a thing
## holds, then power, said as the device does it: output, or draws.
static func _state(stats: Dictionary) -> String:
	if stats.get("ripe", false):
		return "ripe"
	if stats.has("growing") and stats.growing != Plant.GROWING:
		return str(stats.growing)
	if stats.get("dark", false):
		return "no power"
	if stats.get("making_lph", 0.0) > 0.0:
		return "water %.1f L/h" % stats.making_lph
	if stats.has("water_l"):
		return "%.1f/%.1f L" % [stats.get("water_left_l", 0.0), stats.water_l]
	if stats.has("food_kcal"):
		return "%d kcal" % roundi(stats.get("food_left_kcal", 0.0))
	# A radio's frequency before its battery's charge: its dial is what you need.
	if stats.has("tuned"):
		return str(stats.tuned)
	if stats.has("charge_wh") and stats.get("capacity_wh", 0.0) > 0.0:
		return "%d/%d Wh" % [floori(stats.charge_wh), roundi(stats.capacity_wh)]
	if stats.get("in_w", 0.0) > 0.0:
		return "output %d W" % roundi(stats.in_w)
	if stats.get("out_w", 0.0) > 0.0:
		return "draws %d W" % roundi(stats.out_w)
	if stats.has("rope_m"):
		return "%d m" % roundi(stats.rope_m)
	return ""


## A part's stats as they stand: a battery's charge, a crop's state, a coil's length.
static func _part_stats(part: Part) -> Dictionary:
	var now := part.stats.duplicate()
	if part is Battery:
		now["charge_wh"] = part.charge_wh
	if part is Plant:
		now["ripe"] = part.ripe()
		if part.socket != null:
			now["growing"] = part.state
	if part.has_meta(&"line"):
		now.merge((part.get_meta(&"line") as Line).readout())
	return now
