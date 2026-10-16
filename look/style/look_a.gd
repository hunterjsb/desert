extends "res://look/style/look.gd"
## A: Sand Game's own models, as they were. It never had a crate, battery,
## hover tray, charger or panel, so those stay grey boxes.

const SHIELD := preload("res://look/style/sandgame/sg3.fbx")
const PLANTER := preload("res://look/style/sandgame/bubbleplanter.fbx")
const POST := preload("res://look/style/sandgame/post01.fbx")
const RUIN := preload("res://look/style/sandgame/ruins01.fbx")


func title() -> String:
	return "A: Sand Game's models"


func frame(id: StringName, size: Vector3) -> Node3D:
	match id:
		&"shield":
			# Modelled lying down; Sand Game stood it up a quarter turn.
			return _fit(SHIELD, Vector3(size.x, size.y, size.z) * 1.15, Basis(Vector3.RIGHT, -PI / 2.0), -size.y * 0.5)
		&"planter":
			# Its dome planter, as wide as the frame is deep.
			return _fit(PLANTER, Vector3.ONE * size.x * 0.9, Basis.IDENTITY, -size.y * 0.5)
	return null


## Its tether post, at about the height Sand Game stood it.
func stake() -> Node3D:
	return _fit(POST, Vector3(0.25, 1.1, 0.25), Basis.IDENTITY, -0.45)


## Its walk-in ruin stands in place of the grey one, as wide as its footprint.
func ruin(view: MeshInstance3D, at: Transform3D) -> void:
	view.visible = false
	var made := _fit(RUIN, Vector3(18.0, 18.0, 12.0), Basis.IDENTITY, -0.1, true)
	view.add_sibling(made)
	made.global_transform = at


## A model scaled evenly to fit a box, its foot `foot` m below the origin.
func _fit(scene: PackedScene, fit: Vector3, turn: Basis, foot: float, footprint := false) -> Node3D:
	var model := scene.instantiate() as Node3D
	var box := _bounds(model, Transform3D(turn, Vector3.ZERO))
	var s := minf(fit.x / box.size.x, fit.z / box.size.z) if footprint \
		else minf(fit.x / box.size.x, minf(fit.y / box.size.y, fit.z / box.size.z))
	var holder := Node3D.new()
	holder.add_child(model)
	model.transform = Transform3D(turn.scaled(Vector3.ONE * s), Vector3.ZERO)
	var centre := box.get_center() * s
	model.position = Vector3(-centre.x, foot - box.position.y * s, -centre.z)
	return holder


static func _bounds(node: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var here := xf * (node as Node3D).transform if node is Node3D else xf
	if node is MeshInstance3D:
		out = here * (node as MeshInstance3D).get_aabb()
		first = false
	for child in node.get_children():
		var b := _bounds(child, here)
		if b.size != Vector3.ZERO:
			out = b if first else out.merge(b)
			first = false
	return out
