extends SailingAidProbe
## A saved course survives without silently re-engaging automatic sailing.

func run() -> void:
	await aid_rig()
	var course_before := computer.sailing.course
	computer.sailing.choose(computer, SailingAid.Mode.TRIM)
	computer.filters_off = ["weather"]
	check(get_node(^"/root/Saves").save(world), "the sailing rig saves while its drum is engaged")
	check(await resume(), "the sailing rig resumes")
	var consoles := world.devices().filter(func(device: Device) -> bool: return device is Console)
	check(consoles.size() == 1, "the same Console is restored")
	if consoles.is_empty():
		return
	computer = consoles[0]
	check(computer.sailing.course.is_equal_approx(course_before) and computer.filters_off == ["weather"]
		and computer.sailing.mode == SailingAid.Mode.HAND,
		"the course and map choice survive while control starts in hand mode")
	deck = computer._root() as Chassis
	for device: Device in deck.mounted():
		if device is Mast:
			mast = device
