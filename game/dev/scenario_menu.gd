extends CanvasLayer
## Dev: F2 lists the scenarios and a number key drops you into one. Launching
## with `-- --scenario=<key>` starts in one directly.

@onready var _world: World = $"../World"
var _list: Label


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
		lines.append("%d  %s" % [(i + 1) % 10, Scenarios.LIST[i].label])
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_scenarios"):
		visible = not visible
	elif visible and event is InputEventKey and event.pressed and not event.echo:
		var digit: int = event.physical_keycode - KEY_0
		if digit >= 0 and digit <= 9:
			var index := (digit + 9) % 10
			if index < Scenarios.LIST.size():
				visible = false
				apply(Scenarios.LIST[index])
