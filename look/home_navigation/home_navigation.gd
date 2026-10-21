extends MenuProbe
## Capture the requested Home view with explicit service fixtures, not a live camp.

class SampleHome extends Node:
	var state := {"marked": true, "supported": true, "live": true, "metres": 482.0, "bearing": PI * 0.25, "status": "Home beacon received"}
	func nav() -> Dictionary:
		return state
	func unmark() -> String:
		return "Return near Home before unmarking"


func run() -> void:
	await open_main(false)
	world.player.set_physics_process(false)
	world.player.camera.rotation_degrees.x = -8.0
	Dev.hide_overlays()
	var out := OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var suit := world.player.suit
	suit.show_view(true)
	await _shot(out, "carry")
	suit._home_view.show_home()
	await _shot(out, "unmarked")
	var sample := SampleHome.new()
	add_child(sample)
	suit._home_view.source = func() -> Object: return sample
	await _shot(out, "live")
	sample.state.live = false
	sample.state.supported = false
	sample.state.metres = 1620.0
	sample.state.status = "Beacon out of range. Navigation uses its last received position."
	await _shot(out, "last_known")
	suit._home_view._forget()
	await _shot(out, "refused")


func _shot(out: String, name: String) -> void:
	await physics_frames(8)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
