extends MovementProbe
## Movement probe 4: frame-rate proof. The same keys held over the same dunes,
## at 30, 60 and 120 physics ticks a second, trace the same path: a walk that
## turns, a sprint into a slide down the steepest slope near spawn that turns
## too, and a walk with two jumps in it, one landed into a sprint. Then the
## same walk at 60 with the body's feel switched off: the camera's sway,
## spring and lean are only looks, so the path is identical.

const RATES := [30, 60, 120]
## A few millimetres apart at most, over paths of 5 to 15 m.
const SAME_PLACE := 0.005


func run() -> void:
	await load_moving()
	var x := world.player_world_x()
	var z := world.player_world_z()
	var hill := slope_between(x, z, 120.0, 8.0, 20.0, 12.0)
	check(not hill.is_empty(), "a slope to slide down near spawn")
	if hill.is_empty():
		return
	var down: Vector2 = hill.downhill
	var routes := {
		"walk": [Vector2(x, z), Vector2(0.6, 0.8), [[0.0, ["move_forward"]], [1.5, ["move_forward", "move_left"]],
			[2.5, ["move_forward", "sprint"]], [3.5, []]], 4.0],
		"slide": [Vector2(hill.x, hill.z) - down * 3.0, down, [[0.0, ["move_forward", "sprint"]],
			[0.6, ["move_forward", "sprint", "crouch"]], [1.6, ["move_right", "crouch"]], [2.4, ["crouch"]]], 3.5],
		"jump": [Vector2(x, z), Vector2(-0.8, 0.6), [[0.0, ["move_forward"]], [0.5, ["move_forward", "jump"]],
			[0.6, ["move_forward"]], [1.7, ["move_forward", "sprint", "jump"]], [1.8, ["move_forward", "sprint"]],
			[2.8, []]], 3.5],
	}
	for route: String in routes:
		var paths := {}
		for rate: int in RATES:
			paths[rate] = await _trace(routes[route], rate)
		for rate: int in [30, 120]:
			var apart := _apart(paths[rate], paths[60])
			var length := _length(paths[60])
			print("%s, %d ticks against 60: %.2f m long, at most %.4f m apart" % [route, rate, length, apart])
			check(apart < SAME_PLACE, "%s at %d ticks follows the path at 60 (%.4f m apart)" % [route, rate, apart])
		if route == "walk":
			player.feel.set_process(false)
			var unfelt := await _trace(routes[route], 60)
			player.feel.set_process(true)
			var apart := _apart(unfelt, paths[60])
			print("walk at 60 without the body's feel: %.6f m apart" % apart)
			check(apart < 1e-6, "the body's feel never changes the path (%.6f m)" % apart)
	set_rate(60)


## Holds each step's keys from its time on, from rest at `from` facing
## `facing`, and samples your feet 30 times a simulated second.
func _trace(route: Array, rate: int) -> Array[Vector3]:
	# A new tick rate takes hold a frame late, so it's set before you're placed.
	set_rate(rate, 4)
	await place(route[0].x, route[0].y, route[1])
	var steps: Array = route[2]
	var path: Array[Vector3] = [where()]
	var at := {"tick": 0, "step": 0}
	var every := rate / 30
	# Keys change between ticks, at the same simulated moment at every rate.
	var press := func() -> void:
		while at.step < steps.size() and at.tick >= roundi(steps[at.step][0] * rate):
			hold(steps[at.step][1])
			at.step += 1
	press.call()
	await simulate(route[3], func() -> void:
		at.tick += 1
		press.call()
		if at.tick % every == 0:
			path.append(where()))
	hold([])
	return path


func _apart(a: Array[Vector3], b: Array[Vector3]) -> float:
	var most := 0.0
	for i in mini(a.size(), b.size()):
		most = maxf(most, a[i].distance_to(b[i]))
	return most if a.size() == b.size() else INF


func _length(path: Array[Vector3]) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total
