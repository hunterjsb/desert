class_name Settings
extends RefCounted
## The options on this machine: volume, the main menu's music, a few
## graphics settings and the dev console's size. Kept in their own small file, apart from the profile
## and the run, and written only when someone changes one.

## Where they're kept; probes and look-tests point it at a folder of their own.
static var path := "user://settings.cfg"
const SCALES: Array[float] = [0.5, 0.75, 1.0]
## How finely the 3D view is drawn: its edges, glow, contact shade and the
## sun's shadows. The look is the same at each; low draws as the game did
## before there was a choice, and medium holds frame time on modest hardware.
const QUALITIES: Array[StringName] = [&"low", &"medium", &"high"]
## Each quality's drawing: MSAA samples and screen-space AA (thin rope and
## louvres crawl without), glow (in a storm the camp reads by its emissives),
## ambient occlusion, and the sun's shadow filter.
const DRAWN := {
	&"low": {"msaa": Viewport.MSAA_DISABLED, "aa": Viewport.SCREEN_SPACE_AA_DISABLED, "glow": false,
		"ao": false, "filter": RenderingServer.SHADOW_QUALITY_SOFT_LOW},
	&"medium": {"msaa": Viewport.MSAA_DISABLED, "aa": Viewport.SCREEN_SPACE_AA_SMAA, "glow": true,
		"ao": false, "filter": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM},
	&"high": {"msaa": Viewport.MSAA_4X, "aa": Viewport.SCREEN_SPACE_AA_SMAA, "glow": true,
		"ao": true, "filter": RenderingServer.SHADOW_QUALITY_SOFT_HIGH},
}
## The WorldEnvironments a quality dresses, so a change reaches the world in play.
const DRAWN_GROUP := &"quality_drawn"

static var volume := 1.0
## The main menu's music, which its switch mutes.
static var music := true
## The weather station's voice reading its reports from the radio: a switch,
## since a voice out of nowhere can startle.
static var radio_voice := true
static var fullscreen := false
static var vsync := true
## The 3D view's resolution, as a share of the window's.
static var render_scale := 1.0
## One of QUALITIES.
static var quality := &"medium"
## The dev console as it was last resized, px; none, its own first size.
static var console_size := Vector2.ZERO


static func load_saved() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	volume = clampf(file.get_value("audio", "volume", volume), 0.0, 1.0)
	music = file.get_value("audio", "music", music)
	radio_voice = file.get_value("audio", "radio_voice", radio_voice)
	fullscreen = file.get_value("graphics", "fullscreen", fullscreen)
	vsync = file.get_value("graphics", "vsync", vsync)
	render_scale = file.get_value("graphics", "render_scale", render_scale)
	var saved: StringName = StringName(file.get_value("graphics", "quality", quality))
	quality = saved if saved in QUALITIES else quality
	console_size = file.get_value("dev", "console_size", console_size)


static func save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "volume", volume)
	file.set_value("audio", "music", music)
	file.set_value("audio", "radio_voice", radio_voice)
	file.set_value("graphics", "fullscreen", fullscreen)
	file.set_value("graphics", "vsync", vsync)
	file.set_value("graphics", "render_scale", render_scale)
	file.set_value("graphics", "quality", String(quality))
	file.set_value("dev", "console_size", console_size)
	file.save(path)


static func apply(window: Window) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	window.scaling_3d_scale = render_scale
	draw(window)
	if DisplayServer.get_name() == "headless":
		return
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if full != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


## The quality on the window, the sun's shadows, and every world drawing in it.
static func draw(window: Window) -> void:
	var drawn: Dictionary = DRAWN[quality]
	window.msaa_3d = drawn.msaa
	window.screen_space_aa = drawn.aa
	RenderingServer.directional_soft_shadow_filter_set_quality(drawn.filter)
	for node in window.get_tree().get_nodes_in_group(DRAWN_GROUP):
		dress((node as WorldEnvironment).environment)


## The quality's share of a world's environment: its glow and ambient occlusion.
static func dress(environment: Environment) -> void:
	environment.glow_enabled = DRAWN[quality].glow
	environment.ssao_enabled = DRAWN[quality].ao
