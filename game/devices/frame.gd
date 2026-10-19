class_name Frame
extends Part
## An open cube of rails that sticks square on a chassis's top and takes a
## whole-face piece on each of its five other faces: a chassis (upright, a
## wall; on top, a shelf), a screen or fabric. Its own frame stands up its +Z
## from the face it's stuck on, as any part's does, so its faces are sockets
## it adds, which live in the deck's body once it's stuck there.

## Its width and height, m: one chassis piece's.
const WIDE := 1.0
const TALL := 1.0
## A rail's thickness, m.
const RAIL := 0.05
## Its faces, by name, as [where, way out], in its own frame.
const FACES := {
	&"top": [Vector3(0.0, 0.0, TALL), Vector3.BACK],
	&"right": [Vector3(WIDE * 0.5, 0.0, TALL * 0.5), Vector3.RIGHT],
	&"left": [Vector3(-WIDE * 0.5, 0.0, TALL * 0.5), Vector3.LEFT],
	&"front": [Vector3(0.0, WIDE * 0.5, TALL * 0.5), Vector3.UP],
	&"back": [Vector3(0.0, -WIDE * 0.5, TALL * 0.5), Vector3.DOWN],
}
## What a face takes besides a chassis piece: whole-face parts.
const TAKES: Array[StringName] = [&"face", &"screen"]


## Its rails as boxes and its faces as sockets.
static func build(made: Frame, look: Mesh) -> void:
	var h := WIDE * 0.5 - RAIL * 0.5
	var rails: Array[Array] = []
	for x in [-1, 1]:
		for y in [-1, 1]:
			rails.append([Vector3(RAIL, RAIL, TALL), Vector3(x * h, y * h, TALL * 0.5)])
	for z in [RAIL * 0.5, TALL - RAIL * 0.5]:
		for s in [-1, 1]:
			rails.append([Vector3(WIDE - 2.0 * RAIL, RAIL, RAIL), Vector3(0.0, s * h, z)])
			rails.append([Vector3(RAIL, WIDE - 2.0 * RAIL, RAIL), Vector3(s * h, 0.0, z)])
	for rail: Array in rails:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = rail[0]
		shape.shape = box
		shape.position = rail[1]
		made.add_child(shape)
	var view := MeshInstance3D.new()
	view.mesh = look
	made.add_child(view)
	for face: StringName in FACES:
		var socket := Socket.new()
		socket.kind = &"face"
		# By meta, since a name changes as it moves into a deck beside another frame's.
		socket.set_meta(&"face", face)
		socket.transform = Transform3D(Catalog._facing(FACES[face][1]), FACES[face][0])
		made.add_child(socket)


## Its face sockets, by name, wherever they live now.
func faces() -> Dictionary:
	var out := {}
	for node in (socket.fitted if socket != null else get_children()):
		var each := node as Socket
		if each != null and each.kind == &"face":
			out[each.get_meta(&"face")] = each
	return out


## Whether a face takes a part: a whole-face part, of its kind.
static func takes(part: Part) -> bool:
	return part.kind in TAKES


## Where a piece joined on a face sits, in the face's frame: its underside on
## the face, its top facing out.
static func piece_seat() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, 0.0, Chassis.THICK * 0.5))
