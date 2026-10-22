extends SailingAidProbe
## Runs alone
## Sampling and advancing the recommendation share a small render-frame allowance.
const FRAME_MS := 0.5

func run() -> void:
	await aid_rig()
	Engine.max_fps = 60
	computer.sailing._at = -INF
	computer.sailing._job = null
	var samples := PackedFloat64Array()
	var began := computer.sailing.solves
	for i in 240:
		await get_tree().process_frame
		samples.append(computer.sailing.refresh_us / 1000.0)
	samples.sort()
	var p95 := samples[int(samples.size() * 0.95)]
	metric("Sailing advice frame p95", p95, "ms", FRAME_MS)
	metric("Sailing advice worst frame", samples[-1], "ms")
	check(computer.sailing.solves >= began + 2 and not computer.sailing.ideal.is_empty(),
		"bounded slices finish fresh recommendations while the rig moves")
	check(p95 <= FRAME_MS, "the frame's sampling and search stay inside the advice budget")
