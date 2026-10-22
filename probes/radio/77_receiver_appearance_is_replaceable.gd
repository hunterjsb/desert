extends HandsProbe
## Swapping an authored model must preserve the same live instrument and fittings.

const AUTHORED := preload("res://probes/fixtures/receiver/authored_visual.tscn")


func run() -> void:
	await load_hands()
	var receiver := Catalog.device(&"survey_receiver") as SurveyReceiver
	world.content.add_child(receiver)
	receiver.freeze = true
	receiver.global_position = world.player.global_position + Vector3.UP
	var cell := fit_part(receiver, &"battery") as Battery
	receiver.switch(true)
	receiver.tune(2)
	receiver.durability = 0.45
	var frequency := receiver.frequency
	var target := receiver.target.duplicate()
	var sockets := receiver.sockets()
	var bounds := receiver.shape_bounds()
	var charge := cell.charge_wh
	var old := receiver.visual
	check(receiver.replace_visual(AUTHORED), "an authored scene replaces the visual")
	check(not is_instance_valid(old), "the replaced visual is retired")
	check(receiver.on and receiver.frequency == frequency and receiver.target == target
		and receiver.battery() == cell and cell.charge_wh == charge
		and receiver.sockets() == sockets and receiver.shape_bounds() == bounds,
		"replacement preserves the live instrument and its physical fittings")
	check(receiver.frame_view == receiver.visual.shell and receiver.frame_view.mesh is BoxMesh,
		"the authored shell keeps its own geometry")
	check(receiver.face().is_equal_approx(receiver.visual.reading.global_transform),
		"reading uses the authored anchor")
	receiver.visual.present(0.0, 0.0, 0.0)
	var weak := receiver.visual.meter.transform
	receiver.visual.present(1.0, 0.0, 0.0)
	check(not weak.is_equal_approx(receiver.visual.meter.transform), "the authored meter responds")
	Catalog.inherit(receiver, [[Eras.COLONIAL, &"made", []]])
	check(receiver.frame_view.mesh is BoxMesh, "lineage never substitutes a procedural shell for imported art")
	var preview := InventoryLook.new(Vector2i(128, 128))
	add_child(preview)
	preview.show_thing(receiver)
	check(preview.draws == 1, "the authored hierarchy can be drawn in the inventory")
	check(receiver.replace_visual(receiver.DEFAULT_VISUAL), "the original appearance can be restored")
	check(receiver.frame_view.mesh == Dress.lineage(&"survey_receiver", receiver.get_meta(&"lineage", []))
		or receiver.frame_view.mesh == SurveyReceiverLooks.frame(), "the original shell is restored")
	for view in receiver.painted():
		check(Paint.is_worn(view) and is_equal_approx(float(view.get_instance_shader_parameter(&"age")), Paint.age_for(receiver, receiver.durability)),
			"the original materials retain current wear")
	var invalid := PackedScene.new()
	var empty := Node3D.new()
	invalid.pack(empty)
	if is_instance_valid(empty):
		empty.free()
	var working := receiver.visual
	check(not receiver.replace_visual(invalid) and receiver.visual == working and is_instance_valid(working),
		"an invalid replacement leaves the working appearance intact")
	preview.queue_free()
