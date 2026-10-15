class_name Condenser
extends Device
## A crude condenser: it pulls water out of the thin air into the canister
## fitted in it. It runs whenever it has the power and a canister with room,
## drawing the same either way, and cold air gives up its water far more
## easily, so it makes the most at night and little in the afternoon heat:
## all by the felt temperature where it stands.

## Water it has made since it was found, L.
var made_l := 0.0


## The canister in its water socket, or null.
func canister() -> Supply:
	for socket in sockets():
		if socket.kind == &"water" and socket.part is Supply:
			return socket.part
	return null


## What it makes running, L an hour, now or at world time t.
func making_lph(t := NAN) -> float:
	if world == null:
		return 0.0
	var tuning := world.tuning
	var warm := clampf(inverse_lerp(tuning.condenser_cold, tuning.condenser_hot,
		world.weather.felt_temperature(global_position, t)), 0.0, 1.0)
	return tuning.condenser_litres_per_hour * lerpf(1.0, tuning.condenser_hot_share, warm)


func demand_w(t := NAN) -> float:
	return super(t) + (Tuning.current().condenser_w if _room() and not wrecked() else 0.0)


func work(seconds: float, t: float) -> void:
	if _room():
		var made := making_lph(t) * seconds / 3600.0
		made_l += made - canister().fill(made)


## What it's making now, L an hour: nothing dark, wrecked or full.
func making() -> float:
	return making_lph() if powered and _room() and not wrecked() else 0.0


func stats() -> Dictionary:
	var now := super()
	now["making_lph"] = making()
	return now


func _room() -> bool:
	var cell := canister()
	return cell != null and cell.amount < cell.capacity()
