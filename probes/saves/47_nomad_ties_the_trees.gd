extends WorldProbe
## Profile & saves probe 47: Nomad ties the trees together. Hermit, Totality,
## First Light and Set Sail done, and Bared done early, dark while Carbon
## Dated isn't, is no Nomad: Ruins shows none. Carbon Dated done shows both,
## and Nomad with them.


func run() -> void:
	await load_world()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	for id: StringName in [&"shield_day", &"totality", &"bared", &"god_heard", &"sail_waist"]:
		Deeds.done(world, id)
	check(not profile.did("nomad"), "four trees, and Ruins' only deed dark: no Nomad")
	Deeds.done(world, &"ages")
	check(profile.did("nomad") and Deeds.lit(profile, &"nomad"), "Carbon Dated shows Ruins': Nomad")
