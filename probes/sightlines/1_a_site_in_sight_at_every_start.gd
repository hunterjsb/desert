extends Probe
## Sightlines probe 1: every origin begins with something to walk to in
## sight. On three worlds each origin's run is built at its start, and from
## your eye where it begins, something the world draws, a structure on the
## loaded ground or a stand-in past it, shows over the ground as drawn
## between, looked over a metre at a time, by the tuning's pixels at 1080
## rows. The Surveyor's stands past the deep desert's reach, on its horizon,
## and something drawn there shines for your eye on the run's first day.
## Time limit: 900 s

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SEEDS := [1234, 1, 42]

var world: World


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	for s: int in SEEDS:
		for kit in Kit.origins():
			tuning.run_seed = s
			world = WORLD_SCENE.instantiate()
			world.kit = kit
			add_child(world)
			for i in 3000:
				await get_tree().process_frame
				if world.terrain.is_idle() and world.terrain.is_settled_around(world.spawn.x, world.spawn.y):
					break
			var seen := _in_sight(tuning, tuning.start_deep_m if kit.start == &"artery" else 0.0)
			print("seed %d, the %s: %s" % [s, kit.label, seen if seen != "" else "nothing in sight"])
			check(seen != "", "seed %d: the %s begins with something in sight" % [s, kit.label])
			if kit.start == &"artery":
				var when := _shines(tuning)
				print("seed %d, the %s: a glint %s" % [s, kit.label, "at %.1f min" % (when / 60.0) if when >= 0.0 else "never"])
				check(when >= 0.0, "seed %d: the %s's horizon catches the sun for you on the first day" % [s, kit.label])
			world.queue_free()
			await get_tree().process_frame
			await get_tree().process_frame


## The first thing drawn past `beyond` m that shows from your eye, as said; "" if none.
func _in_sight(tuning: Tuning, beyond: float) -> String:
	var camera := world.player.camera.global_position
	var eye := Vector3(world.world_x(camera.x), camera.y, world.world_z(camera.z))
	var least := tuning.start_sight_px * Skyline.PIXEL
	for chunk: TerrainChunk in world.terrain.chunks():
		for site in chunk.structures():
			var view := chunk.view_of(site)
			if view != null:
				var top := (view.global_transform * view.mesh.get_aabb()).end.y
				var why := _shows(tuning, eye, Vector3(site.x, top, site.z), site, beyond, least, "%s, built")
				if why != "":
					return why
	for site in world.terrain.skyline.seen():
		var far := world.terrain.skyline.stand_in(site)
		if not far.is_empty():
			var why := _shows(tuning, eye, Vector3(far.x, far.top, far.z), site, beyond, least, "%s, a stand-in")
			if why != "":
				return why
	return ""


func _shows(tuning: Tuning, eye: Vector3, top: Vector3, site: Structure, beyond: float, least: float, what: String) -> String:
	var flat := Vector2(top.x - eye.x, top.z - eye.z)
	var dist := flat.length()
	if dist < beyond:
		return ""
	var worst := -INF
	for d in range(1, int(dist - site.reach)):
		var at := Vector2(eye.x, eye.z) + flat / dist * d
		var ground := world.terrain.height_at(at.x, at.y) if world.terrain.is_loaded_at(at.x, at.y) \
			else FarRing.ground(world.shape, tuning, at.x, at.y)
		worst = maxf(worst, (ground - eye.y) / d)
	var clear := top.y - eye.y - worst * dist
	if clear < least * dist:
		return ""
	return (what % site.kind) + " %.0f m off, %.1f px clear" % [dist, clear / dist / Skyline.PIXEL]


## When on the run's first day a glint drawn far off and clear of the
## ground between first shines for your eye as brightly and as long as a
## Surveyor's start asks, s; -1 if none does.
func _shines(tuning: Tuning) -> float:
	var camera := world.player.camera.global_position
	var eye := Vector3(world.world_x(camera.x), camera.y, world.world_z(camera.z))
	var skyline := world.terrain.skyline
	var center := world.terrain.chunk_at(eye.x, eye.z)
	var spots := []
	for site in skyline.seen():
		for each in skyline.glints_of(site):
			if Skyline.clearance(world.shape, tuning, eye, each[0], center, 1.0, true) > 0.0:
				spots.append(each)
	var day := world.weather.day
	var lit := 0.0
	var t := 0.0
	while t <= tuning.day_minutes * 60.0:
		var sun := day.sun_direction(t, world.moon.latitude, world.moon.longitude)
		var most := 0.0
		if sun.y > 0.1 and day.sun_shown(t) > 0.5:
			for each: Array in spots:
				most = maxf(most, Skyline.shine(each, eye, sun))
		lit = lit + 1.0 if most >= Starts.GLINT_SEEN else 0.0
		if lit > Starts.GLINT_LASTS:
			return t - lit
		t += 1.0
	return -1.0
