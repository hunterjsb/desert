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

## Eye adaptation

(Hunter, 2026-10-17: "add eye adaptation".) The camera adapts to the light as an eye
does, so a Tu-lit night reads as night with the dunes still there, and stepping from a
bright day into a storm, or out of an eclipse, takes a moment to see. Tu's light stays
physical; the eye does the rest.

**As built** (2026-10-17). Tu-shine stays at 1. The eye opens the camera's exposure
in the dark, but only so far: a night still reads as night.

How it looks, where a run begins with Tu 13° across (`~/Desktop/eye_adaptation.png`,
each moment before and with the eye):

| Moment | The eye | The sand (L*), before and with it |
|---|---|---|
| Noon, any clear day, dusk, a veil of dust | as before | 81, 81 at noon |
| Deep in a storm by day | 1.4 times | 22 to 26: it stays oppressive |
| A full-Tu night, facing away from Tu | 3.1 times | 1.4 to 4.5, a little over where Tu-shine ×3 put it (4.2) |
| The same night, facing Tu | 1.9 times | 1.5 to 3.0 |
| A crescent night, the far side | 6 times, the floor | under 1: dark, the stars out over the dunes |
| Totality begins | 1.1 times | black |
| Totality, 30 s in | 6 times | the sky off black, many more stars, the ring brighter |
| The sun back, 1 s on | 1.6 times, still open | too bright for a moment, as before within two seconds |

**What it reads.** A meter takes each frame's light on the GPU before the tonemap,
so the exposure it leads to never feeds back into it: all the light in the frame,
which is what a pupil follows, and its brightest patch. So whatever is in view moves
it, as with an eye. Tu's disc in view at night holds it to about twice, so Tu's bands
never burn out; look away and the dunes come back within a few seconds. The
headlamp's pool in a black storm holds it to under twice, so the beam reads much as it
did, and the dark beyond stays dark. It takes the light in over half a second, so dust
flickering past doesn't pump it. At the menu, in its storm, the frame's own light swings
by half again with the billows over ten seconds, and the eye by under a tenth against
them. In the clear it doesn't move.

**Its bounds.** It opens only once the frame is dimmer than about a ninth of noon's.
That's the ceiling: noon, and anything brighter than a dusk, look exactly as before, and
nothing is ever darker than before. Below that it makes up only about a third of each
halving of the light. And it never opens past 6 times, the floor, so a black far-side
night stays black, not grey noise. The sky used to dither itself before the tonemap,
and opening the eye made that a coloured hatch on dark skies. The dither now comes
after the tonemap, project-wide.

**How fast.** It opens in two parts, as an eye does. The first doubling comes in about
three seconds, as a pupil widens. Past that it goes slowly, a doubling in about
fourteen seconds. It closes fast, a doubling in under half a second. So stepping into a
storm it has settled in about two seconds. Totality lightens through its 39 seconds:
3 times by 8 s in, 6 by 22 s. A glance at Tu costs only the pupil's few seconds to get
back. A cut doesn't carry over: a new run, a jump of the clock and a scenario each start
the eye settled.

**Why not Godot's own.** Godot has its own auto exposure (`CameraAttributesPractical`).
Between its two bounds it makes up every change in the light, so every scene in that
range shows as bright as every other. It has one speed both ways, and nothing reads it
back. For noon to stay as it is while a full-Tu night got about 3 times, its bounds
would have had to lie a factor of three apart, just under noon. Then a storm would have
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

- It was tuned where a run begins at 13°. At 6° and 9° a full-Tu night has a fifth and
  half the light. The eye opens further, 4.9 and 3.9 times, and those nights still read
  darker: the sand is 1.7 and 2.8, against 4.5.
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

- the planter, as ag-tech issue;
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
  to Zan, with the X said and written as a Z. It's late, a Dark Age or Second Age form (a
  reading: hands that no longer read the code, where the First Kingdoms kept their archives),
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
middle and the forged goods of the First Kingdoms to the Second Age near the surface. The game
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
overbuilt (B's era cue), the skimmer era's crate is "light, cheap and fragile," and the finds
of the ages after the collapse are worn, reused space-age items with
carvings ([Salvage & ruins](prd/salvage-and-ruins.md#gear-and-ruins-by-era)). Not said: what any era's
shield looks like. The built light shield is round and bone white, and the notes' new one is
flat ([Bubble shield & camp](prd/bubble-shield-and-camp.md#the-carried-light-shield-and-the-starts-not-built)).

## Marks by era after the collapse

*Session 4, part 2 ([lore session](lore-session-2026-10-17-part-2.md)); named, not drawn, and
none of it is in the atlas.* The atlas stops at the colonial, surface and new rows. The session
names what the ages after the collapse would carry, to be drawn when there is a find to carry it:
- **First Kingdoms** gear carries heraldry and guild stamps (houses such as Okafor, Kessel,
  Arkwright and Vante; the guilds of the keepers).
- **Second Age** gear carries religious symbols (the faith of Tu).
- **Homesteader** gear carries civilian brand marks, not Tilg's.
- **Carvings and daubs** use the worn slang (Monward, Hanmen, Zanborn, the tu- prefix) and the
  worn names (Zan, Tu, Han, Mon, Aitch): [the names](lore-research.md#slang-and-name-erosion-agreed-session-4-part-2).

## Tu and the sky

*2026-10-17, from [the Tu spec](tu-and-day-2026-10-17.md): the behaviour is in [the
moon](the-moon.md#day-length). Provisional.*

**How it's drawn.** Tu is part of the sky, not a thing in the world: a disc found by its
direction, a sphere hit by each pixel's ray, so it never shifts as you move, never clips,
and sits behind the haze and the storm walls like the rest of the sky. Dunes and ruins
overlap its lower edge because they stand in front of the sky.

- **Bands** run round Tu's spin axis, stretched along it by flow noise, with a few storm
  ovals, all drifting too slowly to see within a session. Tu's axis is Zan's, so from the
  equator, with Tu on the east-west line, the bands stand upright; further north or south
  they lean.
- **Light:** lit from the real sun, with a soft terminator, gentle limb darkening, a thin
  bright rim of atmosphere on the lit side, and a night face only just there.
- **Through Zan's air:** dimmed, warmed and hazed the lower it stands, reddened and
  softened near the horizon, and faded out by a storm's dust.
- **The eclipse:** the sky goes near dark, the stars come out, and Tu's black disc is
  ringed in sunset red, with the corona showing where the sun is nearest the edge.
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

**Cost**, on an RTX 3070 at 1920x1080 with other Godots running probes alongside, so rough:
the sky shader takes about 0.05 ms a frame more than the stock sky, by day facing Tu (2.23
against 2.18 ms) and under the far side's stars (2.40 against 2.35), the same over three runs.
Tu-shine and its shadows take about 0.12 ms by night (2.16 against 2.03). By day Tu-shine is
under a hundredth of the sun's light and isn't drawn at all. Nothing reads the sky's light,
so its reflection map is kept at the smallest size and costs next to nothing to refresh.

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
- **Remodelling against "models wait for the loop".** Here: "Every game object keeps its
  grey-box shape until the loop works," and "models wait for the loop." The notes: "Device
  models should differ by era in shape... The shield comes first." Not said: whether the
  shield's remodel is the first exception or waits with the rest, and whether a new shape keeps
  the grey box's collision and sockets, as the paint pass did.
