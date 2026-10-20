extends LineProbe
## Profile & saves probe 16: a Console resumes. A Console on a plate with a
## battery and a radio stuck beside it, its screen and three instruments in
## its ports, its screen turned to its power page, the number its shield
## page had, is saved and resumed into a fresh world on the same seed: the
## same parts in the same ports, the radio on its deck, the same page and the
## same log, and it reads on.

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var plate := device(&"chassis", spot(0.0, 3.0), Chassis.THICK * 0.5 + 0.01) as Chassis
	var made := Rig.make(&"console") as Console
	Stick.put(plate, plate, Chassis.TOP, Vector2(-0.1, 0.0), 0.0, made)
	# Fitted running, so it logs each one coming online.
	for id: StringName in [&"screen", &"anemometer", &"barometer", &"radar"]:
		fit_part(made, id)
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.37, 0.3), 0.0, Catalog.part(&"battery"))
	Stick.put(plate, plate, Chassis.TOP, Vector2(0.32, -0.3), 0.0, Rig.make([&"radio", [&"battery"]]))
	made.page = Console.Page.POWER
	await simulate(2.0)
	var before := _reading(made)
	print("saved: ", before)
	check(before.log.size() >= 3 and saves.save(world), "saved, its log written")

	check(await resume(), "resumed")
	var found := world.devices().filter(func(n: Node) -> bool: return n is Console)
	check(found.size() == 1, "one Console came back")
	if found.is_empty():
		return
	var after := _reading(found[0])
	print("resumed: ", after)
	check(str(after) == str(before), "the same Console: its parts, page and log")
	await simulate(2.0)
	var text: String = found[0].screen_text(Console.Page.STATS)
	check("WIND" in text and "PRESS" in text and "FRONT" in text, "and it reads on")


## What a save must keep of a Console.
func _reading(made: Console) -> Dictionary:
	var fitted := []
	for socket in made.frame_sockets():
		if socket.part != null:
			fitted.append(str(socket.part.get_meta(&"catalog")))
		elif socket.mounted != null:
			fitted.append(str(socket.mounted.get_meta(&"catalog")))
		else:
			fitted.append("")
	return {"fitted": fitted, "page": made.page, "beside": made._system().map(func(d: Device) -> String:
			return str(d.get_meta(&"catalog"))),
		"log": made.log_lines.map(func(l: Dictionary) -> String: return "%s %s" % [l.at, l.text])}
