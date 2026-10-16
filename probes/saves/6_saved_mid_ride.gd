extends MovementProbe
## Profile & saves probe 6: saved mid-ride. Riding a board flat out, the run
## is saved; resumed into a fresh world on the same seed, you're back on the
## board going as you were, and the ride on goes where the one never saved
## went. A board that can't carry you on resume (the save's ride dropped)
## comes down on the sand as a body, never hanging in the air.

## As close as the round trip holds things, m.
const METRES := 0.02

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_moving()
	await ride_here()
	hold(["move_forward"])
	await ride_for(3.0)
	var going := player.ride.velocity
	var ticks := player.ride.ticks
	check(going.length() > 10.0, "riding fast (%.1f m/s)" % going.length())
	check(saves.save(world), "saved mid-ride")
	await ride_for(2.0)
	var never := where()

	check(await _resume(), "resumed")
	var ride := player.ride
	check(ride != null and ride.board == player.board and ride.board.rider == player, "you're back on the board")
	if ride == null:
		return
	check(ride.ticks == ticks and ride.velocity.distance_to(going) < 1e-6,
		"going as you were (%.2f m/s, saved %.2f)" % [ride.velocity.length(), going.length()])
	await ride_for(2.0)
	var apart := where().distance_to(never)
	print("resumed ride: %.5f m from the one never saved" % apart)
	check(apart <= METRES, "and it rides on where it would have, within %.2f m" % METRES)

	hold([])
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	data.erase("ride")
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data)
	check(await _resume(), "resumed without the ride")
	var board: Hoverboard = null
	for node in world.content.get_children():
		if node is Hoverboard:
			board = node
	check(player.board == null and board != null and not board.freeze, "the board is a body again")
	if board == null:
		return
	await simulate(3.0)
	print("dropped ride: the board %.2f m over the sand" % clearance(board))
	check(clearance(board) < 0.3, "down on the sand (%.2f m over it)" % clearance(board))


## The save on disk resumed into a fresh world on the same seed.
func _resume() -> bool:
	var seed_was := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = seed_was
	add_child(world)
	await settle()
	await get_tree().physics_frame
	player = world.player
	if not saves.restore(world):
		return false
	if saves.restoring:
		await saves.restored
	return true
