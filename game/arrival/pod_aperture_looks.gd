class_name PodApertureLooks
extends RefCounted
## A double-glazed tail panel; the opaque rim leaves a real opening through it.

# Tail-local X is vertical and Z is across the seated view.
const OPENING := Vector2(0.56, 0.68)
static var _frame: ArrayMesh
static var _glass: BoxMesh

static func frame() -> ArrayMesh:
	if _frame != null:
		return _frame
	var b := Paint.Pieces.new()
	var metal := Paint.coat(Paint.GUNMETAL)
	var bone := Paint.coat(Paint.BONE)
	var rubber := Paint.coat(Paint.BLACK)
	var yellow := Paint.coat(Paint.YELLOW)
	var teal := Paint.coat(Paint.TEAL)
	# Four full-depth rim pieces retain the ordinary panel's outside dimensions.
	for side in [-1.0, 1.0]:
		b.box(Vector3((1.0 - OPENING.x) * 0.5, 0.12, 1.0),
			Vector3(side * (1.0 + OPENING.x) * 0.25, 0, 0), metal, 0.008)
		b.box(Vector3(OPENING.x, 0.12, (1.0 - OPENING.y) * 0.5),
			Vector3(0, 0, side * (1.0 + OPENING.y) * 0.25), metal, 0.008)
		for face in [-1.0, 1.0]:
			b.box(Vector3(0.15, 0.012, 0.87), Vector3(side * 0.40, face * 0.061, 0), bone, 0.006)
			b.box(Vector3(0.56, 0.012, 0.085), Vector3(0, face * 0.061, side * 0.41), teal, 0.005)
			# Continuous dark glazing gaskets outline the aperture on both faces.
			b.box(Vector3(0.016, 0.014, OPENING.y + 0.032),
				Vector3(side * (OPENING.x * 0.5 + 0.008), face * 0.056, 0), rubber, 0.002)
			b.box(Vector3(OPENING.x, 0.014, 0.016),
				Vector3(0, face * 0.056, side * (OPENING.y * 0.5 + 0.008)), rubber, 0.002)
			for across in [-1.0, 1.0]:
				b.box(Vector3(0.04, 0.016, 0.06), Vector3(side * 0.40, face * 0.07, across * 0.37), yellow, 0.004)
	_frame = b.commit()
	return _frame


static func glass() -> BoxMesh:
	if _glass == null:
		_glass = BoxMesh.new()
		_glass.size = Vector3(OPENING.x + 0.016, 0.006, OPENING.y + 0.016)
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.36, 0.58, 0.63, 0.045)
		material.roughness = 0.18
		material.metallic = 0.0
		_glass.material = material
	return _glass
