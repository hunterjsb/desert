extends ShieldProbe
## Power probe 6: thirty minutes. A base shield with a full base battery,
## switched on in the worst storm, holds its bubble for about thirty minutes
## of world time and then collapses. It warns first: in the last
## shield_warning_seconds its hum sags and its shell flickers, and never
## before. Its own charge light reads full at the start and dark at the end.


func run() -> void:
	await load_storm(1.0, 15.0)
	var tuning := Tuning.current()
	var generator := shield_at(ahead(4.0), false)
	# A power tick or two, so its light shows the battery.
	await physics_frames(40)
	var green := _shown(generator)
	check(generator.interact(world.player), "F switches it on")
	var start := world.time
	var at := {}
	var flickers: Array[float] = []
	var sags: Array[float] = []
	await live(45.0 * 60.0, 60.0, func() -> void:
		if not generator.running() and not at.has("fell"):
			at["fell"] = world.time - start
		if not at.has("fell"):
			if generator.shelter.glow < 1.0:
				flickers.append(world.time - start)
			if generator.hum.pitch_scale < ShieldGenerator.HUM_PITCH - 0.01:
				sags.append(world.time - start))
	var fell: float = at.get("fell", INF)
	var lasted := fell / 60.0
	print("lasted %.2f min; %d flickers from %.0f s, hum sagging from %.0f s; light %s then %s"
		% [lasted, flickers.size(), flickers.min() if flickers.size() > 0 else -1.0,
			sags.min() if sags.size() > 0 else -1.0, green, _shown(generator)])
	check(lasted > 27.0 and lasted < 33.0, "a full base shield lasted about thirty minutes in a storm (%.2f)" % lasted)
	var warned_from := fell - tuning.shield_warning_seconds - 1.0
	check(flickers.size() > 10 and flickers.min() >= warned_from, "the shell flickered, only near the end")
	check(sags.size() > 10 and sags.min() >= warned_from, "the hum sagged, only near the end")
	check(green.g > 0.9 and green.r < 0.5, "its light read full at the start")
	check(_shown(generator).v < 0.15, "and dark at the end")
	check(generator.shelter.radius == 0.0, "the bubble is down")


func _shown(device: Device) -> Color:
	return ((device.charge_light.mesh as BoxMesh).material as StandardMaterial3D).albedo_color
