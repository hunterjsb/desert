extends Probe
## Saved phase time gives bounded smooth movement without an accumulated random walk.
func run() -> void:
	var tuning := Tuning.current()
	var effects := ArrivalImpactEffects.new()
	add_child(effects)
	effects.setup(tuning)
	for phase in [&"ejection", &"descent", &"entry"]:
		for step in 101:
			var state := {"phase": phase, "elapsed": step * 0.03, "progress": step / 100.0}
			effects.present(state, Rect2())
			var at := effects.camera_offset
			var rotation := effects.camera_rotation
			effects.present(state, Rect2())
			check(effects.camera_offset == at and effects.camera_rotation == rotation
				and at.length() <= tuning.arrival_sway_m + 0.000001
				and rotation.length() <= deg_to_rad(tuning.arrival_sway_deg) + 0.000001,
				"each saved flight sample is repeatable and within configured motion bounds")
		for progress in [0.0, 1.0]:
			effects.present({"phase": phase, "elapsed": 3.0 * progress, "progress": progress}, Rect2())
			check(effects.camera_offset.length() < 0.000001 and effects.camera_rotation.length() < 0.000001,
				"phase boundaries have no sudden residual shake")
