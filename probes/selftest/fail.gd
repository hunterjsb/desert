extends Probe
## Selftest: must fail on a false check.


func run() -> void:
	check(false, "deliberately false")
