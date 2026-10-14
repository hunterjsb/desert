extends Node
## Loads the probe script named after "--" on the command line and runs it.
## A probe that won't load fails here at once instead of hanging: a script that
## fails to parse never calls quit(), which would look exactly like a slow run.


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		_fail("no probe given; pass its res:// path after --")
		return
	var script: Script = load(args[0])
	if script == null or not script.can_instantiate():
		_fail("could not load %s" % args[0])
		return
	var probe: Node = script.new()
	if not (probe is Probe):
		probe.free()
		_fail("%s does not extend Probe" % args[0])
		return
	add_child(probe)


func _fail(why: String) -> void:
	printerr(why)
	print("PROBE FAIL host")
	get_tree().quit(1)
