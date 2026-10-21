class_name Probe
extends Node
## Base for headless probes. Override run(), call check(), and the verdict line
## at the end is what scripts/probe.sh reads. Every probe runs on a fixed seed.

var _failures := PackedStringArray()
## The probe's own folder for saves and the profile, gone when it finishes:
## never the player's own.
var user_dir := OS.get_temp_dir().path_join("sandgame-probe-%d" % OS.get_process_id())


func _ready() -> void:
	seed(probe_seed())
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		var node := get_node_or_null(keeper)
		if node != null:
			node.dir = user_dir
	Settings.path = user_dir.path_join("settings.cfg")
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


## Measurements survive successful runs without publishing the probe's full log.
func metric(label: String, value: float, unit: String, budget: float = -1.0) -> void:
	var sample := {"probe": (get_script() as Script).resource_path.trim_prefix("res://"),
		"name": label, "value": value, "unit": unit}
	if budget >= 0.0:
		sample["budget"] = budget
	print("PROBE_METRIC ", JSON.stringify(sample))


func physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Checks every probe of a kind makes before its verdict.
func before_finish() -> void:
	pass


func _finish() -> void:
	before_finish()
	if DirAccess.dir_exists_absolute(user_dir):
		for file in DirAccess.get_files_at(user_dir):
			DirAccess.remove_absolute(user_dir.path_join(file))
		DirAccess.remove_absolute(user_dir)
	var probe_name := (get_script() as Script).resource_path
	if _failures.is_empty():
		print("PROBE PASS ", probe_name)
		get_tree().quit(0)
	else:
		print("PROBE FAIL ", probe_name, " (%d failed checks)" % _failures.size())
		get_tree().quit(1)
