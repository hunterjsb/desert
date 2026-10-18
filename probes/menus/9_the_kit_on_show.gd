extends MenuProbe
## Menus & UI probe 9: the kit on show. Before any run the main menu shows the
## Surveyor's kit. New game slides it aside, and with the Salvager highlighted
## it shows the Salvager's; back slides it home, the Surveyor's again. A
## Salvager run begun, the menu it quits to shows the Salvager's kit, and so
## does the next session's, the profile read back from its file.


func run() -> void:
	await open_main()
	var surveyor := Kit.named(&"surveyor")
	var salvager := Kit.named(&"salvager")
	check(main.showpiece.kit == surveyor, "before any run, the menu shows the Surveyor's kit")
	var home := _across()
	press(&"ui_accept")
	press(&"ui_down")
	await _until(func() -> bool: return main.showpiece.kit == salvager and _across() > home + 0.5)
	check(main.showpiece.kit == salvager and _across() > home + 0.5,
		"New game slides it aside, showing the highlighted Salvager's kit (%.2f m across)" % _across())
	press(&"ui_cancel")
	await _until(func() -> bool: return main.showpiece.kit == surveyor and is_equal_approx(_across(), home))
	check(main.showpiece.kit == surveyor and is_equal_approx(_across(), home), "back slides it home, the Surveyor's again")

	press(&"ui_accept")
	press(&"ui_down")
	press(&"ui_accept")
	press(&"ui_accept")
	await faded_in()
	await main._quit_to_menu()
	check(main.showpiece.kit == salvager, "the menu a Salvager run quits to shows the Salvager's kit")
	main.queue_free()
	await get_tree().process_frame
	get_node(^"/root/Profile").dir = user_dir
	await open_main()
	check(main.showpiece.kit == salvager, "and so does the next session's")


## How far right of the screen's middle the kit on show stands, m.
func _across() -> float:
	var eye := main.view.player.camera
	return (eye.global_transform.affine_inverse() * main.showpiece.global_position).x


func _until(done: Callable, max_frames := 600) -> void:
	for i in max_frames:
		if done.call():
			return
		await get_tree().process_frame
