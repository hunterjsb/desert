extends ShieldProbe
## Power probe 18: what wear costs is real. Beside a sound turbine in the same
## wind, one the storms half wore makes less, and a worn shield draws more to
## hold the same weather back; their paint says so.

const WIND := 9.0


func run() -> void:
	await load_storm(0.0, WIND)
	var sound := turbine_at(ahead(6.0))
	var worn := turbine_at(ahead(6.0) + Vector3(0.0, 0.0, 3.0))
	worn.wear(2.0, Vector3.RIGHT)
	var shields := [shield_at(ahead(-6.0)), shield_at(ahead(-6.0) + Vector3(0.0, 0.0, 6.0))]
	(shields[1] as Device).wear(0.5, Vector3.RIGHT)
	await physics_frames(10)
	var made := [sound.production_w(), worn.production_w()]
	var drawn := [(shields[0] as Device).demand_w(), (shields[1] as Device).demand_w()]
	var age := func(d: Device) -> float: return d.frame_view.get_instance_shader_parameter(&"age")
	print("turbines %.1f%% and %.1f%% sound make %s W; shields %.1f%% and %.1f%% draw %s W"
		% [sound.durability * 100.0, worn.durability * 100.0, made, shields[0].durability * 100.0,
			shields[1].durability * 100.0, drawn])
	check(made[0] > 0.0 and made[1] < made[0] * 0.9 and made[1] > made[0] * 0.5, "the worn turbine makes less")
	check(drawn[1] > drawn[0] * 1.1, "the worn shield draws more")
	check(age.call(worn) > age.call(sound) and age.call(shields[1]) > age.call(shields[0]), "and both look it")
