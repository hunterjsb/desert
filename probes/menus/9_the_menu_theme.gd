extends MenuProbe
## Menus probe 9: the menu theme. On the main menu its theme, "Salt", fades in
## over the silent desert, heard while the world's own sounds are muted. A new
## run fades it out and stops it; Save & quit back to the menu brings it in
## again from the start.


func run() -> void:
	await open_main()
	await _waited(Main.THEME_FADE + 0.5)
	print("on the menu: theme %s at %.1f dB, world muted %s" % [main.theme.playing, main.theme.volume_db,
		AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD))])
	check(main.theme.playing and main.theme.stream == Sounds.MENU_THEME and main.theme.volume_db > -1.0,
		"on the main menu its theme plays, faded in")
	check(main.theme.bus == Sounds.UI and AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD)),
		"on the menus' bus, heard while the world is muted")

	press(&"ui_accept")
	press(&"ui_accept")
	press(&"ui_accept")
	await faded_in()
	await started()
	await _waited(Main.THEME_FADE + 0.5)
	check(main.in_run() and not main.theme.playing, "a new run fades it out and stops it")

	await main.save_and_quit()
	await _waited(Main.THEME_FADE + 0.5)
	check(not main.in_run() and main.theme.playing and main.theme.volume_db > -1.0,
		"back on the menu it plays again")


func _waited(seconds: float) -> void:
	var until := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
