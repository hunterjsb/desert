class_name Settings
extends RefCounted
## The options on this machine: volume and a few graphics settings. Kept in
## their own small file, apart from the profile and the run, and written only
## when someone changes one.

## Where they're kept; probes and look-tests point it at a folder of their own.
static var path := "user://settings.cfg"
const SCALES: Array[float] = [0.5, 0.75, 1.0]

static var volume := 1.0
static var fullscreen := false
static var vsync := true
## The 3D view's resolution, as a share of the window's.
static var render_scale := 1.0


static func load_saved() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	volume = clampf(file.get_value("audio", "volume", volume), 0.0, 1.0)
	fullscreen = file.get_value("graphics", "fullscreen", fullscreen)
	vsync = file.get_value("graphics", "vsync", vsync)
	render_scale = file.get_value("graphics", "render_scale", render_scale)


static func save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "volume", volume)
	file.set_value("graphics", "fullscreen", fullscreen)
	file.set_value("graphics", "vsync", vsync)
	file.set_value("graphics", "render_scale", render_scale)
	file.save(path)


static func apply(window: Window) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	window.scaling_3d_scale = render_scale
	if DisplayServer.get_name() == "headless":
		return
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if full != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
