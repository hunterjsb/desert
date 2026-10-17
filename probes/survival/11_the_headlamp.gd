extends ShieldProbe
## Survival probe 11: the headlamp. Under a clear sky at noon it's off. At
## dusk, the light wavering round its threshold as a passing veil of dust
## would, it comes on once and stays on. Deep in a storm at night it's on, and
## lights the ground 10 m ahead at least as well as a device's lamp lights the
## sand 5 m off, which is where the tracks look-test found steps still read.

## How far either way, s of the day, dusk wavers as it's crossed, and how fast.
const WAVER := 2.0
const WAVER_HZ := 0.5
## The crossing runs from this long before sunset to this long after, s,
## over this long, s.
const SPAN := 40.0
const CROSSING := 30.0


func run() -> void:
	Tuning.current().headlamp = true
	await load_storm(0.0)
	var lamp := _lamp()
	if lamp == null:
		return
	var day := world.weather.day
	var latitude := world.moon.latitude
	var sunset := 0.0
	while not (day.sun_direction(sunset, latitude, world.moon.longitude).y > 0.0 and day.sun_direction(sunset + 1.0, latitude, world.moon.longitude).y <= 0.0):
		sunset += 1.0
	var noon := sunset - world.tuning.day_minutes * 15.0
	world.time = noon
	await physics_frames(120)
	print("clear noon: light %.2f, the lamp %s" % [world.weather.seen_light, "on" if lamp.on else "off"])
	check(not lamp.on and not lamp.visible, "under a clear sky at noon it's off")

	var switches := 0
	var was := lamp.on
	var ticks := roundi(CROSSING * 60.0)
	for i in ticks:
		var s := float(i) / 60.0
		world.time = sunset - SPAN + 2.0 * SPAN * float(i) / ticks + WAVER * sin(TAU * WAVER_HZ * s)
		await get_tree().physics_frame
		switches += int(lamp.on != was)
		was = lamp.on
	await physics_frames(120)
	print("crossing dusk over %d s, wavering %.0f s either way: %d switch%s, the light %.2f after"
		% [CROSSING, WAVER, switches, "" if switches == 1 else "es", world.weather.seen_light])
	check(switches == 1 and lamp.on and is_equal_approx(lamp.light_energy, world.tuning.headlamp_energy),
		"at dusk it comes on once and stays on")

	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	await load_storm(1.0)
	lamp = _lamp()
	world.time = sunset + world.tuning.day_minutes * 15.0
	world.player.camera.rotation.x = 0.0
	await physics_frames(180)
	var eye := world.player.camera.global_position
	var forward := -world.player.global_basis.z
	var ground := eye + forward * 10.0
	ground.y = world.height_under(ground)
	var lit := light_at(lamp, lamp.global_position, -lamp.global_basis.z, ground)
	# A device's lamp, as the tracks look-test held one: at your side, 1 m up.
	var device_lamp := Catalog.part(&"lamp").find_children("*", "OmniLight3D", true, false)[0] as OmniLight3D
	var side := Vector3(eye.x, world.height_under(eye) + 1.05, eye.z)
	var off := side + forward * 5.0
	off.y = world.height_under(off)
	var beside := light_at(device_lamp, side, Vector3.ZERO, off)
	device_lamp.get_parent().free()
	print("a storm at night: light %.3f, the lamp %s; the ground 10 m ahead gets %.4f of it, a device's lamp's sand 5 m off %.4f"
		% [world.weather.seen_light, "on" if lamp.on else "off", lit, beside])
	check(lamp.on and lamp.visible, "deep in a storm at night it's on")
	check(lit >= beside, "it lights the ground 10 m ahead at least as a device's lamp lights the sand 5 m off")


func _lamp() -> Headlamp:
	var found := world.player.find_children("*", "Headlamp", true, false)
	check(found.size() == 1, "the suit has a headlamp")
	return found[0] if found.size() == 1 else null


## The light a lamp at `from` throws on flat sand at `at`, by the renderer's
## own falloff with distance and, for a spot, toward its rim.
static func light_at(lamp: Light3D, from: Vector3, aim: Vector3, at: Vector3) -> float:
	var to := from - at
	var d := to.length()
	var reach: float = lamp.get(&"spot_range") if lamp is SpotLight3D else lamp.get(&"omni_range")
	var decay: float = lamp.get(&"spot_attenuation") if lamp is SpotLight3D else lamp.get(&"omni_attenuation")
	var falloff := pow(maxf(1.0 - pow(d / reach, 4.0), 0.0), 2.0) * pow(maxf(d, 1e-4), -decay)
	if lamp is SpotLight3D:
		var cut := cos(deg_to_rad(lamp.get(&"spot_angle")))
		var rim := maxf(1e-4, (1.0 - maxf((-to / d).dot(aim), cut)) / (1.0 - cut))
		falloff *= 1.0 - pow(rim, lamp.get(&"spot_angle_attenuation"))
	return lamp.light_energy * falloff * maxf(Vector3.UP.dot(to / d), 0.0)
