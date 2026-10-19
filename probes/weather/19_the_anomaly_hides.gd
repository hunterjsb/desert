extends WeatherProbe
## Wind & storms probe 19: the anomaly hides from every forecast. Through its
## storm, from the clear to its heart, the field the instruments read, the
## radio's forecast and the Console's wind and sand are what a run with no
## anomalies reads. At its heart its damage isn't: outside the bubble wear,
## harm and a crop's dust read the particles five times over and the wind
## half again, and the shield holds back five full storms' sand.

## How near two readings must agree.
const SAME := 1e-6


func run() -> void:
	await load_weather()
	var met := await meet_anomaly()
	if met.is_empty():
		return
	var tuning := world.tuning.duplicate() as Tuning
	tuning.anomaly_chance = 0.0
	var clean := WeatherField.new(world.run_seed, tuning)
	var x := world.player_world_x()
	var z := world.player_world_z()
	var same := true
	var t: float = met.start
	while t <= met.heart:
		var minutes := world.tuning.radio_forecast_minutes * 60.0
		same = same and field.raw_storm_at(x, z, t) == clean.raw_storm_at(x, z, t) \
			and field.wind_at(x, z, t) == clean.wind_at(x, z, t) \
			and Radio.forecast(field, x, z, t, minutes, Weather.FORECAST_STEP) \
				== Radio.forecast(clean, x, z, t, minutes, Weather.FORECAST_STEP)
		t += 30.0
	check(same and clean.anomaly_at(x, z, met.heart) == 0.0, "the field and the radio's forecast read as with no anomaly")

	world.time = met.heart
	await physics_frames(10)
	var console: Console = met.camp[1]
	var shield: ShieldGenerator = met.camp[3]
	var turbine: Device = met.camp[7]
	var cx := world.world_x(console.global_position.x)
	var cz := world.world_z(console.global_position.z)
	var sand: float = console.readings.get("sand", {}).get("g_m3", NAN)
	var wind: float = console.readings.get("wind", {}).get("true_speed", NAN)
	print("at the heart: sand %.2f g/m³, wind %.1f m/s" % [sand, wind])
	check(absf(sand - console.sand_of(clean, clean.raw_storm_at(cx, cz, met.heart))) < SAME
		and absf(wind - clean.wind_at(cx, cz, met.heart).length()) < SAME, "the Console reads the clean sand and wind")

	var weather := world.weather
	var out := turbine.global_position
	var storm := weather.felt_storm(out)
	var past := maxf(weather.felt_wind(out).length() - world.tuning.wind_hurts_from, 0.0)
	var harm := world.player.vitals.harms_at(out)
	var particles: float = harm.storm / (storm * world.tuning.storm_harm)
	var winds: float = harm.wind / (past * world.tuning.wind_harm) if past > 0.0 else NAN
	var held := shield.particle_load() / weather.field_storm(shield.global_position)
	print("outside the bubble: storm %.2f, wind %.1f past; particles x%.2f, wind x%.2f; shield x%.2f, %.0f W" % [
		storm, past, particles, winds, held, shield.demand_w()])
	check(storm > 0.5 and absf(particles - world.tuning.anomaly_particles) < 0.01
		and absf(Planter.felt_at(weather, out, world.time).particles - storm * particles) < SAME,
		"harm and a crop's dust read the particles at the heart's full (x%.2f)" % particles)
	var hidden := weather.hidden(out)
	check(absf(hidden.y - world.tuning.anomaly_wind) < 0.01 and (is_nan(winds) or absf(winds - hidden.y) < 0.01),
		"the wind's harm far less (x%.2f)" % hidden.y)
	var expected := storm * hidden.x / (world.tuning.storm_wreck_minutes * 60.0) \
		+ maxf(weather.felt_wind(out).length() - world.tuning.wind_harm_speed, 0.0) * hidden.y \
		/ (Wear.WIND_SPAN * world.tuning.wind_wreck_minutes * 60.0)
	check(absf(world.wear.rate_at(out) - expected) < SAME, "wear reads the same")
	check(absf(held - world.tuning.anomaly_particles) < 0.01 and shield.demand_w() > 3.0 * world.tuning.shield_storm_w,
		"the shield holds back its full (x%.2f, %.0f W)" % [held, shield.demand_w()])
