extends Probe
## Resuming a saved impact samples its remaining recoil, never starts another jolt.

func run() -> void:
	var tuning := Tuning.current()
	var effects := ArrivalImpactEffects.new()
	add_child(effects)
	effects.setup(tuning)
	var aperture := Rect2(0.25, 0.18, 0.5, 0.55)
	var duration := float(tuning.surveyor_arrival.impact_jolt_s)
	var state := {"phase": &"landing", "elapsed": duration * 0.25, "progress": 0.1}
	var saved := state.duplicate(true)
	effects.present(state, aperture)
	var offset := effects.camera_offset
	var rotation := effects.camera_rotation
	check(offset.length() > 0.0 and rotation.length() > 0.0, "impact has a brief actual camera recoil")
	for step in 101:
		state.elapsed = duration * step / 100.0
		effects.present(state, aperture)
		check(effects.camera_offset.length() <= float(tuning.surveyor_arrival.impact_offset_m) + 0.000001
			and effects.camera_rotation.length() <= deg_to_rad(float(tuning.surveyor_arrival.impact_tilt_deg)) + 0.000001,
			"recoil never exceeds configured movement limits")
	var resumed := ArrivalImpactEffects.new()
	add_child(resumed)
	resumed.setup(tuning)
	resumed.present(saved, aperture)
	check(resumed.camera_offset == offset and resumed.camera_rotation == rotation and saved.elapsed == duration * 0.25,
		"restored saved phase samples the same recoil without mutating elapsed time")
	saved.elapsed = duration + 0.1
	resumed.present(saved, aperture)
	check(resumed.camera_offset == Vector3.ZERO and resumed.camera_rotation == Vector3.ZERO,
		"late impact restore has no fresh jolt")
	resumed.present({"phase": &"recovery"}, aperture)
	check(not resumed.visible and resumed.camera_offset == Vector3.ZERO and resumed.camera_rotation == Vector3.ZERO,
		"recovery releases the presentation completely")
