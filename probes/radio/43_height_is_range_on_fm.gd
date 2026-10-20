extends WeatherProbe
## Radio probe 43: on FM, height is range. Beside Port Morgan its station
## comes through quiet; far off on the ground it's lost behind the moon's
## curve; at that same place lifted high it's back, line of sight again.
## Time limit: 600 s.

## How far from the port's middle each spot stands, m, toward Tu, and how
## high the far one is lifted, m.
const NEAR := 800.0
const FAR := 9000.0
const LIFT := 2500.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var near := await _heard_at(NEAR, 1.5)
	print("beside the port, %.0f m: margin %.1f dB" % [NEAR, near.margin])
	check(near.quiet >= Radio.WHOLE, "beside the port its station comes through quiet")
	var low := await _heard_at(FAR, 1.5)
	print("%.0f m off on the ground: margin %.1f dB" % [FAR, low.margin])
	check(low.heard <= 0.0, "far off on the ground it's lost behind the curve")
	var high := await _heard_at(FAR, LIFT)
	print("%.0f m off, %.0f m up: margin %.1f dB" % [FAR, LIFT, high.margin])
	check(high.quiet >= Radio.WHOLE, "lifted high there it comes through quiet again")


## What a radio tuned to the port's station hears `beside` m from the port
## toward Tu, `up` m over the ground.
func _heard_at(beside: float, up: float) -> Dictionary:
	var history := world.shape.history
	var port: Vector3 = history.landmark(&"port_morgan").p
	var at := Sphere.toward(port, Sphere.bearing(port, history.sub_tu), beside / history.radius)
	world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
	await settle()
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	radio.global_position.y = world.height_at(x, z) + up
	radio.switch_band()
	radio.interact(world.player)
	await physics_frames(2)
	var heard := radio.receive_fm(x, z, world.time)
	radio.free()
	return heard
