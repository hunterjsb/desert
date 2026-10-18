extends MenuProbe
## Menus probe 11: the menu theme. On the main menu its theme, Hunter's "Salt",
## fades in over the silent desert on the menus' bus, heard while the world's
## own sounds are muted, and its switch mutes it. A new run fades it out with
## the screen; Save & quit back to the menu brings it in again.


func run() -> void:
	await open_main()
	await _waited(UIRoot.FADE_SECONDS + 0.5)
	var music := _music()
	print("on the menu: %s, %s at %.1f dB" % [music, "playing" if music != null and music.playing else "silent",
		music.volume_db if music != null else NAN])
	check(music != null and music.playing and music.stream == Sounds.MENU_THEME and music.volume_db > -1.0,
		"on the main menu its theme plays, faded in")
	check(music != null and music.bus == Sounds.UI and AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD)),
		"on the menus' bus, heard while the world is muted")
	Settings.music = false
	await _waited(UIRoot.FADE_SECONDS + 0.5)
	check(not music.playing, "its switch mutes it")
	Settings.music = true
	await _waited(UIRoot.FADE_SECONDS + 0.5)
	check(music.playing, "and on again")

	press(&"ui_accept")
	press(&"ui_accept")
	press(&"ui_accept")
	await faded_in()
	await started()
	check(main.in_run() and _music() == null, "a new run fades it out with the menu's desert")

	await main.save_and_quit()
	await _waited(UIRoot.FADE_SECONDS + 0.5)
	music = _music()
	check(not main.in_run() and music != null and music.playing and music.stream == Sounds.MENU_THEME,
		"back on the menu it plays again")


## The menu's music, while its desert shows.
func _music() -> MenuMusic:
	if main.view == null or not is_instance_valid(main.view):
		return null
	for child in main.view.get_children():
		if child is MenuMusic:
			return child
	return null


func _waited(seconds: float) -> void:
	var until := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
