extends LineProbe
## Original independent ends retain nested ownership through hand, anchor and sand.

var _full := [24.0, 25.0, 26.0]
var _paid := [18.0, 19.0, 20.0]


func run() -> void:
	await load_lines()
	var saves := get_node(^"/root/Saves")
	var me := world.player.global_position
	for i in 3:
		var source := driven_stake(me + Vector3(-2.0 + i * 2.0, 0, -3.0))
		var line := Line.to_waist(world, source.free_tie(me), 2.0)
		line.full = _full[i]
		line.rope.full = _full[i]
		line.rope.length = _paid[i]
		line.rope.strand.set_length(_paid[i])
	var guide := driven_stake(me + Vector3(3, 0, -1))
	var hook := fit_part(guide, &"hook") as RopeHook
	check(_lines()[1].route(hook.guide).is_empty(), "one original line passes through a real hook")
	hands.reel.choose(_lines()[2].ends[1])
	check(saves.save(world), "single ends saved")
	var old: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	old.hands.erase("chosen")
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, old)
	check(await resume(), "pre-choice single-end save resumes")
	check(hands.reel.chosen_body() == null and world.player.waist.tied.size() == 3,
		"old saves retain independent waist ends without inventing a choice")

	var lines := _lines()
	var primary := lines[0].ends[1]
	world.player.waist.untie(primary)
	for i in range(1, 3):
		world.player.waist.untie(lines[i].ends[1])
		check(RopeBundle.gather(primary, lines[i].ends[1]), "the same actual end joins the hand knot")
	hands._grip(primary)
	hands.phase = Hands.Phase.HELD
	hands._ticked = primary.global_transform
	hands.reel.choose(lines[2].ends[1])
	check(saves.save(world) and await resume(), "held group saved and resumed")
	_check_group("held")
	lines = _lines()
	primary = lines[0].ends[1]
	check(hands.held == primary and hands.reel.chosen_body() == lines[2].ends[1],
		"the held primary and selected individual member return")
	check(is_equal_approx(primary.mass, 3.0 * RopeBundle.own_mass(primary)), "loose primary carries all three end masses")

	var anchor := driven_stake(world.player.global_position + Vector3(0, 0, 2))
	anchor.fit(hands.stow(), anchor.free_tie(primary.global_position))
	var anchor_mass := anchor.mass
	check(saves.save(world) and await resume(), "anchored group saved and resumed")
	_check_group("anchored")
	primary = _lines()[0].ends[1]
	anchor = primary.socket.get_parent() as Stake
	check(is_instance_valid(anchor) and is_equal_approx(anchor.mass, anchor_mass)
		and is_equal_approx(primary.mass, RopeBundle.own_mass(primary)) and hands.reel.chosen_body() == null,
		"anchor counts every original mass once and has no remote reel choice")

	primary = anchor.take(primary.socket)
	primary.global_position = world.player.global_position + Vector3(1, 0.3, 0)
	check(saves.save(world) and await resume(), "loose group saved and resumed")
	_check_group("loose")
	primary = _lines()[0].ends[1]
	check(primary.socket == null and hands.held == null and world.player.waist.tied.is_empty()
		and is_equal_approx(primary.mass, 3.0 * RopeBundle.own_mass(primary)),
		"all ends remain in one physical loose group with aggregate mass")


func _lines() -> Array[Line]:
	var found: Array[Line] = []
	for child in world.content.get_children():
		if child is Line:
			found.append(child)
	found.sort_custom(func(a: Line, b: Line) -> bool: return a.full < b.full)
	return found


func _check_group(phase: String) -> void:
	var lines := _lines()
	check(lines.size() == 3 and world.ropes.ropes.size() == 3, phase + ": no Line or rope is cloned")
	if lines.size() != 3:
		return
	var primary := lines[0].ends[1]
	var members := RopeBundle.members(primary)
	check(members.size() == 3 and RopeBundle.slots(primary).size() == 2,
		phase + ": the physical knot owns the same three end Parts")
	for i in 3:
		var line := lines[i]
		check(line.full == _full[i] and line.rope.length == _paid[i] and line.ends.size() == 2
			and members.has(line.ends[1]) and line.ends[1].get_meta(&"line") == line
			and line.rope.b == Line._tip(line.ends[1]) and is_instance_valid(line.rope.b.holder),
			phase + ": each distinct line retains its exact endpoint and lengths")
	check(is_instance_valid(lines[1].rope.through) and lines[1].rope.strand.through == lines[1].rope.through
		and lines[1].routed_by_player, phase + ": the original fairlead route remains attached")
