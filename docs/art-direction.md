# Art direction

*Draft, 2026-10-16. Hunter picked **B, chunky worn industrial, for now**. It lays out the
candidate looks for the game's things, shot side by side in the real world, so the choice
came before any real asset. Every game object stays a grey box until the loop works; the
look-test is `look/style`.*

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

    look/style/shoot.sh ~/Desktop/code/desert-wt-style-shots

The sheets are `~/Desktop/style_<shot>.png`, with full-size frames in
`~/Desktop/code/desert-wt-style-shots/<candidate>/`.

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

## Open questions

- Is B final, or does it take C's bright, kind-coloured parts so they read through the dirt
  and the storm?
- Should wear be one value per find, from its layer and how long it's been out, so the
  colonial-against-crude look comes from the same number that says how sound it is?
- Should parts be coloured by their socket kind everywhere, as the tells already are?
