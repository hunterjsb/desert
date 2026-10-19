extends Probe
## Lineage probe 5: all eras interoperate. A crate frame of each era takes a
## battery, a hover tray, a hook and a panel of every era, and seats a light
## shield of every era on its top; a chassis piece of each era joins one of
## every other. Nothing anywhere asks what era a thing is.

const ERAS: Array[StringName] = [Eras.COLONIAL, Eras.FIRST, Eras.SKIMMER, Eras.SECOND]


func run() -> void:
	var holder := Node3D.new()
	add_child(holder)
	var fitted := 0
	var tried := 0
	for frame_era in ERAS:
		for part_era in ERAS:
			var crate := _made(Catalog.device(&"crate_frame"), frame_era) as Device
			holder.add_child(crate)
			for id: StringName in [&"battery", &"hover_tray", &"hook", &"solar_panel"]:
				var part := _made(Catalog.part(id), part_era) as Part
				var socket: Socket = crate.sockets().filter(func(s: Socket) -> bool: return s.kind == part.kind and s.is_open())[0]
				tried += 1
				crate.fit(part, socket)
				if socket.part == part:
					fitted += 1
			var shield := _made(Catalog.device(&"light_shield"), part_era) as Device
			var top: Socket = crate.sockets().filter(func(s: Socket) -> bool: return s.kind == &"top" and s.is_open())[0]
			tried += 1
			if shield.fits_in(top):
				crate.mount(shield, top)
				if top.mounted == shield:
					fitted += 1
			var deck := _made(Catalog.device(&"chassis"), frame_era) as Chassis
			var piece := _made(Catalog.device(&"chassis"), part_era) as Chassis
			holder.add_child(deck)
			holder.add_child(piece)
			piece.position = Vector3.RIGHT * 2.0
			var ring := deck.frame_sockets()[0]
			tried += 1
			if piece.fits_in(ring):
				deck.join(piece, ring, 0)
				if deck.pieces().size() == 2:
					fitted += 1
			crate.free()
			deck.free()
	check(fitted == tried, "every era's part fits every era's frame (%d of %d)" % [fitted, tried])


func _made(body: Node, era: StringName) -> Node:
	Catalog.found_in(body, era, &"", 11)
	return body
