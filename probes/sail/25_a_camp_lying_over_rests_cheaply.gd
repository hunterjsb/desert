extends SailProbe
## Runs alone
## A camp a blast has put over rests on its frame edges and masthead together,
## its hinged boom included, at a cost a fast rider's frame never feels.

## What resting over may cost the physics tick, µs: a sixteenth of a 60 Hz frame.
const BUDGET_US := 1000.0


func run() -> void:
	await load_sailing()
	rig(open, heading())
	blow(downwind * 10.0)
	hoist(60.0)
	course = heading()
	tending = deg_to_rad(15.0)
	speed_up(4)
	await sail_for(20.0)
	# The sheet made fast as the gusts come: no one eases it.
	tending = 0.0
	blow(downwind * 12.5)
	await sail_for(3.0)
	blow(downwind * 10.0)
	await sail_for(6.0)
	blow(downwind * 18.0)
	await sail_for(10.0)
	check(heel() > 60.0, "the blast puts it over (%.0f°)" % heel())
	blow(Vector2.ZERO)
	await sail_for(2.0)
	var samples: Array[float] = []
	speed_up(1)
	await sail_for(4.0, func() -> void: samples.append(deck.rest_us))
	samples.sort()
	var middle := samples[samples.size() / 2]
	print("lying at %.0f°: resting over costs %.0f µs a tick (median of the running mean), the runners %.0f µs" % [
		heel(), middle, deck.glider.cost_us])
	metric("Capsized rest tick", middle, "µs", BUDGET_US)
	check(middle < BUDGET_US, "resting over stays within its budget (%.0f µs)" % middle)
	check(sunk() < 0.2, "and nothing it carries rests in the sand (%.3f m)" % sunk())
