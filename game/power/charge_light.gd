class_name ChargeLight
extends RefCounted
## The one way charge is shown, on batteries and devices alike: green when
## full, amber when low, red when nearly gone, dark when empty.


static func make(size: Vector3) -> MeshInstance3D:
	var light := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var look := StandardMaterial3D.new()
	look.emission_enabled = true
	box.material = look
	light.mesh = box
	return light


static func paint(light: MeshInstance3D, share: float) -> void:
	var look := (light.mesh as BoxMesh).material as StandardMaterial3D
	var color := Color(0.1, 0.1, 0.1)
	if share > 0.5:
		color = Color(0.3, 1.0, 0.35)
	elif share > 0.2:
		color = Color(1.0, 0.7, 0.15)
	elif share > 0.0:
		color = Color(1.0, 0.2, 0.15)
	look.albedo_color = color
	look.emission = color * (1.5 if share > 0.0 else 0.0)
