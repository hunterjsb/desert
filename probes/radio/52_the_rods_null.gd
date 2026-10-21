extends ShieldProbe
## Radio probe 52: the rod's null. By day a god heard whole with the set
## broadside to it falls silent with the set turned end-on to it, its ferrite
## rod pointing along the god's line; by night, a god far past the skip heard
## by sky wave never falls quite silent so (the night effect).


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	await physics_frames(2)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var day := _god(radio, x, z, false)
	check(day != &"", "by day a god comes in whole broadside")
	if day != &"":
		var side := _heard(radio, day, x, z, false)
		var end := _heard(radio, day, x, z, true)
		print("%s by day: %.2f broadside, %.2f end-on" % [Gods.title(day), side, end])
		check(side >= Radio.WHOLE and end <= 0.0, "end-on to the set it falls silent")

	while world.weather.day.is_day(world.time, world.moon.longitude):
		world.time += 30.0
	var night := _god(radio, x, z, true)
	check(night != &"", "by night a far god comes in by sky wave")
	if night != &"":
		var end := _heard(radio, night, x, z, true)
		print("%s by night, %.0f km off: %.2f end-on" % [Gods.title(night), radio.god_way(night).metres / 1000.0, end])
		check(end > 0.0, "by sky wave its null is shallow, and it's still heard")


## A god that comes in whole broadside to the set now, by sky wave if `sky`;
## &"" with none.
func _god(radio: Radio, x: float, z: float, sky: bool) -> StringName:
	for id in Gods.ids():
		var way := radio.god_way(id)
		var night := not world.weather.day.is_day(world.time, world.moon.longitude)
		if sky != Dial.by_sky(Radio.gods_of(world).carrier(id, world.time), way.metres, night, Tuning.current()):
			continue
		if _heard(radio, id, x, z, false) >= Radio.WHOLE:
			return id
	return &""


## How clean a god comes in with the set broadside to it, or end-on.
func _heard(radio: Radio, id: StringName, x: float, z: float, end_on: bool) -> float:
	broadside(radio, id)
	if end_on:
		radio.global_basis = radio.global_basis.rotated(Vector3.UP, PI / 2.0)
	radio.frequency = Radio.gods_of(world).carrier(id, world.time)
	return radio.receive(id, x, z, world.time).clean
