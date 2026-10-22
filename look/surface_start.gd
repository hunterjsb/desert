class_name SurfaceStart
extends RefCounted
## For captures that frame a run's surface start, not the Surveyor's opening. The
## developer `spawn` scenario stands you at the run's start, the opening's cabin and
## stores go, and the run's own kit is laid beside you and carried as before there was a pod.
## Like any scenario run, it never saves and counts no deeds.

static func begin(main: Main) -> Array[Node]:
	var tree := main.get_tree()
	while main.world() == null:
		await tree.physics_frame
	var world := main.world()
	main.start_scenario(Scenarios.by_key("spawn"))
	for body: Node in SurveyorRecovery.named(world).values():
		if is_instance_valid(body):
			body.queue_free()
	while not world.terrain.is_settled_around(world.spawn.x, world.spawn.y):
		await tree.physics_frame
	var kit := Runs.kit(world)
	world.set_meta(&"kit", kit)
	world.player.suit.restock()
	return kit
