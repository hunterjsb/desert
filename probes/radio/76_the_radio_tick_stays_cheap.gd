extends ShieldProbe
## Radio probe 76: the radio's tick stays cheap. It reads the gods, the sky,
## the weather and the ground every physics tick on the main thread, so a set
## left playing must cost little whatever it's tuned to: on the weather, on
## a far god and on shortwave under the satellites.
## Runs alone

## The most a tick may cost on average, µs (on the weather it cost 1340 before
## its lookups were cached, 2026-10-22); and the ticks timed on each.
const BUDGET_US := 900.0
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
	radio.channel = Radio.WEATHER
	check(await _cost(radio, "Port Morgan Tower") < BUDGET_US, "cheap on the weather")
	var far: Array = Gods.ids().filter(func(id: StringName) -> bool: return not Fm.is_god(id))
	while radio.band != Radio.AM_BAND and radio.switch_band():
		pass
	radio.frequency = gods.carrier(far[0], world.time)
	check(await _cost(radio, "a far god") < BUDGET_US, "cheap on a god")
	while radio.band != Radio.SW_BAND and radio.switch_band():
		pass
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
