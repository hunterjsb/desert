extends CampProbe
## Profile & saves probe 31: the nomad's deeds. A run whose clock has run a
## little short of ten days is no Ten Days; ten whole, it is. Asleep under the
## reference camp's shield through the storm on it, waking once it has passed
## with all of the deck still on it: Slept It Off. A floating deck the wind
## takes off downwind has moved its camp, Moved House, the goal a probe's few
## metres.


func run() -> void:
	await load_camp()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var day := world.tuning.day_minutes * 60.0
	world.began = world.time - 9.9 * day
	await live(1.0, 1.0)
	check(not profile.did("ten_days"), "nine days and most of a tenth is no Ten Days")
	world.began = world.time - 10.0 * day
	await live(1.0, 1.0)
	check(profile.did("ten_days"), "ten whole days: Ten Days")

	var storm := world.weather.field.raw_storm_at(world.player_world_x(), world.player_world_z(), world.time) > 0.0
	check(storm and shield.running() and world.sleep.storm_due(), "a storm on the camp, its shield up over you")
	var night := world.sleep.overnight(world.sleep.wake_for(Sleep.STORM))
	print("slept: %s" % world.sleep.summary(night))
	check(night.woke == &"" and profile.did("slept_it_off"), "woken after the storm, the camp whole: Slept It Off")

	world.tuning.deed_moved_m = 20.0
	var drifter := Catalog.device(&"chassis") as Chassis
	world.content.add_child(drifter)
	fit_part(drifter, &"hover_tray")
	fit_part(drifter, &"battery")
	var down := world.weather.field.prevailing_at(world.time).normalized()
	var at := world.player.global_position + Vector3(down.x, 0.0, down.y) * 15.0
	drifter.global_position = Vector3(at.x, world.height_under(at) + drifter.rest_height(), at.z)
	await live(20.0, 1.0)
	check(profile.did("moved_house"), "a floating deck the wind took off: Moved House")
