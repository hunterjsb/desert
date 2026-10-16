extends CanvasLayer
## Dev: F2 lists the scenarios and a number key drops you into one; past the
## tenth, the first letter of its key. Launching with `-- --scenario=<key>`
## starts in one directly.

## Whichever world is running: a new run brings a new one.
var _world: World:
	get:
		return get_node("../World")
var _list: Label
## The test kit last dropped, cleared when another scenario starts.
var _kit: Array[Node3D] = []


func _ready() -> void:
	layer = 101
	visible = false
	_list = Label.new()
	_list.position = Vector2(8, 150)
	_list.add_theme_font_size_override("font_size", 12)
	_list.add_theme_constant_override("line_spacing", 0)
	_list.add_theme_color_override("font_outline_color", Color.BLACK)
	_list.add_theme_constant_override("outline_size", 4)
	var lines := PackedStringArray(["SCENARIOS  F2 closes"])
	for i in Scenarios.LIST.size():
		lines.append("%s  %s" % [_hotkey(i), Scenarios.LIST[i].label])
	_list.text = "\n".join(lines)
	add_child(_list)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			# The world finishes setting up first.
			await get_tree().process_frame
			apply(Scenarios.by_key(arg.trim_prefix("--scenario=")))


func apply(scenario: Dictionary) -> void:
	if scenario.is_empty():
		push_warning("no such scenario")
		return
	var place := Scenarios.find(_world, scenario)
	if place.is_empty():
		Dev.put("world/scn", "%s: none in 3 days" % scenario.key)
		return
	_world.respawn(place.x, place.z, place.yaw, place.time)
	Dev.put("world/scn", scenario.key)
	for body in _kit:
		if is_instance_valid(body):
			body.queue_free()
	_kit.clear()
	if scenario.kind in ["kit", "ruin"] or scenario.get("camp", false) or scenario.get("survive", false) \
			or scenario.get("farm", false) or scenario.get("board", false):
		# Bodies dropped before the sand under them has collision would be frozen or forgotten.
		while not _world.terrain.is_settled_around(place.x, place.z):
			await get_tree().physics_frame
		if scenario.kind == "ruin":
			_kit = Scenarios.yours(_world)
		elif scenario.kind == "kit":
			_kit = Scenarios.kit(_world)
		elif scenario.get("farm", false):
			_kit = Scenarios.farm(_world)
		elif scenario.get("board", false):
			_kit = Scenarios.board(_world)
		else:
			_kit = Scenarios.camp(_world) if scenario.get("camp", false) else Scenarios.survive(_world)


func _hotkey(index: int) -> String:
	return str((index + 1) % 10) if index < 10 else Scenarios.LIST[index].key.left(1).to_upper()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_scenarios"):
		visible = not visible
	elif visible and event is InputEventKey and event.pressed and not event.echo:
		var pressed := OS.get_keycode_string(event.physical_keycode)
		for index in Scenarios.LIST.size():
			if _hotkey(index) == pressed:
				visible = false
				get_viewport().set_input_as_handled()
				apply(Scenarios.LIST[index])
				return
