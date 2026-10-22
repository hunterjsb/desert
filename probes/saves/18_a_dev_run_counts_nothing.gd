extends MenuProbe
## Profile & saves probe 18: a dev run counts nothing. The console's listing
## commands leave a run counting deeds; one that changes it, warp, makes it a
## dev run, where reaching Port Morgan records no deed nor any landmark toward
## them all. Saved and resumed, it's a dev run still.


func run() -> void:
	await open_main(false)
	await started()
	var profile := get_node(^"/root/Profile")
	var console := main.ui.dev_console
	# The opening's own deeds are earned before the run turns dev.
	var earned: Dictionary = profile.deeds().duplicate(true)
	for listing in ["help", "scenarios", "deeds", "goto"]:
		console.run(listing)
	check(world.counts_deeds, "listing commands leave the run counting")
	console.run("warp 1")
	console.run("goto port_morgan")
	await physics_frames(5)
	check(not world.counts_deeds and profile.deeds() == earned and profile._toward.is_empty(),
		"warp makes it a dev run: nothing recorded at Port Morgan (%s)" % profile.deeds())
	check(main.save_run(), "it saves")
	main.resume()
	await faded_in()
	check(world.has_meta(&"resumed") and not world.counts_deeds, "resumed, it's a dev run still")
