class_name InventoryLook
extends SubViewport
## Something you carry, drawn as itself for the inventory view: its own meshes
## in its own paint, under a clear day's sun and sky as the world has them. It
## draws only when told, once each time, so a full view costs nothing while
## what you carry stays as it was; a compass draws again only as its needle
## turns.

## How it's turned to the camera, degrees about its up and then across: from
## a little above and to one side, as you'd look at it in your hand; a
## compass nearly straight on, to read.
const VIEW := Vector2(-35.0, 22.0)
const READ := Vector2(0.0, 10.0)
## The camera's field of view, degrees, and the room left round the thing.
const FOV := 30.0
const ROOM := 1.08
## The needle turns this far, rad, before it's drawn again.
const NEEDLE_STEP := 0.004
const PARAMS: Array[StringName] = [&"age", &"era", &"lit"]

## What it shows now, and what it showed it by (Suit), to draw again only
## when that changes.
var shown: RigidBody3D
var key := []
## The copy of a compass's needle, or null.
var needle: MeshInstance3D
## How many times it has been drawn, for measuring what it costs.
var draws := 0

var _model := Node3D.new()
var _camera := Camera3D.new()
var _angle := NAN


func _init(pixels: Vector2i) -> void:
	size = pixels
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	var tuning := Tuning.current()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_CLEAR_COLOR
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Weather.AMBIENT_COLOR
	sky.ambient_light_energy = tuning.sky_fill
	sky.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	sky.tonemap_exposure = tuning.exposure
	var surround := WorldEnvironment.new()
	surround.environment = sky
	add_child(surround)
	var sun := DirectionalLight3D.new()
	sun.light_color = Weather.SUN_COLOR
	# From high over your left shoulder.
	sun.basis = Basis.looking_at(Vector3(0.45, -0.75, -0.5))
	add_child(sun)
	_camera.fov = FOV
	add_child(_camera)
	add_child(_model)


## Draws `thing` as it is now, once; nothing for nothing.
func show_thing(thing: RigidBody3D) -> void:
	for copy in _model.get_children():
		copy.free()
	shown = thing
	needle = null
	_angle = NAN
	if thing == null:
		return
	var box := AABB()
	var first := true
	for look: MeshInstance3D in thing.find_children("*", "MeshInstance3D", true, false):
		if not _seen(look, thing):
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = look.mesh
		copy.material_override = look.material_override
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if Paint.is_worn(look):
			for param in PARAMS:
				copy.set_instance_shader_parameter(param, look.get_instance_shader_parameter(param))
		copy.transform = _within(thing, look)
		_model.add_child(copy)
		if thing is Compass and look == (thing as Compass).needle:
			needle = copy
		var each := copy.transform * look.get_aabb()
		box = each if first else box.merge(each)
		first = false
	var view := READ if thing is Compass else VIEW
	var turn := Basis(Vector3.RIGHT, deg_to_rad(view.y)) * Basis(Vector3.UP, deg_to_rad(view.x))
	_model.transform = Transform3D(turn, -(turn * box.get_center()))
	var reach := box.size.length() * 0.5 * ROOM
	_camera.position = Vector3(0.0, 0.0, reach / sin(deg_to_rad(FOV * 0.5)))
	_camera.near = maxf(_camera.position.z - reach * 2.0, 0.01)
	_camera.far = _camera.position.z + reach * 2.0
	_render()


## Turns the compass's needle to `angle`, rad clockwise from its card's
## top, and draws it again if it moved.
func turn_needle(angle: float) -> void:
	if needle == null or absf(angle_difference(angle, _angle)) < NEEDLE_STEP:
		return
	_angle = angle
	needle.transform = Compass.pose(angle)
	_render()


func _render() -> void:
	render_target_update_mode = SubViewport.UPDATE_ONCE
	draws += 1


## Shown in the world: nothing between it and the thing is hidden, as a
## socket's tell is once the socket's full.
static func _seen(node: Node, thing: Node) -> bool:
	while node != thing:
		var spatial := node as Node3D
		if spatial != null and not spatial.visible:
			return false
		node = node.get_parent()
	return true


## A node's pose in the thing's own frame, worked out from its parents: a
## stowed thing is off the tree, where nothing has a global pose.
static func _within(thing: Node, node: Node3D) -> Transform3D:
	var pose := node.transform
	var at := node.get_parent()
	while at != thing:
		pose = (at as Node3D).transform * pose
		at = at.get_parent()
	return pose
