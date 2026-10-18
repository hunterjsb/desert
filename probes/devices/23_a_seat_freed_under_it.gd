extends LineProbe
## Devices probe 23: a seat freed under its host. A shield seated on a
## floating crate is freed outright, as a scenario clearing the kit or the
## ground forgetting it would: the crate runs on without error, its seat open
## again for another shield.


func run() -> void:
	await load_lines()
	var crate := device(&"crate_frame", spot(0.0, 3.0), 0.27)
	var top: Socket = crate.sockets().filter(func(each: Socket) -> bool: return each.kind == &"top")[0]
	var shield := Catalog.device(&"shield")
	world.content.add_child(shield)
	crate.mount(shield, top)
	await simulate(0.5)
	shield.free()
	await simulate(0.5)
	check(top.mounted == null and top.is_open(), "the crate runs on, its seat open again")
	var another := Catalog.device(&"shield")
	world.content.add_child(another)
	crate.mount(another, top)
	await simulate(0.5)
	check(crate.seat_of(another) == top, "and another shield seats there")
