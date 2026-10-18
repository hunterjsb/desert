extends CampProbe
## Profile & saves probe 20: a hermit's whole day. Under the reference camp's
## shield most of a day, its bubble down a moment, then most of a day again:
## no Hermit, since the day has to be unbroken. A little longer, and it's done.
## Time limit: 600 s


func run() -> void:
	await load_camp()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	await idle(0.9)
	shield.stand(false)
	await live(5.0, 1.0)
	shield.stand(true)
	await idle(0.9)
	check(not profile.did("shield_day"), "a day broken by stepping out is no whole day")
	await idle(0.2)
	check(profile.did("shield_day"), "a whole day under it is Hermit")
