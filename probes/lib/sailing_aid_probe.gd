class_name SailingAidProbe
extends SailProbe
## A normal sheet drum and a powered wind-reading Console on a four-frame rig.

var computer: Console
var drum: ManualWinch
var sheet_line: Line


func aid_rig(carried := &"skates") -> void:
	await load_sailing()
	rig(open, heading(), carried, 1, false)
	drum = Catalog.device(&"hand_winch") as ManualWinch
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2(0.2, 0.2), 0.0, drum)
	computer = Rig.make([&"console", [&"screen", &"anemometer"]]) as Console
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 1)), Chassis.TOP, Vector2(0.15, 0.15), 0.0, computer)
	sheet_line = Line.between(world, mast.boom_tie(), drum.free_tie(mast.global_position), 0.1)
	check(mast.rig_sheet(sheet_line), "the drum takes the ordinary routed sheet")
	hoist(5.0)
	blow(downwind * 10.0)
	course = heading()
	computer.sailing.course = course
	await sail_for(2.0)
	check(computer.running() and computer.sailing.winch(computer) == drum, "the fitted powered Console sees its sheet drum")


func reset_aid_world() -> void:
	world.process_mode = Node.PROCESS_MODE_DISABLED
	RopeArticulation.forget(deck)
	world.queue_free()
	await get_tree().process_frame
	world = null
	deck = null
	mast = null
	course = Vector2.ZERO


func progress(from: Vector2, along: Vector2) -> float:
	var here := Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	return (here - from).dot(along)


func place() -> Vector2:
	return Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))


func before_finish() -> void:
	super()
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(deck):
		RopeArticulation.forget(deck)
