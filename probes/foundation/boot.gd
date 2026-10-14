extends Probe
## The project boots the way every later stage assumes: Jolt physics, the Dev
## autoload, the tuning file, and a main scene that loads.


func run() -> void:
	check(ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics",
		"physics engine is Jolt")

	var dev := get_node_or_null("/root/Dev")
	check(dev != null, "Dev autoload is present")
	if dev:
		dev.put("probe/answer", 42)
		check(dev.read("probe/answer") == 42, "Dev reads back what was put")
		check(dev.read("probe/missing", -1) == -1, "Dev returns the default for unknown keys")

	var tuning := Tuning.current()
	check(tuning != null, "tuning file loads")
	if tuning:
		check(Tuning.current() == tuning, "tuning is one shared instance probes can override")

	var main_scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	check(main_scene != null, "main scene loads")
	if main_scene:
		var main := main_scene.instantiate()
		add_child(main)
		await physics_frames(2)
		check(not main.find_children("*", "Camera3D", true, false).is_empty(), "main scene has a camera")
		main.queue_free()
