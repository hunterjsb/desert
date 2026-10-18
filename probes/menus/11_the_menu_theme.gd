extends MenuProbe
## Menus probe 11: the menu theme. On the main menu its theme, "Salt", fades
## in over the silent desert, heard while the world's own sounds are muted. A
## new run fades it out with the screen and stops it; Save & quit back to the
## menu brings it in again from its start.


func run() -> void:
	Settings.music = true
	await open_main()
	var theme := await _theme()
	print("on the menu: theme %s at %.1f dB, world muted %s" % [theme.playing, theme.volume_db,
		AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD))])
	check(theme.playing and theme.stream == Sounds.MENU_THEME and theme.volume_db > -1.0,
		"on the main menu its theme plays, faded in")
	check(theme.bus == Sounds.UI and AudioServer.is_bus_mute(AudioServer.get_bus_index(Sounds.WORLD)),
		"on the menus' bus, heard while the world is muted")

	await main.new_game()
	await faded_in()
	await started()
	check(main.in_run() and (not is_instance_valid(theme) or not theme.playing), "a new run fades it out and stops it")

	await main.save_and_quit()
	theme = await _theme()
	print("back on the menu: %.1f s into it at %.1f dB" % [theme.get_playback_position(), theme.volume_db])
	check(not main.in_run() and theme.playing and theme.volume_db > -1.0
		and theme.get_playback_position() < UIRoot.FADE_SECONDS * 4.0 + 1.0, "back on the menu it plays again from its start")


## The menu's theme once it has faded in.
func _theme() -> MenuMusic:
	for i in 1800:
		await get_tree().process_frame
		for child in main.view.get_children() if main.view != null else []:
			if child is MenuMusic and child.playing and child.volume_db > -1.0:
				return child
	check(false, "the menu's theme fades in")
	return MenuMusic.new()
