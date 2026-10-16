extends Probe
## Every sound the game names is there and plays, and the buses it mixes on
## exist: World, which the main menu mutes, and UI, which it doesn't.


func run() -> void:
	var named := {}
	var path := RegEx.create_from_string("res://assets/audio/[^\"]+")
	for script in _scripts("res://game"):
		for found in path.search_all(FileAccess.get_file_as_string(script)):
			named[found.get_string()] = script
	check(named.size() >= 30, "the game names its sounds (%d found)" % named.size())
	for sound: String in named:
		var stream := load(sound) as AudioStream if ResourceLoader.exists(sound) else null
		check(stream != null and stream.get_length() > 0.0, "%s, named in %s, loads" % [sound, named[sound]])
	for bus in [Sounds.WORLD, Sounds.WEATHER, Sounds.UI]:
		check(AudioServer.get_bus_index(bus) != -1, "the %s bus exists" % bus)
	check(AudioServer.get_bus_send(AudioServer.get_bus_index(Sounds.WEATHER)) == Sounds.WORLD,
		"the weather is part of the world, muted with it")


func _scripts(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	return out
