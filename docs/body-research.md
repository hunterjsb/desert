# The body: working back from the feel

*Research memo, 2026-10-14. Loose: options and a leaning, not canon. It follows
[lore research](lore-research.md): the 150 km lap is compressed distance, so this works out
what real system, body and failing shield would produce the feel in
[the vision](vision.md), [the moon](the-moon.md) and the PRDs.*

> **Superseded by the lore session.** [The 2026-10-14 lore session](lore-session-2026-10-14.md)
> drops the sky shield, and with it the story told here about the air. The air is the
> moon's own: outgassed during an eccentric-orbit phase, then lost to a very slow escape as
> tidal heating fades. So these no longer hold: the shield-era air and the "kind of nice"
> cities (§1, §2's growth arc), the second tenant on the far side (§2), the dead garden as
> the dust source and the poles holding the missing air (§3), the shield (§5), the
> air going back into the poles (§6), and today's air of 0.15-0.2 bar (§1, §6), now about
> 0.3 bar or more. §2's "mild tidal heating" describes the calm state before the sister
> moon is lost. What stands: the system and route reasoning, the radiation numbers, the
> gravity and pressure window (§3, which is the thin-air table the session points to) and
> the candidate bodies (§4). Its escape figures stand too, because the session's loss is
> geological, not on the scale of `{YEARS_SINCE_FALL}`. The text below is left as written,
> and the notes mark the spots. [The lore research](lore-research.md) has the current
> picture.

## 1. The short answer

**Leaning: a moon between Mars-sized and a bit bigger, at 0.4–0.5 g.** It orbits a giant
of about 3–6 Jupiter masses that sits in the habitable zone of a K-dwarf star, at roughly
Ganymede-to-Callisto distance. It's tidally locked, and its real day lasts about 5–7
Earth days. Today's air is about 0.15–0.2 bar, mostly nitrogen, with no oxygen.

**Lower gravity is the lever.** Thin air can only shove you hard if you weigh less. At
1 g the pressure window closes, because the shove needs more air than the daily water
cycle allows.

**The shield never held gas in.** A body this size keeps its air for billions of years.
The shield filtered light (UV out, heat in) and turned the giant's plasma away. When it
failed, the CO₂ and water **froze back onto the poles** and the oxygen rusted into the
sand. So the poles really did collapse, just not the magnetic poles. The air relaxes
toward the moon's natural nitrogen floor, at the pace of the shield's slow death.

## 2. The system and the route

### A poor system

- **The star is a K dwarf** (about 0.7 solar masses and 0.25 solar luminosity). It
  outlives the Sun and flares less than a red dwarf, and Earth-like sunlight falls at
  about 0.5 AU.
- **Giants in the habitable zone are common:** Kepler finds them around about 11% of K
  stars (Hill et al. 2018).
- **The planets:**
  - **A hot rocky world at about 0.25 AU,** a Venus: crushing acid air at 460 °C.
  - **A warm super-Jupiter of about 3–6 Jupiter masses,** which migrated into the
    habitable zone at about 0.5 AU. Its passage left no Earth there.
  - **Maybe a cold outer giant.**
- **A real system already looks like this.** HD 28185 has a giant of at least 5.7
  Jupiter masses on a near-circular 1 AU orbit in its star's habitable zone, plus a
  Saturn-like outer planet.
- **Essentially, you have to pick a moon.**

### Why ships stop here at all

> **Session 3 keeps this.** The [FTL ruling](lore-research.md#4-the-system-the-lane-and-the-harbor)
> replaces "no FTL" with two regimes: information crosses near-instantly and anything with
> mass crosses at one fixed slow rate, so lane crossings take years. The refuelling rationale
> below stands as written.

In the Xandaris space sim, ships jump along hyperlanes. A cargo hauler carries 400 fuel
and burns 25 a jump. Ships refuel only from a world's Fuel stores. Each system gets only
a few lanes (galaxy generation links each to its 3 nearest), and hyperspace storms close
lanes and strand ships
(`space/entities/ship_entity.go`, `game/galaxy.go`, `tickable/ship_refueling.go`,
`tickable/hyperspace_storms.go`). So a poor system can still be **the only link between
two good regions**, a forced stop. It sells:
- **Fuel:** helium-3 for 200 MW fusion reactors (the sim's priciest raw resource) and
  hydrogen, skimmed from the giant. Oil from carbon-rich crust can be refined into Fuel,
  5 Oil to 4 Fuel.
- **Water** from ice.
- **Repairs, crew rest,** and somewhere to wait out a lane storm.

**Why not the giant itself?** It has no surface, and its gravity well is brutal. Jupiter's
escape velocity is 59.5 km/s, and reaching orbit from its cloud tops takes about 42 km/s,
against 7.9 km/s for Earth. This giant is 3–6 times heavier. NASA's atmospheric-mining
studies send robot aircraft to skim gas giants; nobody lives on one. **Why not the
Venus?** 90 bar of acid at 460 °C. **A moon gives you** solid ground, a shallow well
(escape at 5–6 km/s), ice, and a front-row seat on the giant for the skimmers.

### Why this moon

The giant's moons line up like Jupiter's. An Io sits deep in the radiation belts, with
volcanoes and a bare-surface dose of about 36 Sv a day. A Europa gets about 5.4 Sv a
day. Ours sits where Ganymede and Callisto do, at **15–20 giant radii**, where a bare
surface would get only 0.08 down to 0.0001 Sv a day. What makes it the pick:
- **Mild tidal heating** from a weak orbital resonance: enough geology to have outgassed
  a thin nitrogen sky, not Io's hell.
- **It's the only moon big enough to keep air,** like Titan in our solar system.
- **Polar caps of CO₂ and water ice.**
- **A 5–7 day orbit and an approach outside the belts.**

A giant's moons together weigh about 10⁻⁴ of the giant (Canup & Ward 2006). So a
Mars-sized moon needs a giant of at least ~3 Jupiter masses, and a half-g one needs ~6.
It's **the best of a bad set**: the one moon big enough to hold air, far enough out to be
safe, and close enough to the fuel.

It probably formed icy beyond the frost line, was dragged inward with its migrating
giant, and baked dry over billions of years. What's left is a thin nitrogen sky with CO₂
and water locked in the polar caps: barren, sterile, a blank slate.

### The growth arc

> **Superseded by the lore session** from "The shield" row down, and for the two paragraphs
> after the table. The outpost, refinery and port town stand as the hub's early growth, but
> with the moon's own air at the baseline and no shield to follow.

| Stage | What's built | The air |
|---|---|---|
| Outpost | An orbital fuel depot and an ice mine | Natural: ~0.1 bar of nitrogen, cold, UV straight to the ground |
| Refinery | Skimmers to the giant; organics from the crust refined into fuel | The same, plus waste nitrogen from the giant's ammonia |
| Port town | Domes, docks, yards, layovers | The same |
| The shield | A sky-wide filter: UV out, heat in, plasma turned away | The poles warm, the caps give up their CO₂ and water, and pressure climbs to ~0.4–0.5 bar |
| Kind of nice | Towns become cities: lakes, parks, the garden | Warm, open water, a light breather outdoors |
| The collapse and the empires | Emitters fail one by one | The poles cool first, the CO₂ freezes back, UV gets through, the garden browns, oxygen goes into rust, dust bowls form |
| Now, `{YEARS_SINCE_FALL}` on | Ruins | ~0.15–0.2 bar, mostly nitrogen, no oxygen: the desert |
| Ahead | — | Slowly toward the ~0.1–0.15 bar nitrogen floor. Fading, never gone |

**When a whole-moon shield beats domes:** at this size the moon's gravity holds the air,
so the shield never holds pressure. It only filters light and plasma, which per square
metre is far lighter work than a pressure dome. Shielding everything pays once domes
would cover a share of the moon equal to the field-to-dome cost ratio. If the field
costs a thousandth of a dome per square metre, it pays at 0.1% of the surface, about
Bangladesh's area. That's a guess, not a number.

**The terraforming came almost free.** The shield's greenhouse warmed the poles, the
caps breathed out, and the refinery topped up the nitrogen. That's also exactly how it
unwinds.

### The sealed garden: a second company

> **Superseded by the lore session.** Its entity stack has no biotech company, so the
> far-side tenant is dropped, and ruin type follows the terrain rather than the side. The
> agriculture company appears only in the session's AI-provenance example.

Hunter thinks both could be cool, and longitude makes room for both:
- **The port takes the near side,** where the giant hangs permanently overhead for
  skimmer traffic and comms.
- **A biotech company takes the far side:** dark nights, no traffic, and a sterile world
  with no native life to contaminate or be contaminated by. A second tenant also halves
  the shield bill.

Today, **near-side ruins are industrial** (docks, fuel, skimmer parts) and **far-side
ruins are biological** (seed vaults, hydroponics, feral strains). Which company's ruins
you're walking through depends on your longitude.

## 3. Working back from the feel

### Gravity and the pressure window

| | Mars-sized | Half-g | Near-Earth |
|---|---|---|---|
| Radius, mass | 3,390 km, 0.11 Earth | 3,900 km, 0.20 Earth | 5,800 km, 0.73 Earth |
| Gravity, escape velocity | **0.38 g**, 5.0 km/s | **0.52 g**, 6.3 km/s | **0.88 g**, 10.0 km/s |
| Giant needed | ≥3 Jupiter masses | ≥6 | ≥23 (a brown dwarf), or a captured moon |
| Walk-to-run switch (Kram 1997) | 1.3 m/s | 1.5 m/s | 2.0 m/s |
| Standing jump in a suit | 0.9 m | 0.7 m | 0.4 m |
| Fall as hard as 3 m on Earth | 7.9 m | 5.7 m | 3.4 m |
| Dust front speed (1.5 km deep, 4% colder) | **10.5 m/s** | 12 m/s | 16 m/s |
| Dust stays aloft, vs Earth | 2.6× longer | 1.9× | 1.1× |
| Pressure for a gale-like shove, at 36 / 30 m/s gusts | **0.12 / 0.17 bar** | 0.16 / 0.23 | 0.27 / 0.38 |
| Wind that lifts sand at 0.2 bar (at 2 m height) | 10 m/s | 11 m/s | 13 m/s |
| Air overhead at 0.2 bar | 540 g/cm² | 390 | 230 |

A "gale-like shove" means wind force at a fifth of your weight (100 kg, suited), the
ratio an Earth gale gives. The game's storms reach 24 m/s with gusts to about 36
(`tuning.tres`). **Lighter bodies feel the same wind harder.** That's why low gravity
opens the window.

**The window: every target at once.**
- **Water:** above the triple point (0.006 bar), and boiling near the afternoon high. It
  boils at 46 °C at 0.1 bar, 54 °C at 0.15, 60 °C at 0.2 and 69 °C at 0.3. Sun-baked
  surfaces pass that, so anything up to ~0.3 bar works.
- **The shove:** from the table.
- **Sand:** prevailing winds of 10 m/s should sit near the threshold, so crests stream in
  gusts and storms move sand everywhere (Shao & Lu 2000).
- **Sound:** carries fine. At 0.2 bar, sources are ~7 dB quieter than on Earth, and
  nitrogen doesn't swallow high notes the way Mars's CO₂ does (Mars is ~20 dB quieter).
- **The suit:** anything above the Armstrong limit (0.063 bar) means you suffocate
  rather than boil.

**Result:** about **0.12–0.3 bar at 0.38 g**, **0.16–0.3 bar at 0.52 g**, and barely
**0.27–0.3 bar at 0.88 g**. At 1 g it's effectively shut.

**What lower gravity changes in the feel:**
- **Dust walls:** a 1–2 km wall at ~10 m/s comes free, because a real cold-air dust
  front at this gravity moves at that speed, and dust lingers, so storm cover is
  near-persistent.
- **Movement:** jumps are floatier, slides down slip faces slower, falls softer.
- **Walking:** at 0.38 g, the game's 1.4 m/s walk is past the switch, so people would
  lope. At ~0.5 g it stays a walk.
- **Rope:** strain doesn't change, because a floating planter's pull is pure drag. A
  0.6 m² planter in a 36 m/s gust pulls ~70–100 N at 0.15–0.2 bar.
- **The garden:** lower gravity is kind to it. Plants need less structure, and water
  climbs more easily, so trees could stand taller.

### Temperature, storms and the sun

- **Long days make it honest.** A 5–7 Earth-day day gives sun-baked ground of roughly
  60–90 °C in the clear tropics, and nights of −60 to −100 °C at clear latitudes. The
  equator's dust blanket holds it nearer −20 to +40 °C. Water freezes overnight and boils
  off by afternoon. These are rough estimates.
- **The dust blanket is measured.** Mars's 2018 storm dimmed the sunlight at Gale crater
  about 5,000-fold and shrank the day-night swing in air temperature by ~30 K.
- **Equator storms feed themselves.** Dust soaks up sunlight, the heated air stirs, and
  more dust lifts: the feedback behind Mars's global storms. The dead garden supplies the
  dust, as the drained Aral Sea did when it became the Aralkum desert.
- **The poles are calm and clear.** The air there is cold and stable, and the polar caps
  sit at the CO₂ frost point (about 170–177 K at 0.1–0.2 bar). The widest swings are at
  about 50–70° latitude.
- **Hiding from the sun in a storm is honest.** With no oxygen there's no ozone, so UV
  reaches the ground unfiltered, and the same dust that dims the sunlight blocks it.
- **The real radiation at the ground is UV.** With 400–540 g/cm² of air overhead (Earth
  has 1,030), particle radiation is mild, so the suit's radiation lining is mostly about
  the sun.

### The giant, the day and longitude

- **Tidally locked:** the day equals the orbit, about 5–7 Earth days at 15–20 giant
  radii. The game compresses it to 20 minutes.
- **The near side:** the giant hangs fixed overhead, 6–8° across, 11–15 times the width
  of the full Moon. Near-side nights are lit by a full giant at **~150–270 lux**,
  hundreds of times brighter than moonlight. That makes the board's "night as safe
  exploration" honest. Every noon brings an eclipse of 2–3 real hours, about 20–25 game
  seconds.
- **The far side:** truly dark nights and no giant.
- **Leading and trailing:** the trailing hemisphere takes the giant's plasma, the way
  Europa's trailing side is darkened by it.
- **Longitude is a real third dial:** light, radiation and which company's ruins.
- **Tilt:** a moon inherits its giant's tilt. Near zero, like Jupiter's 3°, keeps the
  poles cold enough to trap the air, which the story needs.

#### Tu's size, under trial

*Hunter, 2026-10-17 ([lore session](lore-session-2026-10-17-part-2.md)).* The 6-8° above is the
earlier leaning. The session keeps the giant's angular size a tuning value, to be tried at 6°, 9°
and 13° in game before the orbit is fixed, with "physics follows the look." Three presets are
being built and none is chosen. This page picks none.

What each would imply, as arithmetic from this memo's own geometry (an angular diameter of
2 atan(R/d), the full Moon being 0.52°). It is not a decision:

| Preset | Against the full Moon | Distance, in giant radii |
|---|---|---|
| 6° | about 12 times as wide | about 19 |
| 9° | about 17 times | about 13 |
| 13° | about 25 times | about 9 |

The memo puts the moon at 15-20 giant radii, which is about 6-8°, so 6° sits inside it. The 9°
and 13° presets put the moon closer in, toward the Europa end of the memo's list (a bare-surface
dose of about 5.4 Sv a day, against 0.08 and less at 15-20 radii). A closer preset means redoing
the radiation, the tidal heating and the real day, which shortens with the orbit: that is what
"physics follows the look" asks for. The near-side night figure (about 150-270 lux) and the noon
eclipse (2-3 real hours, 20-25 game seconds) were worked for 6-8° and move with the preset, so
they are not repeated for the others until one is chosen. [The moon](the-moon.md#day-length) says
the same in brief.

## 4. Three candidate bodies

- **Mars-sized (0.38 g).**
  - The roomiest window (0.12–0.3 bar).
  - Dust fronts at ~10 m/s straight from the physics, and the most shove.
  - Needs the smallest giant (≥3 Jupiter masses).
  - Costs: walking becomes loping, and everything floats more.
  - Docs: change Movement's gravity to 3.7 m/s².
- **Half-g (0.52 g).**
  - A window of 0.16–0.3 bar.
  - Walking stays a walk, dust fronts move ~12 m/s, and the shove is still easy at
    ~0.2 bar.
  - Needs a ≥6 Jupiter-mass giant (fine; HD 28185 b is at least 5.7).
  - Docs: gravity 5.1 m/s².
- **Near-Earth (0.88 g).**
  - Feels like Earth and keeps Movement's 9.8 nearly as is.
  - But the window is barely open (0.27–0.3 bar), the shove only works at the top of
    it, and water barely boils off.
  - Needs a brown-dwarf host or a captured moon.
  - Dust fronts move 16 m/s, so walls arrive fast.

In all three, thermal escape is irrelevant. Even with a hot 1,000 K upper atmosphere,
the Jeans parameter for nitrogen is 40 (Mars-sized), 63 and 161, so 0.2 bar lasts
10¹³ years or more. Inside a giant's magnetosphere, plasma could strip ~1 tonne a second
(Io's rate), and even that would take ~25 million years to remove 0.2 bar from a
Mars-sized moon. **No size makes the air leak away in `{YEARS_SINCE_FALL}`.** Fading it that
fast would take ~10,000 tonnes a second (worked for the span this memo first assumed; redo
when the placeholder is set). Redone at the placeholder's rough current value (session 4,
part 2; [Placeholders](lore-research.md#placeholders)): about 12,000 tonnes a second for 0.2 bar
from a Mars-sized moon, the same order, so the conclusion stands.

## 5. The shield: what it did and how it fails

> **Superseded by the lore session.** The agreed arc has no sky shield, so the air is not
> frozen back onto the poles or rusted into the sand. It is lost to a slow escape as tidal
> heating fades. The numbers below remain valid as physics.

| Candidate job | Honest at these sizes? |
|---|---|
| **(a) Held a thicker atmosphere that relaxes back** | **Yes, reframed.** The extra air doesn't leak to space; it **freezes back onto the poles.** Mars's surface pressure swings by about a quarter each year as CO₂ freezes onto its caps and sublimes back, and its buried CO₂ ice could roughly double its air (Phillips 2011; Bierson 2016). Condensation is fast (decades), so **the shield's decay sets the pace**: emitters fail over centuries, and the air follows. Nitrogen doesn't freeze, so it's the floor. |
| **(b) Turned the giant's plasma and sputtering away** | **A real job, but not the fading.** It protected ships in orbit and the upper air over millions of years. At 15–20 giant radii the moon sits inside the giant's magnetosphere (Jupiter's would shrink to ~20–47 radii this close to a star), sheltered from the stellar wind. |
| **(c) Kept the UV out, and the oxygen with it** | **Yes in direction, stretched in pace.** It's why the air is unbreathable while the pressure stays. Rusting away 0.1 bar of oxygen at 0.38 g means oxidising ~90 m of sand in `{YEARS_SINCE_FALL}`, about 1,000 times Earth's weathering rate (both figures worked for the span this memo first assumed; redo when it is set). It fits better if the colonial air was only a few percent oxygen, or if most of it went while the garden was dying. |

**Leaning: one shield, all three jobs.** It's a filter over the sky, like greenhouse
glass: sunlight in, UV out, heat kept in, plasma turned away. The game's own shields
already work this way. Light passes through the bubble, and the late-game temperature
shield is the sky's job at camp scale. **The fading is (a) plus (c):** the air goes back
into the poles and the sand.

## 6. The leaning and Hunter's decisions

> **Superseded by the lore session** on two points. Decision 2 (the air goes back into the
> poles) is replaced by the slow escape, and "today's air: 0.15-0.2 bar" by about 0.3 bar
> or more. Gravity stays Hunter's call.

**Leaning:**
- **A moon of 0.4–0.5 g** (radius ~3,500–3,900 km), **around a ~4–6 Jupiter-mass
  giant** at ~15–20 giant radii.
- **A K dwarf's habitable zone,** in a poor system with a Venus inside.
- **Today's air: 0.15–0.2 bar** of mostly nitrogen.
- **The port on the near side, the garden on the far side.**

It's the middle of the window. Walking stays a walk, dust walls come in at about
10–12 m/s on their own, and storm gusts of 30–36 m/s shove like an Earth gale.

**The decisions only Hunter can make:**
1. **Gravity:** move from 1 g to ~0.4–0.5 g? Everything else follows from this. At 1 g
   the pressure window closes and the host becomes a brown dwarf.
2. **The air goes back into the poles:** low tilt, and polar caps holding the missing
   air as dry ice and frost. That makes the poles the place where the colonial sky lies
   frozen.

## 7. What's now wrong in the-moon.md

> **Superseded by the lore session** in part. The first bullet's "it isn't leaking to
> space" no longer holds: under the session it does leak, very slowly and without any
> shield. The third bullet's 0.15-0.2 bar is now about 0.3 bar or more. [The
> moon](the-moon.md) has been updated to match.

- **"Still slowly leaking away since their magnetic shield failed."** It isn't leaking
  to space. It's freezing onto the poles and rusting into the sand, and the shield was a
  light-and-heat filter, not (just) magnetic.
- **"No magnetic field, so radiation reaches the surface."** The moon sits inside the
  giant's magnetosphere, and the air blocks most particles. What reaches the ground is
  UV.
- **"At a tenth to a third of Earth's pressure, a 100–150 km/h storm pushes like an
  Earth gale."** That depends on gravity. It's true from ~0.15 bar at 0.4–0.5 g, but at
  1 g it needs ~0.3–0.4 bar. The pressure range narrows to about 0.15–0.2 bar.
- **"The gas giant lights [nights] faintly."** That's on the near side only, and not
  faintly: hundreds of times moonlight. The far side is truly dark.
- **"No axial tilt" as an open question.** Near-zero tilt is now a feature: it keeps the
  poles cold enough to trap air. The pole itself is a dry-ice cap.
- **The day:** really about 5–7 Earth days, compressed. Add the noon eclipse on the near
  side.
- **In code, not docs:** `loose_wind_catch` = 0.05 implies an air density of ~0.38 kg/m³
  (about 0.3 bar). At 0.15–0.2 bar it would be ~0.03 per half-metre box. At lower
  gravity, loose things also weigh less, so the felt push stays similar.

**Sources:**
- [Hill et al. 2018, giants in the habitable zone](https://iopscience.iop.org/article/10.3847/1538-4357/aac384)
- [HD 28185 b](https://en.wikipedia.org/wiki/HD_28185_b)
- [Canup & Ward 2006](https://www.boulder.swri.edu/~robin/canupward2006.pdf)
- [Heller & Zuluaga 2013](https://astrobiology.com/2013/09/05/magnetic-shielding-of-exomoons-beyond-the-circumplanetary-habitable-edge/)
- [NASA atmospheric mining](https://ntrs.nasa.gov/citations/20150006664)
- [Europa radiation](https://europa.nasa.gov/news/17/radiation-maps-of-europa-key-to-future-missions)
- [Kram et al. 1997](https://cob.silverchair.com/jeb/article/200/4/821/7425/Effect-of-reduced-gravity-on-the-preferred-walk)
- [Mars soundscape](https://www.cnrs.fr/en/perseverance-records-first-ever-sounds-mars)
- [Mars 2018 storm](https://cab.inta-csic.es/publicaciones/mars-science-laboratory-observations-of-the-2018-mars-year-34-global-dust-storm/)
- [Phillips 2011](https://pubs.usgs.gov/publication/70004038)
- [Bierson 2016](https://www.lpl.arizona.edu/~shane/publications/bierson_etal_grl_2016.pdf)
- [Io's supply](https://angeo.copernicus.org/preprints/angeo-2021-10/angeo-2021-10.pdf)
- [Aralkum](https://earthobservatory.nasa.gov/images/146487/a-dusty-day-over-the-aral-sea)
- Saltation threshold: Shao & Lu 2000, *J. Geophys. Res.* 105, D17.
