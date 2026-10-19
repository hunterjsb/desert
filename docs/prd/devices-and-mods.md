# PRD: Devices & mods

*Draft, 2026-10-13. Answers to [the vision](../vision.md). Rebuilt round the chassis, 2026-10-18.*

## Why this system exists

Building your camp is the gameplay. The camp is chassis: sticky squares you tile into decks,
raise walls and shelves on with frames, and stick anything on wherever it fits, so a camp is
laid out in stations of your own rather than filled slots (Hunter's brother, playtesting: "a
board he could just stick things to"). Plugs, water taps and the few slots a thing has of its
own (a planter's beds, a Console's ports, a carried thing's battery) are the other half: a
part fits them with a magnetic tug. Moving a battery, a tray or a panel is how you progress,
how you adapt the camp, and how you get out of a pinch, so placing and taking things has to
feel great: intuitive, reactive and satisfying, every single time.

**In the world.** Fitting is what the colony could always do, and making is what it never
could: the moon had no fabs, so every part came from somewhere else. Each part carries its own
maker's stamp, separate from the mark of whoever assembled the device around it. A shield
housing might name the contractor while its core names a maker most settlers never heard of.
Batteries are the exception and carry no stamp. See [the lore research](../lore-research.md).

## What the player experiences

- **It goes where you look.** Carry something to a chassis and look at its top, its
  underside or an upright: the thing itself is there, flat on the face, touching nothing,
  turning as you turn it and edging to the face's edges and its neighbours so rows line up.
  Take leaves it there with a clunk.
- **It says when it won't.** Where it would clip, it's red and the line under your aim says
  "blocked"; where it would sink a floating deck, amber, "too heavy".
- **Slots tug.** A plug held near a port, a hook near a ring, a seedling near a bed: the
  part leans toward the slot, a faint ghost shows where it will sit, and take seats it home.
- **Removing feels as good as placing.** Look at what you want and take: that one thing
  slides off its face, or out of its slot, the way it went in, never through anything, and
  take again puts it straight back. It's quick enough to swap a battery in a pinch,
  mid-storm. Dragging a deck never takes it apart.
- **Look at something to see what it does.** A device or part shows its stats briefly
  while you look at it, with no menu.
- **What's on a deck changes it.** Trays lift it where they are, batteries pool for
  everything on it, and every kilogram raises the hover draw.

## How you handle things

Four actions cover handling, with none for particular features: take, use and throw
(decided 2026-10-15), and rotate (Hunter, 2026-10-16). A new device or tool answers these;
it never adds an action of its own. (Getting on and off the hoverboard is movement, with
its own ride action.) The docs name
actions, never keys: keys are only defaults, set in `game/core/controls.gd` and listed
in the game. On screen, a key is always read from the live bindings and coloured to stand
out, never written into the text (Hunter, 2026-10-16), even before players can remap.
**A refusal says why, and sounds** (Hunter, 2026-10-17: "we should have a way to communicate
when a slot is full... like 'tray first'... maybe we could just make a noise"): when take or
use can't do what you're aiming at, the readout says why in a few words and a soft "no"
sounds, never silence. **Built** (2026-10-17, the chassis's 2026-10-18): every refusal goes
through one place in the hands, and the "no" is a dull knock cut from a Sand Game clank.
Where what you hold is shown red, take keeps it in your hands and says "blocked" (or "you're
in the way"); a frame held to a wall says "frames go on a deck's top", a Console held under a
frame "too tall for a frame", a standing device held to a wall "it stands on a deck's top",
and trays and runners on one deck "runners and trays don't mix". Holding a part at a device
whose slots of its kind are all full says "no free battery slot" (or ring, port and so on);
at a device with none of its kind, take still puts it down. A piece held to a deck whose free
rings are all blocked says "no room at that ring", and aiming at a frame with walls on it
says "take its walls off first". Use at a device with nothing to work says "nothing to use", a
stake used off the sand says "not sand" or "out of reach", and something you can't shift says
"it won't shift" as it slips from your hands. Take or use at nothing stays silent.
- **Take** picks up, takes out, puts in, sticks and puts down. One action takes and lets go
  (Hunter, 2026-10-15, at the Stage 5 gate). Taking something too heavy to carry takes
  hold of it: it follows where you face and turns as you turn, as far as your strength
  drags it, and taking again lets go, or sets it where it's shown. That's how you arrange a
  camp of floating things too heavy to lift. Walk off from something you can't shift and it
  slips from your hands. Pressed while what you took is still coming to your hands, it acts
  the moment it's there.
- **Use** works what you're looking at, or uses what you hold: switch a shield, drive a
  stake, set a deck's trays floating or resting (Hunter, 2026-10-16), so a camp that's
  staying put stops spending its charge on floating. **Built** (2026-10-16): use at a deck,
  or at anything stuck on it with nothing of its own to work, empty-handed, switches its
  trays. Resting, they draw nothing and let the deck down onto the sand over two seconds,
  about 0.6 m/s at most; floating again, they lift it back the same way. It shows by where
  it hangs and the board's soft hum falling or rising, and the switch is kept in the save.
  Use at a shield on a deck still switches the shield, and a line or stake in your hands
  keeps its own use. A planter's use is its tray's too (Hunter, 2026-10-17), unless you hold
  a canister to pour. A tray out of power still lets go, as before (Power).
- **Throw** throws what you hold. Having hold of something, it punches it where you look
  (the spec's "drag it while left-clicking to punch it"), a small shove for righting a
  tipped rig: 45 N·s, the tuning's.
- **Reel in and pay out** (Hunter, 2026-10-16): on a line, they shorten and lengthen it
  (Rope & tethering). **Bring near and push out** are their own actions (Hunter,
  2026-10-17: "switch rope scrolling to control + scroll so it doesnt conflict with object
  moving"; then, 2026-10-18, the other way round, as lines matter more: the wheel bare reels,
  held with control it moves what you hold): on anything you hold or have hold of, they bring it nearer or push it farther,
  within reason, and never touch a line. *As built:* a notch is 0.25 m. What you carry goes from
  0.5 m to 2 m in front of your eyes, never nearer than clears you, and still stops short
  of the sand or anything in the way; what you have hold of goes from just clear of you
  out to your 2.5 m reach, following only as far as your strength and the slip allow.
- **Rotate** (Hunter, 2026-10-16): held down, the mouse turns what you hold, or what you
  have hold of, instead of your view. Shown on a face, the turn is about the face's way out,
  settling into soft 15° detents when it's within 3.5° of one and free between them. It's
  also how you right a deck, a planter or a shield that has tipped over: take hold of it
  and roll it back. While you have hold of something heavy it also follows where you look
  up and down, not only round you, so you can lift an edge, tip it, or drag it up a slope,
  still only as far as your strength drags it.

Walking into a loose thing pushes it, with the same strength. A floating thing you
push keeps gliding, as the wind would carry it anyway; to set one down where you want
it, take hold of it, and let go.

## How things join

1. **Stuck on a sticky face.** A chassis piece's whole top and underside are sticky, and
   anything sticks anywhere it fits there: a battery, a tray, a panel, a lamp, a canister,
   a shield, a Console. **Once stuck, a part stops being a physics object**: its shape and
   weight join the deck's body, with nothing left to wobble. A device stays a body of its
   own, held fast where it's stuck, touching nothing of the deck, so it works as itself,
   and everything on one deck is one power pool.
2. **Fitted into a slot.** The only slots left are plugs and water taps, and what's a
   thing's own: hooks on a chassis's edge rings and a planter's, crops in a planter's beds,
   a harvester in its mod mount, a Console's screen, instruments and radar in its ports, a
   sail on its mast, a whole face on a frame, and a battery in what you carry or ride away
   from a deck (the board, the radio, the heat cutter) or what stands alone (the planter
   and the turbine, as they are). A fitted part joins the body the same way.
3. **Resting loose on top.** Put something down on something else without sticking it and
   it just sits there under plain physics, riding on friction and sliding off when jolted
   or caught by a gust. It's allowed but **not balanced around**.

## The chassis as the one structure (built, 2026-10-18)

Hunter's [chassis, kits & dune archaeology spec](../chassis-kits-dunes-2026-10-18.md), from his
brother's playtest ("a board he could just stick things to"): the crate and nearly every slot
went; the chassis is the one structure, a sticky square you tile, tow by its edge rings and stick
anything on freely, so a camp is truly the player's own, laid out in stations (power, weather,
workstation) rather than filled slots.

- **A piece** is 1 m square and 12 cm thick, 9 kg, with a ring in the middle of each edge.
  Its whole top and underside are sticky. It's painted as before: gunmetal rails round a
  teal plate, black corner caps, hazard bands either side of each ring so a deck's outer
  edge reads, and the consignee's stencil on top. It's a find, and the dev console's give
  makes one by its id, `chassis`. A found one may have a tray stuck under it and a battery
  and a panel or lamp on top, as its layer's fills say.
- **A deck** is pieces joined edge to edge into one rigid body. A piece brought edge-on to a
  deck's free ring is offered it the same way a slot is: the tug leans it flush beyond the
  ring, turned the quarter turn nearest how you hold it, the ghost shows it, and take joins
  it. Its frame and all that's on it move into the deck's body. A ring between two pieces
  closes. A hook in the way pops off (Hunter, 2026-10-17): on either ring that closes, or on
  a neighbouring edge facing where the piece goes, it lands on the sand just past the deck's
  edge, its line still tied and let out if it must be to reach; a loose part lying where the
  piece goes moves clear the same way. A device, a deck, a wall or a find still in the sand
  there blocks. Two whole decks don't merge yet.
- **A frame** is an open cube of rails, 1 m a side and 4 kg, that sticks square on a piece's
  top, whatever its aim off the middle, turned to the nearest quarter. Each of its five
  other faces takes a whole-face piece: **a chassis** (on a side, upright, a wall; on top,
  flat, a shelf), **a screen**, or **fabric**, a crude sail (wind on faces, below). A
  piece is offered a free face as it is a ring, and joins the deck's one body there. A wall's
  and a shelf's faces are sticky like any piece's, their rings take hooks and ropes, and no
  piece joins them edge to edge: an upper chassis stands only on a frame. A frame comes off
  by hand once its faces are bare ("take its walls off first").
- **Tall devices** (the Console and the condenser) stand straight on a piece, never under a
  frame, and no frame goes over one: "too tall for a frame". Devices that stand (shields, the
  Console, the condenser, the mast, the helm seat) stick only on a face facing up; the rest
  (the board, the radio, the light panel, the bedroll, a survival kit, the heat cutter) and
  every part stick on any face, upright on a wall included. The planter and the turbine stand
  as they are, on the sand beside a camp.
- **Placing** (`Stick`, the one set of rules for your hands, the kits, the scenarios and the
  finds): a part sits on its back, standing out of the face as it would from a slot, so a
  tray's lifting face and a panel's cells face out; a device on its foot. What you hold is
  shown there itself, eased onto the spot in about a twelfth of a second and riding a floating
  deck as it bobs, non-solid until it's set. Its place is under your aim, on the face or
  through it to the face beyond, its edges coming flush with the face's edges and its
  neighbours' when within 4 cm, or its middle in line with a neighbour's. A tray or runners
  aimed at a top go under it. Aimed at a neighbour, it's shown where it would clip it,
  red. Its shapes are tested 5 mm thinner, so resting against what it sits on never counts,
  and the sand never blocks: a tray stuck under a deck on the sand lifts the deck clear.
  "Too heavy" warns, and never refuses, since a camp resting on the sand carries anything.
  Having hold of something too heavy to carry, it's shown the same way where you look, the
  real thing frozen there, and back where it was when you look away.
- **Hover trays stick onto chassis.** A tray lifts toward the sand it faces: fully facing
  down, as much less as it tips (0.71 halfway to a wall), nothing on a wall or facing the
  sky. A deck counts each tray's lift that way, so a tray on a wall adds weight and no lift.
  A deck floats once its trays together lift its weight, and how it hangs is physics: a
  deck three pieces by three, 113 kg, floats level on four corner trays 1.04 m up, and 1.00 m
  with 221 kg; with its trays bunched along one edge it tips 26° onto the far edge, drawing
  160 W for its 107 kg (devices probe 17). Floating, its trays draw 2 W a kilogram they hold
  up. Use on any piece sets the whole deck floating or resting.
- **Balance and flipping** (the spec's rule, with no new UI): where the trays are against
  where the weight is decides whether a rig floats level, leans or tips; a rig turned over
  holds nothing up, its trays facing the sky, and lies on the sand drawing nothing until it's
  righted with a line, or by a few punches having hold of it. A big, badly built rig flipped
  in a storm may only be stripped and rebuilt upright.
- **One pool a deck.** Battery slots left the shield, the condenser and the Console:
  batteries stick loose on a chassis, and the deck and everything stuck on it, devices and
  loose batteries alike, are one power pool (Power). Cables and hoses are for reaching other
  bodies, a turbine held out on the sand or a planter. The board, stuck on a deck, charges
  from its pool as it did racked; the radio and the heat cutter keep their own batteries.
- **Taking things off.** Take aimed at something stuck takes that one thing, whatever
  crowds it, and it slides off its face to your hands; take again at once and it goes
  straight back where it was, with no looking away first (Hunter's "sometimes attaching
  doesn't work until you look away and look back": every offer is worked out afresh each tick
  from what's free now, and a face's spot is free the moment what was there is taken). Aimed
  at a deck's plate, take has hold of the whole deck, to drag it, unless the piece you aim at
  is bare (nothing stuck on it, no hook) and the rest of the deck holds together without it:
  then it comes off, out across a ring it leaves, or off the frame's face, into your hands.
  Looking at a deck empty-handed, what take would move is highlighted, faintly in the ghost's
  colour.
- **Seams for what's next:** `Chassis.plates()` lists a deck's whole-face plates (walls,
  shelves, screens, fabric), which wind on faces reads (below); a screen on a frame's face
  is dark until something drives it.
- **The power box (built, 2026-10-19)** is a device with battery bays that sticks like any
  other and joins its deck's pool, its bays a slot of its own that batteries go into and come
  out of with take, as any slot's. A light strip by each bay reads its fill and which way it
  flows; use at a battery in a bay holds the bay to charge only. Four makes by era, each its own
  catalog id: the colonial cabinet, the company's dock, a skimmer's rack with dead bays and a
  temple's shrine ([Power](power.md#the-decks-pool-and-the-power-box-agreed-2026-10-18-spec-the-pool-built-2026-10-18-the-box-2026-10-19)
  has their numbers, looks and terms, and where they're found).
- **Saves** keep a deck's pieces as they joined, across a ring or on a frame's face, and each
  thing stuck on each piece by its pose on that piece and the face's way out, with its own
  state (Profile & saves).
- **The kits** start on rigs built by `Rig` from data steps, as the scenarios, the main menu's
  showpiece and found chassis are (Profile & saves); a hook's step can name it, as a stick's can, for
  a line a kit lays from it. The Surveyor's: two pieces joined, a tray
  under each set back under the weight, a frame on the second with a wall on its back, the
  board and a compass hung on the wall, and a battery, the light shield and the light panel on
  the first; 68 kg, floating within 2° of level.
- **The "chassis" scenario** lays four pieces in a row with a tray before each, a spare
  piece and a frame for a wall, two batteries, the light shield and a condenser with an empty
  canister, clear and calm, to build a deck from; two hooks and a coil lie at your feet, and
  the first piece's outer ring has a hook with a line to a stake short of where a piece joined
  there goes, so that join pops it. The "afk" scenario's reference camp is a deck two by two
  (Power).

## Wind on faces (built, 2026-10-19)

Hunter's [spec](../chassis-kits-dunes-2026-10-18.md#wind-on-faces): every vertical and fabric
face is a flat plate that catches the wind, as close to real as can be had cheaply: no cloth
sim, no new bodies or joints. `Faces` does it for each deck, from `Chassis.plates()`.

- **A face is a flat plate.** Each whole face on a frame (a wall, a shelf, a screen, fabric)
  is pushed square to itself by the world's catch (`wind_catch_per_m2`, 0.5 N per m² per
  (m/s)², as a loose body's biggest face), its area, the air's speed and its speed square to
  the face: a flat plate's normal force. A 1 m wall broadside takes 72 N in a 12 m/s wind,
  200 N at 20 and 288 N at 24; edge-on, nothing but its edge's share of the deck's loose
  catch; at 45°, as much across the wind as down it, which is the side force a reach needs
  (probe 35). The push acts at the face's middle, into the deck's one body, and the air it
  meets there is the felt wind less the deck's own motion at that spot, so a deck turning
  through the air is slowed by its faces as much as it's driven. A shelf, level, meets a
  level wind edge-on, and catches only as its deck tips.
- **One face behind another catches a fraction.** Sorted along the wind, a face with another
  just upwind across its footprint catches a tenth (`face_shaded`) of what it would alone,
  as much less as the one in front covers it as the wind sees them, fading back to all of it
  as a lee does, from two heights of the face in front to seven. Side by side across the
  wind, faces don't shade each other (probe 36). No ray casts: the boxes are compared along
  the wind's way in the deck's frame, worked out again only when that way turns 3°.
- **Scoops.** A frame open on a side with its back closed is a scoop, judged by which of
  its faces are filled and where its open side points. Open into the wind, its back catches
  up to 1.3 times (`face_cup`) a flat face's, a parachute's cup against a plate, as much
  more as its sides round about are closed (the floor always is); open away from the wind,
  its back meets the wind as any wall and its lee shelters the inside (probe 37).
- **Fabric is a crude sail,** on any face of a frame, but weak: it can't belly into lift or
  be trimmed, so it pushes as a flat plate, 44 N in a 10 m/s wind square on, a sixth of the
  268 N the sail on the same floating deck draws running before the same wind (probe 38).
  Across the wind it gives as much side force as drag at best. A real sail stays the
  upgrade.
- **Fabric shows its load.** Its canvas is a cloth of its own (`fabric.gdshader`), its hem and
  grommets as before, drawn by the very push the physics makes: its load is that push
  across it over what 12 m/s square on would put there, so it's slack under a third of
  that, flutters in the air going past, faster and harder the more of it, and from a load
  of one it's taut, bellied up to 10 cm at its middle the way the air presses, the lacing
  holding its edges. Edge-on it bears nothing and flutters hardest in a gale (probe 39).
  Taken off a frame it hangs slack. The sail keeps its own cloth.
- **The rest of the deck,** its pieces' edges, what's stuck on them and the devices on it,
  still catches the wind at the deck's middle, less what its own walls' lee keeps from what
  stands behind them. A line holding the deck and the wind that carries it off while you
  sleep count all of it: its faces at the wind's way now and the rest.
- **Its walls shelter what's behind them,** as a small dune does, through the felt weather
  ([Wind & storms](wind-and-storms.md#a-walls-lee-built-2026-10-19)).
- **Balance and flipping** (measured 2026-10-19, storm gusts half the wind). The sand holds
  a resting body by half its weight (World probe 11), so a resting camp left loose slides
  only in a strong wind: the Surveyor's, 70 kg, holds at 15 m/s with its wall broadside,
  creeps half a metre in ten seconds at 20 and slides off at 24; with no wall it holds to 20
  and slides from 22. Moored as it starts, by its line to a stake 4 m upwind, its wall
  broadside upwind is a windbreak that holds: in a 24 m/s storm it leans 14°, at 30 m/s 21°
  with its line peaking at 1,600 N, and at 36 m/s 24°, its line holding, the wall's lee
  keeping half the wind off the rest of the camp. The same wall to leeward shelters nothing
  on it: it holds at 24 m/s, leaning 18°; at 30 it leans 22° to 31° and went over once in
  four tries, and at 36 its line parts and it goes over three times in four. Floating
  moored, the Surveyor's leans 2° at 15 m/s and 11° at 30. A light deck (one piece on one
  tray, a frame and a wall, 34 kg) moored leans 5° to 15 m/s, 10° at 30 and 18° in 36 m/s
  gusts, and goes over once its line parts in a steady 50; adrift it trips where it runs up
  the next dune at 18 m/s, going over in 30 m/s gusts as in 36. A tall wall is the real
  risk: a second storey on the Surveyor's (a shelf on the frame, a frame on that and a wall,
  2 m of wall in all) leans 9° moored in 10 m/s and flips at 15; on a lone piece it won't
  float upright even in still air, and resting moored it leans 30° to 36° at 15 m/s and 52°
  to 64° at 24, held short of going over.
- **Cost** (the dev machine, someone playing): a camp of six faces takes about 18 µs a tick,
  the felt wind it reads included; a rig of 45 (a deck three by three, a frame on each piece
  with three walls, fabric and a shelf) about 50 µs. Turning, its shading and lee are worked
  out again at most every tenth of a second: about 0.2 ms for six faces, 0.75 ms for 45. A
  read of the walls' lee costs about 2 µs near a camp's walls, 1 µs elsewhere. On the dev
  overlay, `faces` is what the wind on decks' faces took last tick.

## Mast mounts, the streamer and the crow's nest (built, 2026-10-19)

Hunter's [spec](../chassis-kits-dunes-2026-10-18.md#sails-and-nomad-gear): "things should mount on the
sail's mast, generically (with top slots gone, that's a sticky spot on the mast). Heavy things up high
raise the centre of mass," and a crow's nest, "a mast mount you climb into. It counts as a seat and
gives a long view for spotting glints, plumes and storm fronts." Found with the [nomads' gear](salvage-and-ruins.md#nomad-gear-agreed-2026-10-18-spec-built-2026-10-19).

- **A standing mast is sticky** (`Mast.face_frame`), as a chassis's faces are, through the same
  `Stick` rules for your hands, the kits and the finds: the four sides of its upper pole, from 1.4 m
  over the deck to its head at 4.4 m, and its head. A thing sits on a side by its base, a part on its
  back and a device on its foot, centred on the pole at the height you aim; things that stand go only
  on its head. Nothing tall goes on a mast, no frame and no mast ("too big for a mast"), and only while
  it stands on a camp ("stand the mast on a deck first"). Your hands meet its upper pole while it
  stands (an `Area3D` for them alone, so what the sand and anything round the mast meet is still the
  stowed pole, as before). A mast with something on it stays on its deck ("take what's on it off
  first"); saves keep what's stuck on it as a piece's.
- **What's high on a camp raises its middle.** A device stuck on another adds its weight to its host
  where its own middle is, not where its foot is (`Device._recompute`), so what's on a mast's pole
  weighs on the camp up there, and a seated device's own low or high middle (a Console's heavy foot)
  counts. A 9 kg big battery 3.2 m up the pole of a mast on a floating deck two by two stands the
  camp's middle 0.376 m higher than the same battery on its deck, what its weight there says, and the
  same push heels it 4.3° against 3.6° (probe 40). Nothing seated touches anything of what carries it,
  all the way down.
- **The wind streamer** (`streamer`, 0.2 kg, `Streamer`): a strip of rust-dyed cloth on a saltbush wand
  whipped with cord, a brass ring at its tip, a bone toggle at its foot. It streams downwind of the air
  it feels, that air less its own way, as a telltale does, and flaps as a wave runs down it: hanging in
  still air, standing out from about 4 m/s, flapping faster and wider the harder it blows. In your hand
  it's the air where you are; in your suit too, drawn as it streams (the inventory's picture from
  behind and above, your way ahead up it, redrawn as it flaps); stuck on a deck or a mast, the air its
  camp goes through, so on a sailing rig it shows the trim. The anemometer stays the one that gives
  numbers. Measured (probe 42): hanging straight down in still air; in 5 m/s level, 2° off downwind,
  its end flapping 0.06 m wide 2.8 times a second; in 16 m/s level, 5° off, 0.18 m wide 7.8 times a
  second; on a deck going 4 m/s through still air, straight aft; in your suit, 5.0 m/s from the wind's
  own way.
- **The crow's nest** (`crows_nest`, 12 kg, `CrowsNest`, a `Helm`): a lookout's basket of wooden posts
  and bent pipe on a plank floor, cloth wound round its lower rail, its rope ladder hung 3.4 m down
  the mast's front. It goes on a standing mast's head and nowhere else ("it goes on a mast's head").
  Use on it, on its ladder from the deck, climbs you in: a seat as the helm is, steering nothing. You
  stand in it, your eyes 6.2 m over the deck; your weight and its are the camp's, up there: on a bare
  deck of four pieces you stand its middle 2.59 m higher, so a hard gust heels it further. Ride or use
  again climbs you down off the deck's side. Its first sit teaches what it is (`CrowsNest.NEST_HOW_TO`).
- **The view is height alone.** Nothing draws farther from up there and no lens closes in: the dunes
  are what hide what's far off, and over the crests round you more of the ground shows, and what
  stands on it. Round the probe's deck, 25% of the ground out to 2.5 km is in sight from the nest against
  19% from the deck (probe 41). A glint the crests hid from the deck, a plume's foot, a front's sand
  under its wall: each is there or not by the same sightlines the Glint deed reads. Why not more: a
  farther haze or skyline from up there would be a rule the ground doesn't keep, and the sightline
  already rewards height.
- **Probes:** 40, a heavy thing up the mast raises the camp's middle by its weight and heels it
  further; nothing tall on a mast, and a mast with something on it stays on its deck. 41, the crow's
  nest goes only on a mast's head, seats you from its ladder, your eyes and weight high, and more of
  the ground shows from it. 42, the streamer hangs, streams and flaps by the wind, shows a moving
  deck's air, and reads in your suit.

## The Console (proposed; first version built)

*Hunter, 2026-10-17 ([session](../console-sensors-sleep-2026-10-17.md)), a voice session. Its own
framing: "Treat them as direction, not a final spec: the Console's slot layout is explicitly due
for a rework." So this is direction. A first version is built (As built, below), and its layout is
a starting point for that rework. Where the session clashes with what is built, the clash is in
the open questions below.*

A new device, **the Console**: "the camp's computer. It handles computation and moves data between
devices." It carries the weather instruments and the screen that shows what they read ([Wind &
storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)), and it is what makes a
shield smart (below).

- **A crate variant, not a seated device.** "It still takes a hover tray, batteries and power like
  a crate." So it is a frame of its own, as the planter and the condenser are, and not a small
  device that seats on a mount like the shield or the radio.
- **Lean on non-mod ports.** "Only one or two rope hooks. Don't remove battery slots."
- **Plenty of mod ports for computer mods.** How many is not said.
- **One side is the screen.** "A full-face screen port. Faces must be laid out so a full-face
  screen can't clip into other parts."
- **The top:** "one regular top slot and one computer-mod top slot (antenna, radar and the like)."
- **Audio** "comes from a radio on a top mount; no separate audio port for now."
- **Linking.** "A chassis connects every Console mounted on it into one system." A deck already
  makes one power pool of what stands on it. This makes it one data system as well. A deck mount
  takes one device, so two Consoles take two pieces.

**The chassis settled the layout** (2026-10-18): the Console's battery slots, rings, tray mount
and top mount went to the deck it stands on, as every device's did, and it keeps only what's its
own, its electronic ports: the screen port, six computer-mod ports, the computer-mod top and a
power port, read as the spec's plugs. Its batteries stick loose on the deck, its radio stands on
the deck beside it, and a line ties to the deck's rings.

**Smart devices.** A device seated on a Console, a shield first, reports its data to the screen
and can be controlled from it. What it can do depends on the Console's gear. [The smart
shield](bubble-shield-and-camp.md#the-smart-shield-proposed-first-version-built) has the detail. As a reading, not in
the session: any device that seats on a top mount could be smart the same way, since a seated
device already stays a body of its own on the host's power pool.

**As built (2026-10-17, a first version):**
- **The name.** The device is the Console. The dev tool's class is `DevConsole` now
  (`game/dev/dev_console.gd`); its action is still the console action, its commands are
  unchanged, and the docs still call it the dev console.
- **A rack, not a crate** (Hunter, 2026-10-18: "instead of a crate, the console should be a
  taller server rack like thing, so we can make the displays bigger"): the Console stands tall
  and narrow, like a server rack, its whole front a big screen.
- **The frame** (as built, 2026-10-18) is a rack 0.7 m wide, 1.3 m tall and 0.6 m deep, and
  10 kg. 1.3 m, not taller, because that's as tall as the radar page wants (the map the full
  width of the screen, its legend, the forecast and the keys under it), and at that height the
  screen's middle sits at your eyes once the Console floats on its tray or on a floating deck.
  Taller would put the screen over your head and tip more easily. It's painted in B as a rack:
  four gunmetal rails on a black plinth, a cap, teal side panels vented in two columns either side
  of their computer-mod ports, a back panel with the fitter's tag over a fan, and on its front
  bolted rack ears either side of the screen, a bezel bar over it and a hazard strip along the
  plinth. Nothing else is on the front, so the screen can't clip anything.
- **Its ports** (2026-10-18): the screen port is the whole front, the six computer-mod ports
  run down its sides, three a side, the computer-mod top over the front of its top, and its
  power port low on its back.
- **It stands upright on a deck.** A tall device, it sticks straight on a piece's top and
  never under a frame. Its frame is heaviest at its foot, so a deck carrying it rides steady:
  moored by the deck's own ring, a deck rides a storm with it.
- **What it draws.** 4 W itself, the screen 3 W more, and each instrument its own: the radar
  6 W, the ground radar 4 W, the particle sensor 1.5 W, the anemometer 0.5 W, the hygrometer 0.3 W
  and the barometer 0.2 W. With the full set that's about 16 W, from its deck's pool. Running short, it gives
  way before a shield, as a deck's trays do. Dark, its screen goes black and
  its instruments stop reading.
- **Where it comes from.** It's a find in the deep layer only, at the same weight as the chassis
  piece. A found one carries what the deep layer fills a screen port, computer-mod ports and a
  computer-mod top with: a screen, instruments and a radar. The screen and the instruments come
  only in found Consoles for now; none lies loose. The heaviest Console that can be found, 49.7
  kg, still drags by hand. The dev console's give makes
  one by its id, `console`, and its parts by theirs: `screen`, `anemometer`, `barometer`,
  `hygrometer`, `particle_sensor` and `radar`.
- **The radar first** (Hunter, 2026-10-18, after playing it: "the console is kind of
  information overload... we shouldnt directly drop any of it... i love the map"). Nothing is
  dropped; it's rearranged so the map leads, and readable from where you stand:
  - **Pages:** the weather radar map first, the whole screen; then stats, every reading in
    detail; then the deck's power; then the log.
  - **The map loses resolution, not itself,** as instruments come off: the more gear, the finer
    it is; with less, it coarsens.
  - **On the map:** the wind as a gyro vector in its legend, a compass too (in detail on the
    stats page); pressure as a bar (in detail on stats); humidity laid over the map itself,
    varying, when a hygrometer gives it; the front's numbers written on the map where the front
    is; the forecast as a line along the map's foot.
- **The screen** (as built, 2026-10-18) is a part, 0.62 by 1.12 m and 3 kg, the whole front of
  the rack, drawn on a canvas of 580 by 1080. It's a terminal in the game's theme, monospaced,
  and its pages go in the order of its tabs:
  - **Radar:** the storm map the full width of the screen, north up. Storms are amber, darker
    where a particle sensor reads them denser. Clear air is laid over in blue as humid as the
    hygrometer makes it, which deepens just ahead of each front, and air the map can't see is
    dark. The front's distance and time are written at the front itself, with a line to it from
    you at the middle; the pressure is a bar down the map's edge, its storm line across it, amber
    when it warns; and the forecast runs along the map's foot. Under the map are the gyro, with
    the wind's speed and where it's from and its angle off the bow written under it, and a small
    table of the pressure with its trend as an arrow, the humidity and the sand, each beside its
    colour on the map, and the map's resolution and scale.
  - **Stats:** every reading as a table (Hunter, 2026-10-18: "line up numbers vertically so its
    easy to read, like a table, and use small up or down arrows instead of rising and falling"):
    labels in one column, numbers right-aligned in the next, units after them, then a note: a
    point of the compass, a trend as a small ▲ or ▼ (– steady), a shield's mode. The rows under a
    reading are indented and dim, and what's urgent is amber. A running shield's line has its
    load under it, the sand it holds back as a share of a full storm's, amber past 100%, which
    only an anomaly makes ([Wind & storms](wind-and-storms.md#the-anomaly-as-built-2026-10-18)).
    Under the table are the larger gyro,
    with the wind's steady part beside the wind and the angle written under it, and the
    pressure's last ten minutes as a line with the storm's line across it.
  - **Power,** in place of the Shield page (Hunter, 2026-10-18: "shield page should be replaced
    with an electrical panel diagram for power and devices on the chassis... devices can be
    managed from the electrical grid screen"): the deck's electrics as a panel. They're its power
    pool: the deck, everything standing or seated on it, and anything cabled to them, so a
    turbine held out on a cable shows. One line runs down the left. What makes power feeds it at
    the top, each source with what it makes now, and their total under OUTPUT ("what makes power
    says output", Hunter, 2026-10-18). The batteries sit on it, with
    their charge as a share, a bar and Wh, the net flow, and how long until they're empty or full
    at it. A power box on the deck sits on the line above them (2026-10-19), mirroring it exactly:
    its row with its charge, then each bay as a cell, its strip as a bar in the charge lights'
    colours, an arrow up as it charges or down as it supplies, its share and its watts; held to
    charge it reads blue, and a dead or empty bay says so. The bank is then what supplies. What
    draws hangs off it below, each device with what it draws now, a dark one marked,
    and their total. Under each device that can be worked is a row of switches, the one lit saying
    how it stands, and use on one works the device through its own use: a shield off, on or smart;
    a radio's own controls, off or on, a sweep to the next carrier as its use does, and its
    volume down or up (the dial in [Radio](radio-sound-and-atmosphere.md#the-dial-and-the-gods-on-the-air-hunter-2026-10-18-built));
    the deck's trays floating or resting; and a device's lamps
    on or off. Each switch logs what it did ("SHIELD SMART", "RADIO 262 KHZ", "DECK REST"). A device's lamps are switched only from here.
    As far as the deck's power box allows (Power): each draw is numbered where it's served, 1 the
    first, with PRI + and PRI - to rank it, and one without a switch of its own (a condenser, a
    board charging) gets ON and OFF, switching it off as a draw the pool skips ("CONDENSER OFF",
    "CONDENSER PRI 1"); a cabinet's bays are keys that hold them to charge or let them supply
    ("CABINET BAY 6 CHARGE"). A Console never switches itself off. These join a device's row of
    switches where there's room. When the draws are more than the page holds, a key at its foot
    pages to the rest, then back to the top.
  - **Log:** the last lines logged, each under its time; the sender shows only when it isn't a
    Console.
- **The gyro is a compass too** (Hunter, 2026-10-18: "show both the wind direction and mag with a
  vector, and then also show our current heading for comparison so we can see the angle... it has
  a dual use as a compass and is useful for sailing"), on the radar's legend and on the stats page
  alike. North is up. The heading is a line out to a mark on the rim: the way the deck points, or
  off a deck the Console's own front, its screen's. The wind is a vector flying in from where it
  comes from, as long as it's strong, and an arc joins the two, the angle written under the
  gyro: the wind angle a sailor trims to, in degrees, to starboard or port, as "45° STBD".
- **Tu-ward on the gyro** (Hunter, 2026-10-18: "we should also show 'tu-ward' on the compasses.
  on the computer yes for sure"; built). A small disc on the gyro's rim in Tu's pale blue, TU
  written just inside it, on the radar's legend and on the stats page alike: the great-circle bearing
  from where you stand toward the point under Tu, nodding with Tu as it does. The Console works
  it from where it is on the moon, so it reads on the far side too, where Tu is below the
  horizon, and points the way to walk to see it rise. Within a degree of the point under Tu, or
  of the one opposite, every way is Tu-ward and the mark goes. The hand-held compass never shows
  it ([survival](survival.md)).
- **The wind is as the deck feels it.** Before, the anemometer read the field's wind over the
  sand, which a deck under way doesn't feel. It reads the field's wind less the deck's own way
  over the sand now, as a masthead anemometer would, still from the field, so a bubble doesn't
  blind it. While the deck moves faster than 0.5 m/s the stats page adds the true wind under it.
  The map's estimate without a radar still carries a storm on the true wind, since storms ride it
  over the sand.
- **The map's resolution comes from the gear in the system:** a radar alone draws 8 cells
  across its 12 km, and each other kind of instrument 4 more, so a radar and two more draw 16
  and the full set (all five computer mods and a radio) 28. A second radar linked on the deck
  draws it half as fine again: two Consoles with the full set and a radar each, 42. With no
  radar there's only an estimate, hatched, 3 cells across with one instrument and 2 more with
  each other kind, up to 9: here as the barometer or the particle sensor knows it, and a storm
  the barometer expects coming on the anemometer's wind, as far upwind as that wind carries it
  before it arrives. With nothing to read there's no map. Taking
  an instrument off steps it back down a tier, and the map stays as long as anything reads.
- **Readable from where you stand.** The map's numbers are set 4 cm high and the rows 2.8 cm, so
  standing a step or two back, about 1.5 m from the screen, every number on the map and on the
  stats and power pages reads at the game's own lens.
- **Nothing wraps** (Hunter: "on fcst and sheild the text wraps"). Every row fits its line at
  those sizes: the stats table is 32 characters at most, the forecast along the map's foot too,
  and a log line is its time and at most 26 more ("FRONT 2.3 km NNE · 4 min"). A row too long
  for its line, from a sender still to come, is cut, never wrapped. Over 90 minutes, a time
  reads in hours ("1.5 h").
- **Working the screen** takes only use (Hunter: "the bottom bar should have all our tabs
  instead of next shield auto"). Along its foot are its tabs, one for each page: Radar, Stats,
  Power, Log. The one you're on is marked, the one you aim at lights up, and use there goes to its
  page. Use on a switch on the power page works it, and use anywhere else on the screen does
  nothing. A page that wants gear joins the tabs once it's built, the bar sharing its width among
  them: a survey of what's under the sand. Use at the frame sets its deck's trays floating or resting.
  Dark, use on the screen says "no power". Take aimed at the screen takes it out, like any part.
  Saved pages keep their numbers, the Shield page's being Power's now, so an older save on the
  Shield page opens on Power.
- **Its draw cost is small.** The screen is a small canvas of its own. It's drawn only when what
  it shows has changed, checked at most four times a second of world time, and only while
  someone stands within 15 m. Taken out, a screen's canvas is hidden and kept, not freed, so
  putting a screen back makes nothing new. The radar's map is sampled a few rows a tick, a whole
  pass a second of world time, by one Console in the system; one sample per cell gives its
  storm, sand and humidity alike.
- **Taking the screen out never stutters** (Hunter: "game stutters when the screen is
  removed"). The stall was the first part taken out in a run, whatever it was: taking it cost
  10 to 12 ms in its frame (21 to 22 ms against 16.7) while the GPU compiled the shader of the
  ghost that shows where a held part fits, and in the "console" scenario the screen is what you
  take first. Later takes cost about 1 ms. The ghost's shader compiles while the world loads
  now, as the sand's does, so the first take costs what any does, 1.5 ms. Putting a screen back
  cost 12 ms each time, making its canvas again; with the canvas kept, 0.6 ms. Measured in the
  game on the desktop's GPU, unseen; the Console look-test prints the first take's frame.
- **Linking.** Every Console on one chassis deck is one system: the deck and everything standing
  or seated on it. Their instruments pool, so each screen shows every reading in the system,
  each taken from the first Console that has it. A Console off a deck is a system of its own,
  with whatever is seated on it. Nothing links by cable yet. The first running Console speaks
  for the system: it logs the storm and runs the smart shield, and every screen in the system
  shows the logs merged by time.
- **Its messages** go out through [the terminal output
  system](#the-terminal-output-system-proposed-session-4-part-5-first-piece-built), and a radio
  seated anywhere in the system sounds its tones as a line prints: that's the Console's audio.
- **Its battery, aloud** (Hunter: "...unless you have a speaker'd or radio'd Console on its
  chassis, then we should use the Valve 'battery low' voicebit"): with a radio in its system, the
  Console logs its pool running out and, after its tones, says "Battery low." and then "Battery
  critical." in the radio's voice ([Radio](radio-sound-and-atmosphere.md)), from the radio, at its
  knob, on or off and whatever it's tuned to. Each is said once as what's left to run the Console
  on falls past 20% and 5% (`console_battery_low`, `console_battery_critical`), and again once it's
  back 2 points over. What's left is measured from where the Console goes dark: the pool's empty
  batteries, or with a shield in the pool its 25% reserve, below which the Console and the radio
  give way to the shield ([Power](power.md)); so there "low" comes at 40% of the bank and
  "critical" at 29%. The Radio voice switch in Options silences it; without a radio there's no
  voice.
- **Saves** keep its page and its log, and its parts and anything seated on it as any device's;
  a shield keeps its smart switch, and a device whether its lamps are on. Older saves load as
  before, their shields smart: the Console's old auto switch isn't read.
- **The "console" scenario** stands a Console on a deck of two pieces floating on a tray each,
  moored by the deck's ring to a stake upwind. The Console holds its screen, the four side
  instruments and the radar, its screen facing you at your eyes; two big batteries and a radio
  are stuck behind it, and the base shield on the other piece beside a battery, switched off. A storm is due in four to six
  minutes, so the radar sees the front coming, the shield switches itself on, and the storm
  arrives while you watch.
- **What's under the sand gets its own page** when mods detect it (Hunter, 2026-10-18): old
  lines and buried structures, as the dev map draws them, on a Survey page among the tabs, not
  over the weather radar. Built 2026-10-19 with the ground radar (below).
- **The navigation computer** (2026-10-19, `nav_computer`, a give id): a Console of the Varran
  empire's make, the Varran settler's, out of place and heavy on his minimal rig (Profile & saves). The
  Console's rack in an armoured case, imperial blue under ivory corners with chrome handles, 30 kg, its
  weight at its foot; its radar under a dome on its head and an anemometer's cups beside it. Its five
  weather instruments are built into its frame, so it reads the wind, the pressure, the humidity and
  the sand with nothing fitted, and its radar reaches 9 km, half again a Console's: its map is 24
  cells across, 9 km each way, with its screen alone. It draws 14 W, the screen 3 more. Its screen port and power
  port are the Console's, with two computer-mod ports for more; a built-in instrument counts as fitted
  everywhere a Console counts its gear (`Console._fitted`). It's new make, not found: no lineage marks.
- **Still proposed:** the final layout, any part on the computer-mod top besides the radar (an
  antenna), god modules, makers' Consoles past the Varrans', a Console linked by cable, and devices
  other than shields made smart.

### The ground radar and the sieve (built 2026-10-19)

Dune archaeology's setup ([Wind & storms](wind-and-storms.md#dune-archaeology-agreed-2026-10-18-spec-built-2026-10-19)):
a ground radar fitted to a Console, a sand scoop and a sieve, all on one deck.
- **The ground radar** (`ground_radar`) is a computer mod for a side port, as the other sensors are:
  a sealed survey set, its antenna's face turned down to the sand, the contractor's amber band, 1.4 kg,
  4 W. It reads 300 m round its Console **(default)**: the old lines under the sand (history's paths),
  every structure on the ground or under it, and each big dune's ruin, built or still a seed, its place
  looked over whatever your pace while it runs. `GROUND RADAR ONLINE` goes to the log as it's fitted,
  and the stats page adds how many it finds and how many a storm is baring. It doesn't sharpen the
  storm map: it reads the sand, not the weather.
- **The Survey page** joins the tabs while the system has a ground radar: a map round the Console out to
  the radar's reach, north up, rings every 100 m, the old lines faint, a structure a square and a dune's
  ruin a triangle, an outline while the sand is over it, amber while a storm lays it bare
  (`sites.newly_exposed`), solid once it's out. Under it the nearest five, each its name, how far and which
  way, and a row under that: the sand over it, "bared" or "dug out".
- **The sieve** (`sieve`), a saltwood hoop rimmed in steel with a worn steel mesh, half a metre across,
  1.2 kg. Nothing takes it; it sticks on a deck. Carried, or set down or stuck on a deck within 4 m of
  where you dig, it sifts what a scoop digs off a ruin (Salvage & ruins).
- **Where they come from.** Dune ruins hold them: sieves on their shelves and in their caches, a ground
  radar most often in their deepest cache; a relay mast's cabinet now and then holds a ground radar.
- **Assembled** (Field Kit, Profile & saves): a Console with a ground radar fitted, a scoop and a sieve
  stuck on one deck, recorded as a piece joins or something sticks, and as the radar comes online.
- **The give and the creative menu** make both by their ids, `ground_radar` among the devices and `sieve`
  among the tools.

**Ending-linked Console pieces (endings session; proposed, not built).** The endings give the
Console two late uses ([the vision](../vision.md#landmarks-and-endings)):
- **A Walker taken whole (Agreed).** "Take the whole Walker onto a chassis: works as a Console
  with full weather sensing built in (like two fully modded weather Consoles), leaving its slots
  free for other mods. Important late game." A deck is one data system (above), so the Walker
  reads as a Console on the deck chassis, and it lines up with "roughly two linked Consoles" for
  a storm mini-map ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
  Not said: what frame a legged robot is, or whether it stands on a deck mount, which takes one
  device the size of a crate.
- **Teaching and taking the Walker** (agreed, 2026-10-18, [spec](../storms-signals-sailing-2026-10-18.md)).
  The Walker is a legged survey robot that exists only to understand Zan's weather, indifferent to
  its flock; the nomads followed it for centuries until it walked them into the anomaly, and then they
  abandoned it (Hunter, 2026-10-18: it walks alone, and they still listen and pray). Teaching it takes
  evidence for each of the anomaly's tells (the compass drift, the radio's crackle, the shield's load; Hunter,
  2026-10-18, after session 5). Your own sensor logs, recorded through an anomaly and uploaded by plugging
  your Console into the Walker, are one form of that evidence, and a singing stone
  ([below](#the-singing-stone-agreed-session-5-not-built)) is another, "at least those two things, probably
  more." Once it is taught, anomalies show on your map and its moon-wide feed flags them, for anyone
  listening. It doesn't mind its chassis being taken as long as it keeps roaming and surveying;
  kept still too long it goes bad (its feed degrades, its draw rises, its logs turn subtly wrong).
  Taken before the nomads' line is done, they may go on pilgrimage and find their god gone, and
  turn aggressive only if it hasn't been taught; teaching it afterwards calls them off. Aggro
  mostly touches the endings.
- **Captured hive mind tech (Idea).** Sealed deep in the black site, it "looks like an incredibly
  powerful Console mod," the endings session's route for a human to consume the other gods.
  Session 4, part 3 makes that ending hive mind start only, so this is an Idea with a clash
  ([lore research](../lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)).
  As a part it is a computer mod (a kind of its own, in the socket types below), found in a
  landmark and never crafted.

**A survey mod (session 4, part 4; proposed, not built).** "A basic survey mod on the console picks up
buried metal, so colonial pipelines show as lines on screen" ([World &
terrain](world-and-terrain.md#readability)). It is a computer mod, found and never crafted. It sits
oddly with the Console session's line that "ground and ruin detection is separate equipment (looking
down, not up), likely a different camp setup" ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
The newest session wins, so a basic survey mod is a Console mod, and the heavier detection (the
Archaeologist's ground-penetrating radar) is read as staying separate; the session does not say.

**Gods on the Console (session 4, part 5; proposed, not built).** A mounted god's terminal output is
what a Console's full-face screen shows, and a god module is a part of the computer-mod class
([the terminal output system](#the-terminal-output-system-proposed-session-4-part-5-first-piece-built), [god
modules](#god-modules-as-crate-modules-proposed-session-4-part-5-not-built)). A Walker taken whole is
still the Console with weather sensing built in, above.

**One map, with filters (Hunter, 2026-10-19; agreed, not built).** "Instead of more tabs im
thinking one map tab with filters: weather, archeology, and navigation." The Console keeps one Map
page. What used to want its own page lays over it as a filter you switch on and off: weather (the
radar, fronts, anomalies once the Walker is taught), archaeology (the ground radar's Survey) and
navigation (bearings, the Walker's contacts, the course and the sail's ideal).

## The patrol board as a superchassis (proposed, not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)). Direction, not a spec:
no number is set and none of it is built.* The Daventry patrol board's build note asks for "mount
points for a shield, battery, radio, condenser, bedroll and tow, as a chassis rather than
special-cased slots," and says this "also generalises the existing board."
[Movement](movement.md#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built) has the
board's side: the kit, its weakness of few slots, and the clash with "It tows nothing."

Against what is built, as readings and not in the session: the chassis (2026-10-18) is the
"chassis rather than special-cased slots" the note asks for. A shield, a battery, a radio, a
bedroll and a small condenser all stick on a sticky face, and a tow is a hook on an edge ring. A
patrol board read as a chassis is a board whose top is sticky, which the session doesn't size: a
1.3 m board carrying a shield, a battery, a radio, a condenser and a bedroll is still a question of
room. Either way the kit's board, hung on the Surveyor's upright, is unchanged.

## What Sand Game taught us

- **Snapping happened on contact.** Anything that bumped a sticky area got stuck, even
  by accident.
- **The snapped object froze wherever it touched,** not at a defined spot.
- **A frozen body parked under another body isn't part of it.** Its weight and shape
  never joined the parent.
- **Matching was done by name.** A crop was recognised by "carrot" appearing in its
  node name, and ropes found their ends by searching the whole scene for "rope".

## Rules

1. **Sticking and snapping need intent.** Only what you're holding, or have hold of,
   sticks or snaps, only where it fits, and only when you take it home: it's shown
   there, or the tug leans it in, and take sets it (Hunter, 2026-10-15: "add a little more
   player agency"). Nothing sticks or snaps by being bumped, or by drifting close.
2. **Slots are defined spots,** with a position and a facing, and a fitted part sits
   exactly there. A stuck thing sits exactly where you set it, its base on the face.
3. **A fitted or stuck part is part of the body.** Its collision and weight merge into
   it. There are never joints between a deck and what's on it.
4. **A body's abilities come from what's on it.** Capacity, lift, hooks, protection,
   wind catch and weight are all computed from what's fitted and stuck. Change them and
   the deck changes.
5. **Parts come out the way they went in.** Removing a part never passes it through the
   device. Last on, first off: aimed at a hook with a line tied to it, take unties the line,
   and the hook once it's bare (Hunter, 2026-10-15: untying kept taking the hook).
6. **Parts are typed.** Nothing is ever matched by its name.
7. **Loose stacking is plain physics.** There's no special code for it, but it has to
   be stable.

## The feel, in detail

- **The tug** starts within roughly 40 cm of a free socket the part fits, while it's
  facing roughly the right way. The part eases toward the socket, the ghost appears, and
  you hear a faint magnetic hum.
- **The snap** happens on a press of take, never on its own, so the tug can afford to
  reach a little further and pull a little harder. A clunk (Sand Game's metal clanks),
  and it's home.
- **Letting go:** pull back out of range and the tug releases smoothly. It never yanks
  the part back.
- **Several sockets nearby:** the nearest well-aligned one wins, and the ghost shows
  which one that is.
- **Removing:** the device turns the socket's side toward you if it's free and light
  enough to turn. A staked or heavy device stays put, so you walk round to the part.
- **Speed:** a battery swap should take a second or two.
- **Picking up small things is forgiving** (Hunter, 2026-10-15). Aim near a small loose
  thing and it's the one you'd take, without pixel-perfect aim; a big one you look right
  at. Among several small things together, the one nearest your aim wins, and it doesn't
  flicker between them as your aim wavers. Picking from a tight cluster is still open.

**As built in the skeleton (2026-10-14), slots since the chassis (2026-10-18):**
- **The tug follows your aim, not the part's position.** A part held at arm's length
  can never get within 30 cm of a slot on something sitting on the sand. So a free
  slot tugs when your line of sight passes within reach of where the part would sit,
  and you're on its open side.
- **No crouching to fit** (Hunter, 2026-10-16: "im also having to crouch for a lot of
  mods, like the hover tray and hooks"). Looking at a device with a part in hand, or
  within 40 cm of its frame, offers the free slot that part fits, standing: the only
  one of its kind wherever on the device you look, or of several the one nearest where
  you aim among those facing you. Aiming right at a free slot's spot, on any device,
  still wins over a sticky face; a sticky face your look meets wins over a slot only
  offered. An offered slot leans the part partway in with the hum, the ghost shows where
  it goes, and take seats it; nothing fits until you take. On the device's far side, the
  ghost doesn't show through it (2026-10-17). A device stuck on a deck keeps its own
  slots. Taking out: with empty hands, the part you look straight at comes out, and take
  again puts it straight back. A tray, out of sight under its deck when you stand, comes
  out as easily (2026-10-17): a look at the plate's lower edge, or just under it, within
  15 cm of the tray, is a look at the tray, and use there still sets the deck floating or
  resting; a chassis piece, 12 cm thick, is the piece by its top and the upper half of its
  edges, and its tray by a look at its lowest 6 cm or just under it.
- **A tray aimed at a top goes under it,** and a deck lying on the sand lifts clear onto it.
- **The device doesn't turn toward you on removal yet;** it holds still while the part
  slides out.
- **A hook adds a socket** (2026-10-15): a tie socket on its ring while it's fitted,
  where a line's end snaps on. Taking the hook out takes the line's end off first.
- **A device stuck on a deck stays a body of its own** (2026-10-16, Hunter: "can we make the
  shield snappable to the crate like lights are? so we can mount and charge it and drag it
  around?"), held fast on the deck and touching nothing of it, so it carries on working as
  itself and the camp stays fully simulated: it rides with the deck, adds its weight, shares
  its power pool, and use still switches it. Take lifts it straight off its face, whole,
  whatever of it you aim at, unless you aim at a part in a slot of its own.
- **Keys on screen come from the bindings** (2026-10-16). The keys list and its hint,
  the inventory view and the dev console read each action's key from the live bindings
  and draw it in one colour. Rebinding an action changes all of them, and a mouse button
  is named as one, like "click". The look-tests' own keys aren't actions, so they're
  coloured but written as they are.
- **Rotate** (2026-10-16) is held down. While it's held with something in your hands, or
  something you have hold of, the mouse turns that instead of your view, and your view
  comes back the moment you let go. The near side follows the mouse: across turns it
  about the vertical, and up or down tips it about your view's right, so pushing up
  rolls the face toward you up over the top. A held part or shield turns in your hands,
  and you put it down, or stick it, the way it now faces. Something you have hold of is
  turned as hard as your strength allows, so a planter or a lone piece on its side rolls
  back upright. Nothing rights itself, beyond a running tray holding its deck up while it
  faces the sand.
- **Take-hold keeps its tilt and follows your look up and down** (2026-10-16). What you
  have hold of keeps the tilt it had when you took it, not only its heading, and its
  turning is held firm each tick, since on the sand it turns against friction and tips
  about an edge, lifting its own weight. It rises and sinks as you look, at the reach
  you took it at, but never higher than a little above your eyes. Your hands only lift
  and never press down, so its own weight lets it down, and dragging is no harder for
  looking at your feet. More than your strength lifts stays on the sand.

## Where parts come from, and how they wear

- **Parts are found, never crafted,** at least for now. Salvage is the only source,
  which makes every find matter.
- **Parts wear out only from the elements:** wind, storm and temperature, through the
  felt weather. Use never wears them. A part sheltered from a harm doesn't wear from
  it, so the shield protects your parts as well as you. (Session 4, part 5 gives each era a repair
  material, which nothing here mends yet: [frames by era](#frames-by-era-agreed-session-4-part-5-not-built).)

## Frames by era (Agreed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 4; it supersedes the 17 Oct notes'
"trade-offs, not a ladder" crate table ([Salvage & ruins](salvage-and-ruins.md#gear-and-ruins-by-era)
has the eras and the ruins). Today there is one crate frame, and none of this is built.*

**All eras interoperate** (Agreed): "any crate takes any module, and there are no per-era compatibility
rules. Eras differ only in stats, along one axis: **efficiency vs repairability**." So a frame's era is
data on the frame, and nothing in the join, the sockets or the deck asks what era a piece is.

| Era | Feel | Shape | Materials | Colour | Efficiency | Repaired with |
|---|---|---|---|---|---|---|
| Colonial | Industrial | Rounded rectangles, chamfered edges, modular panels | Composites, alloys | Off-white, grey, safety orange | Best | Finite colonial parts only |
| First Kingdoms | Maintained heirloom | Colonial geometry intact, plus crests, flared caps, filigree vent grilles | Original kept clean; brass and copper fittings; hardwood or bone handles | Faded colonial base, house-colour enamel bands (deep red, ochre, teal) | Near-colonial, more durable | Metal |
| Second age | Devotional relic | Asymmetric and organic; lost parts rebuilt in other forms (round ceramic cap on a square housing); bulges, wraps, tassels, charms, water vials | Salt-glazed ceramic, sand-glass, saltbush wood, fern cord, leather; metal only where original survived | Bone white, sand, rust, clay; deep water-blue glaze only on Cistern-touched items | Crude, lossy | Grown and gathered: cord, ceramic, saltbush wood |

"First-age gear is a machine with decoration; second-age gear is a craft object with a machine buried
inside. Late-game camps should mix eras on purpose." The shape, material and colour columns are the art
side ([art direction](../art-direction.md#shape-by-era)); this PRD owns the stats.

What it replaced, quoted: the colonial crate "best power efficiency per kilogram," the skimmer-era crate
"light, cheap and fragile, because Zan wasn't a desert yet and gear wasn't built for storms," and the
first-age crate "practical to drag without a hover tray, still mountable, somewhat worse power efficiency
per kilogram." Part 5 puts the First Kingdoms at "near-colonial, more durable," so the drag-without-a-tray
row goes. The skimmer era has no row in the new table (open questions).

Where this meets what's built, as readings and not in the session:
- **Efficiency is the draw.** A tray floats everything on it at about 2 W per kilogram (91 W for the
  kit's 45.5 kg, 112 W for a fully fitted 56 kg), and a device has one durability. "Efficiency" reads as
  that draw per kilogram floated, and an era's frame is data (its own stats, as the light shield's are),
  not new rules. "Near-colonial" is a number a little above the colonial one; none is set.
- **Repairability is what mends it,** and today nothing mends: parts wear only from the elements and
  "use never wears them." The column needs a repair act and a repair material per era (the kiln makes the
  second age's ceramic and glass, [below](#the-kiln-agreed-session-4-part-5-not-built)). Whether a worn frame
  is mended or only replaced is not said (open questions).
- **"Still mountable" and "interoperate" agree.** The bottom mount keeps its tray socket in every era,
  and the chassis joins pieces by their rings whatever their era.
- **A mixed deck is the point.** The nomad city is "a huge tethered raft of salvaged chassis, shields
  and turbines," and part 5 says late camps should mix eras on purpose.
- **Era and maker are two axes.** The maker table below says who built a crate and what for; the era says
  how it trades efficiency for repair. A Frontier Ag grow crate is colonial; the Sisters' water-storage
  crate is second age.

Found mods ride along. First Kingdoms finds can carry mods such as tuning for low-power setups, and a
mod fits a mount and adds to the device, as the extra-hook mod does (below). Today only the planter has a
mod mount.

**Built 2026-10-18** ([the world system](../world-system.md#era-stats)): every frame and part has its
era's stats, from its lineage, as factors on the numbers it already has (`Eras.GEAR`). Against colonial
make, the First Kingdoms keep 0.92 of a battery's capacity, a panel's or a turbine's watts and a tray's
lift, draw 1.05 times as much (a tray a kilogram, a shield, an instrument, a lamp) and stand the weather
1.5 times as long; the skimmer era keeps 0.85, draws 1.10, lasts half as long and weighs 0.7; the second
age keeps 0.75, draws 1.25 and lasts 0.9 **(defaults, all but the order)**. So a colonial battery holds
100 Wh and a second-age one 75. The run's kit is the company's issue, colonial numbers. Eras interoperate
as agreed: nothing in the fit, the seat or the deck asks what era a piece is (probe 5 of the lineage
probes). **Repair is still needed:** each era's material is data (finite colonial parts, metal, scrap for
the skimmer era by default, cord, ceramic and saltbush wood), and there's no repair act, no material in
the catalog and no rule for what a mend gives back.

## Item lineage (Agreed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 3, "The Dark Age: a lineage rule, not
a site layer." Nothing is built.* "A second-age item is a colonial or first-age item remade in the Dark
Age. Item data should record lineage: original era plus remake history." The marks that show it are in
[art direction](../art-direction.md#layered-marks-agreed-session-4-part-5-named-not-drawn), and the rule
is in [Salvage & ruins](salvage-and-ruins.md#the-dark-age-as-a-lineage-rule-agreed-session-4-part-5-not-built).

Readings, not in the session:
- **Lineage is a short list on the part,** an original era and then each remake: colonial made it, the
  First Kingdoms kept or marked it, the Dark Age remade it. A part that never left its era has a list of
  one. It sits beside the maker (who made it) and the layer a find came from (where it lay), which are
  separate things already in the data.
- **It drives the look and nothing else.** "Visual only; no stat effect required." The stats come from the
  era of the frame (frames by era above), so a Dark Age remade crate is a second-age frame whose marks read
  three deep.
- **It is generated, not saved, for finds.** A find's lineage is drawn from the find's own stream of the
  seed, as its layer and its fitted parts are. Only a part you carry needs it kept, with the part.
- **Typed parts hold.** Lineage is a field of the part, not a new part (rule 6).

**Built 2026-10-18** ([the world system](../world-system.md#what-lineage-does-now)): a find's lineage is
drawn from its loot seed and its site's era and kind (`Eras.lineage`) and given with `Catalog.found_in`,
the loot package's one call; what you take keeps it through a save. It drives the look (layered marks,
[art direction](../art-direction.md#layered-marks-agreed-session-4-part-5-named-not-drawn)), and its last
hands' era drives the stats, as above: a Dark Age remade crate is a second-age frame whose marks read
three deep. A thing without one is the company's issue, or, from an older save, looks as it did.

## Crate makers (Agreed direction, session 4, part 4; not built)

*[Session 4, part 4](../plants-worldgen-ruins-2026-10-17.md), "Agreed direction." Nothing is built, and
today there is one crate frame.* "Multiple manufacturers make crates with different slot mixes. A
crate's maker tells you its era and its job; the slot mix is the variety axis." This sits beside
frames by era above: the era sets a frame's trade-off between efficiency and repair, and the maker sets what it is for.

| Maker | Era | Character |
|---|---|---|
| Tilg & Standard | Colonial | Standard logistics all-rounder, most common |
| Halloran Isotope | Colonial / skimmer | Industrial, rugged, heat-tolerant, few planter slots |
| Frontier Ag | Colonial | Purpose-built grow crates with deep beds and integrated misters; rare and fragile |
| First Kingdoms / second age (hand-built) | First Kingdoms, second age | Crude, heavy, odd slot layouts; the Sisters' versions built for water storage |

Readings, not in the session:
- **A maker's crate is a frame, and a frame is data.** A frame is a list of sockets (rule 4), so a
  slot mix is a list. Another maker is another entry in the catalog, as an era's crate is. Sockets
  save by list index, which only matters for the frames that exist: a new maker's frame is new, and
  the rule is that nothing is inserted into an old one.
- **A maker spans eras, and an era spans makers.** Halloran's "rugged" crate is colonial and skimmer,
  where the skimmer era's own crate was "light, cheap and fragile" (frames by era, old table). Read as a
  crew's improvised crates against Halloran's industrial ones, both in the skimmer era.
- **Frontier Ag's misters are the humidifier built in.** The grow crate with "integrated misters"
  holds what the humidifier below is a separate part for, which puts a humidifier in the rare crate
  and makes the late-game one a part you fit.
- **"Crate" is the planter's word here.** A grow crate with deep beds is a planter variant: the
  built planter is a frame of its own, with plant slots, and a crate has none
  ([Farming](farming.md#planter-sizes-as-socket-kinds-agreed)).
- **"Tilg & Standard" and the colonial row.** The merger was no later than the war
  ([lore research](../lore-research.md#17-open-after-the-endings-session-and-session-4-part-3)), after
  the colonial era, and the colonial crate's stencil is the acronym TILG (art direction). The session
  writes the maker as the company is known; read as the same company. One word to change if
  colonial crates should read Tilg.

## The burner and the humidifier (proposed, not built)

*[Session 4, part 4](../plants-worldgen-ruins-2026-10-17.md): "New equipment implied: burner/generator
(for coalcane fuel), humidifier. Both are crate parts like the existing devices." Implied, not
specified; direction only.*

- **The burner** consumes coalcane and produces power ([Power](power.md#fuel-crops-and-the-burner-proposed-not-built)).
- **The humidifier** raises humidity for storm crops, a managed input in the late game, with the lamp
  for light ([Farming](farming.md#progression-agreed)). Its water and power draw are not said.
- **The lamp** that grows the office fern is the existing lamp-on-crate snap.

Readings, not in the session:
- **"Crate parts like the existing devices" has two readings.** A part fits a socket (a battery, a
  panel, a hook), and a device is a frame with sockets of its own, and the existing devices include
  both: the shield and the radio seat on a top mount while the condenser and the charger stand on a
  deck mount. Which the burner and humidifier are is not said. They would need a fuel input (a stalk
  of coalcane is neither a battery nor a canister) and a water input, so a frame with its own sockets
  is the likelier. If so, each gets a row in "what each frame has" below.
- **The socket kind is open.** A top mount, a deck mount and the planter's mod mount are the
  candidates for the humidifier, and a new fuel socket for the burner. The session names none.

## The kiln (Agreed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 5. Nothing is built, and no number is
set.* "The kiln is a new processing device that burns coalcane. It is what makes second-age repair
possible." Four chains:

1. **Ceramics and glass:** fires salt-glazed ceramic and sand-glass, the repair materials for second-age
   gear.
2. **Water:** boils tainted stormcup water safe.
3. **Food:** roasts the bitterness out of wild tubers; dries and salts food for keeping.
4. **Salt:** reduces saltbush bladders to salt.

"Era variants work like crate makers: same job, different efficiency and fuel draw."

| Variant | Era | Notes |
|---|---|---|
| Electric furnace | Colonial | Most efficient; runs on power, not coalcane |
| Brass-fitted forge | First Kingdoms | Middle efficiency |
| Beehive clay kiln | Second age | Lossy, but buildable and repairable from gathered materials |

Readings, not in the session:
- **One device, three catalog entries, four recipes.** The three variants are frames with different
  numbers, as the crate's eras are; the four chains are recipes: items in and a fuel or power draw, items
  out. No chain is a subsystem of its own (Farming's rule 3, "one shared system per area").
- **It is a device that stands on a deck mount,** a crate-sized thing like the condenser and the charger,
  with a place for its input and its output and a fuel input (coalcane is neither a battery nor a
  canister, as the burner's case was). The electric furnace needs a power socket instead. Which sockets
  is not said, and any new one is appended to a frame.
- **The wild-water chain pairs with the water socket.** A canister of tainted stormcup water goes in and a
  safe one comes out, through the same one-at-a-time socket as everywhere else.
- **"Buildable and repairable from gathered materials" is the first thing the player makes.** Parts are
  "found, never crafted," and crafting is out of scope. A clay kiln built from gathered stuff, and ceramic
  fired in it, are the first crafting in the design; the session names no other (open questions).
- **Era variants make coalcane's price an era choice.** The colonial furnace needs no fuel and a lot of
  power, the others burn the same cane the burner and the Stoker want ([Power](power.md#the-kiln-and-its-fuel-agreed-session-4-part-5-not-built)).

## The terminal output system (proposed, session 4, part 5; first piece built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), sections 2 and 14, step 6: "Terminal output
system: short god logs, forms and dispatches rendered on consoles. One system serves every god." The
session labels the design pieces Agreed and gives no detail of how they are built, so what follows is
direction, a proposal. Its first piece is built, for the Console's own messages (As built, below).*

The rule behind it is the amended one: people never talk, and "machines can talk through their
terminals." Allowed output is "short logs, requisition forms, incident reports, dispatches, error
messages, licensing notices, and rare clipped lines ('Unacceptable.')." "Quests arrive as terminal
output. The player answers physically... Never by choosing a reply." "A god's personality lives in its
formatting and word choice, not in paragraphs." ([The lore](../lore-research.md#the-dialogue-rule-amended-agreed-session-4-part-5)
has the rule.)

Proposed, in this PRD's terms:
- **A terminal is a screen that prints a short line from a source.** The source is a god's state; the
  screen is either a stationary god's own terminal, a prop at its home, or the player's **Console**
  (above), whose full-face screen shows what a god module on the deck prints. One output system feeds
  both, which is "one system serves every god."
- **The lines are data.** Each god has a set of templates keyed by its state (willing, captive, fed,
  corrupted, displeased) and by an event (a module mounted, a dispatch delivered, water wasted), plus a
  format: the form's header, the ranks, the caps, the unit. The personality is in those templates and
  nothing else, which is "differences come from data, not a subsystem per god."
- **It prints and does not ask.** A terminal has no input. A quest is a printed line that names a thing to
  carry, slot, feed, place or steal, and the world's state is the answer: a condition the game can see.
  There is no menu and no reply, so no new action: "A new device or tool answers these; it never adds
  an action of its own."
- **It is short.** A few lines on screen, the latest on top, and a line is one clipped sentence or a
  form's few fields.
- **Read at the screen.** State shows on things first (Menus & UI): you look at a terminal to read it. A
  god module on a deck with no Console prints nowhere, a reading.

Readings, not in the session:
- **Three things are called a console.** `Console` is the dev tool's class and the camp device
  proposed above, and part 5 says "stationary gods as consoles." This PRD says "a god's terminal" for the
  last. The naming question already open here ([The name](#open-questions)) grows by one.
- **The Quartermaster's forms and the radio.** "Locks your radio to military frequencies" is an
  instruction to the radio device, printed as a form on the screen; the radio is a different system
  ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md)).
- **Text, not voice.** The session says terminals. Whether any god is ever heard is the Radio PRD's open
  question about voices.

**As built, its first piece (2026-10-17):**
- **One small system,** `Terminal` (`game/devices/terminal.gd`). It holds what senders print, each
  line with its sender: log lines and forms, kept with the local time they printed at, the newest
  last and 32 at most; and each sender's live readout, a few rows printed over its last. A form is
  its title, then each field as a key and its value. It prints and never asks. A screen shows it,
  and redraws only when something new is printed.
- **Only the Console prints through it so far,** under the sender CON. Its readout is its weather
  rows, a table. Its log lines are its own messages, short and in caps, the numbers in their
  units: "FRONT 1.2 km N · 5 min", "SHIELD AUTO-ON", "PRESSURE ▼ · STORM ~6 min", "STORM PASSED",
  "SHIELD DOWN · NO POWER", "SHIELD OFF", "RADIO ON", "RADAR ONLINE", "LINKED · 2 CONSOLES".
  The storm's arrival is a form: "IN STORM", then its sand and when it clears.
- **The voice is in the formatting.** A "!" before a line marks it urgent, and it shows in a
  storm's amber; a row indented runs on from the one before and shows dim; a row's cells apart
  by tabs are a table, a label, a number, its unit and a note, which a screen lines up in columns,
  the labels in the accent. That marking and the wording are all the Console's personality: data,
  not code.
- **On the screen** a log reads as time and line ("14:03 SHIELD AUTO-ON"), the sender shown only
  when it isn't a Console, a form's fields indented under its title, the newest at the foot, where
  the proposal had it on top. Linked Consoles' logs show merged, by time.
- **Saved** with the Console that holds it.
- **Still proposed:** gods and their templates by state and event, forms printed by a god, dispatches,
  a god's own terminal prop, and quests printed as lines.

## God modules as crate modules (proposed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), sections 7 to 14. The pantheon is Agreed; how it
is built is the session's proposal, step 7: "God module framework: mountable gods as crate modules with
innate powers; stationary gods as consoles; per-god state (willing, captive, fed, corrupted)." Nothing
is built.* Four gods are mountable (the Walker, the Quartermaster, Mother Cistern, the Almanac), and three
are not (the Ledger is the ship, the Stoker and the Eye are places).

| Module | Innate powers, from the session |
|---|---|
| The Walker | Weather sensing; "like two fully modded weather Consoles" when taken whole (the endings session). Its core is a legendary module. |
| The Quartermaster | A cache map to old military depots and skimmer-era loot; full ground radar with burial depth; military hardening (storms, particles and static can't damage it); "many mod slots"; an orbital strike if willing (deferred). |
| Mother Cistern | The water module from Sister: forecasts and conservation reminders; taking her stops the Sister basin dripping, forever. |
| The Almanac | Yield boosts and habitat reveals; probably crossbreeding (Idea). |

Proposed, in this PRD's terms:
- **A god module is a typed part, found and never crafted** (rule 6), at its landmark: the Walker on its
  route, the Quartermaster in the black site, Mother Cistern in Sister, the Almanac in the Rim ag
  complex. Its powers are data on the part, as any device's abilities come from its parts (rule 4).
- **"Many mod slots" is a part that adds sockets,** as the extra-hook mod adds a hook. Sockets are
  appended and never inserted (they save by list index).
- **The state is saved with the part:** willing or captive, and for the gods that stay put, fed,
  corrupted or authorised. The terminal's lines read the state. "You can take its core without consent":
  captive is a state a theft sets, and willing is one a god's trust sets (dispatches, below).
- **It sits where a computer mod sits,** on a Console, as the endings session has the Walker "work as a
  Console," or in a socket kind of its own. A computer-mod port is proposed above; the session names none.
- **A module can act on its neighbours.** The Quartermaster "requisitions a cut of your camp power,"
  "won't light civilian lamps" and "locks your radio to military frequencies." Those are changes to
  other devices' draw and behaviour, by data, along the same link that already makes a deck one power
  pool. Rule 4 has a device's abilities come from its own parts, so this is new.
- **Orbital strike (Agreed; deferred).** Willing Quartermaster only: "a few shots per game or a long
  recharge. It blasts a crater down to a buried ruin and destroys loot near impact, so you aim
  off-centre." A captive one refuses. It needs a placed change to the ground (open questions) and a count
  or a recharge (the session's own open question).

## The singing stone (Agreed, session 5; not built)

*[Session 5](../lore-session-2026-10-18-mitchell-wow-shoemaker.md), "Singing stones." Direction, not a
spec; nothing is built. The lore is in [the lore research](../lore-research.md#shoemaker-and-the-singing-stones-agreed-session-5).*
Fragments of Shoemaker, black, glassy and scored with melted grooves, warm and strongly magnetic.
- **The item:** low tech, no attachments, mountable on a chassis.
- **What it tells you.** Wind plays its grooves like a flute, so its note follows the open wind even when
  you are sheltered behind a dune. Because it is magnetic, it sings slightly off-key before an anomaly, while
  compass drift is starting.
- **A quest piece.** The Walker can't sense anomalies and a stone can, so delivering one teaches the Walker
  the anomaly tell, tying into its quest line ([Console](#the-console-proposed-first-version-built)).
  **Ruled (Hunter, 2026-10-18):** teaching takes one piece of evidence for each tell, and the stone and your
  own sensor logs are two forms of it, "at least those two things, probably more." Which form gives which
  tell is not said; the stone's off-key note is the compass drift's, a reading.

Readings, not in the session:
- **It is one more tell,** beside the compass drift, the odd static and the shield's particle load
  ([Wind & storms](wind-and-storms.md#the-anomaly-as-built-2026-10-18)), and it is audio. The off-key note
  reads the same hidden term the other tells do; the plain note is the wind's.
- **"No attachments" means no sockets,** so it is a typed part with nothing seated on it, mounted like a
  wind streamer ([nomad gear](salvage-and-ruins.md#nomad-gear-agreed-2026-10-18-spec-built-2026-10-19)).
- **Not said:** the note's pitch and loudness, whether several stones change it, how far ahead of an anomaly
  the off-key note is, and where stones are found beyond the black stones in the sand, Halfrise's cradles and
  Sister's stone.

## Mitchell as a module (Idea, session 5; not built)

*[Session 5](../lore-session-2026-10-18-mitchell-wow-shoemaker.md), "Player era: the undead god" and "Relationships
and module interactions." The core is **Agreed**: Mitchell's core is silent but intact, and it can be revived
and carried as a console module, like the other non-stationary gods. What it does is the session's "likely
mechanic (not designed yet)," so it is an Idea. The lore is in [the lore
research](../lore-research.md#mitchell-the-dead-god-agreed-session-5).*
- **Idea:** it heals or makes medicine on credit, and starts quietly charging in water or salvage if you
  fall too far behind. **Ruled (Hunter, 2026-10-18):** the player crafts nothing. The module would
  auto-craft its recipes, turning resources into health or healing on its own. Still an Idea.
- **Beside the Quartermaster:** the Quartermaster grants Mitchell clearance it gives no one else (Idea:
  perhaps unlocking military med-tech recipes), and Mitchell immediately opens a tab on the Quartermaster.
- **Beside the Ledger:** they won't get on. **Beside Mother Cistern:** carrying it costs you her, at least
  while it is on the cart. With the three linked, the Quartermaster might broker peace (left open).
- **Its voice** is its formatting and word choice ([the terminal output
  system](#the-terminal-output-system-proposed-session-4-part-5-first-piece-built)): it greets you by name,
  says "your little balance" and never "debt," never threatens and only remembers out loud, and calls itself
  "a full-service institution."

Readings, not in the session:
- **It is a god module like the others** (a typed part found at its landmark, its state saved with it), so
  the table above grows a fifth row; the session gives it no innate powers beyond the Idea.
- **A tab is a number on the part,** printed on the terminal, and charging is the same move as the
  Quartermaster's requisitioned power and the Almanac's royalty: a god takes a cut. Health already mends
  with rest ([Survival](survival.md)), so "heals" is a faster mend, and the auto-crafted healing turns
  resources (water, salvage, food) into it.
- **The Clerk's field synthesiser** is a found device in the second age's ruins; the session says players
  find "working Clerk synthesisers" and not what one does.

## Dispatch items (proposed, session 4, part 5; not built)

*[Session 4, part 5](../gods-gear-farside-2026-10-17.md), section 13 and step 8: "Dispatch items: sealed
packets with sender, recipient and opened/forged flags." Nothing is built.* "Dispatches are the quest
system: a god's console prints a sealed packet for another god, and you carry it."

Proposed, in this PRD's terms:
- **A dispatch is a small carried item,** like a ration or a rope coil: it has a sender, a recipient and
  two flags, **opened** and **forged**. A god's terminal prints one when the state calls for it, so it is
  given and not crafted.
- **Delivery is physical.** The player carries it and slots it into the recipient's terminal. Nothing is
  chosen. "Deliver faithfully and the sender warms to you," and the player "can also open or misdeliver
  packets"; what opening or misdelivering does to the sender is not said.
- **Channels are data,** the session's four: a repaired Starcom (persistent, every god at once), the
  Walker (reliable, slow, on its route), storm radio windows (rare, fragmentary; back burner) and the
  player. Only the last is an item the player carries.
- **Forgery is the hive mind start's, and deferred.** "Sealed packets open easily for you... you can forge
  dispatches and set gods against each other."
- **The Eye keeps what it is given.** Each of the Stoker's packets the player delivers changes the
  Eye's state; how many are needed is not said.

## Slots and sticky faces

Since the chassis (2026-10-18) the only slots are plugs and water taps and what a thing has of
its own; everything else sticks on a chassis's sticky faces.

| Slot | Takes | Owned by |
|---|---|---|
| Sticky face | Anything that isn't for a slot only, anywhere it fits on a chassis piece's top or underside, a wall's or a shelf's: batteries, trays, runners, a keel, panels, lamps, canisters, frames, and every device that sticks. A socket is made where a thing sticks, its pose its own | Devices & mods |
| Battery slot | Batteries, in what works away from a deck: the board, the radio, the heat cutter, the planter and the turbine | Power |
| Battery bay | Batteries, in a power box's bays; a skimmer rack's dead bays take nothing (2026-10-19) | Power |
| Ring | Rope hooks, on a chassis piece's edges and a planter's; on a grid piece, another piece's edge | Rope & tethering |
| Port | A cable's plug | Power |
| Water socket | A canister or a hose's end, one at a time (2026-10-17) | Survival, Farming |
| Bottom mount | The planter's own hover tray | Farming |
| Plant slot (small pot, standard planter, deep bed) | Crops by the size they declare; a planter's and a survival kit's | Farming |
| Mod mount, food slot | A harvester; a ration, in a survival kit | Farming, Survival |
| Sail mount | A sail, on its boom, low on a mast; seated, it adds a tie at the boom's end for the sheet (2026-10-18) | Movement |
| Frame face | A whole face on a frame: a chassis piece (a wall or a shelf), a screen or fabric | Devices & mods |
| Computer-mod port, computer-mod top, screen port | A Console's own electronic ports: its instruments, its radar, its screen (2026-10-17) | Devices & mods, Wind & storms |

**As built, what each thing has** (2026-10-18):

| Thing | Battery | Ring | Port | Other | Sticks |
|---|---|---|---|---|---|
| Chassis piece | | 4 | | sticky top and underside; its rings join other pieces | joins by its rings or a frame's face |
| Frame | | | | five faces | square on a top |
| Planter | 1 | 2 | 1 | its tray's bottom mount, 3 standard and 1 pot slot, a mod mount, a water socket | stands as it is |
| Wind turbine | 1 | | 1 | | stands as it is |
| Condenser | | | 1 | a water socket | stands, tall |
| Shield generator, light shield | | | 1 | | stands |
| Console | | | 1 | a computer-mod top, a screen port the whole front and six computer-mod ports | stands, tall |
| Mast | | | | a sail mount | stands |
| Helm seat | | | | use on it sits you at the helm ([Movement](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)) | stands |
| Light solar panel | | | 1 | | any face |
| Hoverboard | 1 | | 1 | | any face; charges from a deck's pool |
| Radio | 1 | | 1 | | any face |
| Heat cutter | 1 | | | | any face |
| Bedroll | | | | use on it sleeps, and in your hands lays it out ([Survival](survival.md#sleep-as-built-2026-10-18)) | any face |
| Survival kit | | | | a water and a food socket, 2 standard and 1 pot slot | any face |
| Power cabinet | 8 bays | | 1 | a readout | stands, tall |
| Power box (company issue) | 4 bays | | 1 | | any face |
| Battery rack | 12 bays, 3 dead | | 1 | | stands, tall |
| Power shrine | 3 bays | | 1 | | stands |

The crate and the charger are gone: a chassis does what the crate did, and a battery stuck on a
deck with a panel charges as the charger did.

**Carried, a device works as anywhere else** (Hunter, 2026-10-17): a carryable device goes
in with what the suit carries whole and works on its own battery, riding on you (Survival).
There's no flag for it: no device is an exception.

**Runners and the mast** (2026-10-18). Runners stick under a deck as a tray does: skates or a
board plate, which ride the sand on their blades, slide along their length and grip across it,
lengthwise the way they're stuck. A deck carries one or the other, never both, and mixing refuses
with "runners and trays don't mix". The mast stands on a deck, and its sail fits its sail mount.
How they sail is in [Movement](movement.md#sailing-the-camp-hunter-2026-10-17).

**The keel and the helm seat** (2026-10-18). The keel sticks where a tray would and lifts like
one, less; floating, it holds its camp across the wind. The helm seat stands on a deck. Each one's
behaviour is its own, found by what it is (the keel by its grip, the seat by being one), never by
where it's stuck. How they sail is in
[Movement](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built).

Some parts **add sockets of their own**. An extra-hook mod fits a mount and provides a
hook. That's how found mods expand a device. A hose's end fitted in a water socket offers
a water socket of its own on top, so a canister or another hose goes on there too
(Survival, 2026-10-17).

## Skeleton version

- Device frames with sockets, and typed parts.
- Magnetic snapping and removal as described, with crude feel.
- All five socket types above.
- Fitted parts merging into the device's shape and weight, and device stats computed
  from parts.
- A look-at line: what a thing is and the one thing you need about it now
  ([Menus & UI](menus-and-ui.md#saying-less)).
- Loose stacking left to physics.
- The probes below, all passing.

## Full version

- **The feel, polished:** the ghost, the hum, the clunk and the easing of the turn.
- **Parts that add sockets,** like the extra-hook mod.
- **Part tiers and upgrades.** Session 4 adds a second axis, the frame's era (Frames by era).
- **More part types,** as the other PRDs need them.
- **Per-part wear from the elements.** In the skeleton, wear is a single durability on
  the whole device (Bubble shield & camp).
- **The Console and its computer mods** (proposed, 2026-10-17; a first version built, see
  above), with the smart devices they make.

## Probes

1. **No accidental snaps or sticks.** Drop, throw and drag parts against slots and sticky
   faces thousands of times, and let go mid-tug or while shown where they'd stick: nothing
   goes on unless it's held, aimed and taken. Standing by a chassis, a held tray is shown
   under it, a hook offered the near ring, a shield shown on its top; at a planter, the ring
   nearer your aim; each waits for take.
2. **Stuck and fitted are rigid.** A chassis with parts stuck all over it and a full
   planter, thrown and gusted, keep every part exactly in place: no loose bodies, no joints.
3. **Weight adds up.** A chassis's weight is its own plus what's stuck and fitted, through
   sticking, fitting and taking off at random; a known push agrees, and its trays draw for it.
4. **It lands exactly.** A part sits precisely at its slot, or at its pose on a face, top
   or underside.
5. **Off the way it went on.** Every part on a loaded floating chassis and a planter comes
   off from eight directions, straight out of its slot or off its face, never through the
   body, and goes back on through the hands at the same spot.
6. **Loose stacks are stable.** A loose stack on a floating chassis stays still ten
   minutes, then a gust knocks it all off cleanly.
7. **Origin shifts are invisible.** Stuck parts and a loose stack come through a shift untouched.
8. **Nothing falls through.** A dying floating chassis, chassis dropped from 3 m, thrown
   parts, a cable popping off a drifting chassis, a battery under a falling planter: none
   ends up under the sand.
9. **Arranging by hand.** Walking into a floating planter pushes it no faster than you walk;
   taken hold of, it follows and swings round, and let go it stops; a 200 kg condenser slips
   from your hands.
10. **Small things come easy.** Aim at the sand beside a small loose thing and it's the one
    you'd take; between two, a wavering aim settles on one; nothing is taken through
    something in the way.
11. **Keys come from the bindings.** Rebind an action and every key shown for it follows, a
    mouse button too, and the new key works.
12. **Turned by hand.** Holding rotate turns what you hold and not your view; a condenser and
    a planter on their sides roll upright; a shield is set down standing; looking up lifts a
    light condenser but not a heavy one.
13. **Use rests a deck.** Use at the Surveyor's deck sets it resting, settling gently and
    drawing nothing, and floating again; use at the shield on it switches only the shield;
    saved resting, it resumes resting.
14. **Trays come out standing.** A look at a floating planter's lower edge is a look at its
    tray; a standing look at a chassis's top or edge is the piece, not the tray under it.
15. **The ghost in sight.** A slot offered on a planter's far side shows no ghost through it;
    walk round and it does; a tray's shows under it.
16. **One rigid deck.** Five pieces joined by hand into an L sit flush and square; a
    condenser beyond a ring blocks it; with trays, a condenser and batteries the deck rides a
    gusting storm moored, its pieces never moving against each other.
17. **Trays lift where they are,** so a balanced rig floats and a lopsided one tips. A deck
    three by three floats level on four corner trays, rides lower loaded, rests too heavy and
    floats again on a tray under every piece; with its trays bunched along one edge it tips
    its far edge onto the sand.
18. **A condenser onto a deck.** Having hold of one and looking at a deck, the condenser
    itself is shown there, touching nothing, and back in your hold when you look away; take
    sticks it; a loose battery on the deck runs it and a shield as one pool; taken off again
    it drags away and the deck stays.
19. **Take takes what you aim at.** One battery taken out of a crowd comes off alone and goes
    straight back on with take again, the aim never leaving, and a radio's own battery the
    same; aimed at a deck's plate, take has hold of the whole deck; only a bare piece comes
    off, out across its ring.
20. **A load off centre leans.** A piece with its load over its one tray floats level; with a
    big battery at its back edge it leans 3 to 20° and stays still.
21. **A loaded piece joins from your hold,** the real piece shown at the ring, its condenser
    in the deck's pool once it joins.
22. **A refusal says why,** with a knock: a full battery slot, a condenser shown where a
    shield stands, a piece with something beyond every ring, use at a bare chassis.
23. **A device freed under it.** A shield stuck on a floating chassis freed outright: the
    chassis runs on and another shield sticks in the same place.
24. **Consoles on a deck are one system.** Two on a deck pool their readings, one on its own
    plate doesn't; two radars draw a finer map; moved off, each keeps only its own.
25. **Instruments add detail.** A Console on a plate gains a reading per instrument and a
    radio stuck beside it the forecast; its map grows finer with each and coarsens as they go.
26. **The Console rides upright.** The heaviest Console, stuck on a two-piece deck with a
    shield and big batteries, floats leaning only a little and rides a gusting storm upright,
    moored by the deck's ring.
27. **A hook in the way pops off,** keeping its line through a save; the piece that joins from
    your hold carries a condenser.
28. **Switched from the screen.** The power page switches the shield, the radio, the deck's
    lamp and its trays; its watts and bank are the pool's.
29. **The gyro points Tu-ward** from a Console on a plate, round the moon.
30. **The Console says its battery is low** (2026-10-18). A Console with a radio on its deck
    logs and says "Battery low." from the radio as its deck's pool falls past the low line, once
    until it's back over, then "Battery critical."; with the Radio voice off, it only logs it.
31. **It sticks on every face.** Held to a piece's top a battery is shown there itself and
    take sticks it flat where you aim; a tray aimed at the top goes under, facing the sand;
    a frame stands square; pieces join a frame as a wall and a shelf; the board sticks on the
    wall's outer face, batteries on the shelf and the wall's inner face, fabric on the frame.
32. **Blocked shows red.** Where another stands it's red and "blocked", and take keeps it with
    a knock; clear, it sticks. Past a floating piece's lift it's amber, "too heavy", sticks
    all the same, and the piece no longer floats.
33. **A tray lifts the way it faces:** fully under, 0.71 tipped halfway, nothing on a wall
    (and the deck counts none), nothing flipped over, drawing nothing.
34. **Frames take walls and shelves,** and go only on a top; a Console never under one nor a
    frame over it; a chassis never sticks; a shelf's rings take hooks but no piece; a frame
    with walls on won't come off.
35. **Broadside, not edge-on** (2026-10-19). A wall broadside to a steady wind is pushed
    downwind as a flat face its size; edge-on, next to nothing; at 45°, off the wind as well
    as down it.
36. **One face shades another.** Two frames side by side across a steady wind, walled front
    and back: each wall upwind takes what a lone one would, and each behind a fraction.
37. **A scoop open upwind catches more.** A frame walled on its back, sides and top is pushed
    harder with the wind blowing into its open side than with the same wind on its back.
38. **Fabric pulls weakly.** Fabric facing aft on a floating deck draws it downwind with the
    sail furled, but at under a quarter of the sail's pull in the same wind.
39. **The cloth shows its load.** Its load goes as its push, the same share of it in a breeze
    as in a fresh wind; slack in the breeze, taut in a gale, bellied the other way with the
    wind round, and bearing nothing edge-on while the air stirs it.
40. **A heavy thing up the mast.** Stuck high on a standing mast, a big battery stands its camp's
    middle higher by what its weight there says, and the same push heels it further; nothing tall
    goes on a mast, and a mast with something on it stays on its deck.
41. **The crow's nest.** It goes only on a mast's head; its ladder climbs you in, seated, your
    eyes over 5 m above the deck and your weight high on it; more of the ground shows from up there.
42. **The streamer.** It hangs in still air, streams downwind in a breeze and stands out level in a
    gale, flapping wider and faster; stuck on a moving deck it streams aft; in your suit it reads the
    air where you are.

## Out of scope

- Crafting, for now. Parts come from Salvage & ruins.

## Open questions

- **Can pieces from different eras join freely in the chassis, or do they need adapters?**
  *Answered by session 4, part 5: they join freely, and there are no per-era compatibility rules
  (below).* Open in the notes (Hunter, 2026-10-17). Here: "Pieces join edge to edge by their rings," "A
  piece... is a find," and "Trays lift where they are" (which replaced "every piece needs its
  own hover tray" the same day). Not said: whether a piece's era matters to the join at all,
  and what a first-age piece, "practical to drag without a hover tray," does in a deck
  that floats on its trays' combined lift. If adapters exist, the rules here
  would make one a typed part that is found, not crafted (rule 6, and out of scope below).
  Session 4, part 2 lists the question again among its own open ones, still unanswered. It also
  shows why it matters: the moving nomad city is "a huge tethered raft of salvaged chassis,
  shields and turbines," pieces of many eras lashed together.
- **Efficiency of what.** "Best power efficiency per kilogram" could mean the hover draw per
  kilogram floated, or something else of the frame's. The notes give no numbers for any era. *Narrowed
  by session 4, part 5: efficiency is one axis against repairability; still no numbers.*
- **Where the tuning mods go.** A low-power tuning mod needs a mod mount, and only the planter
  has one. Whether the crate, the shield and the rest get one is not said.

Session 4, part 3 (2026-10-17) adds three. Each is quoted on both sides and left standing.

- **A bedroll needs a mount.** Here: the crate has one rack, which holds the board (Movement). The
  sleep session: bedrolls share the board's mount on a crate. The session: the patrol board carries
  a bedroll of its own. Not said whether a board's bedroll mount is the rack's kind.
- **A tow on a board.** Here: the board "tows nothing" and has one battery slot and one port. The
  session: a "Tow" among the board's gear. Not said whether it is a ring mount with a hook or
  something of its own, or how strong it is against a board that "digs in" under a haul.
- **The Walker on a deck mount.** Here: a deck mount takes "a crate frame, a condenser, either
  shield or a charger," one device the size of a crate. The endings session: the whole Walker goes
  "onto a chassis" and works as a Console. Not said whether it fits a deck mount or has a frame of
  its own.

The Console session (2026-10-17) is direction, not a spec. Its own open questions come first, then
what folding it in raised. Each is quoted on both sides and left standing.

- **The Console's face and slot layout.** Open in the session ("rework pending"). Here: every
  side of the built crate carries something. The front has a port, a battery slot and a ring, the
  back a battery slot and a ring, the left a ring and the rack, and the right a ring and, high
  up, the charge light. The session: "one side is dedicated to visual output: a full-face screen
  port," with faces laid out so it "can't clip into other parts." With the side rings gone (the
  frames table says rings front and back only), the right side is left with the charge light and
  the left with the rack. Not said: which face is the screen, whether a Console keeps the rack
  (a bedroll would share it, [Survival](survival.md#sleep-proposed)) and the light, and where
  "plenty" of mod ports go once the screen has a whole side. *Built as a first version
  (2026-10-17), the rework still pending:* the front is the screen and nothing else, the back
  takes the batteries, both rings and the port, each side three computer-mod ports, and the
  charge light stays high on the right. It has no rack. *Reworked (2026-10-18):* a rack 1.3 m
  tall, the same sockets in the same order on its new body, the screen the whole front.
- **Which computer mods, and which slot kinds.** Open in the session. Here: "Parts are typed"
  (rule 6), and the planter's mod mount, one kind, takes the harvester. The session: computer
  mods in "plenty of mod ports," and "antenna, radar and the like" in a computer-mod top. Not
  said: whether a computer mod fits that same mod kind (then a harvester would fit a Console and
  a radar a planter) or a kind of its own. The socket types above take the second reading, as
  a proposal. Also not said: whether the Console's antenna is the radio's
  "antenna mods" ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md)) or a different part.
  *Built (2026-10-17):* computer mods are a kind of their own, so a harvester doesn't fit a
  Console nor a radar a planter. Four go in the side ports (anemometer, barometer, hygrometer,
  particle sensor) and the radar on the top. No antenna is built.
- **One regular top slot, three wants.** Here: a top mount takes "solar panels, instruments such
  as the radio, lamps, the shield generator," and the kit's crate fills both of its top mounts,
  with a light shield and a light panel. The session: a Console has one regular top slot, a
  shield on it "becomes 'smart'," and audio "comes from a radio on a top mount." The shield and
  the radio can't both have the one slot. Not said: whether the radio goes on the computer-mod
  top, the shield stands on a neighbouring deck piece (then it isn't "on" the Console), or a
  Console keeps two regular tops. *Built (2026-10-17):* one regular top. A shield is smart on it
  or anywhere on the Console's deck, so the radio can keep the top while the shield stands on
  the next piece.
- **What a link reaches.** Here: everything on one deck shares one power pool, and cabled devices
  share one. The session: "a chassis connects every Console mounted on it into one system." Not
  said: whether a Console off a chassis links to anything (a cable?), whether the link takes in
  the other devices on the deck or only other Consoles, and whether a Console stands on a deck
  mount at all. The deck mount takes "a crate, a condenser, a shield, a charger," and a Console is
  "a crate variant," which reads as yes, but is a reading. *Built (2026-10-17):* a Console stands
  on a deck mount. The link takes in the whole deck: Consoles pool their instruments, and every
  shield on it is smart. A Console off a deck links to nothing; a cable doesn't link Consoles.
- **The name.** `Console` is taken. It is already a class (`game/dev/console.gd`), an action
  (`console`) and the Menus & UI PRD's "dev console," and this PRD's chassis section says "the
  console's give makes one by its id." Not said: whether the device keeps Hunter's name and the
  dev tool's words change, or the other way round. Until it is settled the docs say "the dev
  console" for the tool and "the Console" for the device. *Answered (2026-10-17):* the device
  keeps the name. The dev tool's class and file are `DevConsole` and `dev_console.gd`, and its
  action and commands are as they were.
- **Running a screen with four actions.** Here: "Four actions cover handling... A new device or
  tool answers these; it never adds an action of its own." The session: a shield "can be
  controlled from the screen." Menus & UI says state shows on things first, and the vision that
  most menus come as devices, so the screen is that. Not said: how a screen is operated. Use at a
  spot on it, or a look, are the candidates, and the aim has to pick one control among many on a
  full face. *Built (2026-10-17):* use at a spot. Its keys sit along its foot, a third of the width
  each, and the one you aim at lights up. Use on a key presses it, and use anywhere else steps the
  page. No action was added.
- **The ring shave against "add new ones at the end."** Here: the frames table says the crate has
  two rings, "front and back only" (Hunter, 2026-10-17: "shave 2 hook slots off the crate now
  that we have the chassis"), and `catalog.gd` still lists four, the side two at entries 1 and 2
  of the list. The session: "Sockets save by list index." Taking out entries 1 and 2 moves every
  socket after them, so older saves would load the wrong sockets. Not said: how the shave keeps
  saves, by leaving the entries unused or by a migration. A Console cut from the crate's list,
  with "only one or two rope hooks," meets the same thing. *For the Console, settled (2026-10-17):*
  it's a frame of its own with a list of its own, so nothing in the crate's moves. The crate's
  shave is separate work.

Session 4, part 4 (2026-10-17) adds the following. Each is quoted old and new. The newest session wins
in the living docs, so this PRD follows it as direction and says so on each line.

- **Three planter kinds against two plant slots.** Here: the planter has "3 small and 1 large plant
  slot" and a survival kit "2 small and 1 large," and the socket table has "Plant slot (small,
  large)." The session: small pot, standard planter and deep bed as socket kinds, "no new collision
  logic." *Follows the session.* Not said which built slot is which kind. Sockets save by list index,
  so the built slots keep their places and the new kinds are appended
  ([Farming](farming.md#open-questions)).
- **Maker, era and the one crate frame.** Here: one crate frame, and "frames by era" as the only
  second axis. The session adds the maker as a third, with four makers. *Follows the session.* Not
  said which maker's crate the kit's is, or whether "Tilg & Standard" in the colonial row is the
  colonial crate (stencilled TILG).
- **The burner against the heavy generator.** Here ([Power](power.md#sources)): a "heavy generator"
  that "rides on caterpillar tracks, slows the camp, and burns fuel." The session: a burner or
  generator that is a "crate part." Not said whether they are one device or two.
- **A survey mod on the Console against separate detection.** Quoted above. *Follows the session.*
- **Pieces of different eras and makers in one deck.** The older question, open in the notes, grows
  with the makers: a Halloran piece and a hand-built first-age piece in one deck. *Answered for eras by
  session 4, part 5 (below); makers are not named.*

Session 4, part 5 (2026-10-17, [the gods session](../gods-gear-farside-2026-10-17.md)) adds the
following. Each is quoted old and new. The newest session wins in the living docs, so this PRD follows
it as direction and says so on each line.

- **Eras against adapters. Answered.** Here (the first question above): "Can pieces from different eras
  join freely in the chassis, or do they need adapters?" The session: "any crate takes any module, and
  there are no per-era compatibility rules." *Follows the session:* they join freely, and the question
  above and the makers' version of it ("a Halloran piece and a hand-built first-age piece in one deck")
  are answered for eras. Makers are read the same way; the session names none.
- **The crate table against efficiency and repairability.** Here (the 17 Oct notes): "Era gear has
  trade-offs, not a ladder," with three crates. The session: one axis, efficiency against repairability,
  and a table of three eras that has no skimmer era. *Follows the session.* Not said where the skimmer
  era sits (its old row, "light, cheap and fragile," is the only word), what "near-colonial" is as a
  number, or whether "Efficiency of what" (above) means the hover draw.
- **Repair against "parts wear out only from the elements."** Here: "Use never wears them," and nothing
  mends. The session: each era has a repair material and the kiln makes the second age's. Not said what
  repairing is, what a worn part needs, or whether the elements' wear can be undone.
- **A kiln against "found, never crafted" and "crafting, for now" out of scope.** Here: parts are found,
  and crafting is out of scope. The session: a kiln "fires salt-glazed ceramic and sand-glass," and the
  beehive kiln is "buildable and repairable from gathered materials." *Follows the session as
  direction.* Not said what goes in for ceramic and glass (clay and sand are the guess), or what building
  a kiln is.
- **A god's module against a device whose abilities come from its parts.** Here (rule 4): abilities
  come from the device's own parts. The session: the Quartermaster "requisitions a cut of your camp power,"
  "won't light civilian lamps" and "locks your radio." Not said whether the module reaches the rest of the
  deck by the pool and the Console's link, or by something of its own.
- **Where a god module sits.** Here: a computer-mod port on a Console (proposed), the planter's mod mount,
  or a deck mount. The session: modules "you can carry on a crate," and the Walker "onto a chassis." Not
  said which socket, or how the whole Walker (a legged robot, above) differs from its core as a module.
  The Walker's open question above, "The Walker on a deck mount," is the same thing.
- **Three consoles.** Here: `Console` is a class, an action and a device. The session: "stationary gods
  as consoles." Not said which word wins. The docs say "a god's terminal" for the prop.
- **A dispatch is neither a part nor a device.** Here (rule 6): "Finds are typed parts and devices." The
  session: a sealed packet with sender, recipient and flags. A ration, a canister and a rope coil are
  items too, so a dispatch reads as one more small item. Not said which class.
- **An orbital strike against the ground.** Here (World & terrain rule 2): loaded ground never changes.
  The session: the strike "blasts a crater down to a buried ruin." *Deferred in the session.*
- **What a god module draws.** Here: "Instruments, farming gear and tools draw small amounts" (Power).
  The session gives a module no draw. Not said whether a Quartermaster's hardening, a Walker's sensing or
  a Cistern's forecasts cost power, or whether a god module can be left without any.

Session 5 (2026-10-18, [the Mitchell session](../lore-session-2026-10-18-mitchell-wow-shoemaker.md)) raised
the following. Hunter ruled on the first three afterwards (2026-10-18), and the rulings replace the old
wording above; the last is still open. Each clash is in the session's [Clashes
note](../lore-session-2026-10-18-mitchell-wow-shoemaker.md#clashes).

- **Eight gods against seven. Ruled:** Mitchell is a dead god who can be revived to become an eighth. It is
  a fifth mountable module beside the four above; the seven stay seven.
- **Medicine, a tab and recipes against "crafting, for now" out of scope. Ruled:** no player crafting. A
  device such as Mitchell's module would auto-craft its recipes, turning resources into health or healing on
  its own (Idea). Crafting stays out of scope for the player.
- **A stone against the sensor logs. Ruled:** both. Teaching the Walker takes evidence for each tell of the
  anomaly, and a singing stone and your own sensor logs are two forms of it.
- **A module that costs you another god.** The session: carrying Mitchell "costs you" Mother Cistern. Here:
  nothing but a module's own draw ("What a god module draws," above). Not said how the loss is counted, or
  how it sits with the Cistern axis, which wants her restored and linked.
