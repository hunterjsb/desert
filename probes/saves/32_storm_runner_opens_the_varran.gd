extends MenuProbe
## Profile & saves probe 32: the Varran settler waits for Storm Runner. On a
## fresh profile New game lists four starts, the Surveyor first and
## highlighted, the Varran settler's place still ????, and nothing opens it
## but its deed: Storm Runner done, it's there by name, new, and offers
## Normal only, as a start the game isn't balanced round.


func run() -> void:
	await open_main()
	var profile := get_node(^"/root/Profile")
	var varran := Kit.named(&"varran")
	check(varran.unlock == "storm_runner" and Deeds.TABLE.has(StringName(varran.unlock)) and not varran.balanced,
		"the Varran settler is opened by Storm Runner, and isn't balanced")
	press(&"ui_accept")
	var menu: Words = main.ui.top()
	check(menu.words().size() == 4 and menu.words()[0] == Kit.standard().label.to_upper() and menu.highlighted() == 0
		and menu.words()[3] == "????", "a fresh profile's New game: four starts, the Surveyor first, the Varran's ???? (%s)"
		% ", ".join(menu.words()))
	press(&"ui_cancel")
	for id in ["sail_waist", "close_hauled", "land_yacht"]:
		profile.deed(id)
	check(not varran.is_open_to(profile), "the deeds before it don't open it")
	profile.deed("storm_runner")
	check(varran.is_open_to(profile) and profile.is_new(profile.start(&"varran")), "Storm Runner opens it, new")
	press(&"ui_accept")
	menu = main.ui.top()
	check(menu.words()[3] == varran.label.to_upper(), "New game names it (%s)" % ", ".join(menu.words()))
	for i in 4:
		if menu.highlighted() != 3:
			press(&"ui_down")
	press(&"ui_accept")
	check(main.ui.top().words() == PackedStringArray(["NORMAL"]), "it offers Normal only (%s)" % ", ".join(main.ui.top().words()))
