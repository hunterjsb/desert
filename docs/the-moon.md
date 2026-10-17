# The moon, physically

*Proposal, 2026-10-13, updated 2026-10-14. Not settled yet. This is the physical profile
the systems lean on: wind, storms, temperature and water. The aim is to stay consistent
with real physics everywhere except one deliberate cheat. Where the [lore
session](lore-session-2026-10-14.md) overrides it (the air's origin and its pressure), this
page follows the session.*

## Where it is

A moon of a gas giant, with the giant orbiting in the warm part of its star's habitable
zone. Moons like this are a real idea in planetary science: a moon can get Earth-like
sunlight from its star, plus some warmth from its planet's tides.

## The one cheat: compressed distance

A lap of the moon is **about 150 km** in the game, so circling it is an epic and the
poles are reachable. That's compressed distance, the same way the 20-minute day is
compressed time. **The real body is far bigger** (decided 2026-10-14): nobody in the
world lives on a 24 km rock. A body that small couldn't hold gravity or air. The real
size is whatever makes the rest of this profile honest; [the body research](body-research.md)
works it out from the feel we want. The leaning is **0.4–0.5 g** (a radius of roughly
3,500–3,900 km), pending Hunter's call. The game's gravity is unchanged for now, and the
dev gravity toggle tries the lower value. **Everything else stays honest.**

## The air: thin, unbreathable, fading

- **There has to be an atmosphere.** With no air there's no wind, no storms, no dunes
  and no sound, and liquid water can't exist at all.
- **It's thin:** about 0.3 bar or more, around a third of Earth's pressure, mostly
  nitrogen. It's the moon's own air: what it formed with, topped up by volcanoes during
  its long eccentric-orbit phase. As the tidal heating fades, topping-up falls behind a
  very slow escape, which is a geological backdrop, not something you'd see. **Agreed
  (session 3):** the lore reads the leak as a clock. Storms last only while air remains, and
  the player arrives with the window closing ([the lore
  research](lore-research.md#the-surface-today-agreed-session-3)). **Agreed (session 4, part
  2):** the orbit was more eccentric when the colonists came and has been rounding out since, so
  the heating fades and the vents go quiet ([the lore](lore-research.md#tu-the-tidal-lock-and-the-water-agreed-session-4-part-2)).
- **Thin air still makes real wind.** Mars, at under 1% of Earth's pressure, has global
  dust storms and moving dunes, but its winds would barely push you. At 0.3 bar, 130 km/h
  gusts push like an Earth gale even at near-Earth gravity (at the leaning 0.4–0.5 g,
  0.15–0.2 bar would do). That matches the wind we want: strong enough to drag you and
  strain ropes.
- **You can't breathe it,** so the suit supplies your air.
- **The radiation at the ground is mostly UV.** The moon sits inside the giant's
  magnetosphere, and the air stops most particles. With no oxygen there's no ozone, so
  the sun's UV arrives unfiltered. The suit shields you from that too.

## Temperature

- **Days are hot and nights freeze**, even at the equator. Thin, dry air holds little
  heat.
- **The storms blanket the equator.** Dust in the air absorbs sunlight by day and
  radiates heat at night, so storms shrink the day-night swing. That's been measured
  on Mars. It's why the stormy equator is milder and the clear poles swing wider: hotter
  days, colder nights. The latitude dial is real physics.

## Water goes through all three phases every day

Liquid water needs enough air pressure; below about 0.6% of Earth's, ice turns straight
to vapour. At our pressures liquid water can exist, but it boils at a low temperature:
about 60 °C at 0.2 bar, and about 69 °C at 0.3 bar. So on a hot afternoon, open water
boils off, and at night it freezes.

**Every day, water freezes overnight, melts at dawn and boils off by afternoon.** That
gives water a daily rhythm:

- **Frost and dew form in the cold hours,** more of it toward the clear, cold-night
  poles. Harvest it at dawn.
- **Open water doesn't last.** It has to be stored sealed.
- **Condensers pull water from the air.** They're found, they draw power, they can be
  towed, and they work best at night, and better toward the far side (below).
- **Plants that store water,** like the yucca.
- **Sealed fresh water in ruins** keeps you going early on.
- **Water drifts to the far side** (Agreed, session 4, part 2). The near side is heated by the
  sun and by Tu's infrared, and the far side runs colder. Water evaporates on the warm side and
  cold-traps as frost and ground ice on the far side. While the vents outgassed they topped the
  near side up, and once they quieted it drained outward. This stands beside the poles' frost
  above, and how the two cold traps combine is open.

## Day length

A day lasts about 20 minutes, start to finish, and it's fixed. That's compressed game
time, the way most survival games handle days. **Zan is tidally locked to Tu** ([the Tu
spec](tu-and-day-2026-10-17.md), 2026-10-17): one face always points at the giant, and the
real day is one lap round it.

**Three sizes of Tu are under trial** (Hunter, 2026-10-17, lore session part 2: "Keep
angular size a tuning value; test 6°, 9° and 13° in game before fixing the orbit. Physics
follows the look."). The tuning value is how wide Tu is across the sky. The orbit, the
eclipse and the night light follow from it, and a dev command switches among them during a
run. 13° is the default. None is chosen. The working is in [the body
research](body-research.md#tus-size-under-trial).

| | 6° | 9° | 13° (the default) |
|---|---|---|---|
| Orbit, in Tu radii | 19.1 | 12.7 | 8.8, Io-like |
| Real day, at 4 Jupiter masses | 6.0 Earth days | 3.2 | 1.9 |
| Totality | 16 game seconds, 24 from first contact to last | 26 s, and 34 | 40 s, and 47 |
| A full Tu's light at night | about 140 lux, 0.14% of the sun's | 310 lux, 0.31% | 640 lux, 0.64% |
| Walk for Tu to rise or sink by its own width | 2.5 km | 3.8 km | 5.4 km |

**Tu hangs fixed in the sky,** at a place set by where you stand: overhead at the sub-Tu
point, lower the further you are from it, on the horizon 90° away, and never seen on the
far side. Its height tells you how far you are from that point, and its bearing which way.
It nods by about a degree over each day, since the orbit is slightly eccentric. On the
compressed lap a degree is about 420 m, so a few kilometres' travel moves it plainly.

**Local time follows longitude.** The sun and the stars turn round the sky once a day and
only Tu stays put, so the further east you are, the later in the day it is. There's still
no axial tilt: the sun rises due east and sets due west everywhere.

**Runs start on the near side, 60° of longitude east of the sub-Tu point,** so Tu stands
30° up, due west. The start keeps the clock it had: a run begins at 07:12 local, the sun
coming up behind you and a bright, waning Tu ahead.

**The eclipse.** Once a day the sun passes behind Tu, and the whole near side sees it
total. Tu is far wider than the sun, so the partial phase either side lasts only a few
seconds. The sky and the sunlight drop near dark and the stars come out, the sun's corona
and a red ring of sunset light on Tu's rim show briefly, the air cools a few degrees, and
solar makes nothing, so a camp needs storage or wind to ride it out. It falls at noon at the
sub-Tu point and later the further east you are: where a run starts, at 16:00.

**The Rim** (Hunter, 2026-10-17, lore session part 2). Between the near side and the far
side lies the Rim, where Tu sits half-risen on the horizon, 90° from the sub-Tu point: no
eclipse to speak of, and mild ([the
lore](lore-research.md#tu-the-tidal-lock-and-the-water-agreed-session-4-part-2)). Nothing
special is built for the eclipse there: the sun goes behind Tu where Tu is in your sky, and
there that's on the horizon, as the sun rises or sets, when it has next to no light to lose.

**Tu's phases run opposite the sun:** its dark face at the eclipse and full half a day
later. At the sub-Tu point that's noon and midnight; where a run starts, full Tu comes at
04:00.

**Nights.** On the near side Tu lights the night: a weak, cool light from Tu's direction,
scaled by its phase, a thin crescent's after the eclipse and a full Tu's in the small hours.
It's far too weak for panels. Its brightness has a tuning scale of its own on top of the
physical value, 1 by default, so how bright a night is can be tuned apart from Tu's size. The
game has no eye adaptation, so at 1 a full-Tu night reads on screen as deep night, the dunes
barely there: a seventh of the light the game's nights had before at 13°, a fifteenth at 9°
and a thirty-fourth at 6°. At 13° and a scale of 3 the dunes read and it's still plainly
night; at 10 it's an overcast dusk (`~/Desktop/tu_more.png`).
The far side never sees Tu, and its nights are truly dark, lit by the stars alone.

**The stars** turn once a day round the spin axis. A bright star marks the north celestial
pole and a close pair the south, so the height of either above the horizon is your
latitude, and the same stars at the same local hour, night after night, show how far east
or west you've come. Tu's disc, the sun and the dust hide them.

**Open** (quoted in [the body research](body-research.md#open-after-the-tu-spec-2026-10-17)):
which size; where runs start relative to the sub-Tu point, and whether they
reach the far side; whether the eclipse kicks the weather; Tu's body number; and Tu's
palette ([art direction](art-direction.md#open-questions)).

**Open: seasons** (deferred by Hunter, 2026-10-14). The skeleton gives the moon no axial
tilt, so the sun rises due east, sets due west, and climbs only as high as the latitude
allows. Near-zero tilt is now the leaning: it keeps the poles cold, with CO₂ and water
frost caps. A tilt would add seasons.
