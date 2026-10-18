extends MenuProbe
## Profile & saves probe 18: a dev run counts nothing. While the console's
## god holds you, and once a dev scenario has been used in a run, reaching
## Port Morgan records no deed, nor any landmark toward reaching them all.


func run() -> void:
	await open_main(false)
	await started()
	var profile := get_node(^"/root/Profile")
	var console := main.ui.dev_console
	console.run("god")
	console.run("goto port_morgan")
	await physics_frames(5)
	check(profile.deeds().is_empty() and profile._toward.is_empty(), "nothing recorded as god (%s)" % profile.deeds())
	console.run("god")
	console.run("scenario dusk")
	console.run("goto port_morgan")
	await physics_frames(5)
	check(profile.deeds().is_empty() and profile._toward.is_empty(), "nothing recorded in a dev scenario (%s)"
		% profile.deeds())
