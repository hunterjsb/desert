extends ShieldProbe
## Radio probe 37: the jammer and the burn. While babel, the wartime jammer,
## is overhead, it sprays static over the dial round its carrier: tuned near
## it the static rises and what's there is buried, coming through less clean;
## far along the dial there's none of it, and babel doesn't bury itself. The
## cinder fires its burn the moment its decay bottoms out, flaring in the
## sky for a few seconds, and not otherwise. Under clear skies everywhere.


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var sky := Radio.constellation_of(world)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var up := _first(world.time, func(u: float) -> bool:
		return sky.orbits[&"babel"].seen_from(p, u).elevation > deg_to_rad(40.0))
	world.time = up
	var babel := sky.carrier(&"babel", up)
	var near := sky.jamming(babel + 15.0, p, up)
	var far := sky.jamming(babel - 300.0, p, up)
	print("babel %.0f° up on %d kHz: jamming %.2f 15 kHz off it, %.3f 300 kHz off" % [
		rad_to_deg(sky.orbits[&"babel"].seen_from(p, up).elevation), roundi(babel), near, far])
	check(near > 0.3 and far < 0.001, "it sprays static near its carrier, none far off")
	check(sky.jamming(babel, p, up, &"babel") == 0.0, "and doesn't bury itself")

	radio.on = true
	radio.frequency = babel + 15.0
	await physics_frames(5)
	var static_near := radio.noise
	radio.frequency = babel - 300.0
	await physics_frames(5)
	print("the radio's static: %.2f near babel, %.2f far from it" % [static_near, radio.noise])
	check(static_near > 0.3 and radio.noise < 0.05, "the radio's static rises near it")

	# What's near it is buried: the same satellite, heard with babel up and set.
	var gone := _first(up, func(u: float) -> bool: return sky.orbits[&"babel"].seen_from(p, u).elevation < 0.0)
	radio.frequency = babel + 15.0
	var buried: float = radio.receive_from(sky.orbits[&"cinder"], babel + 15.0, &"cinder", x, z, up).clean
	var heard := (1.0 - sky.jamming(babel + 15.0, p, up))
	print("a signal 15 kHz off babel comes through %.2f of what it would, with babel set %.2f" % [heard,
		1.0 - sky.jamming(babel + 15.0, p, gone)])
	check(heard < 0.7 and sky.jamming(babel + 15.0, p, gone) == 0.0, "near it, a signal is buried; with it set, not")
	check(buried >= 0.0, "reception still works out under it")

	# The cinder's burn.
	var cinder: Satellite = sky.orbits[&"cinder"]
	var bottom := cinder.decay_seconds * 3.0
	check(sky.burning(&"cinder", bottom + 1.0) and not sky.burning(&"cinder", bottom + 10.0)
		and not sky.burning(&"cinder", bottom - 5.0), "the cinder burns just as its decay bottoms out")
	check(cinder.height(bottom + 30.0) > cinder.height(bottom - 30.0) or cinder.sinking(bottom + 1.0)
		> cinder.sinking(bottom - 1.0), "and is thrown back up")
	check(not sky.burning(&"ghost", bottom + 1.0), "only a decaying one burns")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 5.0
	check(false, "found a moment")
	return from
