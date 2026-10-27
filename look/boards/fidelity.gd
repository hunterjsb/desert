extends "res://look/paint/paint.gd"
## Look-test: the boards and the rig in the art-direction camp's own light:
## the four makes side by side, each from where its rider looks down on it,
## the company's board in each era its hands can give it, and the rig's parts
## on their backs, their working faces up; and the makes again hovering at
## their ride height, lit as they are ridden, for the night and the storm.
##   godot --path . --disable-vsync res://look/boards/fidelity.tscn -- --look grey --capture <dir> [--storm]
## look/boards/fidelity.sh shoots both weathers and builds the sheet.

## The rows, camp frame: the makes, then the company's board by era, then the
## rig; each row's z and its things' x.
const MAKES_Z := 5.0
const ERAS_Z := 5.0
const RIG_Z := 4.9
const MAKES_X := [-0.84, -0.28, 0.28, 0.84]
const ERAS_X := [3.2, 3.75, 4.3, 4.85, 5.4]
const ERA_LINES := [[], [[Eras.COLONIAL, &"made", [&"tilg"]]],
	[[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"haberjack"]]], [[Eras.SKIMMER, &"made", []]],
	[[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"pellicott"]],
		[Eras.DARK, &"remade", [&"wood", &"cord", &"ceramic"]], [Eras.SECOND, &"blessed", [&"tu", &"charm"]]]]
## The rig's parts on their backs, x, and the sail along the row.
const RIG := [[&"hover_tray", -5.6], [&"skates", -4.75], [&"board_plate", -3.9], [&"keel", -3.2]]
## The hovering row, camp frame, inside the bubble; how high they ride, m.
const HOVER_X := [2.9, 3.47, 4.04, 4.61]
const HOVER_Z := 1.9
const RIDE := 0.35

## Boards drawn as their riders see them run: their emitters and lamps lit.
var _lit: Array[Device] = []


func _dress() -> void:
	super._dress()
	for i in BoardMakes.ALL.size():
		_board(BoardMakes.ALL[i], [], Vector3(MAKES_X[i], 0.0, MAKES_Z))
	for i in ERA_LINES.size():
		_board(BoardMakes.ISSUE, ERA_LINES[i], Vector3(ERAS_X[i], 0.0, ERAS_Z))
	for entry: Array in RIG:
		_set_down(Catalog.part(entry[0]), Vector3(entry[1], 0.0, RIG_Z), 0.0, true)
	for i in BoardMakes.ALL.size():
		var board := _board(BoardMakes.ALL[i], [], Vector3(HOVER_X[i], 0.0, HOVER_Z))
		board.global_position += Vector3.UP * RIDE
		_lit.append(board)
	var sail := Catalog.part(&"sail")
	_set_down(sail, Vector3(-4.3, 0.0, RIG_Z + 0.75), PI * 0.5)


## A board lying flat with a charged battery at its nose, its nose away.
func _board(id: StringName, line: Array, at: Vector3) -> Device:
	var board := Catalog.device(id)
	if not line.is_empty():
		Catalog.inherit(board, line)
	for socket in board.sockets():
		if socket.kind == &"battery":
			var cell := Catalog.part(&"battery") as Battery
			cell.charge_wh = cell.capacity()
			world.content.add_child(cell)
			board.fit(cell, socket)
	_set_down(board, at, PI)
	return board


## Off, a board's lamps go dark; these are held lit, as ridden.
func _process(_delta: float) -> void:
	for board in _lit:
		board.frame_view.set_instance_shader_parameter(&"lit", 1.0)


func _shots() -> Array:
	var shots := []
	var middle := Vector3(0.0, 0.05, MAKES_Z)
	for moment in ["morning", "dusk"]:
		shots.append(["makes2_%s" % moment, moment, Vector3(0.35, 1.45, MAKES_Z + 1.75), middle])
	for i in MAKES_X.size():
		var x: float = MAKES_X[i]
		shots.append(["deck_%d" % i, "midmorning", Vector3(x + 0.05, 1.15, MAKES_Z + 0.85), Vector3(x, 0.04, MAKES_Z - 0.2)])
	# Close over two decks, the camera creeping 2 mm a frame: a face fighting
	# another for its pixels flickers from frame to frame.
	for i in 4:
		var x := -0.56 + i * 0.002
		shots.append(["creep_%d" % i, "midmorning", Vector3(x + 0.06, 0.95, MAKES_Z + 0.75), Vector3(x, 0.04, MAKES_Z - 0.1)])
	shots.append(["eras2", "midmorning", Vector3(4.4, 1.5, ERAS_Z + 1.8), Vector3(4.3, 0.05, ERAS_Z)])
	shots.append(["rig2", "midmorning", Vector3(-4.4, 1.7, RIG_Z + 2.0), Vector3(-4.4, 0.05, RIG_Z + 0.2)])
	shots.append(["rig_dusk", "dusk", Vector3(-4.4, 1.7, RIG_Z + 2.0), Vector3(-4.4, 0.05, RIG_Z + 0.2)])
	shots.append(["floater", "midmorning", Vector3(-2.5, 1.12, 2.05), Vector3(-1.9, 1.08, 0.6)])
	var hover := Vector3(3.75, 0.3, HOVER_Z)
	# Low and ahead of their noses, under their emitters, toward their lamps.
	shots.append(["hover_night", "night", Vector3(4.5, 0.2, HOVER_Z - 1.9), hover])
	shots.append(["hover_storm", "storm", Vector3(4.5, 0.2, HOVER_Z - 1.9), hover])
	shots.append(["storm_makes", "storm", Vector3(0.35, 1.45, MAKES_Z + 1.75), middle])
	shots.append(["storm_floater", "storm", Vector3(-2.5, 1.12, 2.05), Vector3(-1.9, 1.08, 0.6)])
	return shots
