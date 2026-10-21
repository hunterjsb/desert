class_name ArrivalSaveProbe
extends DeckProbe
## Save fixtures keep their real physical objects; the observer only counts controller callbacks.
class Observer extends SurveyorArrival:
	var restores := 0
	var guarded_grips := 0
	var unguarded_grips := 0
	var restored_under_guard := false
	func restore() -> void:
		restores += 1
		restored_under_guard = world.get_meta(&"arrival_restoring", false)
	func recover(body: Node) -> void:
		if world.get_meta(&"arrival_restoring", false):
			guarded_grips += 1
		else:
			unguarded_grips += 1
		super.recover(body)

var saves: Node
var observer: Observer

func prepare_arrival() -> void:
	await load_lines()
	saves = get_node(^"/root/Saves")
	for item in world.player.suit.carried:
		if is_instance_valid(item):
			item.free()
	world.player.suit.carried.clear()
	world.arrival_enabled = true
	world.arrival_state = SurveyorManifest.resolve(world.run_seed, Sphere.point(world.moon.latitude, world.moon.longitude))
	_observe()

func _observe() -> void:
	if is_instance_valid(world.arrival):
		world.arrival.free()
	observer = Observer.new()
	observer.world = world
	world.arrival = observer
	world.add_child(observer)

func resume_arrival() -> bool:
	var run_seed := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = run_seed
	world.arrival_enabled = true
	world.set_meta(&"resumed", true)
	add_child(world)
	await settle()
	world.player.set_physics_process(false)
	_observe()
	if not saves.restore(world):
		return false
	if saves.restoring:
		await saves.restored
	await get_tree().process_frame
	hands = world.player.hands
	ropes = world.ropes
	return true

func skin_count(node: Node) -> int:
	var total := 1 if node is MeshInstance3D and node.has_meta(&"pod_skin") else 0
	for child in node.get_children():
		total += skin_count(child)
	return total
