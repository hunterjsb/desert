extends ShieldProbe
## Scratch: a line's load as the night reckons it from a breeze against what it bears live in a storm wind.
## Time limit: 300 s

func run() -> void:
	for floats in [false, true]:
		for wind in [20.0, 30.0, 40.0]:
			if world != null:
				remove_child(world)
				world.queue_free()
				await get_tree().process_frame
			weather_everywhere(0.0, 6.0)
			await load_world(1234, false)
			var here := world.player.global_position
			var down := Vector3(world.weather.field.prevailing_at(0.0).normalized().x, 0, world.weather.field.prevailing_at(0.0).normalized().y)
			var at := here + down * 10.0
			var crate := Catalog.device(&"crate_frame")
			world.content.add_child(crate)
			crate.global_position = Vector3(at.x, world.height_under(at) + (world.tuning.hover_height if floats else 0.27), at.z)
			fit_part(crate, &"hook")
			if floats:
				fit_part(crate, &"hover_tray")
				fit_part(crate, &"big_battery")
				crate.global_position.y += crate.rest_height() - world.tuning.hover_height
			var spot := at - down * 3.0
			var stake := Catalog.stake()
			world.content.add_child(stake)
			stake.drive(spot, world.height_under(spot))
			var rope := Line.between(world, crate.free_tie(spot), stake.free_tie(at), 0.3).rope
			for i in 300:
				await get_tree().physics_frame
			var was := world.ropes.bearing(rope)
			var calm := rope.sustained
			weather_everywhere(0.0, wind)
			var predicted := world.ropes.load_at(rope, world.time, 0.0, was)
			var live_mean := 0.0
			var n := 0
			for i in 900:
				await get_tree().physics_frame
				if i > 450:
					live_mean += rope.sustained
					n += 1
			print("floats %s, %.0f N at 6 m/s, then at %.0f m/s: live %.0f N, reckoned %.0f N (%+.1f%%)" % [floats, calm, wind,
				live_mean / n, predicted, 100.0 * (predicted - live_mean / n) / (live_mean / n)])
