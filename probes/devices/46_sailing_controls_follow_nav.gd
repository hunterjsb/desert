extends SailingAidProbe
## Hiding Nav hides its advice and controls without changing an engaged drum.

func run() -> void:
	await aid_rig()
	var shown := computer._model(Console.Page.MAP, computer.pooled_readings())
	check(shown.has("chart") and shown.chart.has("sailing") and not shown.chart.sailing.is_empty(),
		"the sailing deck's wind reader feeds actual and ideal rig marks to Nav")
	var camp := Scenarios.rig_at(world, [
		[&"stick", Vector2i.ZERO, &"top", Vector2(-0.2, 0.0), 0.0, &"home_beacon", &"beacon"],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0.25, 0.0), 0.0, &"battery"]], [25.0, 25.0], false)
	check(world.home.mark(camp.named.beacon) == "", "a separate physical camp is marked Home")
	await physics_frames(30)
	_press(&"sail_home")
	var relative: Vector3 = camp.deck.global_position - world.player.global_position
	check(computer.sailing.home and computer.sailing.target(computer).dot(Vector2(relative.x, relative.z).normalized()) > 0.95,
		"the Home control points the recommendation toward the real camp fix")
	_press(&"sail_course")
	check(not computer.sailing.home, "the course control returns to a held heading")
	_press(&"sail_control")
	check(computer.sailing.mode == SailingAid.Mode.TRIM, "the Map's control key engages the physical sheet drum")
	_press("nav")
	shown = computer._model(Console.Page.MAP, computer.pooled_readings())
	check(not shown.has("chart") and not shown.has("sail_keys") and computer.sailing.mode == SailingAid.Mode.TRIM,
		"Nav off hides its marks and keys while the engaged drum keeps its command")
	_press("nav")
	check(computer._model(Console.Page.MAP, computer.pooled_readings()).has("sail_keys"), "Nav on restores its controls")
	drum.take(drum.frame_sockets()[0])
	await physics_frames(4)
	check(computer.sailing.mode == SailingAid.Mode.HAND and computer.sailing.winch(computer) == null,
		"disconnecting the sheet releases computer control")


func _press(to: Variant) -> void:
	for key: Dictionary in computer.keys(Console.Page.MAP):
		if str(key.to) == str(to):
			computer.press((key.box as Rect2).get_center() / Vector2(Console.PIXELS))
			return
	check(false, "the Map exposes its requested control")
