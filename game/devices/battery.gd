class_name Battery
extends Part
## A battery: a part that carries its charge wherever it goes, so swapping one is
## carrying stored power by hand. Its light shows how full it is.

var charge_wh := 0.0
## What went in (plus) or out over the last power tick, W: which way it's
## flowing, for a power box's strip.
var flow_w := 0.0
## The strip of light on its case; it moves into a device with the rest of it.
var light: MeshInstance3D


func capacity() -> float:
	return stats.get("capacity_wh", 0.0)


## Puts energy in, up to full; returns what didn't fit.
func fill(wh: float) -> float:
	var taken := minf(wh, capacity() - charge_wh)
	charge_wh += taken
	return wh - taken


## Takes energy out, down to empty; returns what it gave.
func drain(wh: float) -> float:
	var given := minf(wh, charge_wh)
	charge_wh -= given
	return given


func show_charge() -> void:
	if light != null:
		ChargeLight.paint(light, charge_wh / maxf(capacity(), 1e-9))
