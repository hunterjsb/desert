extends MenuProbe
## Menus & UI probe 9: a how-to once a profile. The first time a sail's sheet
## is at your waist, a short how-to shows, its keys as bound; tied on again it
## doesn't, nor in a new run on the same profile.


func run() -> void:
	await open_main(false)
	await started()
	await faded_in()
	var how_to: Control = main.ui._how_to
	await _sheet_at_waist()
	check(how_to.modulate.a > 0.5 and how_to.text.contains(Controls.key_for(&"reel_in")),
		"the first sheet at your waist shows its how-to, its keys as bound")

	how_to.modulate.a = 0.0
	var waist := world.player.waist
	var end: RigidBody3D = waist.tied.back()
	waist.untie(end)
	waist.tie(end)
	await physics_frames(10)
	check(how_to.modulate.a == 0.0, "tied on again, it isn't shown again")

	await main.new_game()
	await faded_in()
	await _sheet_at_waist()
	check(how_to.modulate.a == 0.0, "nor in a new run on the same profile")


## A mast with its sail standing beside you, its sheet tied at your waist.
func _sheet_at_waist() -> void:
	var mast := Catalog.device(&"mast") as Mast
	world.content.add_child(mast)
	var sail := Catalog.part(&"sail")
	world.content.add_child(sail)
	mast.fit(sail, mast.sockets()[0])
	mast.global_position = world.player.global_position + Vector3(2.0, 0.5, 0.0)
	mast.freeze = true
	Scenarios.sheet_to_waist(world, mast)
	await physics_frames(10)
