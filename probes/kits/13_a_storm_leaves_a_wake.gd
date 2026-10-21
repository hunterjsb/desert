extends Probe
## Calm after a stripping storm leaves time to reach the find; it still reburies.
class PassingStorm extends WeatherField:
	func raw_storm_at(_x: float, _z: float, t: float) -> float:
		return 1.0 if t >= 0 and t < 900 else -1.0
	func dune_shift_at(_x: float, _z: float, _t: float) -> float:
		return 1.0

func run() -> void:
	var tuning := Tuning.current()
	var field := PassingStorm.new(1234, tuning)
	var memo := Exposure.Memo.new()
	var depth := 6.0
	var early := Exposure.taken(field, 0, 0, -60, tuning, memo)
	var wake := Exposure.taken(field, 0, 0, 1500, tuning, memo)
	var later := Exposure.taken(field, 0, 0, 6300, tuning, memo)
	print("storm wake: %.2fm before, %.2fm ten calm minutes later, %.2fm after ninety" % [early, wake, later])
	check(Exposure.level(depth, early) == 0 and Exposure.level(depth, wake) > 0.1
		and Exposure.level(depth, later) == 0, "the cleared weather leaves a temporary reachable find")
