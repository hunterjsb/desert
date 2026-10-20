extends WorldProbe
## Profile & saves probe 23: a save never buries you. A cistern stood by hand
## where a storm digs its pit out; you stand on its floor as the storm lets
## go, the sand held off it over you, and the run is saved once the weather
## alone would have the pit filling. Resumed in a fresh world, it comes back
## dug out as it was held, the sand at your feet and not over them, and held
## still while you stand there.

const KIND := &"cistern"
## On its pit's floor, plan m.
const FLOOR := Vector2(0.0, -2.2)


func run() -> void:
	await load_world(1234, true, true)
	world.time_warp = 0.0
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x() + 320.0, world.player_world_z())
	var stands := func(at: Vector2) -> bool: return sites.by_hand(KIND, at.x, at.y, 0.0, 0.0).stands()
	var storm := StormSite.find(world.weather.field, world.tuning, from.x, from.y, 2, 100.0, 1.0, 0.0, stands, world.shape)
	check(not storm.is_empty(), "a storm that digs a cistern out")
	if storm.is_empty():
		return
	var site := sites.by_hand(KIND, storm.x, storm.z, 0.0, storm.depth)
	sites.add(site)
	world.time = storm.peak
	var floor := site.to_world(FLOOR)
	teleport(floor.x, floor.y)
	await settle()
	var t: float = storm.peak
	while t < storm.after:
		t += 3.0
		world.time = t
		await get_tree().process_frame
		await get_tree().process_frame
	var alone := Exposure.level(site.depth, site.pure_taken(t))
	check(site.level() >= Exposure.DUG_OUT and alone < 1.5,
		"held dug out over you while the weather alone fills it (%.2f against %.2f)" % [site.level(), alone])
	var data := Snapshot.take(world)
	check(data.held.size() == 1, "the save keeps the sand held off it (%d)" % data.held.size())

	await _fresh_world()
	var snapshot := Snapshot.new(world)
	snapshot.begin(data)
	# Laid by hand it isn't saved, so it's laid again as it was, before its ground is built.
	var again := world.shape.sites.by_hand(KIND, storm.x, storm.z, 0.0, storm.depth)
	world.shape.sites.add(again)
	await settle(true)
	snapshot.finish(data)
	await physics_frames(30)
	var over := world.height_at(world.player_world_x(), world.player_world_z()) - world.player.global_position.y
	print("resumed at level %.2f, the weather alone %.2f; the sand %.3f m over your feet"
		% [again.level(), Exposure.level(again.depth, again.pure_taken(world.time)), over])
	check(again.level() >= Exposure.DUG_OUT and over < 0.05, "resumed dug out, the sand at your feet, not over them")
	await physics_frames(60)
	check(again.level() >= Exposure.DUG_OUT, "and held while you stand there")


## A fresh world on the same seed, the old one gone.
func _fresh_world() -> void:
	var seed_was := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = seed_was
	add_child(world)
	await settle()
