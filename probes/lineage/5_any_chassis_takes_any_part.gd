extends Probe
## Lineage probe 5: all eras interoperate. A chassis of each era takes a
## battery, a panel and a light shield stuck on its top, a hover tray under
## it and a hook on its ring, of every era; a frame of every era stands on
## it; and a piece of every era joins it. Nothing anywhere asks what era a
## thing is.

const ERAS: Array[StringName] = [Eras.COLONIAL, Eras.FIRST, Eras.SKIMMER, Eras.SECOND]


func run() -> void:
	var holder := Node3D.new()
	add_child(holder)
	var fitted := 0
	var tried := 0
	for frame_era in ERAS:
		for part_era in ERAS:
			var deck := _made(Catalog.device(&"chassis"), frame_era) as Chassis
			holder.add_child(deck)
			for each: Array in [[&"battery", Chassis.TOP, Vector2(0.3, 0.3)], [&"solar_panel", Chassis.TOP, Vector2(0.0, -0.27)],
					[&"hover_tray", Chassis.BOTTOM, Vector2.ZERO], [&"frame", Chassis.TOP, Vector2.ZERO],
					[&"light_shield", Chassis.TOP, Vector2(-0.25, 0.25)]]:
				var thing: RigidBody3D = _made(Catalog.part(each[0]) if Catalog.PARTS.has(each[0]) else Catalog.device(each[0]), part_era)
				tried += 1
				if Stick.why_not(deck, deck, each[1], thing) == "":
					var socket := Stick.put(deck, deck, each[1], each[2], 0.0, thing)
					fitted += int(socket.part == thing or socket.mounted == thing)
			var hook := _made(Catalog.part(&"hook"), part_era) as Part
			tried += 1
			deck.fit(hook, deck.frame_sockets()[0])
			fitted += int(hook.socket != null)
			var piece := _made(Catalog.device(&"chassis"), part_era) as Chassis
			holder.add_child(piece)
			piece.position = Vector3.RIGHT * 2.0
			var ring := deck.frame_sockets()[1]
			tried += 1
			if piece.fits_in(ring):
				deck.join(piece, ring, 0)
				if deck.pieces().size() == 2:
					fitted += 1
			deck.free()
	check(fitted == tried, "every era's part fits every era's chassis (%d of %d)" % [fitted, tried])


func _made(body: Node, era: StringName) -> Node:
	Catalog.found_in(body, era, &"", 11)
	return body
