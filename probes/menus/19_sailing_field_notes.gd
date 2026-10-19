extends MenuProbe
## Menus & UI probe 19: physical sailing instructions remain readable at
## 720p, open from the scenario's booklet, and return through normal menus.


func run() -> void:
	get_window().size = Vector2i(1280, 720)
	await open_main(false)
	await started()
	await faded_in()
	main.start_scenario(Scenarios.by_key("sail"))
	var notes: SailingNotes
	for i in 600:
		await get_tree().physics_frame
		for child in world.content.get_children():
			if child is SailingNotes:
				notes = child
		if notes != null:
			break
	check(notes != null, "sail scenario lays a physical booklet")
	if notes == null:
		return
	check(notes.global_position.distance_to(world.player.global_position) < 2.5,
		"notes are within reach at the starting board")
	check(world.content.get_children().any(func(n: Node) -> bool:
		return n is Chassis and (n as Chassis).camp().any(func(d: Node) -> bool: return d is Streamer)),
		"the practice rig carries a streamer for reading apparent wind")
	check(notes.interact(world.player) and main.ui.is_open(), "using loose notes opens their chapter list")
	var chapters := main.ui.top()
	for chapter in SailingNotes.PAGES.size():
		var paragraphs: PackedStringArray = SailingNotes.PAGES[chapter][1].split("\n\n", false)
		for paragraph in paragraphs.size():
			var page := notes.page(chapter, paragraph)
			main.ui.open(page)
			await _layout()
			var body: RichTextLabel = page.find_children("*", "RichTextLabel", true, false)[0]
			var rect := get_viewport().get_visible_rect()
			check(body.get_content_height() <= body.size.y + 1.0 and rect.encloses(body.get_global_rect()),
				"chapter %d page %d text fits at 720p" % [chapter + 1, paragraph + 1])
			for item in page._items:
				check(rect.encloses((item.button as Control).get_global_rect()), "page navigation stays on screen")
			check(not body.text.contains("{reel_in}") and not body.text.contains("{interact}"),
				"instructions render action bindings")
			press(&"ui_cancel")
			check(main.ui.top() == chapters, "back returns to chapters")
	press(&"ui_cancel")
	check(not main.ui.is_open() and not Controls.mouse_free, "closing the booklet returns to the run")
	world.player.hands.hold(notes)
	await physics_frames(20)
	check(notes.use(world.player, Vector3.ZERO) and main.ui.is_open(), "the carried booklet can be read again")
	press(&"console")
	press(&"ui_cancel")
	check(main.ui.is_open() and main.ui.top().visible, "console restores the chapter list")


func _layout() -> void:
	for i in 4:
		await get_tree().process_frame
