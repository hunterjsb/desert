extends ShieldProbe
## Radio probe 56: the radio's tick stays cheap. It reads the gods, the sky,
## the weather and the ground every physics tick on the main thread, so a set
## left playing must cost little whatever it's tuned to: on the weather
## station, on a god, on shortwave under the satellites and on FM.
## Runs alone

## The most a tick may cost on average, µs (on the weather station it cost
## 1340 before its lookups were cached, 2026-10-22); and the ticks timed on each.
const BUDGET_US := 700.0
const TICKS := 240


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter", &"fm_converter"],
		[0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	# Only the probe's own calls run its tick, so each is timed alone.
	radio.set_physics_process(false)
	var gods := Radio.gods_of(world)
	radio.frequency = gods.carrier(&"walker", world.time)
	check(await _cost(radio, "the weather station") < BUDGET_US, "cheap on the weather station")
	radio.frequency = gods.carrier(&"quartermaster", world.time)
	check(await _cost(radio, "a god") < BUDGET_US, "cheap on a god")
	radio.switch_band()
	check(radio.band == Radio.FM_BAND and await _cost(radio, "FM") < BUDGET_US, "cheap on FM")
	radio.switch_band()
	var p := radio.point_at(world.world_x(radio.global_position.x), world.world_z(radio.global_position.z))
	var up := Radio.constellation_of(world).carriers(p, world.time)
	radio.frequency = up[0][0] if not up.is_empty() else Shortwave.LOWEST
	check(radio.band == Radio.SW_BAND and await _cost(radio, "shortwave") < BUDGET_US, "cheap on shortwave")


## Its mean tick on what it's tuned to now, µs, over TICKS physics frames.
func _cost(radio: Radio, on: String) -> float:
	var spent := 0
	var most := 0
	for i in TICKS:
		await physics_frames(1)
		var from := Time.get_ticks_usec()
		radio._listen(1.0 / Engine.physics_ticks_per_second)
		var took := Time.get_ticks_usec() - from
		spent += took
		most = maxi(most, took)
	var mean := float(spent) / TICKS
	print("%s: %.0f µs a tick on average, %d µs at most" % [on, mean, most])
	return mean
