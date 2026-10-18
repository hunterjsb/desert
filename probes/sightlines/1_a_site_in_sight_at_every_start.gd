extends Probe
## Sightlines probe 1: every origin begins with something to walk to in
## sight. On three worlds each origin's run is built at its start, and from
## your eye where it begins, something the world draws, a structure on the
## loaded ground or a stand-in past it, shows over the ground as drawn
## between, looked over a metre at a time, by the tuning's pixels at 1080
## rows. The Surveyor's stands past the deep desert's reach, on its horizon.
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
