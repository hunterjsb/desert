extends MenuProbe
## Menus & UI probe 9: the prop aside, and the music's switch. Before any run
## the main menu shows the Surveyor's camp. Every menu opened off it stands
## down the left with the prop slid aside: the deeds, Options, the controls
## list, the question before a reset, who you come as and the mode; back slides it
## home. Who you come as shows the highlighted Salvager's board, and each
## origin's gear as listed is what its run sets down. With a save, New game's
## question slides it aside too. The menu a Salvager run quits to shows the
## Salvager's board, and so does the next session's. The music's switch,
## reached by the menu's actions, mutes it, and the next session's is muted.


func run() -> void:
	open_every_start()
	await open_main()
	var surveyor := Kit.named(&"surveyor")
	var salvager := Kit.named(&"salvager")
	check(main.showpiece.shown == surveyor.id, "before any run, the menu shows the Surveyor's camp")
	var home := _across()
	press(&"ui_down")
	press(&"ui_accept")
	await _aside("the deeds", home)
	press(&"ui_cancel")
	press(&"ui_down")
	press(&"ui_accept")
	await _aside("Options", home)
	for i in 4:
		press(&"ui_down")
	press(&"ui_accept")
	await _aside("the controls list", home)
	press(&"ui_cancel")
	press(&"ui_down")
	press(&"ui_accept")
	await _aside("the question before a reset", home)
	press(&"ui_cancel")
	press(&"ui_cancel")
	await _until(func() -> bool: return is_equal_approx(_across(), home))
	check(not main.showpiece.aside() and is_equal_approx(_across(), home), "back slides it home")
	press(&"ui_up")
	press(&"ui_up")
	press(&"ui_accept")
	press(&"ui_down")
	await _aside("who you come as", home)
	await _until(func() -> bool: return main.showpiece.shown == salvager.id)
	check(main.showpiece.shown == salvager.id, "showing the highlighted Salvager's board")
	var drift := PackedStringArray()
	for kit in Kit.origins():
		var listed := kit.gear()
		for id in kit.carried:
			listed[id] -= kit.carried[id]
			if listed[id] == 0:
				listed.erase(id)
		var got := _set_down(kit)
		if str(_sorted(listed)) != str(_sorted(got)):
			drift.append("the %s lists %s, a run sets down %s" % [kit.label, _sorted(listed), _sorted(got)])
	check(drift.is_empty(), "each origin's gear as listed is what its run sets down (%s)" % "; ".join(drift))
	press(&"ui_accept")
	await _aside("the mode", home)

	press(&"ui_accept")
	await faded_in()
	await main.save_and_quit()
	check(main.showpiece.shown == salvager.id, "the menu a Salvager run quits to shows the Salvager's board")
	home = _across()
	press(&"ui_down")
	press(&"ui_accept")
	await _aside("New game's question over a save", home)
	press(&"ui_cancel")
	# Up from Resume, round to the switch in the bottom left.
	press(&"ui_up")
	press(&"ui_up")
	press(&"ui_accept")
	check(not Settings.music, "the music's switch, reached by the menu's actions, mutes it")
	main.queue_free()
	await get_tree().process_frame
	get_node(^"/root/Profile").dir = user_dir
	# As a new session starts, before its settings are read.
	Settings.music = true
	await open_main()
	check(main.showpiece.shown == salvager.id, "the next session's shows the Salvager's board")
	check(not Settings.music, "and its music is muted still")


## The menu on top stands down the left, the prop slid aside right of its words.
func _aside(what: String, home: float) -> void:
	await _until(func() -> bool: return _across() > home + 0.4)
	check(main.ui.top().side and main.showpiece.aside() and _across() > home + 0.4,
		"%s stands on the left and sets the prop aside (%.2f m across)" % [what, _across() - home])


## What a run sets down of a kit, as its gear counts it, set down in the
## menu's world and gone again.
func _set_down(kit: Kit) -> Dictionary:
	var got := {}
	var made := Runs.kit(main.view, kit)
	var plugs := []
	for node in made:
		if node is Cable:
			plugs.append_array(node.plugs)
	for node in made:
		var id: StringName = &"line" if node is Line else (&"strong_cable" if node is StrongCable
			else (&"cable" if node is Cable else node.get_meta(&"catalog", &"")))
		if node in plugs or id == &"":
			continue
		var deck := node as Chassis
		# A deck counts each of its pieces, and the parts stuck on it; the
		# devices stuck on it are in what was made already.
		var bodies: Array = deck.pieces() if deck != null else [node]
		for body: Node in bodies:
			got[id] = got.get(id, 0) + 1
			# A line's ends are the line's.
			if body is Device:
				for socket: Socket in body.frame_sockets():
					if socket.part != null and socket.kind != &"tie":
						var part: StringName = socket.part.get_meta(&"catalog")
						got[part] = got.get(part, 0) + 1
		if deck != null:
			for socket in deck.stuck():
				if socket.part != null:
					var part: StringName = socket.part.get_meta(&"catalog")
					got[part] = got.get(part, 0) + 1
	for node in made:
		if is_instance_valid(node):
			node.free()
	return got


static func _sorted(counts: Dictionary) -> Array:
	var out := []
	for id in counts:
		out.append("%s %d" % [id, counts[id]])
	out.sort()
	return out


## How far right of the screen's middle the prop stands, m.
func _across() -> float:
	var eye := main.view.player.camera
	return (eye.global_transform.affine_inverse() * main.showpiece.global_position).x


func _until(done: Callable, max_frames := 600) -> void:
	for i in max_frames:
		if done.call():
			return
		await get_tree().process_frame
