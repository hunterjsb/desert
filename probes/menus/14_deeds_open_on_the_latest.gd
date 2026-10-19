extends MenuProbe
## Menus & UI probe 14: the deeds open on the latest. With none done they
## open on the first still to do; with Green Thumb done and then Hermit, on
## Hermit, not the first card. Until the deeds are looked at, the main menu
## marks Deeds as new.


func run() -> void:
	await open_main()
	var profile := get_node(^"/root/Profile")
	check(await _opens_on() == &"board_distance", "with none done, the first still to do")
	for id in ["crop", "shield_day"]:
		profile.deed(id)
	# Done a moment apart, as they would be.
	profile._deeds["crop"].at = 1000.0
	profile._deeds["shield_day"].at = 2000.0
	check(not Deeds.unseen(profile).is_empty(), "the main menu marks Deeds while they're new")
	check(await _opens_on() == &"shield_day", "with two done, the one done last")
	check(Deeds.unseen(profile).is_empty(), "looked at, they're new no longer")


## The card the deeds menu highlights as it opens.
func _opens_on() -> StringName:
	main.ui.open(main.ui.deeds())
	await get_tree().process_frame
	await get_tree().process_frame
	var focused := get_viewport().gui_get_focus_owner()
	main.ui.close_top()
	return focused.get_meta(&"deed", &"") if focused != null else &""
