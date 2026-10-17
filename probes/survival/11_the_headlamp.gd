extends ShieldProbe
## Survival probe 11: the headlamp. A run begins with it off; the headlamp
## action switches it on, fading in to its full beam, and off again. On, deep
## in a storm at night, it lights the ground 10 m ahead at least as well as a
## device's lamp lights the sand 5 m off, which is where the tracks look-test
## found steps still read.


func run() -> void:
	await load_storm(1.0)
	var lamp := _lamp()
	if lamp == null:
		return
	await physics_frames(30)
	check(not lamp.on and not lamp.visible, "a run begins with it off")
	_switch()
	await physics_frames(roundi(world.tuning.headlamp_fade_seconds * 60.0) + 10)
	check(lamp.on and is_equal_approx(lamp.light_energy, world.tuning.headlamp_energy), "the headlamp action switches it on, to its full beam")
	_switch()
	await physics_frames(roundi(world.tuning.headlamp_fade_seconds * 60.0) + 10)
	check(not lamp.on and not lamp.visible, "and off again")
	_switch()

	var day := world.weather.day
	var latitude := world.moon.latitude
	var midnight := 0.0
	while day.sun_direction(midnight, latitude).y > -0.9 * cos(latitude):
		midnight += 1.0
	world.time = midnight
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
	check(lamp.on and lamp.visible, "switched on, deep in a storm at night")
	check(lit >= beside, "it lights the ground 10 m ahead at least as a device's lamp lights the sand 5 m off")


## The headlamp action, pressed once.
func _switch() -> void:
	var press := InputEventAction.new()
	press.action = &"headlamp"
	press.pressed = true
	Input.parse_input_event(press)
	var release := press.duplicate() as InputEventAction
	release.pressed = false
	Input.parse_input_event(release)


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
