extends ShieldProbe
## Radio probe 46: a long wire. On shortwave, on its converter's terminals
## alone, a satellite overhead comes through chewed up; an antenna reel clipped
## to the radio and its wire strung out, it comes through cleaner, as a real
## shortwave set hears better on a long wire.

## How far off the reel stands, m.
const OUT := 10.5


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.switch_band()
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var sky := Radio.constellation_of(world)
	var overhead := sky.carriers(radio.point_at(x, z), world.time)
	check(radio.band == Radio.SW_BAND and not overhead.is_empty(), "on shortwave, a satellite overhead")
	if overhead.is_empty():
		return
	var id: StringName = overhead[0][1]
	radio.frequency = overhead[0][0]
	await physics_frames(40)
	var bare: Dictionary = radio.receive_from(sky.orbits[id], radio.frequency, id, x, z, world.time)
	_reel_out(radio, OUT)
	await physics_frames(40)
	var strung: Dictionary = radio.receive_from(sky.orbits[id], radio.frequency, id, x, z, world.time)
	print("the %s: dirt %.2f on its terminals; on %.1f m of wire, %.1f m up at most, %.2f" % [id, bare.dirt,
		radio.wire.x, radio.wire.y, strung.dirt])
	check(radio.wire.x >= Tuning.current().sw_wire_m, "the reel's wire is its long wire")
	check(strung.dirt < bare.dirt - 0.2, "on a long wire it comes through cleaner")


## An antenna reel stood `out` m off a radio, its wire clipped to the set.
func _reel_out(radio: Radio, out: float) -> AntennaReel:
	var reel := Scenarios.standing(world, &"antenna_reel", [], [0.0, 2.0]) as AntennaReel
	reel.freeze = true
	reel.global_position = radio.global_position + Vector3(out, 0.0, 0.0)
	reel.clip(radio)
	return reel
