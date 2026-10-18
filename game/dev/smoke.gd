class_name Smoke
extends RefCounted
## An exported build's check on its own OS (`-- --smoke`, or `--smoke=<png>`
## to keep a frame where there's a screen): a new Normal run, half a minute
## of it, Save & quit to the menu with the save there to resume, and out
## with exit code 0. Judged as a probe is. Its saves and profile are its
## own, never the player's.

const SECONDS := 30.0


static func asked() -> bool:
	return Array(OS.get_cmdline_user_args()).any(func(arg: String) -> bool: return arg.begins_with("--smoke"))


static func run(main: Main) -> void:
	var tree := main.get_tree()
	var dir := OS.get_temp_dir().path_join("sandgame-smoke-%d" % OS.get_process_id())
	main.saves().dir = dir
	main.profile().dir = dir
	Settings.path = dir.path_join("settings.cfg")
	print("smoke: %s, %s on %s (%s), user data in %s" % [OS.get_name(), DisplayServer.get_name(),
		RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_driver_name(),
		OS.get_user_data_dir()])
	var failed := PackedStringArray()
	var started := Time.get_ticks_msec()
	await main.new_game(false, false, Kit.standard())
	if not main.in_run():
		failed.append("no run began")
	else:
		print("smoke: in a run after %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
		for i in roundi(SECONDS * Engine.physics_ticks_per_second):
			await tree.physics_frame
		var shot := _shot_path()
		if shot != "" and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var saved := main.get_viewport().get_texture().get_image().save_png(shot)
			print("smoke: frame kept in %s (%s)" % [shot, error_string(saved)])
		if main.world().player.vitals.dead:
			failed.append("died in the first half minute")
		var seed := main.world().run_seed
		await main.save_and_quit()
		if main.in_run() or not main.has_save() or main.saves().run_seed() != seed:
			failed.append("Save & quit left no save to resume (%s)" % main.save_refused())
	main.saves().delete()
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)
	print("smoke: %.1f s in all" % ((Time.get_ticks_msec() - started) / 1000.0))
	if failed.is_empty():
		print("PROBE PASS smoke")
		tree.quit(0)
	else:
		printerr("CHECK FAILED: ", "; ".join(failed))
		print("PROBE FAIL smoke")
		tree.quit(1)


static func _shot_path() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--smoke="):
			return arg.trim_prefix("--smoke=")
	return ""
