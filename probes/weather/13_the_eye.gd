extends WeatherProbe
## Wind & storms probe 13: the eye. Headless draws nothing, so its meter never
## reads; the probe hands the eye readings as the meter would. In daylight it's
## as the game was before it. On a frame as black as a night with no Tu it
## opens over time, never at once: about a stop in the first few seconds and
## on to its floor within half a minute, never past it. Back in daylight it
## closes within a couple of seconds, never past where it began. With Tu's disc
## in view it opens no further than keeps it short of white. The world's camera
## takes the exposure it gives, and the fixed one with the eye off.

## Readings, stops: noon's frame, and a frame darker than the far side's.
const DAY := -1.2
const BLACK := -14.0
const STEP := 1.0 / 60.0


func run() -> void:
	await load_weather()
	var tuning := world.tuning
	var eye := Eye.new(tuning)
	var most := log(tuning.eye_most) / Eye.LN2
	var live := func(seconds: float, reading: float, bright: float) -> PackedFloat32Array:
		var trace := PackedFloat32Array()
		for i in roundi(seconds / STEP):
			eye.see(reading, bright)
			eye.adapt(STEP)
			trace.append(eye.stops)
		return trace
	live.call(5.0, DAY, DAY)
	check(eye.stops == 0.0, "in daylight the exposure is the game's before (+%.2f stops)" % eye.stops)

	var dark: PackedFloat32Array = live.call(30.0, BLACK, BLACK)
	var at := func(s: float) -> float: return dark[roundi(s / STEP) - 1]
	var rising := true
	for i in range(1, dark.size()):
		rising = rising and dark[i] >= dark[i - 1]
	print("in the black: +%.2f stops at 1 s, %.2f at 4 s, %.2f at 15 s, %.2f at 30 s, the floor %.2f"
		% [at.call(1.0), at.call(4.0), at.call(15.0), at.call(30.0), most])
	check(rising and at.call(1.0) < 0.6 and at.call(4.0) > 0.7 and at.call(15.0) < most - 0.3,
		"it opens over time, a stop or so in a few seconds and the rest slower")
	check(absf(at.call(30.0) - most) < 0.05 and Array(dark).max() <= most + 1e-4,
		"within half a minute it reaches its floor, and never passes it (%.2f)" % Array(dark).max())

	var light: PackedFloat32Array = live.call(3.0, DAY, DAY)
	print("back in daylight: +%.2f stops at 0.5 s, %.2f at 2 s" % [light[29], light[119]])
	check(light[119] < 0.05 and Array(light).min() >= 0.0,
		"back in daylight it closes within two seconds, never past where it began")

	# Tu's disc at night filling a patch of the view as bright as the white line.
	live.call(30.0, BLACK, log(tuning.eye_white) / Eye.LN2 - 0.5)
	check(absf(eye.stops - 0.5) < 0.01, "with Tu in view it opens only so far as keeps it short of white (+%.2f)"
		% eye.stops)

	var environment := (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var own := world.weather.eye
	for i in 60:
		own.see(BLACK, BLACK)
		await get_tree().process_frame
	check(own.stops > 0.0 and is_equal_approx(environment.tonemap_exposure, tuning.exposure * own.exposure()),
		"the camera takes the eye's exposure (x%.2f)" % (environment.tonemap_exposure / tuning.exposure))
	tuning.eye_adapts = false
	await get_tree().process_frame
	await get_tree().process_frame
	check(environment.tonemap_exposure == tuning.exposure, "and the fixed one with the eye off")
