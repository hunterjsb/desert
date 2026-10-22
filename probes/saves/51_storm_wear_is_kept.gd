extends SavesProbe
## A storm's wear comes back with what it marked: how sound the turbine is,
## and which way its paint was blasted.


func run() -> void:
	saves = get_node("/root/Saves")
	await load_storm(0.0)
	var turbine := turbine_at(ahead(6.0))
	turbine.rotate_y(0.7)
	turbine.wear(1.2, Vector3(1.0, 0.0, 0.4))
	var kept := [turbine.durability, turbine.weathered, turbine.frame_view.get_instance_shader_parameter(&"blasted")]
	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var found := world.devices().filter(func(d: Device) -> bool: return d.get_meta(&"catalog", &"") == &"turbine")
	check(found.size() == 1, "the turbine is back")
	if found.size() != 1:
		return
	var back: Device = found[0]
	var shown: Vector4 = back.frame_view.get_instance_shader_parameter(&"blasted")
	print("kept %s; back %s %s %s" % [kept, back.durability, back.weathered, shown])
	check(is_equal_approx(back.durability, kept[0]) and back.weathered.is_equal_approx(kept[1]),
		"as worn, the same way")
	check(shown.is_equal_approx(kept[2]), "and its paint shows it as it did")
