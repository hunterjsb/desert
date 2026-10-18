extends WeatherProbe
## Sightlines probe 3: a storm between you and what's far off hides it, as
## it hides the ground behind. At the Surveyor's start, clear where you
## stand, at a moment a storm stands between you and a far stand-in, and at
## one it stands between you and a chunk of far saltbush, each is drawn
## hidden (its stand-in, glints and bushes take their veil from Skyline);
## at a moment the air between is clear, both show.
## Time limit: 600 s

## Far enough off that a storm fits between, m.
const BEYOND := 2000.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	tuning.run_seed = 1234
	world = WORLD_SCENE.instantiate()
	world.kit = Kit.origins().filter(func(each: Kit) -> bool: return each.start == &"artery")[0]
	add_child(world)
	field = world.weather.field
	await settle()
	world.time_warp = 0.0
	var skyline := world.terrain.skyline
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var mast: Structure = null
	for site in skyline.seen():
		if site.distance_to(here.x, here.y) > BEYOND and not skyline.stand_in(site).is_empty() \
				and (mast == null or site.top_in(site.state()) > mast.top_in(mast.state())):
			mast = site
	var bushes := Vector2i.MAX
	var shown := skyline.far_bushes()
	for coord: Vector2i in shown:
		var at := (Vector2(coord) + Vector2.ONE * 0.5) * tuning.chunk_size
		if at.distance_to(here) > BEYOND and (bushes == Vector2i.MAX or shown[coord][0] > shown[bushes][0]):
			bushes = coord
	check(mast != null and bushes != Vector2i.MAX, "a far stand-in and far bushes past %.0f m" % BEYOND)
	if mast == null or bushes == Vector2i.MAX:
		return
	var at_mast := Vector2(mast.x, mast.z)
	var at_bushes := (Vector2(bushes) + Vector2.ONE * 0.5) * tuning.chunk_size
	print("a %s %.0f m off, and %d far bushes %.0f m off" % [mast.kind, at_mast.distance_to(here), shown[bushes][0],
		at_bushes.distance_to(here)])
	var between := func(to: Vector2, t: float) -> bool:
		var mid := here.lerp(to, 0.5)
		return field.raw_storm_at(here.x, here.y, t) < -0.03 and field.raw_storm_at(mid.x, mid.y, t) > 0.1
	var clear := func(t: float) -> bool:
		for to: Vector2 in [at_mast, at_bushes]:
			for k in 9:
				var p := here.lerp(to, k / 8.0)
				if field.raw_storm_at(p.x, p.y, t) > -0.06:
					return false
		return true
	var moments := [find_time(func(t: float) -> bool: return between.call(at_mast, t)),
		find_time(func(t: float) -> bool: return between.call(at_bushes, t)), find_time(clear)]
	for i in moments.size():
		world.time = moments[i]
		world.weather.forecast_now()
		await physics_frames(3)
		for k in 120:
			await get_tree().process_frame
		var mast_shows := skyline.veil_of(mast)
		var bushes_show: float = skyline.far_bushes().get(bushes, [0, -1.0])[1]
		print("at %.1f min: the stand-in shows %.2f, the bushes %.2f; the far view %s" % [moments[i] / 60.0,
			mast_shows, bushes_show, "shown" if world.terrain.is_far_shown() else "hidden"])
		if i < 2:
			check(world.terrain.is_far_shown(), "clear where you stand, the far view is drawn")
		if i == 0:
			check(mast_shows < 0.05, "a storm between you and a far stand-in hides it (%.2f)" % mast_shows)
		elif i == 1:
			check(bushes_show >= 0.0 and bushes_show < 0.05, "a storm between you and far bushes hides them (%.2f)" % bushes_show)
		else:
			check(mast_shows > 0.9 and bushes_show > 0.9, "with the air between clear, both show (%.2f, %.2f)" % [
				mast_shows, bushes_show])
