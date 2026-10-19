extends WorldProbe
## Profile & saves probe 30: the far places' deeds, gone to. From the
## Homesteader's start, an eclipse watched whole out in the open counts
## nothing in a dev run; in a player's own, the next is Totality. A far
## stand-in's glint seen from past the deed's distance, its site reached
## after, is Glint. Under Tu is Under Tu; at a live vent's mouth, Live Vent;
## 40 km off it, its burst's boom is Thunder; past the Rim, The Dark Side.
## Time limit: 600 s


func run() -> void:
	var tuning := Tuning.current()
	var p := Starts.find(TerrainShape.new(1234, tuning), &"wayshrine", tuning)
	tuning.spawn_latitude_degrees = rad_to_deg(Sphere.latitude(p))
	tuning.spawn_longitude_degrees = rad_to_deg(Sphere.longitude(p))
	# Clear skies: a storm would hide what's far off.
	tuning.storm_threshold = 2.0
	await load_world(1234, false, true)
	var profile := get_node(^"/root/Profile")
	await _eclipse()
	check(not profile.did("totality"), "a dev run's eclipse watched whole counts nothing")
	world.counts_deeds = true
	await _eclipse()
	check(profile.did("totality"), "an eclipse watched whole in the open: Totality")

	var glinted := await _glint()
	check(glinted != null, "a far stand-in's glint seen from %.0f m or further" % tuning.deed_glint_m)
	if glinted != null:
		check(not profile.did("glint"), "seen, not yet reached")
		teleport(glinted.x, glinted.z)
		await physics_frames(3)
		check(profile.did("glint"), "its site reached: Glint")

	var history := world.shape.history
	await _go(history.sub_tu)
	check(profile.did("under_tu"), "Tu overhead: Under Tu")
	var vent: Dictionary = history.geology.live()[0]
	await _go(vent.p)
	var mouths := structures_near(&"vent_mouth", 3000.0)
	check(not mouths.is_empty(), "the live vent's mouth laid")
	if not mouths.is_empty():
		teleport(mouths[0].x, mouths[0].z)
		await physics_frames(3)
		check(profile.did("live_vent"), "at its mouth: Live Vent")
	var away := Sphere.bearing(vent.p, history.sub_tu) + PI
	await _go(Sphere.toward(vent.p, away, 40000.0 / history.radius))
	await _boom()
	check(profile.did("thunder"), "a burst's boom from 40 km: Thunder")
	await _go(Sphere.point(0.0, deg_to_rad(tuning.tu_longitude_degrees + 100.0)))
	check(profile.did("dark_side"), "past the Rim, where Tu never rises: The Dark Side")


## The next eclipse watched from half a minute before it to half a minute after.
func _eclipse() -> void:
	var day := world.weather.day
	world.time = day.next_eclipse(world.time + 60.0) - 30.0
	world.time_warp = 3.0
	await physics_frames(roundi(60.0 / 3.0 * Engine.physics_ticks_per_second))
	world.time_warp = 1.0


## Looks over the far stand-ins drawn from the start for one whose glint
## would shine, some time in the next day, for your eye at a spot on the
## sand past the deed's distance, over the dunes and under a clear sky;
## stands you there then until the skyline has marked it. Its site, or null.
func _glint() -> Structure:
	var skyline := world.terrain.skyline
	for i in 600:
		if skyline.is_idle():
			break
		await get_tree().process_frame
	var found := _shining(skyline)
	if found.is_empty():
		return null
	teleport(found[2].x, found[2].y)
	await settle()
	for i in 600:
		if skyline.is_idle():
			break
		await get_tree().process_frame
	world.time = found[1]
	for i in 300:
		await get_tree().process_frame
		if skyline.glinted.has(found[0].id):
			return found[0]
	return null


## A far stand-in, a moment and a spot on the sand from which one of its
## glints shines for your eye then: [site, world time, world x and z], or [].
func _shining(skyline: Skyline) -> Array:
	var day := world.weather.day
	var tuning := world.tuning
	var shape := world.shape
	var x := world.player_world_x()
	var z := world.player_world_z()
	for site in skyline.seen():
		if world.terrain.is_loaded_at(site.x, site.z):
			continue
		for glint in skyline.glints_of(site):
			var at: Vector3 = glint[0]
			var n: Vector3 = glint[1]
			var t := world.time
			while t < world.time + tuning.day_minutes * 60.0:
				t += 3.0
				var sun := day.sun_direction(t, world.moon.latitude, world.moon.longitude)
				if sun.y < 0.15 or day.sun_shown(t) < 0.6 or n.dot(sun) <= 0.0:
					continue
				var mirror := 2.0 * n.dot(sun) * n - sun
				var way := Vector2(mirror.x, mirror.z)
				if absf(mirror.y) > 0.08:
					continue
				for far in range(roundi(tuning.deed_glint_m) + 50, 2900, 100):
					var spot := Vector2(at.x, at.z) + way.normalized() * far
					# The sun from that spot on the moon, a little east or north of here.
					var seen := day.sun_direction(t, world.moon.latitude - (spot.y - z) / world.moon.radius,
						world.moon.longitude + (spot.x - x) / (world.moon.radius * cos(world.moon.latitude)))
					var eye := Vector3(spot.x, shape.height_at(spot.x, spot.y) + Skyline.EYE, spot.y)
					var center := Vector2i(floori(spot.x / tuning.chunk_size), floori(spot.y / tuning.chunk_size))
					if Skyline.shine(glint, eye, seen) >= Starts.GLINT_SEEN + 0.15 \
							and world.weather.field.raw_storm_at(spot.x, spot.y, t) < -0.05 \
							and Skyline.clearance(shape, tuning, eye, at, center, site.reach) > 0.5:
						return [site, t, spot]
	return []


## Travels to a point on the moon and waits for the ground there.
func _go(to: Vector3) -> void:
	world.travel(rad_to_deg(Sphere.latitude(to)), rad_to_deg(Sphere.longitude(to)), 0.0)
	await settle()
	await physics_frames(3)


## Waits for the next burst from a live vent this far off to arrive as a boom.
func _boom() -> void:
	var geology := world.shape.history.geology
	var here := Sphere.point(world.moon.latitude, world.moon.longitude)
	var rumbles := world.weather.rumbles
	var next := Vector2(INF, 0.0)
	for vent in geology.live():
		var metres := Sphere.angle(here, vent.p) * geology.radius
		if metres < world.tuning.deed_thunder_m or metres > Rumbles.HEARD:
			continue
		var t := world.time
		while t < world.time + 7200.0:
			var burst := geology.last_burst(vent, t)
			if burst.y > 0.0 and burst.x > world.time:
				if burst.x < next.x:
					next = Vector2(burst.x, metres)
				break
			t += 10.0
	check(next.x < INF, "a live vent bursting 35 to 45 km off")
	if next.x == INF:
		return
	# Sound's speed as the boom comes, by the air's warmth where you stand then.
	world.time = next.x
	await get_tree().process_frame
	var arrives := next.x + next.y / rumbles.speed()
	world.time = arrives - 3.0
	var profile := get_node(^"/root/Profile")
	while world.time < arrives + 6.0 and not profile.did("thunder"):
		await get_tree().process_frame
	print("booms heard: %s" % [rumbles.heard.map(func(each: Dictionary) -> String:
		return "%s %.1f km" % [each.source, each.distance / 1000.0])])
