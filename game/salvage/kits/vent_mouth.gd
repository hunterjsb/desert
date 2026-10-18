class_name VentMouth
extends Structure
## A live vent's mouth on the ground (GeologyKit). It stands where geology put
## it, a little along the rift where its apron holds the dunes best: its pit
## and rampart over the dunes' mean under it, and round them its apron, which
## the dunes rise or fall from no steeper than its grade, banking at the
## sand's own slope at its edge. The same in every state.

## Where its middle's ground is sampled for the dunes' mean, plan m.
const UNDER := [Vector2(0.0, 0.0), Vector2(5.0, 0.0), Vector2(-5.0, 0.0), Vector2(0.0, 9.0), Vector2(0.0, -9.0)]
## Its apron is tried against the dunes on rings this far from the slot, m,
## at this many points round each.
const RINGS := [30.0, 42.0, 50.0, 56.0]
const ROUND := 12


func place_step() -> bool:
	var shape: TerrainShape = _ctx.shape.get_ref()
	if shape == null:
		return super()
	var best := INF
	var best_v := 0.0
	var best_pad := 0.0
	var steps := roundi(GeologyKit.LOOK / GeologyKit.LOOK_STEP)
	for k in 2 * steps + 1:
		var v := GeologyKit.LOOK_STEP * ceili(k * 0.5) * (1.0 if k % 2 == 1 else -1.0)
		var pad := 0.0
		for each: Vector2 in UNDER:
			var at := to_world(each + Vector2(0.0, v))
			pad += shape.dunes(at.x, at.y)
		pad /= UNDER.size()
		var over := -INF
		for d: float in RINGS:
			for i in ROUND:
				var a := TAU * i / ROUND
				var p := Vector2(cos(a) * d, sin(a) * d)
				p.y += signf(p.y) * GeologyKit.SLOT + v
				var at := to_world(p)
				over = maxf(over, absf(shape.dunes(at.x, at.y) - pad) - GeologyKit.band(d))
		if over < best:
			best = over
			best_v = v
			best_pad = pad
		if over <= 0.0:
			break
	var moved := to_world(Vector2(0.0, best_v))
	x = moved.x
	z = moved.y
	_stand(best_pad)
	return true


func _made(dx: float, dz: float, _s: int) -> Vector2:
	var d := GeologyKit.from_slot(plan(dx, dz))
	var own := pad() + GeologyKit.profile(d)
	var shape: TerrainShape = _ctx.shape.get_ref()
	if shape == null or d >= GeologyKit.APRON:
		return Vector2(own, 0.0 if shape == null else 1.0)
	var band := GeologyKit.band(d)
	var ground := clampf(shape.dunes(x + dx, z + dz), own - band, own + band)
	return Vector2(ground, smoothstep(GeologyKit.APRON - 2.0, GeologyKit.APRON, d))
