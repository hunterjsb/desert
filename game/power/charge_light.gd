class_name ChargeLight
extends RefCounted
## The one way charge is shown, on batteries and devices alike: green when
## full, amber when low, red when nearly gone, dark when empty. Every light
## shares one look per state and painting swaps which it wears, so a light
## costs nothing to make: salvage makes many.

const COLORS: Array[Color] = [Color(0.1, 0.1, 0.1), Color(1.0, 0.2, 0.15), Color(1.0, 0.7, 0.15),
	Color(0.3, 1.0, 0.35)]

static var _looks: Array[StandardMaterial3D] = []


static func make(size: Vector3) -> MeshInstance3D:
	var light := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _look(0)
	light.mesh = box
	return light


static func paint(light: MeshInstance3D, share: float) -> void:
	var level := 3 if share > 0.5 else (2 if share > 0.2 else (1 if share > 0.0 else 0))
	var box := light.mesh as BoxMesh
	if box.material != _look(level):
		box.material = _look(level)


static func _look(level: int) -> StandardMaterial3D:
	if _looks.is_empty():
		for i in COLORS.size():
			var look := StandardMaterial3D.new()
			look.emission_enabled = true
			look.albedo_color = COLORS[i]
			look.emission = COLORS[i] * (1.5 if i > 0 else 0.0)
			_looks.append(look)
	return _looks[level]
