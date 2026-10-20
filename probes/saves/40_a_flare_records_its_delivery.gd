extends ShieldProbe
## Only a normal run's actual flare call records the delivery deed.

func run() -> void:
	await load_storm(0.0)
	world.counts_deeds = true
	Scenarios.surveyor_over(world, 1.0)
	await _call()
	check(Profile.did("care_package"), "the successful call records Care Package")
	Profile.forget_deeds()
	world.counts_deeds = false
	await _call()
	check(not Profile.did("care_package"), "a developer run does not award it")

func _call() -> void:
	var flare := Catalog.part(&"flare") as Flare
	world.content.add_child(flare)
	flare.global_position = world.player.global_position + Vector3.UP
	flare.light()
	await physics_frames(4)
	check(flare.called, "the lit flare called an actual delivery")
