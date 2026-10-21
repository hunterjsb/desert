extends Probe
## Save data keeps the actual arrival and recovery state, without rolling again.
func run() -> void:
	var opening := SurveyorManifest.resolve(1234, Sphere.point(0.2, -0.3))
	opening.phase = &"landed"
	opening.structure[0].recovered = true
	opening.equipment[0].recovered = true
	opening.equipment[0].state.fill_fraction = 0.4
	var resumed: Dictionary = bytes_to_var(var_to_bytes(opening))
	check(resumed == opening, "phase, landing, damage, survivors and recovery round-trip unchanged")
	resumed.equipment[0].state.fill_fraction = 0.2
	check(opening.equipment[0].state.fill_fraction == 0.4, "restored plain data does not alias the earlier manifest")
