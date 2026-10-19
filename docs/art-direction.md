# Art direction

*Draft, 2026-10-16. Hunter picked **B, chunky worn industrial, for now**. It lays out the
candidate looks for the game's things, shot side by side in the real world, so the choice
came before any real asset. Every game object keeps its grey-box shape until the loop
works, now painted in B (below); the look-test is `look/style`.*

## The test

One small camp beside the corner of the ruin nearest the run's start, on seed 1234 on the
Ridges dunes with the sand shader, in the game's own light, haze and storms: a floating
crate frame with a hover tray, a battery and a hook; a planter with seedlings and a sapling;
the shield generator with its bubble up; a stake with a line to the crate's hook; and a
charger under a solar panel. They're the game's own devices, sizes, sockets and rope, with
each candidate drawn over them, so only the look changes. B, C and D also lay two finds in
the sand in front of the camp: a crude surface-era lamp made from a can, and an overbuilt
sealed colonial module whose light is still on.

Shots, each candidate beside today's grey boxes: the camp from 8 m at morning, mid-morning,
noon and dusk; from 50 m, and that frame's middle blown up two times; the crate from 5 m,
also blown up; the crate close up; the two finds; and from inside the bubble in a storm.

    look/style/shoot.sh <out dir>

The sheets are `~/Desktop/style_<shot>.png`; the full-size frames weren't kept, and the
command above shoots them again.

The stencilled marks (RMC, B-07, FIELD UNIT T2, SC HM-3, HYDRO-4) are placeholders that
show where marks would go, not names.

## The candidates

### A. Sand Game's models, as they were

Its shield generator (`sg3`), dome planter, tether post and walk-in ruin (`ruins01`), copied
from the `archive` branch. Sand Game never had a crate, battery, hover tray, charger or panel,
so those stay grey boxes. Its `outline01` shader turns out to be a highlight for what you're
aiming at (zero width at rest), not a style, so it isn't used.

- **Production cost:** these look generated and lightly cleaned up: 10k to 23k triangles
  each, scaled to a 2 m box, one baked texture each, and generator-style file names. That's
  cheap to make, but every one needs rescaling, turning upright and sockets placed by hand,
  and each one comes out in a different style.
- **Readability:**
  - **Battery or hook at 5 m:** there's no battery or hook to compare.
  - **Device against sand at 50 m:** the devices don't stand out, but the ruin does, from
    far off.
  - **Sockets:** there's no socket language at all. The dome planter hides its slots.
- **Fit:** the ruin is the best single object in the test, a warm painted mass that sits in
  the haze. Its lighting is baked into the texture, though, so it fights the real sun at
  morning and dusk. Next to it, the grey boxes look like a different game.
- **Frame cost:** the same frame time as grey. About 57k more triangles in view.

### B. Chunky worn industrial

Bevelled hard-surface pieces: posts, rails, inset panels with a seam, corner caps, bolts,
bezels. Company-issue paint: gunmetal frames, teal panels and safety yellow, with the shield
in a different maker's bone white. One shader wears every piece without UVs. Paint chips at
edges and corners down to bare metal, old chips go red with rust, faces turned to the
prevailing wind are scoured pale, and sand settles on what faces up and along the foot. Each
socket has a dark bezel with a tab in its kind's colour. The colonial ruin is poured concrete
with formwork seams, tie holes, a faded painted band, a sector stencil and corner guards.

- **Production cost:** the most expensive by hand: hard-surface modelling in Blender with
  bevels, trims and decals for marks. The test suggests a cheaper route, though: a kit of
  bevelled pieces assembled in Godot, plus the one wear shader driven by a wear amount, got
  this far with no textures and no unwrapping. A kit is mid-cost; hand-made assets are high.
- **Readability:**
  - **Battery or hook at 5 m:** only just. The battery reads by its charge strip, and the
    steel hook against the teal. The dirt that sells the look also mutes the parts.
  - **Device against sand at 50 m:** no, only the bubble does.
  - **Sockets:** they read well close up. The bezels look like somewhere a part goes.
- **Fit:** the best fit with the sand shader and the haze; the scour and dust tie the
  devices to the ground. The ruin is the strongest version of the game's own ruin. In the
  storm the teal and gunmetal go to brown silhouettes, and only the glows and the bone
  white still read.
- **Era cue:** this is where "older is better" reads best. The can lamp is rust and rag; the
  colonial module is crisp, deep-chamfered ceramic white with a gold contact strip and a lit
  status light. The shader's wear amount (0.06 against 1.0) does half the work.
- **Frame cost:** the same frame time as grey. About 700 draws against grey's 210, since
  every piece and stencil is its own mesh here; real assets would merge each device into one.

### C. Low-poly, flat-shaded, tight palette

Chamfered blocks and few-sided drums, faceted, in six colours and a glow: teal, cream,
coral, charcoal, mustard, sage. The battery is mustard, hooks are cream, the tray's edge is
coral, and sockets are charcoal plates with a dot in their kind's colour. The ruin is one
flat colour with a painted gradient (darker at the foot, each wall's facing a shade apart)
and a teal band.

- **Production cost:** the cheapest. Simple shapes and one material per colour, made quickly
  in Blender or straight from primitives in Godot, and it scales to many devices.
- **Readability:**
  - **Battery or hook at 5 m:** yes, the clearest of all: mustard block against cream ring.
  - **Device against sand at 50 m:** the teal crate is a dot you can just pick out.
  - **Sockets:** they read as plates. Clear, but plain.
- **Fit:** it's clean against the sand. Without texture, though, the big planes go flat:
  the ruin needed a painted gradient to read as built rather than as cardboard. Cream and
  mustard survive the storm best.
- **Era cue:** a red can against a white block. It reads only by colour and shape, so the
  difference in quality between crude and overbuilt is mostly lost.
- **Frame cost:** the same frame time as grey. About 310 draws.

### D. Cel-shaded and inked

C's shapes and palette, drawn as a picture-book: two flat light steps, a warm rim, and a
dark ink line round every silhouette (an inverted hull), the ruin included.

- **Production cost:** the same as C, plus two shaders. The ink is a second draw of
  everything, and faceted meshes need care, since the hull opens at hard edges.
- **Readability:**
  - **Battery or hook at 5 m:** as clear as C.
  - **Device against sand at 50 m:** the best of the four, since the ink makes each device
    a dark mark.
  - **Sockets:** as C.
- **Fit:** the weakest. The sand, haze and storm are rendered realistically and aren't
  inked, so the inked devices look like stickers on a photograph. It would only cohere if
  the whole world went that way, ground and storm too.
- **Frame cost:** the same frame time as grey. About 490 draws: the ink doubles C's.

## What the sheets show across all of them

- **At 50 m the camp is the bubble.** In clear air the shell's dome reads from 50 m in every
  candidate, while the devices are a few pixels. Distance readability is the shield's job,
  and maybe a lamp's or a mast's, not paint's.
- **In a storm the camp is its light.** Inside the bubble everything goes to brown
  silhouettes, and what reads is what glows (the shield, the battery strips, the tray's
  emitters) and whatever is white. Whichever style is chosen, the storm look gets decided by
  emissives and the warm light inside the bubble.
- **Frame time isn't a deciding factor:** the GPU took 2.2 to 2.3 ms for every candidate,
  grey included. (Other Godots were running probe suites alongside, so the times are rough;
  the draw and triangle counts aren't affected.)
- **The sockets' kind colours** already in the game (amber battery, blue tray, green top)
  work as accents in every style. B shows them as bezel tabs, C as dots.

## First impressions (Claude's, not a decision)

B carries the world best: the maker's marks, the wear and the colonial-against-crude
contrast are all in it, and it sits in the sand and haze most naturally. C reads best:
parts are unmistakable at 5 m and it's the cheapest to make. A middle way might take B's
bevelled kit, wear shader and marks, and keep C's discipline: a tight palette, with
saturated kind-coloured parts (amber batteries, bright hooks) that survive the dirt and the
storm. A shows what generated models look like here: a striking ruin, but a camp that
doesn't hang together. D needs the world restyled along with it.

## Where Hunter is

He liked all four, weighed B against C with D as the runner-up, and went with **B for now**
(2026-10-16). "For now" keeps it open to the community's view and to C's readable parts.
A paint pass brings B's palette and wear shader onto the game's grey shapes ahead of any
real asset (left to Claude, 2026-10-16); models wait for the loop.

## As painted

*2026-10-16.* The game wears B on its grey-box shapes, which are unchanged, collision
included. The shaders live in `game/look/`, and the look-test reads the same copies. Each
device and part is one merged mesh in one shared material. How sound a device is drives
its wear, so the weather chips it, rusts it and finally takes it down to the metal. A
find's layer sets where its paint starts: a deep one is crisp and a surface one rusty.
Free sockets show a dark bezel with a tab in their kind's colour, and charge lights are
as they were. The ruin is poured concrete, with formwork seams, tie holes, a faded band and
a stencilled number by each corner. Maker's marks came next (below). To shoot the camp,
finds and ruin before and after: `look/paint`.

**Flicker,** fixed after Hunter's first play (2026-10-16). Pieces of one look that shared a
face's plane fought over its pixels as the camera moved. These were the crate's corner caps
against its posts and rails, the condenser's lid against its posts, the planter's rim against
its tub, the light panel's base against its rails, the hoverboard's nose band inside its deck,
and a socket tell's tab against its plate. Each now stands a few millimetres proud or inside.
The ruin's formwork seams, tie holes, band and stencils, and the paint's chips, now soften by a
pixel's footprint, and the seams fade out by about 30 m, as the sand's ripples do. To shoot the
runs that show it, use `look/marks` with `--motion`. What still crawls is the edges of thin
pieces, such as rope and louvres: the project draws without antialiasing.

**Crops** (2026-10-17). Each crop has a look at each of its stages, built in B's kit of
bevelled pieces, balls and drums, and it grows into each stage before the next replaces
it. Plants wear no paint, so nothing of them chips; they hold a little sand. The
root-tuber is a potato's leafy top over a mound of soil, its tubers swelling at the
mound, and mature its top flowers white and yellows at its lowest leaves. The vat fungus
is a white mat of mycelium that pins as it matures and, fruited, three tiers of grey-brown
oyster fans over cream gills on a pale stem. The saltbush is woody stems branching low
into small oval leaves silvered by their salt, held level to the sun; folded, the leaves
close up against their stems, a pose in steps of a sixth. Every look of every stage is
built while the world loads. `look/crops/shoot.sh <dir> [sheet]` shoots each crop at each
stage in a planter on a clear morning, unseen; the sheet from 2026-10-17 is
`~/Desktop/crops.png`.

## Eye adaptation

(Hunter, 2026-10-17: "add eye adaptation".) The camera adapts to the light as an eye
does, so a Tu-lit night reads as night with the dunes still there, and stepping from a
bright day into a storm, or out of an eclipse, takes a moment to see. Tu's light stays
physical; the eye does the rest.

**As built** (2026-10-17). Tu-shine stays at 1. The eye opens the camera's exposure
in the dark, but only so far: a night still reads as night.

**Retuned for 9°** (2026-10-17), once 9° became the default. Hunter found the full-Tu
nights at 13° bright enough, and at 9° such a night has half their light, so the eye now
opens further in the deep dark: a full-Tu night at 9° reads as the 13° one did, and a
storm by day is as it was. Only the eye's own numbers moved (its line, share and
floor); Tu-shine stays physical.

How it looks, where a run begins with Tu 9° across, each moment before and with the eye
(`look/eye/shoot.sh`; `~/Desktop/eye_adaptation.png` is the sheet from before the retune,
at 13°):

| Moment | The eye | The sand (L*), before and with it |
|---|---|---|
| Noon, any clear day, dusk, a veil of dust | as before | 81, 81 at noon |
| Deep in a storm by day | 1.4 times | 22 to 27: it stays oppressive |
| A full-Tu night, facing away from Tu | 6.2 times | 0.7 to 4.5, as the 13° night read before (at 13° now, 6.6) |
| The same night, facing Tu | 3 times | 0.8 to 2.4 |
| A crescent night, the far side | 7 times, the floor | under 1: dark, the stars out over the dunes |
| Totality begins | 1.1 times | black |
| Totality's last second, 25 s in | 6.7 times | 2.3: the sky off black, many more stars, the land faintly red |
| The sun back, 1 s on | 1.7 times, still open | too bright for a moment, as before within two seconds |

**What it reads.** A meter takes each frame's light on the GPU before the tonemap,
so the exposure it leads to never feeds back into it: all the light in the frame,
which is what a pupil follows, and its brightest patch. So whatever is in view moves
it, as with an eye. Tu's disc in view at night holds it to about three times, so Tu's
bands never burn out; look away and the dunes come back within a few seconds. The
headlamp's pool in a black storm holds it partly closed, so the beam reads much as it
did, and the dark beyond stays dark. It takes the light in over half a second, so dust
flickering past doesn't pump it. At the menu, in its storm, the frame's own light swings
by half again with the billows over ten seconds, and the eye by under a tenth against
them. In the clear it doesn't move.

**Its bounds.** It opens only once the frame is dimmer than about a thirteenth of noon's.
That's the ceiling: noon, and anything brighter than a dusk, look exactly as before, and
nothing is ever darker than before. Below that it makes up about half of each halving
of the light. And it never opens past 7 times, the floor, so a black far-side night
stays black, not grey noise. The sky used to dither itself before the tonemap,
and opening the eye made that a coloured hatch on dark skies. The dither now comes
after the tonemap, project-wide.

**How fast.** It opens in two parts, as an eye does. The first doubling comes in about
three seconds, as a pupil widens. Past that it goes slowly, a doubling in about
fourteen seconds. It closes fast, a doubling in under half a second. So stepping into a
storm it has settled in about two seconds. Totality lightens through its 26 seconds:
3 times by 8 s in, 6 by 22 s, nearly 7 by its end. A glance at Tu costs only the pupil's few seconds to get
back. A cut doesn't carry over: a new run, a jump of the clock and a scenario each start
the eye settled.

**Why not Godot's own.** Godot has its own auto exposure (`CameraAttributesPractical`).
Between its two bounds it makes up every change in the light, so every scene in that
range shows as bright as every other. It has one speed both ways, and nothing reads it
back. For noon to stay as it is while a full-Tu night got about 6 times, its bounds
would have had to lie a factor of six apart, just under noon. Then a storm would have
been lifted as far as the night, a dusk made as bright as noon, and totality would
have gone no deeper. So the eye is our own: `game/weather/eye.gd`, fed by
`game/weather/eye_meter.gd`. Tuning's Eye group holds its line, share, floor, white
and speeds.

**Fair tests.** Tuning's `eye_adapts` switches it off, back to the fixed exposure.
Every look-test that builds the world switches it off, so its shots and readings compare
across builds. `look/tracks` and `look/headlamp` take `--eye` to read as the eye sees.
`look/eye/shoot.sh <dir> [sheet]` shoots each moment both ways, and times the eclipse
and the step into a storm. `look/menus` keeps the eye on, as the game plays, and says
how far it swung. Headless draws nothing, so in probes the eye never reads and the
exposure is as before. Probe 13 (Wind & storms) hands the eye readings itself.

**Cost**, on the RTX 3070 at 1920x1080 with other Godots running alongside, so rough:
the meter takes 0.04 to 0.08 ms a frame over five runs (in the last, 2.31 against 2.25
by day and 5.00 against 4.92 in a storm), and the dither after the tonemap next to
nothing (0.00 and 0.03).

**What's fragile.**

- It was tuned where a run begins at 9°. At 13° a full-Tu night has twice the light, and
  the eye still opens 4.5 times, so it reads brighter than it used to (6.6 against 4.5).
  At 6° it has under half, the eye stops at its floor, and the sand reads 2.4.
- The retune opens anything darker than a storm by day further than before, and
  anything between that and the line a touch less. A storm by day itself didn't move;
  deep dusks and storms at night weren't shot again.
- Anything bright in view closes it a little, as it would an eye. A lamp's bulb close
  up or a shield's glow does too, which could read as the eye "flinching" by a camp at
  night.
- The bright patch is 64 pixels across. On a 4K screen that's half the size in the
  view, so smaller bright things count.
- The reading comes back a frame or two late. That's harmless at these speeds.
- Only the player's camera has the meter. Another camera, if one is ever added, would
  keep the last exposure.

## Maker's marks

*2026-10-16, mapped onto [session 3](lore-session-2026-10-16.md) the same day. Loose, not
canon: the names are the lore's, and every design is a rough placeholder.*

Six rough marks on a few things: a contractor's tag, a member state's seal, two makers' signs,
a crate's label and a crew's patch. Each is painted where its lore says it belongs, so a mark
means something wherever it appears. They're stencilled or stamped on with the paint, so the
same wear chips, scours and dusts them: a deep find's mark is crisp, and a surface one's is
ragged and flaked in patches. They read close up; at 5 m they're a smudge.

| Mark | What it stands for | Carried by |
|---|---|---|
| **Contractor's tag:** "RMC" on a notched plate | A corporate builder of the colonial era: the Remote Moon Contractor, who built the hub's infrastructure and fitted what was bought in ([part 1 §4](lore-session-2026-10-14.md#4-whos-there-the-entity-stack), [part 2 §1](lore-session-2026-10-14-part-2.md#1-the-oem-tier-who-actually-makes-things)) | The condenser; a found shield's housing; the ruin, beside each stencilled 07 |
| **Member state's seal:** rings round a chevron, in another hand's paint | One of the governments the UG federated, before it stood as one: early ruins show member-state and corporate markings that don't match ([session 3](lore-research.md#factions-agreed-session-3)) | The ruin, beside the contractor's tag |
| **Shield maker's sign:** a bubble on its ground, the emitter beneath | The main shield OEM, the common make; it's unnamed, and "Acme Shield Corporation" is the lore's own placeholder ([part 2 §3](lore-session-2026-10-14-part-2.md#3-shields)) | The light shield you start with, on its body; a found shield, small, on its emitter cap |
| **Wind maker's sign:** three vanes in a ring | Wind's maker, a different one from solar's ([part 2 §4](lore-session-2026-10-14-part-2.md#4-power)) | The turbine |
| **Consignment label,** by era | The box says who ordered it; the parts inside say who made them ([part 2 §1](lore-session-2026-10-14-part-2.md#1-the-oem-tier-who-actually-makes-things)). The deep one is Tilg's, stencilled in the capitals of the acronym it still was, the shipping line that registered Zan as a temporary transshipment hub ([session 3](lore-research.md#factions-agreed-session-3)) | The crate frame's two ring sides |
| **Skimmer crew's patch,** painted by hand: the giant, a dive across it, a tally | The hoverboard as skimmer-culture personal gear, not official issue ([lore research, question 11](lore-research.md#13-open-questions-for-hunter)) | A found hoverboard's tail, which is what shows when it's found nose-down; a board of your own is new and plain |

**Why these.** The marks go where the lore names a maker or issuer. The ruin's wall shows
session 3's early markings that don't match: a corporate builder's tag and number beside a
member state's seal, in two hands' paint. The same contractor's tag on the devices found in the
sand lets the player tie them to the buildings. Its build-out is the overbuilt colonial tech
([part 1 §6](lore-session-2026-10-14.md#6-history-runs-backwards-in-the-ground)), and corporate tech lies deepest
([session 3](lore-research.md#the-surface-today-agreed-session-3)). The two shields show issuer
against maker. The light shield was bought new, so it carries only its maker's sign. A found
one carries the tag of the contractor who fitted it, with the maker's sign small on the core
inside. The crate is the lore's own example of the box and its label.

**Left blank on purpose.** Batteries and the other commodity parts carry no mark ([part 2
§4](lore-session-2026-10-14-part-2.md#4-power)). So do the survival kit and the charger, since the lore doesn't say who made
them, and inventing an issuer would be making canon. The next candidates were left out to keep
this to a few:

- the planter, as ag-tech issue (session 4, part 4 names the maker: Frontier Ag, one of the main
  remote colonial contractors, with its grow crates and its crops);
- the solar panels, from a big commodity OEM;
- Standard Freight's plain, severe stamp, for when hull wreckage or war-era materiel is in the
  game.

**How era shows.** The atlas has a row per era: a recent make (yours), the surface and the
deep. A found device takes its layer's row. So far the crate's label is the mark that changes
most from row to row:

- **Deep:** "TILG" over "XN 0217", Tilg's consignment stencil in the acronym's capitals (it
  hasn't worn into "Tilg" yet: [the names](lore-research.md#slang-and-name-erosion-agreed-session-4-part-2)),
  crisp, routed by the system's official code. The X form is old and official
  ([names](lore-research.md#hierarchy-and-the-name-decay-agreed-session-3)).
- **Surface:** "ZN" daubed back on by hand in rust red: a copy from memory, on the way from XN
  to Zan, with the X said and written as a Z. It's late, a Dark Age or second-age form (a
  reading: hands that no longer read the code, where the First Kingdoms kept their archives; [the
  lore](lore-research.md#era-names-again-agreed-session-4-part-4-corrected-in-part-5) restores the
  Dark Age),
  and session 3 dates ruins by which form appears. **Decided (session 4, part 2, 2026-10-17):
  the Z stays.** "The hand-daubed 'ZN' consignment mark is intentional drift from XN."
- **Yours:** a plain batch number, "LOT 3127", for a recent, cheap make. Session 4, part 2 says
  the Surveyor's starting gear "is company issue, which fits the existing 'new' mark row and its
  cheap batch stencil."

The crew's patch has only two states: a found board carries it, and a board of your own is
plain, since nobody has painted it yet.

Wear does the rest, from the same amount that wears the paint: ragged edges, patches flaked
away, scour on the windward side and sand on what faces up.

**The strata.** Session 3 has three strata: corporate tech deepest, skimmer-era salvage in the
middle and the forged goods of the First Kingdoms to the second age near the surface. The game
has two layers so far. The deep
one carries the corporate and colonial marks (the contractor, the seal, Tilg) and also the
crew's patch, since boards are found deep. Once a middle layer exists, the patch belongs
there. Military gear carries no mark yet, since there's none in the game. Session 3 makes it
extremely rare and brought only by deserters (session 4, part 2 adds what the Provisional built
on Zan itself), and its marks would be the war era's standardised, severe ones.

**Placeholders.** Every design and ink colour is a placeholder. So are these:

- "RMC," the Remote Moon Contractor, is part 1's working name. Session 3 names no builder.
- The member state is unnamed, and so is its seal.
- The shield maker and the wind maker are unnamed.
- In "XN 0217", only XN comes from the lore; the number is invented. The moon's own
  designation, XN-118-7, stays off crates.
- "ZN" is an invented form on the lore's path from XN to Zan. It stays (session 4, part 2).
- "LOT 3127" and the patch's design are invented too.

**How it's built.** It's one atlas, `game/look/marks.png` (six columns by three rows, 1536 ×
384), drawn by `game/look/marks.py` (Python 3 with Pillow, lettered in the repo's Geist Mono).
Red is each mark's own ink (dark or pale), and green a hand-mixed daub. `Paint.Pieces.stamp()`
paints a mark on the next piece's faces that turn its way, and the marks travel as UVs on the
merged meshes, so there are no new meshes, materials or per-instance textures. The worn and
ruin shaders share the atlas.

**Cost.** Against master, every shot draws the same calls and triangles. The GPU time was 1.5
to 3.2 ms against master's 1.8 to 3.7 ms, but other Godots were running probe suites
alongside, so the times are rough. Each pixel of worn paint or ruin costs one more texture
read. The atlas is under 3 MB of video memory with its mipmaps, loaded with the paint.

**Shots.** `look/marks/shoot.sh <dir>` shoots this build; `--sheets <before> <after>` builds
`~/Desktop/marks_<thing>.png`. Each marked thing is shot close up and from 5 m, and a deep and
a surface crate side by side.

## Shape by era

*Hunter, 2026-10-17 ([notes](session-notes-2026-10-17.md)); asked for, not drawn.* "Device models
should differ by era in shape, not just maker's marks. The shield comes first."

Today an era shows in paint and marks only. Wear "does half the work" (B, above), the atlas has
a row per era, and every shape is still a grey box wearing B. The notes want the silhouette to
tell the era too. What each era's gear is like is in the other docs: colonial is crisp and
overbuilt (B's era cue), and the finds of the ages after the collapse are worn, reused space-age
items with carvings ([Salvage & ruins](prd/salvage-and-ruins.md#gear-and-ruins-by-era)). Not said: what
any era's shield looks like. The built light shield is round and bone white, and the notes' new one is
flat ([Bubble shield & camp](prd/bubble-shield-and-camp.md#the-carried-light-shield-and-the-starts-not-built)).

**The table (Agreed, session 4, part 5; named, not drawn).** [Session 4, part
5](gods-gear-farside-2026-10-17.md) answers it, section 4, for three eras. It supersedes the notes'
"light, cheap and fragile" skimmer-era crate and "practical to drag" first-age crate as the story of
the shapes; the stats are in [Devices & mods](prd/devices-and-mods.md#frames-by-era-agreed-session-4-part-5-not-built).

| Era | Feel | Shape | Materials | Colour |
|---|---|---|---|---|
| Colonial | Industrial | Rounded rectangles, chamfered edges, modular panels | Composites, alloys | Off-white, grey, safety orange |
| First Kingdoms | Maintained heirloom | Colonial geometry intact, plus crests, flared caps, filigree vent grilles | Original kept clean; brass and copper fittings; hardwood or bone handles | Faded colonial base, house-colour enamel bands (deep red, ochre, teal) |
| Second age | Devotional relic | Asymmetric and organic; lost parts rebuilt in other forms (round ceramic cap on a square housing); bulges, wraps, tassels, charms, water vials | Salt-glazed ceramic, sand-glass, saltbush wood, fern cord, leather; metal only where original survived | Bone white, sand, rust, clay; deep water-blue glaze only on Cistern-touched items |

"First-age gear is a machine with decoration; second-age gear is a craft object with a machine buried
inside. Late-game camps should mix eras on purpose."

Readings, not in the session:
- **The colonial row is the grey box's cousin.** Rounded rectangles with chamfered edges are what the
  grey boxes already are with their corners taken off, and "off-white, grey, safety orange" sits with B's
  chunky worn industrial and the deep marks' crisp stencils. The built light shield's bone white is
  the second age's colour more than the colonial one's.
- **The First Kingdoms row is colonial plus dressing.** The geometry is the colonial one, so one frame
  can wear both: add the crest, the flared cap and the grille, repaint the band in a house colour. Its
  house colours (red, ochre, teal) are the houses' enamel, which the heraldry in "Marks by era" sits on.
- **The second age's colour is the sand's.** Bone, sand, rust and clay are the dunes' own, so
  second-age gear blends in and the blue glaze is the one thing that doesn't: the Cistern's mark.
- **The skimmer era has no row.** The notes' skimmer crate was "light, cheap and fragile"; part 5's table
  skips it. Its look (hasty, welded, improvised) is B's wreckage texture, and nothing here draws it.
- **One shield first.** The notes asked for the shield to change first. Three silhouettes of one device
  (a chamfered housing, the same with a crest and a vent grille, and an asymmetric one with a ceramic cap)
  is the smallest test of the table.

## Marks by era after the collapse

*Session 4, part 2 ([lore session](lore-session-2026-10-17-part-2.md)); named, not drawn, and
none of it is in the atlas.* The atlas stops at the colonial, surface and new rows. The session
names what the ages after the collapse would carry, to be drawn when there is a find to carry it:
- **First Kingdoms** gear carries heraldry and guild stamps (houses such as Okafor, Kessel,
  Arkwright and Vante; the guilds of the keepers).
- **Second-age** gear carries religious symbols (the faith of Tu).
- **Homesteader** gear carries civilian brand marks, not Tilg's.
- **Carvings and daubs** use the worn slang (Monward, Hanmen, Zanborn, the tu- prefix) and the
  worn names (Zan, Tu, Han, Mon, Aitch): [the names](lore-research.md#slang-and-name-erosion-agreed-session-4-part-2).

### Layered marks (Agreed, session 4, part 5; named, not drawn)

*[Session 4, part 5](gods-gear-farside-2026-10-17.md), section 3; none of it is in the atlas.* The
Dark Age made the second age's gear by remaking older gear, so a remade item can wear all its past:
"a colonial maker's stamp, First Kingdoms heraldry scratched over it, Dark Age repair work holding it
together. Visual only; no stat effect required." They are "readable without text," and they come from the
item's lineage ([Devices & mods](prd/devices-and-mods.md#item-lineage-agreed-session-4-part-5-not-built)).

Readings, not in the session:
- **The marks are layers of one atlas, in order.** The stencil is the bottom paint, the heraldry a
  scratch over it (a cut through the paint, not an overprint), and the repair a patch on top (a different
  material's colour, a weld or a cord-lashing), so the wear that chips the top chips down to the one
  under. The shaders already share the atlas ("How it's built," above).
- **A find reads its history by depth of look.** A colonial find has one mark. A First Kingdoms find has
  its stamp and a crest. A second-age find has all three, and the player who reads the three in order has
  read its lineage with no text.
- **The surface crate's "ZN" is a Dark Age daub or a second-age one.** Hands that no longer read the code
  wrote it; the Dark Age is where the knowledge is lost.
- **The Dark Age leaves no mark of its own on buildings,** only on things: it has no structures.

**As drawn** (2026-10-18; [the world system](world-system.md#the-marks)). A thing's lineage stacks its
marks over its own look, each layer added as pieces in the paint pass, not repainted:
- **The maker's stamp** is the look's own, from its first hands' row: colonial gear the colonial row, the
  company's issue the new one.
- **The First Kingdoms** add an enamel band in the house's colour round a frame's top edges, a round
  housing or a part's end, and a small enamel plaque with the house's crest cut through it to bright metal
  (a new scratched ink), two brass rivets at its top: Okafor's key (they kept the last Harbourmaster's),
  Kessel's cauldron, Arkwright's arch, Vante's tower, in deep red, ochre, teal, and ochre with red.
- **The Dark Age** adds cord lashed round corner posts or round a body, a round ceramic cap on a square
  corner, a saltbush-wood splint lashed along an edge, and a plate off another thing in its paint, riveted
  on crooked, with "ZN" daubed back on it where the thing was consigned.
- **The second age** adds the sign of Tu, half-risen and banded, daubed on a limewashed patch, a charm on
  cord, a dyed tassel, a sand-glass water vial tied on; the Cistern's touch a blue-glazed cap and charm.

The wear shader chips every layer by its own share: the enamel chips, the cord and ceramic hardly, so the
newest work reads freshest on an old thing. The atlas grew a fourth row for the ages after
(`marks.py`): the four crests and the sign of Tu, read by mark number past the sixth; a stamp can now
also name its row, so the Dark Age's "ZN" sits on a colonial crate whose own stencil still reads TILG.
They're one merged mesh a lineage, no new material or draw. Seen so far only on a flat CPU render of their
meshes: `look/lineage/shoot.sh` shoots the sheet once the GPU is back.

## Tu and the sky

*2026-10-17, from [the Tu spec](tu-and-day-2026-10-17.md): the behaviour is in [the
moon](the-moon.md#day-length). Provisional.*

**How it's drawn.** Tu is part of the sky, not a thing in the world: a disc found by its
direction, a sphere hit by each pixel's ray, so it never shifts as you move, never clips,
and sits behind the haze and the storm walls like the rest of the sky. Dunes and ruins
overlap its lower edge because they stand in front of the sky.

- **Bands** run round Tu's spin axis, stretched along it by flow noise, with a few storm
  ovals. Tu's axis is Zan's, so from the equator, with Tu on the east-west line, the bands
  stand upright; further north or south they lean. **Tu turns** on that axis, so its
  storms come round and go behind the limb, while the bands and ovals slide on it too
  slowly to see within a session ([as built](#tu-turning-and-close-as-built)).
- **Light:** lit from the real sun, with a soft terminator, gentle limb darkening, a thin
  bright rim of atmosphere on the lit side, and a night face only just there.
- **Through Zan's air:** dimmed, warmed and hazed the lower it stands, reddened and
  softened near the horizon, and faded out by a storm's dust.
- **The eclipse:** the sky goes near dark, the stars come out, and Tu's black disc is
  ringed in sunset red, with the corona showing where the sun is nearest the edge.
  **More epic, and through the storm** (Hunter, 2026-10-17: "eclipse is very awesome and
  dark. lets make it a little more epic, and allow it to shine into the storm, the ring of
  fire"): the ring of fire glows through a storm's dust when everything else is lost in it,
  and totality gets more of an occasion. As built: [the eclipse](#the-eclipse-as-built).
- **Stars:** a fixed field turning about the pole, faint and many, with the two pole
  marks brighter than any. They're lost in daylight and in the dust, and Tu hides them.

**The palette.** Tu is the one big cool mass in a warm frame. B is gunmetal, teal, safety
yellow and bone white on warm sand and dust, so a cool, pale Tu reads at a glance and
doesn't fight the safety yellow or the kind-coloured parts. Its greys and bone tie it to
B's metal and the shield's white, its ochre to the sand and its rust to the wear. Nothing
is saturated: the haze and the rim do the work.

| Part | Colour |
|---|---|
| Zones, the light bands | pale bone grey, #D8D8D2 |
| Belts | slate, #7E8A96, and gunmetal, #4E5A66, deepest |
| A wash through some belts | sand ochre, #BC9E76 |
| Storm ovals | cream, #E4DED0, and one rust, #9E5C42 |
| The lit rim | pale sky blue, #9FC0F0 |
| The eclipse ring | sunset red, #FF5A1E |
| Where the ring flares | orange, #FFA14A |
| The last light before totality | copper, #FF8C4D |
| The corona | pearl, #F2F8FF |
| Tu-shine, the light it casts | cool white, #C8DCFF |

**As built** (2026-10-17). The sky is one shader, `game/weather/sky.gdshader`, fed each frame
by `game/weather/sky_view.gd` from the day's one frame (`game/weather/day_cycle.gd`). It
replaces the stock sky and draws the same gradient and haze under Tu and the stars, so a clear
day looks as it did. The sun's disc stays in the storm pass, where Tu now cuts it. What shows
by day is what's lit: as with the Moon in daylight, Tu's dark face is lost against the bright,
hazy sky, so at noon where a run begins Tu is a big, pale crescent. The whole disc shows once
the sky goes dark in the eclipse, and at night. Tu-shine is a second sun-like light from Tu.
Whichever of it and the sun is brighter casts the shadows, so the shadow map is never split.

To see it: the dev scenarios `eclipse` and `far`, and the console's `tu` to switch sizes. The
look-test `look/sky/shoot.sh <dir>` shoots the three sizes at the same moments; its sheets are
`~/Desktop/tu_sizes.png` and `~/Desktop/tu_more.png`.

### Tu turning, and close, as built

*2026-10-18, after Hunter's "yeah we should tackle it, and add a little more detail, staring
at the low detail red spot every night pulls you out of it."*

**It turns.** The whole cloud field turns about Tu's pole, true to scale: 6.8 turns a day
seen from Zan at 9°, one each 2 minutes 57 ([the moon](the-moon.md#day-length)). `DayCycle.tu_turn`
is the one account of how far it has turned; SkyView hands it to the sky as `tu_spin`, and the
compass's sway reads the same. The clouds are laid round Tu's own longitude, so nothing in them
has a seam as it comes into view. At 9° the clouds at the middle of the face move about 2 pixels
a second at 1080p, about half as fast as the stars. One turn a day and three are under trial
against it: `~/Desktop/tu.png` has the same three minutes at each rate.

**Detail where the eye rests.** Tu is about 85, 125 and 185 pixels across at 1920x1080 at 6°,
9° and 13°, and the red spot 24 by 14 at 9°. All of it is from the palette above, mixed:

- **The red spot** has a pale hollow round it, a dark collar, a darker red ring just inside,
  and two arms swirling in to a lighter, ochre core, the whole turning slowly, once in about
  half an hour. The bands bend round it as a stream round a stone, squeezing past it, with
  filaments plainest where they're bent. Behind it, where the bands shear past, a churned
  wake of pale and dark tears and ochre, widening for a few of its lengths. At 9° the spot
  reads as a swirl with its collar and core, the arms an S across it; at 13° and close they
  wind plainly.
- **The cream ovals** are built the same, smaller, without the wake, and a string of small
  white ones rides the dark belt south of the red spot.
- **Festoons:** dark plumes trailing from the north equatorial belt toward the equator, each
  its own length and hooked back by the shear, dark at the root and wisping out, some missing.
- **The band edges:** where a zone meets a belt the jets shear, and here and there waves
  break along the edge, curling over. Pale rifts tear slantwise through the belts, and fine
  filaments run along the flow.
- **Nothing shimmers as it turns.** Each piece of detail fades to its mean once it's finer than
  about two pixels, by how wide a pixel is where the ray meets Tu, so a small Tu shows only
  what it can hold and a close one shows more. The night face keeps only its broad bands, so
  in the eclipse only the ring holds the eye, and the dusk crescent carries the detail it lights.

How it's built: Tu's clouds are their own include, `game/weather/tu_clouds.gdshaderinc`, which
the sky shader draws and the look-test unrolls. To see it: `look/tu/shoot.sh <dir>`, which
shoots each size on a full-Tu night, at dusk and in the eclipse, Tu blown up pixel for pixel,
the default close, the spin at each rate and the whole of Tu unrolled, and times it.

**Cost,** on the RTX 3070 at 1920x1080 with other Godots running, so rough: timed against the
sky as it was, alternated in the same run (the look-test's `--against`), twice. With Tu filling
the frame, about two million pixels all of them Tu's, the new clouds cost 0.18 and 0.14 ms more
than the old (3.53 against 3.35 ms, and 5.75 against 5.61), where the old cost 0.4 to 0.8 ms
more than the stock sky. That's under a tenth of a nanosecond a pixel, so with Tu in view as the
game draws it, about 12,000 pixels at 9°, it's about a thousandth of a millisecond, lost in the
runs' spread (3.06 against 3.03 ms in one, 4.43 against 4.90 in the other). Only Tu's pixels
pay, and its night face skips the fine detail.

**What's fragile.**

- On a full-Tu night the eye opens only so far as keeps the brightest 64-pixel patch in view
  short of white. At 6° and 9° Tu barely fills a patch, so the dark sky in it holds the
  reading down, the eye opens further, and Tu's pale zones burn out: about half the middle of
  its face at 9°, nearly all of it at 6°, a fifth at 13°. It was so before. The detail in the
  belts, the ovals and the festoons shows; the zones' own is lost. A smaller patch in the
  eye's meter would fix it, and would dim the night facing Tu a little.
- The red spot's arms are two clean spirals broken up by noise; close, they read a little
  drawn.
- At a whole number of turns a day, Tu shows the same face at the same hour every night.
- The look-test finds a moment with the red spot in view from its place and drift, copied
  from the include: moving the spot means moving them there too.

### The eclipse, as built

*2026-10-17, after Hunter's "a little more epic, and allow it to shine into the storm".*
Where a run begins, at 9°, it runs like this:

- **The last light goes copper.** In the few seconds the sun takes to go in, its last
  sliver is low on Tu's limb and seen through Tu's air, so the light and the sky it lights
  turn copper as it thins.
- **The diamond ring.** As the last of the sun goes, a bead blazes where it went in, with
  a soft glare round it, and lingers a second or two after; the same where it comes out.
  Tu is a gas giant with no valleys on its limb, so there are no Baily's beads, only the
  one.
- **The ring of fire flares.** Backlit, Tu's rim burns orange in an arc about where the
  sun went in. The arc spreads round the limb as it fades over the first few seconds,
  and settles into a thin, patchy line of red all round, slowly boiling, with Tu's high
  haze lit just inside it and a soft glow past it, which fades to nothing well inside the
  stretch of sky it's drawn over. (It once ended there in a hard edge, a faint red circle
  round Tu at three times its width, plain at third contact with the eye wide open:
  Hunter, 2026-10-17, "theres a discinct kinda transparent red circle around tu with a
  hard cutoff".) At third contact it all runs backward.
- **The corona** shows past Tu's edge while the sun is behind it: pearly streamers,
  longest along the sun's equator, slowly changing, brightest where the sun is nearest
  the edge.
- **The ring lights the world red,** as a lunar eclipse does the Moon: the land faintly
  coppery, and the air glowing low all round the horizon, brightest under Tu. It's a
  fifth of the ring's own light, so totality stays night-dark: the sand reads 0.6 at
  mid-totality, and 2.3 by its end as the eye opens. The stars come out and the eye
  lightens the sky as before.
- **A hush.** The wind's sound dips by about half through totality, easing in and out
  over a couple of seconds. The storm's roar doesn't: a storm is a storm.
- **Through a storm.** The ring is one more light in the storm's dust, from the sun's
  bearing, as the sun's own is. Its red light carries far deeper into the dust, in from
  the billowed face and down through the roof, and dust throws light forward, so where
  everything else is lost the dust glows from within: a fiery halo about the ring's
  bearing, and a dimmer red all round it. The grains round you catch it the same way. It
  reads deep in a storm, out in the dust and from inside a bubble at a lit camp, where
  the lamp holds the eye down.
- **Like fire** (Hunter, 2026-10-17: "the storms look a litte too... blocky? they should
  look like fire"). At first the ring lit the dust evenly, so a wall at totality was one
  flat, dark-red block, and inside the halo was a fixed round glow. Now a wall's billows
  rising toward the ring burn orange and the rest smoulder red, so it's its own billows
  churning. Inside, flames in the dust close by rise and race with the gusts, so the
  halo licks and changes shape from second to second, while the whole view's light holds
  within about a sixth of a stop and the eye doesn't pump. The light never reads the
  storm map's front, whose cells would show as tiles in a light this far-reaching.

Weighed and left out: shadow bands. At a contrast that shows they look like the sand's
own ripples breathing, at one that doesn't they're invisible, and they'd last two
seconds a day as stripes racing over the sand: too near the flicker that was fixed.

How it's built: `DayCycle.eclipse()` and `DayCycle.ring_light()` are the one account of
where the eclipse stands and how bright the ring is. The sky shader draws the ring, the
bead, the corona and the horizon's glow from them; Weather lights the ground, the sky's
fill and the haze with the ring's share and the copper; the storm pass adds the ring to
its dust's light (`ring_light`, with its own reach and its forward throw) and the grains
take it through `ring_glow`. Outside an eclipse the ring's light is nought, and the sky's
and the dust's work for it is skipped.

To see it: the dev scenario `eclipse`, or `look/eclipse/shoot.sh <dir> [sheet]`, which
watches it live with the eye on, in the clear and in a full storm, and times it. The
look-test's `--walls` finds the run's own storms instead: a wall coming at you and the
deep inside of one, at totality and by day. The sheet is `~/Desktop/eclipse_epic.png`,
now the two fixes before and after.

**Cost**, on the RTX 3070 at 1920x1080, so rough: at mid-totality, against the same frame
with the eclipse's light taken out. In a window, as first built: about 0.05 ms in the clear
and 0.06 to 0.17 ms deep in a storm. On gamescope's headless screen, with the fire:
0.17 ms in the clear, 0.16 out in a storm's dust and 0.21 in a bubble, against 0.12, 0.06
and 0.12 for the first version on the same screen; runs there differ by 0.1 to 0.3 ms. The
flames cost one noise read a pixel. It costs that only during the minute or so round each
eclipse.

**What's fragile.**

- The halo in a storm leans on the ring's light carrying further into the dust than the
  sun's does, and on the dust throwing it forward. Both are judged by eye, not worked
  from the dust.
- The ring lights the ground at a fifth of what lights the dust, so totality stays dark.
- The flames inside a storm are read once a pixel, about 8 m out, so they're a sheet of
  flame at that depth rather than through the dust. Running fast they could show as a
  pattern travelling with you.
- A wall's billows burn by a tap 45 m toward the ring, which near the ground also sees
  the storm head's nose lifted off the sand. So it only counts in the outer few hundred
  metres of a storm; deeper, the flames alone shape the light.
- The ring's flare, the bead and the corona's reach scale with Tu's size, and were
  judged at 9° only.
- The hush dips the wind's sound, not the wind: anything that reads the wind still
  feels it.

**Cost**, on an RTX 3070 at 1920x1080 with other Godots running probes alongside, so rough:
the sky shader takes about 0.05 ms a frame more than the stock sky, by day facing Tu (2.23
against 2.18 ms) and under the far side's stars (2.40 against 2.35), the same over three runs.
Tu-shine and its shadows take about 0.12 ms by night (2.16 against 2.03). By day Tu-shine is
under a hundredth of the sun's light and isn't drawn at all. Nothing reads the sky's light,
so its reflection map is kept at the smallest size and costs next to nothing to refresh.

## Sand and wind: one wind texture (agreed direction, 2026-10-18)

From the [sand and wind techniques research](sand-and-wind-techniques-2026-10-18.md) Hunter
brought: wind is a field, not an event, so one player-centred texture baked on the GPU (wind on
the ground, lee shelter, and how hard the wind moves sand there) feeds the streamers, the sand's
shading and the tracks' healing alike, and they stay consistent. Its roadmap, in order:
- **P0, the wind texture and GPU shelter,** with `wind_at` kept on the CPU for sound and play.
  **P1, the sand's own `light()`**: backscatter diffuse (Fujii's Oren-Nayar), the sheen as the
  max of rim and "ocean", and glitter stepped by distance and faded by footprint so it never
  crawls. These two first, side by side.
- **Then:** streamers gated on wind past sand's threshold (an ordinary breezy afternoon moves
  sand, not only a storm); tracks healing by local wind cubed and shelter, not one clock; a GPU
  track texture and a dense displaced patch near you for real trail depth (Godot has no
  tessellation); crest plumes off dune brinks; ripples that migrate with the wind; drifts.
- Each untested Godot piece is prototyped before it's relied on: a `Texture2DRD` sampled in
  `vertex()` and in particle shaders, varyings into `light()`, and the cost of a displaced patch.

**Built: P0, the wind map (2026-10-18).** `WindMap` (`game/weather/wind_map.gd`) bakes a texture
every drawn frame, 128 texels a side over the 256 m round you, 2 m a texel and snapped to whole
texels so it never swims. It's an RGBA16F compute pass on the main RenderingDevice, read through a
`Texture2DRD` as in Godot's Compute Texture demo, its shaders built from source as the eye meter's
are (a `.glsl` file won't import headless). Each texel holds:
- **rg, the wind on the ground,** m/s in world x and z: `wind_at`'s twin in GLSL, from Godot's own
  FastNoiseLite ported as Godot runs it (`game/world/noise_glsl.gd`).
- **b, the lee,** the share of a full lee along the wind blowing there: `Lee.exact`'s twin, so the
  lee turns with the wind continuously, not by the 4 m lattice and 2° headings. It reads the ground
  from a wrapped kilometre of 2 m heights, baked from the dunes' own twin and filled only where the
  window moves on.
- **a, the sand the wind moves,** 0 to 1: the wind past sand's threshold (from 5 m/s, all it can by
  8), out of the lee (1 - b), by the hour (most in the afternoon heat, a quarter of it at night) or
  by a front's outflow, day or night, whichever is more.

The open air's wind is rg * (1 - `lee_wind` * b), as `Weather.open_wind`. `wind_at`, the lee and
the storms stay on the CPU, the authority for play and sound; nothing reads the map back.

The lee isn't the research's ten taps and 10°-15° ramp. Desert's dunes stand 260 m apart and a lee
reaches seven crest heights, a hundred metres and more, where ten 2 m taps see twenty. So the GPU
runs the lee the game already plays by: its 32 taps out to 250 m, and its ramp from two to seven
crest heights, an elevation angle from about 27° down to 8°.

**Checked against the CPU** in `look/wind` (headless has no RenderingDevice, so this is the map's
probe; `look/wind/shoot.sh` runs it unseen): in light air, a breeze, the breeze some days on with
the wind turned 36°, and a storm, over the deep dune sea near spawn:
- the wind within 0.022 m/s of `wind_at`, 0.1%, which is the half floats' own step;
- the lee within 0.004 of `Lee.exact` (99% within 0.0005). The lattice the game plays by, `Lee.share`,
  is within 0.002 of it on average and 0.04 for 99% of texels, but 0.16 at worst, at a lee's sharp
  edge, which is the lattice's own blending;
- the sand moved within 0.003, the heights within 3 mm of the dunes;
- 59 km out and 40 days on (the air drifted 480 km): the wind within 0.016 m/s, the lee within 0.01,
  the heights within 7 cm. Out there the dunes' wander, a difference over 0.3 m of a noise read at
  32 bits, jitters by centimetres on the CPU as on the GPU.

**What it costs,** on the RTX 3070 at 1920x1080, by the GPU's own clock: 0.026 ms a frame standing,
0.031 ms moving a texel every frame, 0.067 ms the one frame after a jump when all the heights refill.
The main thread spends 26 µs a frame packing and recording it.

**The prototypes:** a `Texture2DRD` reads correctly in a spatial shader's `vertex()` and `fragment()`
and in a particle shader's `process()`, each within 0.002 of the map read back. Use `textureLod`.
Particle shaders take no varyings, so the shared include (`wind_map.gdshaderinc`) holds none. The
sand's marks already read a `Texture2DRD` in `vertex()`. The one consumer so far is the sand's own
view of the map for the look-test (`wind_view`, off in the game): arrows, the lee as `vertex()`
read it, and the sand moved.

**Not built:** the coarse 64² map over a kilometre.

**Fragile:**
- Three GPU twins must change with their CPU functions: `TerrainShape.dunes()`, `wind_at()` and
  `Lee.exact()`. Each sits beside its twin, but only the look-test, on a GPU, catches a drift.
- Structures aren't in the GPU's heights, so round a ruin the map's lee is the bare dunes'.
- `NoiseGLSL` draws only smooth simplex with plain FBm, and complains of any other noise.

## Open questions

- **Tu's palette** (open in the spec: "Tu's palette, to be settled against
  `art-direction.md`"). The cool palette above is provisional, and the screenshots are the
  test. The alternative is a warm, Jupiter-like Tu, cream and tan and brown, which would
  sit closer to the sand and cast a warmer light than the spec's "cool and dim."
- Is B final, or does it take C's bright, kind-coloured parts so they read through the dirt
  and the storm?
- Should wear be one value per find, from its layer and how long it's been out, so the
  colonial-against-crude look comes from the same number that says how sound it is?
- Should parts be coloured by their socket kind everywhere, as the tells already are?
- Which makers get names, and in what register, before a mark's letters stop being
  placeholders?
- **The crate's surface label. Resolved (session 4, part 2, 2026-10-17): "ZN" stays.** The
  session: "The Z on surface crates stays. The hand-daubed 'ZN' consignment mark is intentional
  drift from XN." That settles the notes' "Open: the XN-to-Z crate label. Hunter's first
  reaction was that it should read XN; it may stay as story," and the lore's "writing kept the X
  for centuries" ([the names](lore-research.md#names-the-ug-catalog-and-the-moon)) reads as the
  copyist's drift, not a rule. The atlas reads "ZN" as it did, and nothing was changed.
- **Era shapes against the skimmer era.** Part 5's shape table has colonial, First Kingdoms and second
  age, and no skimmer era; the notes' "light, cheap and fragile" is the only word on its gear. Not said
  what it looks like, or whether it is the colonial shape worn hard.
- **Layered marks against the atlas.** *Answered 2026-10-18:* a stack, each lineage entry its own pieces
  over the look from a few presets a layer (a house, a set of repairs, a set of gifts), the atlas a row
  longer.
- **Remodelling against "models wait for the loop".** Here: "Every game object keeps its
  grey-box shape until the loop works," and "models wait for the loop." The notes: "Device
  models should differ by era in shape... The shield comes first." Not said: whether the
  shield's remodel is the first exception or waits with the rest, and whether a new shape keeps
  the grey box's collision and sockets, as the paint pass did.
