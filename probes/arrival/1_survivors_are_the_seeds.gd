extends Probe
## Global random calls cannot reroll the resolved opening.
func run() -> void:
	var point := Sphere.point(0.2, -0.3)
	var first := SurveyorManifest.resolve(1234, point)
	for i in 100:
		randi()
	var again := SurveyorManifest.resolve(1234, point)
	check(first == again and first.landing_point == point, "the same seed and landing give the same resolved opening")
	var other := SurveyorManifest.resolve(7, point)
	check(first.equipment != other.equipment and first.cargo_order != other.cargo_order, "another seed changes equipment condition and stowage")
