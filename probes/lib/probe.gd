class_name Probe
extends Node
## Base for headless probes. Override run(), call check(), and the verdict line
## at the end is what scripts/probe.sh reads. Every probe runs on a fixed seed.

var _failures := PackedStringArray()


func _ready() -> void:
	seed(probe_seed())
	await run()
	_finish()


## Override for a different fixed seed; never randomise it.
func probe_seed() -> int:
	return 1


## The probe body. May await.
func run() -> void:
	pass


func check(condition: bool, what: String) -> void:
	if not condition:
		_failures.append(what)
		printerr("CHECK FAILED: ", what)


func physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Checks every probe of a kind makes before its verdict.
func before_finish() -> void:
	pass


func _finish() -> void:
	before_finish()
	var probe_name := (get_script() as Script).resource_path
	if _failures.is_empty():
		print("PROBE PASS ", probe_name)
		get_tree().quit(0)
	else:
		print("PROBE FAIL ", probe_name, " (%d failed checks)" % _failures.size())
		get_tree().quit(1)
