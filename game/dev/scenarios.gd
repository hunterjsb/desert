class_name Scenarios
extends RefCounted
## Dev starting conditions. Each one searches this run's own weather for a
## moment and a place that match, so a playtest starts where it needs to
## without faking anything. A probe checks each delivers what it says.

## kind: "spawn", "clear", "front" (a storm `distance` m upwind, coming at
## you), "deep" (inside, far from any edge), "back" (inside, clear air
## `distance` m upwind), "sky" (clear, for the light) or "kit" (clear, with the
## test kit dropped in front of you). day is the window of time of day to look
## in: 0 is midnight, 0.5 noon.
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
	{"key": "kit", "label": "test kit: devices and parts, clear day", "kind": "kit", "day": [0.42, 0.55]},
]

## The test kit, as [catalog id, metres to your right, metres ahead]: an empty
## crate frame and planter, and parts for every kind of socket on them.
const KIT_DEVICES := [[&"crate_frame", -1.0, 3.0], [&"planter", 1.2, 3.2]]
const KIT_PARTS := [
	[&"battery", -1.6, 1.6], [&"big_battery", -1.2, 1.7], [&"hook", -0.8, 1.6], [&"hook", -0.55, 1.7],
	[&"lamp", -0.25, 1.6], [&"seedling", 0.1, 1.7], [&"seedling", 0.35, 1.6], [&"seedling", 0.6, 1.7],
	[&"sapling", 0.95, 1.6], [&"battery", 1.3, 1.7], [&"hover_tray", -2.6, 2.4],
	[&"hover_tray", 2.8, 2.6], [&"solar_panel", -2.6, 3.6],
]

## How far upwind a search looks for edges, and its step.
const REACH := 6000.0
const STEP := 25.0
## Search the first three days, finely enough not to step over dusk.
const HORIZON := 3.0 * 24.0 * 3600.0
const TIME_STEP := 10.0
## "deep" means full storm for at least this far either way along the wind.
const DEEP := 300.0


static func by_key(key: String) -> Dictionary:
	for scenario in LIST:
		if scenario.key == key:
			return scenario
	return {}


## Where to put the player: {x, z, yaw, time}, or {} if this run's weather has
## no such moment in three days.
static func find(world: World, scenario: Dictionary) -> Dictionary:
	var spawn := Vector2(world.tuning.chunk_size, world.tuning.chunk_size) * 0.5
	if scenario.kind == "spawn":
		return {"x": spawn.x, "z": spawn.y, "yaw": 0.0, "time": 0.0}
	var field := world.weather.field
	var day := world.weather.day
	var t := 0.0
	while t < HORIZON:
		var hour := day.time_of_day(t)
		if hour >= scenario.day[0] and hour <= scenario.day[1]:
			var upwind := -field.prevailing_at(t).normalized()
			var place := _place(field, scenario, spawn, upwind, t)
			if not place.is_empty():
				place.time = t
				place.yaw = atan2(-upwind.x, -upwind.y) if scenario.kind != "sky" else _yaw_to_sun(scenario)
				return place
		t += TIME_STEP
	return {}


static func _place(field: WeatherField, scenario: Dictionary, from: Vector2, upwind: Vector2,
		t: float) -> Dictionary:
	match scenario.kind:
		"clear", "sky", "kit":
			if field.raw_storm_at(from.x, from.y, t) <= 0.0 \
					and (scenario.kind == "sky" or field.next_change(from.x, from.y, t, 600.0, 10.0) == INF):
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


## Dusk faces the sunset in the west; night faces east, toward the dawn.
static func _yaw_to_sun(scenario: Dictionary) -> float:
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
		_drop(world, device, Transform3D(yaw, Vector3(0.0, size.y * 0.5, 0.0)), entry[1], entry[2])
		dropped.append(device)
	for entry: Array in KIT_PARTS:
		var part := Catalog.part(entry[0])
		_drop(world, part, Transform3D(yaw * Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO), entry[1], entry[2])
		dropped.append(part)
	return dropped


static func _drop(world: World, body: Node3D, pose: Transform3D, right: float, ahead: float) -> void:
	var player := world.player
	var at := player.global_position + player.global_basis.x * right - player.global_basis.z * ahead
	at.y = world.height_under(at) + 0.02
	world.content.add_child(body)
	body.global_transform = pose.translated(at)
