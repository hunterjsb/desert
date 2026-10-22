extends ReceiverVisual
## Original meshes and materials, preserved behind the visual scene contract.

const LOOK := preload("res://game/look/survey_receiver_looks.gd")


func _init() -> void:
	shell = _piece(LOOK.frame(), Vector3.ZERO)
	meter = _piece(LOOK.needle(), LOOK.METER_AT)
	tuning = _piece(LOOK.knob(), LOOK.KNOB_AT)
	volume = _piece(LOOK.knob(), LOOK.VOLUME_AT)
	volume.scale = Vector3.ONE * 0.38
	_piece(LOOK.loop(), LOOK.LOOP_AT)
	reading = Marker3D.new()
	reading.name = "Reading"
	reading.position = LOOK.FACE
	add_child(reading)


func _piece(mesh: ArrayMesh, at: Vector3) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = at
	add_child(view)
	painted_meshes.append(view)
	return view


func apply_frame_look(mesh: ArrayMesh) -> void:
	shell.mesh = mesh
