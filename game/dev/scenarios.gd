class_name Scenarios
extends RefCounted
## Dev starting conditions. Each one searches this run's own weather for a
## moment and a place that match, so a playtest starts where it needs to
## without faking anything. A probe checks each delivers what it says.

## kind: "spawn", "clear", "front" (a storm `distance` m upwind, coming at
## you), "deep" (inside, far from any edge), "back" (inside, clear air
## `distance` m upwind), "sky" (clear, for the light) or "kit" (clear, with the
## test kit dropped in front of you). day is the window of time of day to look
## in: 0 is midnight, 0.5 noon. "camp" drops a floating camp in front of you,
## each piece on one line to a stake, with stakes and coils to add more.
## "survive" starts you over on sealed water, with a crude camp to keep you.
## "ruin" stands you in front of the ruin nearest where the run began, clear
## and calm, with finds round it and a bare crate frame of your own. "farm"
## sets two planters growing in front of you, one with a harvester, and a
## shield for the storm on its way. "radio" sets a radio and a shield in front
## of you with a storm on its way, to sit it out and follow a beacon. "afk"
## parks the reference camp round you, running, to be left alone, its farm
## watered by a condenser on hoses. "lee" stands you at the foot of a tall
## slip face, facing up it into the wind coming over its crest, with a storm
## on its way. "chassis" lays out pieces, their trays, a crate and a
## condenser to build a deck from. "eclipse" faces Tu in the clear, the sun
## `eclipse` s from going behind it. "moon" stands you elsewhere on the moon:
## [latitude, degrees east of the point under Tu], so [30, 180] is the far
## side, 30° north. Times of day are local.
const LIST: Array[Dictionary] = [
	{"key": "spawn", "label": "spawn: where and when the run began", "kind": "spawn"},
	{"key": "clear", "label": "clear day, no storm for 10 min", "kind": "clear", "day": [0.42, 0.55]},
	{"key": "wall", "label": "wall on the horizon, 3 km", "kind": "front", "distance": 3000.0, "day": [0.35, 0.5]},
	{"key": "storm_500", "label": "storm 500 m away", "kind": "front", "distance": 500.0, "day": [0.35, 0.55]},
	{"key": "storm_100", "label": "storm 100 m away", "kind": "front", "distance": 100.0, "day": [0.35, 0.55]},
	{"key": "storm_20", "label": "storm 20 m away", "kind": "front", "distance": 20.0, "day": [0.35, 0.55]},
	{"key": "deep", "label": "deep in a storm", "kind": "deep", "day": [0.35, 0.55]},
	{"key": "clearing", "label": "storm about to clear, 100 m", "kind": "back", "distance": 100.0, "day": [0.35, 0.55]},
	{"key": "dusk", "label": "dusk, sun on the horizon", "kind": "sky", "day": [0.733, 0.745]},
	{"key": "night", "label": "night", "kind": "sky", "day": [0.85, 0.95]},
	{"key": "eclipse", "label": "eclipse: clear, facing Tu, the sun half a minute from going behind it",
		"kind": "clear", "eclipse": 30.0},
	{"key": "far", "label": "far side: a clear night with no Tu, 30° north, facing the pole star", "kind": "sky",
		"day": [0.9, 0.97], "moon": [30.0, 180.0]},
	# Calm, so a floating device doesn't drift off before there's rope to hold it.
	{"key": "kit", "label": "test kit: devices and parts, clear and calm", "kind": "kit", "day": [0.42, 0.55],
		"calm": 6.0},
	{"key": "camp", "label": "camp to stake: floaters on one line each, a shield, a storm 500 m off", "kind": "front",
		"distance": 500.0, "day": [0.35, 0.55], "camp": true},
	{"key": "survive", "label": "survive a few days: sealed water, a crude condenser, a shield, at dawn", "kind": "clear",
		"day": [0.25, 0.3], "survive": true},
	{"key": "ruin", "label": "go looking: a ruin and finds near you, your own bare crate frame, clear and calm",
		"kind": "ruin", "day": [0.35, 0.5], "calm": 6.0},
	# A clear morning, with a storm due in time to pick the carrots first and
	# before the noon heat that wilts fungus: "due" is when, s, in place of ten
	# clear minutes.
	{"key": "farm", "label": "farm: carrots ripening in the clear, fungus for the storm due in minutes, a harvester, a shield",
		"kind": "clear", "day": [0.33, 0.37], "due": [90.0, 200.0], "farm": true},
	{"key": "board", "label": "ride: a charged hoverboard at your feet by a small camp, a shield and a crate, clear and calm",
		"kind": "clear", "day": [0.35, 0.5], "calm": 6.0, "board": true},
	{"key": "radio", "label": "radio: a radio and a charged shield in front of you, a storm 300 m off", "kind": "front",
		"distance": 300.0, "day": [0.35, 0.55], "radio": true},
	# A morning like a run's, the first storm minutes off, so it soon shows what the camp does in one.
	{"key": "afk", "label": "AFK: the reference camp parked round you and running, a farm under the shield hosed to a condenser, a turbine out in the wind",
		"kind": "clear", "day": [0.3, 0.4], "due": [180.0, 480.0], "afk": true},
	# A storm due soon, so the lee is felt in the clear and then as it comes over the crest.
	{"key": "lee", "label": "lee: at the foot of a tall slip face, the wind over its crest, a storm minutes off",
		"kind": "lee", "day": [0.35, 0.55], "due": [120.0, 360.0]},
	{"key": "chassis", "label": "chassis: pieces, their trays, a crate and a condenser to build a deck from, clear and calm",
		"kind": "clear", "day": [0.35, 0.5], "calm": 6.0, "chassis": true},
]

## The test kit, as [catalog id, metres to your right, metres ahead]: empty
## frames, a shield generator among them, and parts for every kind of socket.
const KIT_DEVICES := [[&"crate_frame", -1.0, 3.0], [&"planter", 1.2, 3.2], [&"charger", -2.4, 1.5],
	[&"turbine", 2.6, 1.6], [&"shield", 0.05, 3.2]]
## Where the kit's common cable, strong cable and hose land, right and ahead.
const KIT_CABLE := [0.0, 2.3]
const KIT_STRONG_CABLE := [0.0, 1.6]
const KIT_HOSE := [0.0, 1.3]
const KIT_PARTS := [
	[&"battery", -1.6, 1.6], [&"big_battery", -1.2, 1.7], [&"hook", -0.8, 1.6], [&"hook", -0.55, 1.7],
	[&"lamp", -0.25, 1.6], [&"carrot", 0.1, 1.7], [&"carrot", 0.35, 1.6], [&"carrot", 0.6, 1.7],
	[&"fungus", 0.95, 1.6], [&"battery", 1.3, 1.7], [&"hover_tray", -2.6, 2.4],
	[&"hover_tray", 2.8, 2.6], [&"solar_panel", -2.6, 3.6], [&"solar_panel", -3.0, 2.2],
	[&"hook", 1.65, 1.7], [&"hook", 1.95, 1.6], [&"canister", -2.0, 1.2],
]
## Stakes lying across your way, and rope coils, right and ahead.
const KIT_STAKES := [[-1.3, 1.15], [-1.3, 1.3], [-1.3, 1.45]]
const KIT_COILS := [[0.6, 1.2], [1.2, 1.2]]
## The camp: floating devices [catalog id, right, ahead] each on a line to a
## stake further upwind, a charged shield generator, and spare stakes and coils by your feet.
const CAMP_DEVICES := [[&"planter", -2.0, 4.0], [&"crate_frame", 2.0, 4.0]]
const CAMP_SHIELD := [0.0, 2.6]
const CAMP_STAKE_AHEAD := 3.0
const CAMP_STAKES := [[-0.6, 1.2], [-0.6, 1.35], [-0.6, 1.5], [-0.6, 1.65]]
const CAMP_COILS := [[0.4, 1.2], [0.9, 1.2], [1.4, 1.2]]

## Survival's start, right and ahead: the condenser, the shield generator, the
## cable to join them, and spare rations.
const SURVIVE_CONDENSER := [-0.9, 2.6]
const SURVIVE_SHIELD := [0.9, 2.3]
const SURVIVE_CABLE := [0.0, 1.7]
const SURVIVE_RATIONS := [[0.35, 1.3], [0.6, 1.3]]

## The farm, right and ahead: a planter to pick by hand, one with a
## harvester, the shield generator between them so its bubble takes both and
## their stakes, and a canister to fit to a water socket. Its crops start
## part grown, so the carrots ripen within a minute in the clear and the
## fungus within a few once the storm's dark is on it.
const FARM_BY_HAND := [-1.6, 2.8]
const FARM_HARVESTER := [1.6, 2.8]
const FARM_SHIELD := [0.0, 2.0]
const FARM_CANISTER := [-0.5, 1.3]
const FARM_CROPS := [&"carrot", &"carrot", &"carrot", &"fungus"]
const FARM_GROWN := {&"carrot": 0.85, &"fungus": 0.5}

## The board, nose ahead, and the small camp beside you: right and ahead.
const BOARD_AT := [0.0, 1.3]
const BOARD_SHIELD := [-2.0, 3.0]
const BOARD_CRATE := [2.2, 3.4]

## The radio, its face to you and far enough out to be in view as you
## arrive, and the shield to sit the storm out by it.
const RADIO_AT := [0.4, 2.4]
const RADIO_SHIELD := [-1.0, 3.2]

## The reference camp, right and ahead, facing upwind: the shield and the
## planters in front of you, the condenser beyond the shield between them, the
## crate behind you near the bubble's edge, its stake upwind of it, and the
## turbine downwind of the bubble near the end of its cable, so the wind holds
## it out there.
const AFK_SHIELD := [0.0, 2.0]
const AFK_PLANTERS := [[-2.2, 2.6], [2.2, 2.6]]
const AFK_CONDENSER := [0.0, 4.2]
const AFK_CRATE := [0.0, -2.0]
const AFK_STAKE := [1.6, -0.6]
const AFK_TURBINE := [0.0, -7.4]
## What you carry, as you'd leave yourself: nothing brings you water yet, the
## condenser waters only the farm, so this many canisters, and no food: the
## farm drops it onto you.
const AFK_CANISTERS := 3

## The chassis pieces lying in a row ahead of you, a tray in front of each,
## and the crate and condenser to stand on the deck either side: right and ahead.
const CHASSIS_PIECES := [[-1.8, 3.6], [-0.6, 3.6], [0.6, 3.6], [1.8, 3.6]]
const CHASSIS_TRAYS := [[-1.8, 2.2], [-0.6, 2.2], [0.6, 2.2], [1.8, 2.2]]
const CHASSIS_CRATE := [3.4, 2.4]
const CHASSIS_CONDENSER := [-3.4, 2.4]

## Your own frame, to fit what you find to: right and ahead.
const YOURS := [1.5, 2.5]
## How far from where the run began to look for a ruin, m.
const RUIN_SEARCH := 4000.0

## A tall slip face's foot: level sand at the bottom of a drop whose crest
## stands at least this far above it, m, and a lee there of at least this
## share of a full one. Looked for this far either way along the wind from
## where the run began, m, in steps this long, along lines this far either
## side, m.
const LEE_TALL := 15.0
const LEE_SHARE := 0.9
const LEE_SEARCH := 3000.0
const LEE_STEP := 4.0
const LEE_LINES := [0.0, 200.0, -200.0, 400.0, -400.0]

## How far upwind a search looks for edges, and its step.
const REACH := 6000.0
const STEP := 25.0
## Search the first three days, finely enough not to step over dusk.
const HORIZON := 3.0 * 24.0 * 3600.0
const TIME_STEP := 10.0
## "deep" means full storm for at least this far either way along the wind.
const DEEP := 300.0


## Puts you into a scenario on this world: there and then, with its own
## things in front of you in place of the run's kit, and the last scenario's
## gone. Where it put you, or that it found nowhere, shows on the overlay at
## once; its things follow once the sand under them is solid.
static func apply(world: World, scenario: Dictionary) -> void:
	if scenario.is_empty():
		push_warning("no such scenario")
		return
	var place := find(world, scenario)
	if place.is_empty():
		Dev.put("world/scn", "%s: none in 3 days" % scenario.key)
		return
	stand(world, scenario, place)
	Dev.put("world/scn", scenario.key)
	# Untyped: what the ground unloaded once you moved away is freed already.
	for body in world.get_meta(&"scenario_kit", []):
		if is_instance_valid(body):
			body.queue_free()
	world.remove_meta(&"scenario_kit")
	if not (scenario.kind in ["kit", "ruin"] or scenario.get("camp", false) or scenario.get("survive", false)
			or scenario.get("farm", false) or scenario.get("board", false) or scenario.get("radio", false)
			or scenario.get("afk", false) or scenario.get("chassis", false)):
		return
	# Bodies dropped before the sand under them has collision would be frozen or forgotten.
	while is_instance_valid(world) and not world.terrain.is_settled_around(place.x, place.z):
		await world.get_tree().physics_frame
	if not is_instance_valid(world):
		return
	# Its own kit takes the place of the run's, gone before anything lands on it.
	for body in world.get_meta(&"kit", []):
		if is_instance_valid(body):
			body.free()
	world.remove_meta(&"kit")
	var dropped: Array[Node3D]
	if scenario.kind == "ruin":
		dropped = yours(world)
	elif scenario.kind == "kit":
		dropped = kit(world)
	elif scenario.get("farm", false):
		dropped = farm(world)
	elif scenario.get("board", false):
		dropped = board(world)
	elif scenario.get("radio", false):
		dropped = radio(world)
	elif scenario.get("afk", false):
		dropped = afk(world)
	elif scenario.get("chassis", false):
		dropped = chassis(world)
	else:
		dropped = camp(world) if scenario.get("camp", false) else survive(world)
	world.set_meta(&"scenario_kit", dropped)


## Puts you where find() found, there on the moon too.
static func stand(world: World, scenario: Dictionary, place: Dictionary) -> void:
	world.respawn(place.x, place.z, place.yaw, place.time)
	if scenario.has("moon"):
		var at := moon_at(world, scenario)
		world.moon.place(rad_to_deg(at.x), rad_to_deg(at.y))


## Where on the moon a scenario stands you, radians: its "moon", or the spawn's.
static func moon_at(world: World, scenario: Dictionary) -> Vector2:
	var tuning := world.tuning
	if not scenario.has("moon"):
		return Vector2(deg_to_rad(tuning.spawn_latitude_degrees), deg_to_rad(tuning.spawn_longitude_degrees))
	return Vector2(deg_to_rad(scenario.moon[0]), wrapf(deg_to_rad(tuning.tu_longitude_degrees + scenario.moon[1]), -PI, PI))


static func by_key(key: String) -> Dictionary:
	for scenario in LIST:
		if scenario.key == key:
			return scenario
	return {}


## Where to put the player: {x, z, yaw, time}, or {} if this run's weather has
## no such moment in three days.
static func find(world: World, scenario: Dictionary) -> Dictionary:
	var spawn := world.spawn
	if scenario.kind == "spawn":
		return {"x": spawn.x, "z": spawn.y, "yaw": 0.0, "time": 0.0}
	if scenario.kind == "ruin":
		return _at_ruin(world, scenario)
	if scenario.kind == "lee":
		return _in_lee(world, scenario)
	var field := world.weather.field
	var day := world.weather.day
	var moon := moon_at(world, scenario)
	var t := 0.0
	if scenario.has("eclipse"):
		t = day.next_eclipse(0.0) - day.totality() * 0.5 - scenario.eclipse
	while t < HORIZON:
		var hour := day.time_of_day(t, moon.y)
		if scenario.has("eclipse") or (hour >= scenario.day[0] and hour <= scenario.day[1]):
			var upwind := -field.prevailing_at(t).normalized()
			var place := _place(field, scenario, spawn, upwind, t)
			if not place.is_empty():
				place.time = t
				place.yaw = _facing(day, scenario, moon, upwind, t)
				return place
		t += world.tuning.day_minutes * 60.0 if scenario.has("eclipse") else TIME_STEP
	return {}


static func _place(field: WeatherField, scenario: Dictionary, from: Vector2, upwind: Vector2,
		t: float) -> Dictionary:
	match scenario.kind:
		"clear", "sky", "kit", "ruin", "lee":
			# No storm for ten minutes, or one due within the window asked.
			var due: Array = scenario.get("due", [INF, INF])
			if field.raw_storm_at(from.x, from.y, t) <= 0.0 \
					and field.wind_at(from.x, from.y, t).length() < scenario.get("calm", INF) \
					and (scenario.kind == "sky" or _within(field.next_change(from.x, from.y, t, minf(due[1], 600.0), 10.0), due)):
				return {"x": from.x, "z": from.y}
		"front", "back":
			# March upwind for an edge with enough of the other side behind it.
			var into_storm: bool = scenario.kind == "front"
			var need: float = scenario.distance + 50.0
			var run := 0.0
			var d := 0.0
			var was := _stormy(field, from, upwind, 0.0, t)
			while d < REACH:
				d += STEP
				var now := _stormy(field, from, upwind, d, t)
				if now == was:
					run += STEP
					continue
				if now == into_storm and run >= need:
					var edge := _refine(field, from, upwind, d - STEP, d, t)
					var at: Vector2 = from + upwind * (edge - scenario.distance)
					return {"x": at.x, "z": at.y}
				was = now
				run = 0.0
		"deep":
			var run := 0.0
			var d := 0.0
			while d < REACH:
				var p := from + upwind * d
				run = run + STEP if field.storm_at(p.x, p.y, t) == 1.0 else 0.0
				if run >= DEEP * 2.0:
					var at := from + upwind * (d - DEEP)
					return {"x": at.x, "z": at.y}
				d += STEP
	return {}


## In front of the nearest ruin's door, facing it, at a moment in the day's
## window that's clear and calm there and stays clear ten minutes.
static func _at_ruin(world: World, scenario: Dictionary) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	for ruin in world.shape.ruins.around(world.spawn.x, world.spawn.y, RUIN_SEARCH):
		var at := ruin.to_world(Ruin.APPROACH)
		var door := ruin.to_world(Ruin.DOORS[0][0])
		var t := 0.0
		while t < HORIZON:
			var hour := day.time_of_day(t, deg_to_rad(world.tuning.spawn_longitude_degrees))
			if hour >= scenario.day[0] and hour <= scenario.day[1] and not _place(field, scenario, at, Vector2.ZERO, t).is_empty():
				var facing := (door - at).normalized()
				return {"x": at.x, "z": at.y, "yaw": atan2(-facing.x, -facing.y), "time": t}
			t += TIME_STEP
	return {}


## At the foot of a tall slip face, facing up it, at a moment in the day's
## window that's clear with a storm due, the wind blowing over the crest.
static func _in_lee(world: World, scenario: Dictionary) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	var mean := WeatherField.mean_heading(world.run_seed)
	var longitude := moon_at(world, scenario).y
	for foot in feet(world, mean):
		# Out of the long-term wind's lee, which the dunes face, is out of most winds'.
		if world.weather.lee.share(foot.x, foot.y, mean) < LEE_SHARE:
			continue
		var t := 0.0
		while t < HORIZON:
			var hour := day.time_of_day(t, longitude)
			if hour >= scenario.day[0] and hour <= scenario.day[1] \
					and not _place(field, scenario, foot, Vector2.ZERO, t).is_empty() \
					and world.weather.lee.share(foot.x, foot.y, field.prevailing_at(t).angle()) >= LEE_SHARE:
				var upwind := -field.prevailing_at(t).normalized()
				return {"x": foot.x, "z": foot.y, "yaw": atan2(-upwind.x, -upwind.y), "time": t}
			t += TIME_STEP
	return {}


## Feet of tall slip faces round where the run began, facing a wind blowing
## toward heading: level sand just past a slip face's slope, from a crest
## LEE_TALL m or more above. Nearest first.
static func feet(world: World, heading: float) -> Array[Vector2]:
	var down := Vector2.from_angle(heading)
	var found: Array[Vector2] = []
	for across: float in LEE_LINES:
		var from := world.spawn + down.orthogonal() * across - down * LEE_SEARCH
		var behind := PackedFloat64Array()
		var d := 0.0
		while d < 2.0 * LEE_SEARCH:
			var at := from + down * d
			behind.append(world.shape.height_at(at.x, at.y))
			d += LEE_STEP
			var n := behind.size()
			if n < 16:
				continue
			var h := behind[n - 1]
			var crest := h
			for k in range(n - 16, n):
				crest = maxf(crest, behind[k])
			# Level for a step, after two at a slip face's slope.
			if absf(behind[n - 2] - h) < LEE_STEP * 0.1 and behind[n - 4] - behind[n - 2] > 2.0 * LEE_STEP * 0.45 \
					and crest - h >= LEE_TALL:
				found.append(at)
	found.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(world.spawn) < b.distance_squared_to(world.spawn))
	return found


static func _within(value: float, span: Array) -> bool:
	return value >= span[0] and value <= span[1]


static func _stormy(field: WeatherField, from: Vector2, along: Vector2, d: float, t: float) -> bool:
	var p := from + along * d
	return field.raw_storm_at(p.x, p.y, t) > 0.0


## The edge between lo and hi along the ray, to a centimetre.
static func _refine(field: WeatherField, from: Vector2, along: Vector2, lo: float, hi: float,
		t: float) -> float:
	var at_hi := _stormy(field, from, along, hi, t)
	while hi - lo > 0.01:
		var mid := (lo + hi) * 0.5
		if _stormy(field, from, along, mid, t) == at_hi:
			hi = mid
		else:
			lo = mid
	return hi


## Storms come from upwind, so you face it. Dusk faces the sunset in the west,
## night faces east toward the dawn, the far side north to the pole star, and
## an eclipse faces Tu.
static func _facing(day: DayCycle, scenario: Dictionary, moon: Vector2, upwind: Vector2, t: float) -> float:
	if scenario.has("eclipse"):
		var tu := day.tu_direction(t, moon.x, moon.y)
		return atan2(-tu.x, -tu.z)
	if scenario.kind != "sky":
		return atan2(-upwind.x, -upwind.y)
	if scenario.has("moon"):
		return 0.0
	return PI / 2.0 if scenario.key == "dusk" else -PI / 2.0


## Drops the test kit on the sand in front of the player, squared to them,
## parts lying socket side down. Returns what it dropped.
static func kit(world: World) -> Array[Node3D]:
	var player := world.player
	var yaw := Basis(Vector3.UP, player.global_rotation.y)
	var dropped: Array[Node3D] = []
	for entry: Array in KIT_DEVICES:
		var device := Catalog.device(entry[0])
		var size: Vector3 = Catalog.DEVICES[entry[0]].size
		drop(world, device, Transform3D(yaw, Vector3(0.0, size.y * 0.5, 0.0)), entry[1], entry[2])
		dropped.append(device)
	for entry: Array in KIT_PARTS:
		var part := Catalog.part(entry[0])
		drop(world, part, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), entry[1], entry[2])
		dropped.append(part)
	dropped.append_array(stakes_and_coils(world, KIT_STAKES, KIT_COILS))
	var at := player.global_position + player.global_basis.x * KIT_CABLE[0] - player.global_basis.z * KIT_CABLE[1]
	at.y = world.height_under(at)
	var cable := Catalog.cable(world, at)
	dropped.append(cable)
	dropped.append_array(cable.plugs)
	at = player.global_position + player.global_basis.x * KIT_STRONG_CABLE[0] - player.global_basis.z * KIT_STRONG_CABLE[1]
	at.y = world.height_under(at)
	var strong := Catalog.cable(world, at, true)
	dropped.append(strong)
	dropped.append_array(strong.plugs)
	at = player.global_position + player.global_basis.x * KIT_HOSE[0] - player.global_basis.z * KIT_HOSE[1]
	at.y = world.height_under(at)
	var hose := Catalog.hose(world, at)
	dropped.append(hose)
	dropped.append_array(hose.plugs)
	return dropped


## Drops the camp in front of the player: each floating device, its battery
## and tray fitted and a hook on every ring mount, on one line from a hook to
## a stake driven upwind of it, and a shield generator with a full battery,
## switched off. Returns what it dropped.
static func camp(world: World) -> Array[Node3D]:
	var dropped: Array[Node3D] = []
	for entry: Array in CAMP_DEVICES:
		dropped.append_array(_tethered(world, entry[0], entry[1], entry[2]))
	dropped.append(standing(world, &"shield", [&"battery"], CAMP_SHIELD))
	dropped.append_array(stakes_and_coils(world, CAMP_STAKES, CAMP_COILS))
	return dropped


## A device floating in front of you, its battery and tray fitted and a hook
## on every ring mount, on one line from a hook to a stake driven upwind of
## it: [device, stake].
static func _tethered(world: World, id: StringName, right: float, ahead: float) -> Array[Node3D]:
	var player := world.player
	var device := Catalog.device(id)
	drop(world, device, Transform3D(Basis(Vector3.UP, player.global_rotation.y),
		Vector3(0.0, world.tuning.hover_height, 0.0)), right, ahead)
	for socket in device.sockets():
		var fill: Variant = {&"battery": &"battery", &"bottom": &"hover_tray", &"ring": &"hook"}.get(socket.kind)
		if fill != null:
			var part := Catalog.part(fill)
			world.content.add_child(part)
			device.fit(part, socket)
	device.global_position.y += device.rest_height() - world.tuning.hover_height
	var stake := Catalog.stake()
	var at := device.global_position - player.global_basis.z * CAMP_STAKE_AHEAD
	world.content.add_child(stake)
	stake.drive(at, world.height_under(at))
	Line.between(world, device.free_tie(stake.global_position), stake.free_tie(device.global_position), 0.5)
	return [device, stake]


## A run's sealed-water start: you fed, watered and whole, carrying a fresh
## suit's kit, and on the sand in front of you a crude condenser with a
## battery, a panel and an empty canister, a charged shield generator, a
## cable to join them, and spare rations. Returns what it dropped.
static func survive(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	var condenser := standing(world, &"condenser", [&"battery", &"solar_panel", &"canister"], SURVIVE_CONDENSER)
	(condenser as Condenser).canister().drain(INF)
	var dropped: Array[Node3D] = [condenser, standing(world, &"shield", [&"battery"], SURVIVE_SHIELD)]
	var player := world.player
	var at := player.global_position + player.global_basis.x * SURVIVE_CABLE[0] - player.global_basis.z * SURVIVE_CABLE[1]
	at.y = world.height_under(at)
	var cable := Catalog.cable(world, at)
	dropped.append(cable)
	dropped.append_array(cable.plugs)
	var yaw := Basis(Vector3.UP, player.global_rotation.y)
	for entry: Array in SURVIVE_RATIONS:
		var ration := Catalog.part(&"ration")
		drop(world, ration, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), entry[0], entry[1])
		dropped.append(ration)
	return dropped


## Two hover planters floating in front of you, each on a line to a stake as
## in the camp, sown with carrots and a fungus part grown, one tank full and
## one half: one to pick by hand, and one with a harvester that keeps its
## slots sown and drops food onto you. A charged shield generator, switched
## off, stands between them, with a full canister by your feet to fit to the
## half-full one's water socket, which keeps its tank full. You start
## fed, watered and whole, on a fresh suit's kit and a spare carrot to sow.
## Returns what it dropped.
static func farm(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	world.player.suit.carried.append(Catalog.part(&"carrot"))
	var dropped: Array[Node3D] = []
	for where: Array in [FARM_BY_HAND, FARM_HARVESTER]:
		var tied := _tethered(world, &"planter", where[0], where[1])
		var planter := tied[0] as Planter
		for id: StringName in FARM_CROPS + ([&"harvester"] if where == FARM_HARVESTER else []):
			var part := Catalog.part(id)
			for socket in planter.sockets():
				if socket.kind == part.kind and socket.part == null:
					planter.fit(part, socket)
					break
		for plant in planter.plants():
			plant.set_growth(FARM_GROWN[plant.crop])
		planter.tank_l = world.tuning.planter_tank_litres * (1.0 if planter.harvests() else 0.5)
		dropped.append_array(tied)
	dropped.append(standing(world, &"shield", [&"battery"], FARM_SHIELD))
	var yaw := Basis(Vector3.UP, world.player.global_rotation.y)
	var canister := Catalog.part(&"canister")
	drop(world, canister, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), FARM_CANISTER[0], FARM_CANISTER[1])
	dropped.append(canister)
	return dropped


## A hoverboard lying at your feet, nose ahead, a full battery in it, and a
## small camp beside you for the range warnings to watch: a charged shield
## generator, switched off, and a bare crate frame. Returns what it dropped.
static func board(world: World) -> Array[Node3D]:
	return [standing(world, &"board", [&"battery"], BOARD_AT), standing(world, &"shield", [&"battery"], BOARD_SHIELD),
		standing(world, &"crate_frame", [], BOARD_CRATE)]


## A radio with a full battery on the sand in front of you, switched off, and
## a charged shield generator beside it, switched off. Returns what it dropped.
static func radio(world: World) -> Array[Node3D]:
	return [standing(world, &"radio", [&"battery"], RADIO_AT), standing(world, &"shield", [&"battery"], RADIO_SHIELD)]


## The reference camp, parked round you and left running: the base shield
## in the middle with a big battery, and two planters with harvesters beside
## it, sown and watered, their trays resting, near enough to drop food onto
## you. Each is on a hose from a condenser beyond the shield, on a battery
## and a panel of its own: the second hose goes on the first's end, so the
## condenser waters both. Behind you, downwind, the floater: a crate resting
## on its tray, moored to a stake, two big batteries in it, the light panel
## on one top mount, cabled to the shield, and a panel on the other. The
## crate holds a turbine out in the wind beyond the bubble on a strong cable:
## a turbine only works planted, and a loose one slides off in a storm. You
## start fed and watered, stocked up to leave it running. Returns what it
## dropped.
static func afk(world: World) -> Array[Node3D]:
	world.player.vitals.fresh()
	var carried := world.player.suit.carried
	for thing in carried:
		thing.free()
	carried.clear()
	for i in AFK_CANISTERS:
		carried.append(Catalog.part(&"canister"))
	var shield := standing(world, &"shield", [&"big_battery"], AFK_SHIELD) as ShieldGenerator
	var dropped: Array[Node3D] = [shield]
	for where: Array in AFK_PLANTERS:
		var planter := standing(world, &"planter", [&"battery", &"hover_tray", &"harvester"] + FARM_CROPS, where) as Planter
		planter.tank_l = world.tuning.planter_tank_litres
		dropped.append(planter)
	var condenser := standing(world, &"condenser", [&"battery", &"solar_panel"], AFK_CONDENSER)
	var crate := standing(world, &"crate_frame", [&"big_battery", &"big_battery", &"hover_tray", &"hook", &"hook"],
		AFK_CRATE)
	# Its port toward the turbine.
	crate.global_basis = crate.global_basis.rotated(Vector3.UP, PI)
	var panel := Catalog.device(&"light_panel")
	crate.mount(panel, _free(crate, &"top"))
	fill(world, crate, [&"solar_panel"])
	var turbine := standing(world, &"turbine", [&"battery"], AFK_TURBINE)
	for device: Device in dropped + [crate]:
		if device.stats().lift_kg > 0.0:
			device.resting = true
			device.lift_share = 0.0
	var player := world.player
	var at := player.global_position + player.global_basis.x * AFK_STAKE[0] - player.global_basis.z * AFK_STAKE[1]
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.drive(at, world.height_under(at))
	dropped.append_array([crate, turbine, stake, condenser])
	dropped.append(Line.between(world, crate.free_tie(stake.global_position), stake.free_tie(crate.global_position)))
	# Their plugs and ends go with the devices they're in.
	dropped.append(wire(world, panel, shield))
	dropped.append(wire(world, crate, turbine, true))
	for planter in dropped.filter(func(b: Node3D) -> bool: return b is Planter):
		dropped.append(plumb(world, condenser, planter))
	shield.stand(true)
	return dropped


## A cable laid between two devices, plugged into the port of each; a
## strong one holds them together too.
static func wire(world: World, a: Device, b: Device, strong := false) -> Cable:
	var at := (a.global_position + b.global_position) * 0.5
	at.y = world.height_under(at)
	var cable := Catalog.cable(world, at, strong)
	for i in 2:
		var device: Device = [a, b][i]
		device.fit(cable.plugs[i], _free(device, &"port"))
	return cable


## Four chassis pieces lying bare on the sand ahead of you, a hover tray on
## its back in front of each, and either side a crate frame with two charged
## batteries, whose power floats the deck once it stands on it, and a
## condenser with a battery and an empty canister. Returns what it dropped.
static func chassis(world: World) -> Array[Node3D]:
	var dropped: Array[Node3D] = []
	for where: Array in CHASSIS_PIECES:
		dropped.append(standing(world, &"chassis", [], where))
	var yaw := Basis(Vector3.UP, world.player.global_rotation.y)
	for where: Array in CHASSIS_TRAYS:
		var tray := Catalog.part(&"hover_tray")
		drop(world, tray, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), where[0], where[1])
		dropped.append(tray)
	dropped.append(standing(world, &"crate_frame", [&"battery", &"battery"], CHASSIS_CRATE))
	var condenser := standing(world, &"condenser", [&"battery", &"canister"], CHASSIS_CONDENSER) as Condenser
	condenser.canister().drain(INF)
	dropped.append(condenser)
	return dropped


## A hose laid from one device to another, an end in the water socket of
## each: the first's own, or the free one on the end already there.
static func plumb(world: World, a: Device, b: Device) -> Hose:
	var at := (a.global_position + b.global_position) * 0.5
	at.y = world.height_under(at)
	var hose := Catalog.hose(world, at)
	for i in 2:
		var device: Device = [a, b][i]
		device.fit(hose.plugs[i], _free(device, &"water"))
	return hose


## A device's first free socket of a kind.
static func _free(device: Device, kind: StringName) -> Socket:
	for socket in device.sockets():
		if socket.kind == kind and socket.is_open():
			return socket
	return null


## Your own bare crate frame on the sand beside you, to fit what you find to.
static func yours(world: World) -> Array[Node3D]:
	return [standing(world, &"crate_frame", [], YOURS)]


## A device standing on the sand, squared to you, with these parts fitted.
static func standing(world: World, id: StringName, parts: Array, where: Array) -> Device:
	var device := Catalog.device(id)
	var size: Vector3 = Catalog.DEVICES[id].size
	drop(world, device, Transform3D(Basis(Vector3.UP, world.player.global_rotation.y),
		Vector3(0.0, size.y * 0.5, 0.0)), where[0], where[1])
	fill(world, device, parts)
	return device


## These parts fitted into a device's first free sockets of their kinds.
static func fill(world: World, device: Device, parts: Array) -> void:
	for part_id: StringName in parts:
		var part := Catalog.part(part_id)
		world.content.add_child(part)
		var socket := _free(device, part.kind)
		if socket != null:
			device.fit(part, socket)


## Stakes lying flat across your way and coils lying on their backs.
static func stakes_and_coils(world: World, stakes: Array, coils: Array) -> Array[Node3D]:
	var player := world.player
	var yaw := Basis(Vector3.UP, player.global_rotation.y)
	var dropped: Array[Node3D] = []
	for entry: Array in stakes:
		var stake := Catalog.stake()
		drop(world, stake, Transform3D(yaw * Basis(Vector3.BACK, PI / 2.0), Vector3(0.0, 0.035, 0.0)),
			entry[0], entry[1])
		dropped.append(stake)
	for entry: Array in coils:
		var line := Line.make(world, world.tuning.rope_coil_length)
		var at: Vector3 = player.global_position + player.global_basis.x * entry[0] - player.global_basis.z * entry[1]
		at.y = world.height_under(at) + 0.02
		line.coil.global_transform = Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), at)
		dropped.append(line.coil)
	return dropped


## Sets a body on the sand, right and ahead of you, in the pose given.
static func drop(world: World, body: Node3D, pose: Transform3D, right: float, ahead: float) -> void:
	var player := world.player
	var at := player.global_position + player.global_basis.x * right - player.global_basis.z * ahead
	at.y = world.height_under(at) + 0.02
	world.content.add_child(body)
	body.global_transform = pose.translated(at)
