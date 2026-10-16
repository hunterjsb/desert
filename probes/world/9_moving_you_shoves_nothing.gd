extends WorldProbe
## World & terrain probe 9: putting you somewhere at once, as a respawn or a
## resumed save does, shoves nothing that stood against you where you were.


func run() -> void:
	await load_world()
	var x := world.player_world_x()
	var z := world.player_world_z()
	# Against you, on the side you'll go.
	var box := drop_box(x + 0.6, z, 0.3)
	await physics_frames(60)
	var was := box.global_position
	world.respawn(x + 10.0, z, 0.0, 0.0)
	await physics_frames(30)
	var moved := box.global_position.distance_to(was)
	check(moved < 0.01, "what stood against you stays put (moved %.3f m)" % moved)
