extends LineProbe
## Profile & saves probe 16: a Console resumes. A Console on the sand with its
## screen, three instruments and a radio on its top, its screen turned to its
## power page, the number its shield page had, is saved and resumed into a
## fresh world on the same seed: the same parts in the same sockets, the same
## page and the same log, and it reads on.

var saves: Node


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_lines()
	var made := device(&"console", spot(0.0, 3.0), 0.26) as Console
	for id: StringName in [&"battery", &"screen", &"anemometer", &"barometer", &"radar"]:
		fit_part(made, id)
	var radio := Catalog.device(&"radio")
	world.content.add_child(radio)
	fit_part(radio, &"battery")
	made.mount(radio, Scenarios._free(made, &"top"))
	made.page = Console.Page.POWER
	await simulate(2.0)
	var before := _reading(made)
	print("saved: ", before)
	check(before.log.size() >= 3 and saves.save(world), "saved, its log written")

	check(await resume(), "resumed")
	var found := world.content.get_children().filter(func(n: Node) -> bool: return n is Console)
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
	return {"fitted": fitted, "page": made.page,
		"log": made.log_lines.map(func(l: Dictionary) -> String: return "%s %s" % [l.at, l.text])}
