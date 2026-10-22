extends MovementProbe
## Profile & saves probe 48: Quiver. A short hop on a racer counts no make;
## ridden past Quiver's distance, each make counts once, and the last of the
## four ridden is Quiver.


func run() -> void:
	await load_moving()
	world.counts_deeds = true
	set_rate(60, 4)
	var profile := get_node(^"/root/Profile")
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var came := await _ride(flat, BoardMakes.RACER, 1.0)
	check(profile.toward_count("quiver") == 0, "a %.0f m hop on a racer counts no make" % came)
	for make in BoardMakes.ALL:
		came = await _ride(flat, make, 8.0)
		print("%s: %.0f m in 8 s" % [make, came])
	check(profile.toward_count("quiver") == BoardMakes.ALL.size() and profile.did("quiver"),
		"each make ridden counts once: Quiver")
	set_rate(60)


## A fresh board of this make ridden flat out along +x this long, s: how far it came, m.
func _ride(flat: Dictionary, make: StringName, seconds: float) -> float:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	await ride_here(&"battery", make)
	var ride := player.ride
	hold(["move_forward"])
	await ride_for(seconds)
	hold([])
	return ride._came
