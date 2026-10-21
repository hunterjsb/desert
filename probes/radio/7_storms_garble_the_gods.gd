extends ShieldProbe
## Radio probe 7: storms garble the gods. Tuned to the strongest god on the
## dial under clear skies, the set broadside to it, what it says comes through whole, never cut, its
## carrier where it belongs. With a storm all along the way, the same god is
## distorted, its carrier slides off where you tuned, and it drops out part
## of the time, and the static under it rises.

## Moments sampled, s apart.
const SAMPLES := 200
const EVERY := 0.7


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var gods := Radio.gods_of(world)
	var t0 := world.time
	var best := &""
	var strongest := 0.0
	for id in Gods.ids():
		radio.frequency = gods.carrier(id, t0)
		var heard := radio.receive(id, x, z, t0)
		var got: float = heard.strength / maxf(heard.rod, 1e-4)
		if got > strongest:
			strongest = got
			best = id
	broadside(radio, best)
	radio.on = true
	radio.frequency = gods.carrier(best, t0)
	var clear := _listen(radio, best, x, z, t0)
	print("%s at %d kHz, clear skies: %s" % [Gods.title(best), roundi(radio.frequency), clear])
	check(clear.whole == SAMPLES and clear.cuts == 0 and clear.slid == 0.0,
		"under clear skies it comes through whole, never cut, never sliding")
	await physics_frames(3)
	var quiet := radio.hiss.volume_db

	weather_everywhere(1.0)
	await physics_frames(3)
	var stormy := _listen(radio, best, x, z, t0)
	print("in a storm: %s; the line says \"%s\"" % [stormy, radio.said])
	check(stormy.whole < SAMPLES / 4, "in a storm what it says is distorted (%d of %d whole)" % [stormy.whole, SAMPLES])
	check(stormy.cuts > SAMPLES / 10 and stormy.cuts < SAMPLES, "it drops out part of the time (%d of %d)"
		% [stormy.cuts, SAMPLES])
	check(stormy.slid > 1.0, "its carrier slides off where you tuned (up to %.1f kHz)" % stormy.slid)
	check(radio.hiss.volume_db > quiet + 3.0, "and the static rises (%.0f dB from %.0f)" % [radio.hiss.volume_db, quiet])


## How a god comes through over the samples: lines whole, cuts, and the
## farthest its carrier slid, kHz.
func _listen(radio: Radio, id: StringName, x: float, z: float, from: float) -> Dictionary:
	var whole := 0
	var cuts := 0
	var slid := 0.0
	for i in SAMPLES:
		var heard := radio.receive(id, x, z, from + i * EVERY)
		if heard.cut:
			cuts += 1
		elif heard.text == heard.words:
			whole += 1
		slid = maxf(slid, absf(heard.warp))
	return {"whole": whole, "cuts": cuts, "slid": slid}
