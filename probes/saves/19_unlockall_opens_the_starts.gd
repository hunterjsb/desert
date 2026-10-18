extends MenuProbe
## Profile & saves probe 19: unlockall opens the starts. On a fresh profile
## only the Surveyor is open. The console action opens the console over the
## main menu, with no run; unlockall there opens every start, and New game
## then shows none locked. Forgetting the deeds leaves them open.


func run() -> void:
	await open_main()
	var profile := get_node(^"/root/Profile")
	var all := Kit.origins().size()
	check(Kit.open_to(profile).size() == 1, "a fresh profile has the Surveyor alone")
	press(&"console")
	var console := main.ui.dev_console
	check(console.visible and not main.in_run(), "the console opens over the main menu")
	console.run("unlockall")
	console.run("deeds clear")
	press(&"console")
	check(Kit.open_to(profile).size() == all, "unlockall opens every start (%d of %d)"
		% [Kit.open_to(profile).size(), all])
	press(&"ui_accept")
	check(not main.ui.top().words().has("????"), "New game shows none locked (%s)" % ", ".join(main.ui.top().words()))
