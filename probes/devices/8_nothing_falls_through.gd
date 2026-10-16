extends HandsProbe
## Devices probe 8: nothing goes through the sand, the bug that killed Sand
## Game. A floating crate loses power and drops onto every kind of part; dead
## crates fall onto parts from 3 m; parts are thrown hard at the sand; a storm
## blows a floating crate off on a cable until the plug pops out; and Hunter's
## case, through the hands: a battery taken from a floating planter is
## dropped right under it as it falls. Nothing ever needs rescuing, nothing
## goes deeper than the rescue line even for a tick (a crate landing at 8 m/s
## can press a panel in for one step; the sand floor puts it back the next),
## and once things settle nothing rests in the sand past Jolt's slop.

## Jolt lets contacts sink 2 cm; a settled corner past this is in the sand.
const TOO_DEEP := 0.06
const PARTS: Array[StringName] = [&"battery", &"big_battery", &"solar_panel", &"plug", &"hook", &"carrot",
	&"lamp", &"hover_tray"]

var _deepest := 0.0
var _what := ""
var _resting := 0.0
var _resting_what := ""


func run() -> void:
	await load_hands()
	speed_up(4)
	await _crushed_by_a_floater_that_dies()
	await _dropped_on_from_height()
	await _thrown_at_the_sand()
	await _hands_drop_a_battery_under_a_falling_planter()
	await _cable_pulled_until_the_plug_pops()
	speed_up(1)
	print("deepest corner for a tick %.3f m (%s); settled %.3f m (%s)" % [_deepest, _what, _resting, _resting_what])
	check(_deepest < World.BELOW_SAND, "nothing even began to go through (deepest %.3f m, %s)" % [_deepest, _what])
	check(_resting < TOO_DEEP, "nothing settled in the sand (deepest %.3f m, %s)" % [_resting, _resting_what])


func _crushed_by_a_floater_that_dies() -> void:
	for i in PARTS.size():
		var under := spot(-8.0 + i * 2.0, -4.0)
		part(PARTS[i], Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), under + Vector3.UP * 0.05))
		var crate := device(&"crate_frame", under, 1.2)
		fit_part(crate, &"hover_tray")
		fit_part(crate, &"battery")
	await simulate(2.0, _watch)
	for node in world.content.get_children():
		if node is Device and node.battery() != null:
			node.take(node.battery().socket).queue_free()
	await simulate(4.0, _watch)
	_clear()


func _dropped_on_from_height() -> void:
	for i in PARTS.size():
		var under := spot(-8.0 + i * 2.0, 4.0)
		part(PARTS[i], Transform3D(Basis.IDENTITY, under + Vector3.UP * 0.1))
		var crate := device(&"crate_frame", under, 3.0, true)
		crate.take(crate.battery().socket).queue_free()
	await simulate(4.0, _watch)
	_clear()


func _thrown_at_the_sand() -> void:
	for i in 40:
		var at := spot(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)) + Vector3.UP * 1.5
		var thrown := part(PARTS.pick_random(), Transform3D(Basis.from_euler(Vector3(randf(), randf(), randf()) * TAU), at))
		thrown.linear_velocity = Vector3(randf_range(-1, 1), randf_range(-1.5, -0.5), randf_range(-1, 1)).normalized() * 15.0
	await simulate(3.0, _watch)
	_clear()


## Hunter's case: take a floating planter's battery, then let it go right under
## the planter as the planter, now dark, comes down on it.
func _hands_drop_a_battery_under_a_falling_planter() -> void:
	var planter := device(&"planter", spot(0.0, -3.0), 1.2)
	fit_part(planter, &"hover_tray")
	var cell: Battery = fit_part(planter, &"battery")
	await simulate(2.0, _watch)
	var at := seat(cell.socket)
	var target := at * Vector3(0.0, 0.0, 0.06)
	look(target + at.basis.z * 1.2, target)
	await simulate(0.1)
	check(hands.grab(), "the battery comes out through the hands")
	await simulate(1.0, _watch)
	# Let go of it under the planter's middle, just as it lands.
	hands.drop()
	cell.global_position = planter.global_position + Vector3.DOWN * 0.3
	await simulate(4.0, _watch)
	_clear()


func _cable_pulled_until_the_plug_pops() -> void:
	var tuning := Tuning.current()
	tuning.prevailing_speed = 25.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	var charger := device(&"charger", spot(0.0, 0.0), 0.2)
	charger.freeze = true
	var crate := device(&"crate_frame", spot(0.0, 2.0), 1.2)
	fit_part(crate, &"hover_tray")
	fit_part(crate, &"battery")
	var cable := Catalog.cable(world, charger.global_position + Vector3.UP)
	for pair: Array in [[charger, cable.plugs[0]], [crate, cable.plugs[1]]]:
		var end: Device = pair[0]
		end.fit(pair[1], end.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0])
	await simulate(8.0, _watch)
	check(cable.plugs.any(func(p: Part) -> bool: return p.socket == null), "the drifting crate pulled a plug out")
	await simulate(4.0, _watch)
	tuning.prevailing_speed = 0.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	_clear()


func _watch() -> void:
	var now := _depth()
	if now[0] > _deepest:
		_deepest = now[0]
		_what = now[1]


## How deep the deepest corner of anything loose is in the sand, and what it is.
func _depth() -> Array:
	var deepest := 0.0
	var what := ""
	for node in world.content.get_children():
		var body := node as RigidBody3D
		if body == null or body.freeze:
			continue
		for child in body.get_children():
			var shape := child as CollisionShape3D
			if shape == null or not shape.shape is BoxShape3D:
				continue
			var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
			var to_world := body.global_transform * shape.transform
			for i in 8:
				var corner := to_world * (half * Vector3(1 - (i & 1) * 2, 1 - (i & 2), 1 - (i & 4) / 2))
				var depth := world.height_under(corner) - corner.y
				if depth > deepest:
					deepest = depth
					what = body.get("label") if "label" in body else String(body.name)
	return [deepest, what]


## Each scenario ends settled: what rests in the sand now stays there.
func _clear() -> void:
	var now := _depth()
	if now[0] > _resting:
		_resting = now[0]
		_resting_what = now[1]
	for node in world.content.get_children():
		if node is RigidBody3D or node is Cable:
			node.free()
