extends MenuProbe
## Profile & saves probe 18: a dev run counts nothing. Once a dev scenario
## has been used in a run, reaching Port Morgan records no deed, nor any
## landmark toward reaching them all.


func run() -> void:
	await open_main(false)
	await started()
	main.ui.dev_console.run("scenario dusk")
	main.ui.dev_console.run("goto port_morgan")
	await physics_frames(5)
	var profile := get_node(^"/root/Profile")
	check(profile.deeds().is_empty() and profile._toward.is_empty(), "nothing recorded (%s)" % profile.deeds())
