class_name VarranLooks
extends RefCounted
## The Varran settler's own gear in the empire's coats (Dress): new, clean
## and glossy, out of place on Zan. Imperial blue under ivory armour, chrome
## and brass, an amber light where it's working. The navigation computer is
## a rack in a heavy rounded case, its radar under a dome on its head; the
## personal shield a flat puck with a dome for its emitter, its battery
## cradled at its back.

const FRONT := Basis(Vector3.UP, PI)


## Draws a Varran thing's look into its pieces; false for an id that isn't one.
static func frame(b: Paint.Pieces, id: StringName, size: Vector3, _era := Eras.NEW, _extra := 0.0) -> bool:
	match id:
		&"nav_computer":
			_computer(b, size)
		&"personal_shield":
			_shield(b, size)
		_:
			return false
	return true


static func _coats() -> Dictionary:
	return {"blue": Paint.coat(Paint.IMPERIAL_BLUE, 0.6, 0.35, 0.3, 0.5), "ivory": Paint.coat(Paint.IVORY, 0.5, 0.0, 0.35, 0.6),
		"chrome": Paint.coat(Paint.STEEL.lightened(0.2), 0.3, 0.95, 0.15, 0.3),
		"brass": Paint.coat(Paint.BRASS, 0.3, 0.9, 0.3, 0.4), "black": Paint.coat(Paint.BLACK, 0.3, 0.3, 0.4),
		"amber": Paint.coat(Paint.WORKING_AMBER, 0.0, 0.0, 0.4, 0.0, 2.5)}


## Its screen fills the front; ivory armour wraps the corners and the head, a
## heavy plinth carries it, chrome handles stand off its sides, and the dome
## of its radar and an anemometer's cups ride on top.
static func _computer(b: Paint.Pieces, size: Vector3) -> void:
	var c := _coats()
	var h := size * 0.5
	b.box(Vector3(size.x - 0.03, size.y - 0.1, size.z - 0.03), Vector3(0.0, 0.02, 0.0), c.blue, 0.05)
	b.box(Vector3(size.x, 0.12, size.z), Vector3(0.0, -h.y + 0.06, 0.0), c.ivory, 0.04)
	b.box(Vector3(size.x - 0.06, 0.03, size.z - 0.06), Vector3(0.0, -h.y + 0.135, 0.0), c.black, 0.01)
	b.box(Vector3(size.x, 0.07, size.z), Vector3(0.0, h.y - 0.1, 0.0), c.ivory, 0.03)
	for x in [-1, 1]:
		for z in [-1, 1]:
			b.box(Vector3(0.06, size.y - 0.2, 0.06), Vector3(x * (h.x - 0.03), 0.0, z * (h.z - 0.03)), c.ivory, 0.025)
	# The screen's bezel on its front, an amber strip lit under it.
	b.box(Vector3(size.x - 0.04, size.y - 0.14, 0.02), Vector3(0.0, 0.01, -h.z + 0.01), c.black, 0.004)
	b.box(Vector3(size.x * 0.6, 0.016, 0.01), Vector3(0.0, -h.y + 0.105, -h.z - 0.004), c.amber, 0.002)
	for x in [-1, 1]:
		var turn := Basis(Vector3.UP, x * PI * 0.5)
		# A handle each side, stood off on brass feet.
		for y in [-0.15, 0.25]:
			b.box(Vector3(0.03, 0.03, 0.05), Vector3(x * (h.x + 0.02), y, 0.12), c.brass, 0.006)
		b.drum(0.014, 0.42, Vector3(x * (h.x + 0.045), 0.05, 0.12), c.chrome, Basis.IDENTITY, 10)
		# Louvres low on each side, the case's cooling.
		for i in 6:
			b.box(Vector3(0.26, 0.012, 0.02), turn * Vector3(-0.08, -0.45 + i * 0.05, h.x - 0.008), c.black, 0.002, turn)
	# Its back: a vent's ring over its power port.
	b.ring(0.07, 0.11, Vector3(0.0, 0.2, h.z - 0.004), c.black, Basis(Vector3.RIGHT, PI / 2.0), 12)
	b.box(Vector3(0.3, 0.05, 0.012), Vector3(0.0, -0.05, h.z - 0.004), c.brass, 0.003)
	# The radar's dome and the anemometer's cups on its head.
	b.drum(0.22, 0.04, Vector3(0.0, h.y - 0.045, -0.04), c.chrome, Basis.IDENTITY, 20)
	b.ball(0.2, Vector3(0.0, h.y - 0.03, -0.04), c.ivory, Vector3(1.0, 0.6, 1.0))
	b.drum(0.008, 0.22, Vector3(0.22, h.y + 0.05, 0.2), c.chrome, Basis.IDENTITY, 6)
	for i in 3:
		var arm := Basis(Vector3.UP, i * TAU / 3.0)
		b.box(Vector3(0.006, 0.006, 0.07), Vector3(0.22, h.y + 0.16, 0.2) + arm * Vector3(0.0, 0.0, 0.035), c.chrome, 0.0, arm)
		b.ball(0.016, Vector3(0.22, h.y + 0.16, 0.2) + arm * Vector3(0.0, 0.0, 0.07), c.black)
	b.ball(0.012, Vector3(-0.2, h.y - 0.05, 0.2), c.amber)


## A flat puck: its ivory rim round a blue body, the emitter's chrome dome on
## top, a cradle for its battery at its back and a grip across its head.
static func _shield(b: Paint.Pieces, size: Vector3) -> void:
	var c := _coats()
	var h := size * 0.5
	var r := h.x * 0.92
	b.drum(r, size.y * 0.55, Vector3(0.0, -h.y + size.y * 0.3, 0.0), c.blue, Basis.IDENTITY, 24)
	b.drum(h.x * 0.96, size.y * 0.16, Vector3(0.0, -h.y + size.y * 0.08, 0.0), c.ivory, Basis.IDENTITY, 24)
	b.drum(r * 0.78, size.y * 0.08, Vector3(0.0, -h.y + size.y * 0.6, 0.0), c.ivory, Basis.IDENTITY, 24)
	b.ball(r * 0.5, Vector3(0.0, -h.y + size.y * 0.62, 0.0), Paint.coat(Paint.CELL, 0.0, 0.4, 0.15, 0.4), Vector3(1.0, 0.7, 1.0))
	b.ring(r * 0.5, r * 0.56, Vector3(0.0, -h.y + size.y * 0.66, 0.0), c.chrome, Basis.IDENTITY, 16)
	# A grip across its head, to carry it running.
	for x in [-1, 1]:
		b.box(Vector3(0.02, size.y * 0.35, 0.03), Vector3(x * r * 0.62, h.y - size.y * 0.2, -r * 0.5), c.chrome, 0.004)
	b.box(Vector3(r * 1.3, 0.02, 0.03), Vector3(0.0, h.y - 0.03, -r * 0.5), c.chrome, 0.004)
	# The battery's cradle at its back.
	b.box(Vector3(0.24, 0.02, 0.05), Vector3(0.0, -h.y + 0.02, h.z - 0.02), c.ivory, 0.006)
	b.box(Vector3(0.012, size.y * 0.75, 0.05), Vector3(-0.125, -0.02, h.z - 0.02), c.ivory, 0.004)
	b.box(Vector3(0.012, size.y * 0.75, 0.05), Vector3(0.125, -0.02, h.z - 0.02), c.ivory, 0.004)
	b.ball(0.012, Vector3(h.x * 0.7, -h.y + size.y * 0.45, -h.z * 0.7), c.amber)
