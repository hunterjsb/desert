class_name ItemIcons
extends RefCounted
## A thing's look as a small picture, for a card in a menu: its frame and
## what's fitted, in Dress's paint, drawn once in a little world of its own
## and kept. Asked before it's drawn, the picture is blank and fills in a
## frame or two later; with no screen to draw on, it stays blank.

## Each picture's thing: a catalog frame and what fills its sockets by their
## place in its list, or a part alone; then how it's turned to be seen,
## degrees about the up axis and down from level.
const LOOKS := {
	&"board": {"frame": &"board", "turn": Vector2(30.0, 50.0)},
	&"shield": {"frame": &"shield", "turn": Vector2(35.0, 25.0)},
	&"crop": {"part": &"root_tuber", "turn": Vector2(30.0, 20.0)},
	&"planter": {"frame": &"planter", "sockets": {0: &"root_tuber", 1: &"root_tuber", 2: &"saltbush", 3: &"vat_fungus"},
		"turn": Vector2(25.0, 35.0)},
	&"chassis": {"frame": &"chassis", "turn": Vector2(30.0, 40.0)},
	&"console": {"frame": &"console", "sockets": {1: &"screen"}, "turn": Vector2(155.0, 15.0)},
	&"turbine": {"frame": &"turbine", "turn": Vector2(30.0, 15.0)},
	&"helm": {"frame": &"helm_seat", "turn": Vector2(150.0, 20.0)},
	&"compass": {"part": &"compass", "turn": Vector2(0.0, 55.0)},
	&"cutter": {"frame": &"cutter", "turn": Vector2(60.0, 25.0)},
	&"survival_kit": {"frame": &"survival_kit", "turn": Vector2(30.0, 30.0)},
	&"sealant": {"part": &"sealant", "turn": Vector2(30.0, 25.0)},
	&"radio": {"frame": &"radio", "turn": Vector2(160.0, 15.0)},
	&"bedroll": {"frame": &"bedroll", "turn": Vector2(40.0, 30.0)},
}
## Pixels a side.
const SIZE := 128

static var _made := {}


static func of(tree: SceneTree, id: StringName) -> Texture2D:
	if not _made.has(id):
		var picture := ImageTexture.create_from_image(Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8))
		_made[id] = picture
		if DisplayServer.get_name() != "headless":
			_draw(tree, id, picture)
	return _made[id]


## Drawn in a viewport of its own, once, then let go.
static func _draw(tree: SceneTree, id: StringName, picture: ImageTexture) -> void:
	var port := SubViewport.new()
	port.size = Vector2i(SIZE, SIZE)
	port.own_world_3d = true
	port.transparent_bg = true
	port.render_target_update_mode = SubViewport.UPDATE_ONCE
	var thing := _thing(LOOKS[id])
	port.add_child(thing)
	var box := _bounds(thing)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 40.0, 0.0)
	port.add_child(light)
	var air := WorldEnvironment.new()
	air.environment = Environment.new()
	air.environment.background_mode = Environment.BG_CLEAR_COLOR
	air.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	air.environment.ambient_light_color = Color(0.75, 0.75, 0.78)
	air.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	port.add_child(air)
	var eye := Camera3D.new()
	eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	eye.size = box.size.length() * 1.05
	var turn: Vector2 = LOOKS[id].turn
	var back := Basis(Vector3.UP, deg_to_rad(turn.x)) * Basis(Vector3.RIGHT, -deg_to_rad(turn.y))
	eye.transform = Transform3D(back, box.get_center() + back.z * box.size.length() * 2.0)
	port.add_child(eye)
	tree.root.add_child.call_deferred(port)
	for i in 3:
		await tree.process_frame
	var image := port.get_texture().get_image()
	if image != null and not image.is_empty():
		picture.set_image(image)
	port.queue_free()


## The thing's look alone: its frame's mesh, a rotor if it has one, and the
## looks of what's fitted, each where its socket holds it.
static func _thing(spec: Dictionary) -> Node3D:
	var thing := Node3D.new()
	if spec.has("part"):
		_part(thing, spec.part, Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO))
		return thing
	var frame: Dictionary = Catalog.DEVICES[spec.frame]
	var size: Vector3 = frame.size
	_mesh(thing, Dress.frame(spec.frame, size, frame.get("mast", 0.0)), Transform3D.IDENTITY)
	if frame.has("mast"):
		_mesh(thing, Dress.rotor(spec.frame), Transform3D(Basis(), Vector3(0.0, size.y * 0.5 + frame.mast, 0.0)))
	var sockets: Dictionary = spec.get("sockets", {})
	for k: int in sockets:
		var entry: Array = frame.sockets[k]
		_part(thing, sockets[k], Transform3D(Catalog._facing(entry[2]), entry[1]))
	return thing


## A part as it stands in its socket: a crop grown, anything else standing
## out along the socket's +Z.
static func _part(on: Node3D, id: StringName, socket: Transform3D) -> void:
	var spec: Dictionary = Catalog.PARTS[id]
	if spec.has("crop"):
		_mesh(on, Dress.crop(id, Plant.MATURE), socket)
	else:
		var size: Vector3 = spec.size
		_mesh(on, Dress.part(id, size), socket * Transform3D(Basis(), Vector3(0.0, 0.0, size.z * 0.5)))


static func _mesh(on: Node3D, mesh: Mesh, pose: Transform3D) -> void:
	if mesh == null:
		return
	var look := MeshInstance3D.new()
	look.mesh = mesh
	look.transform = pose
	on.add_child(look)


static func _bounds(thing: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for look: MeshInstance3D in thing.get_children():
		var each := look.transform * look.mesh.get_aabb()
		box = each if first else box.merge(each)
		first = false
	return box
