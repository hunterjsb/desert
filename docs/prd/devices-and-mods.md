# PRD: Devices & mods

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Editing your devices is the gameplay. Every device is a frame with **sockets**, and
every part fits a socket of its type. Fitting a hook, a hover tray, a better battery or
a charged one is how you progress, how you adapt the camp, and how you get out of a
pinch. So fitting and removing parts has to feel great: intuitive, reactive and
satisfying, every single time.

**In the world.** Fitting is what the colony could always do, and making is what it never
could: the moon had no fabs, so every part came from somewhere else. Each part carries its own
maker's stamp, separate from the mark of whoever assembled the device around it. A shield
housing might name the contractor while its core names a maker most settlers never heard of.
Batteries are the exception and carry no stamp. See [the lore research](../lore-research.md).

## What the player experiences

- **Magnetic snapping.** Bring a part you're holding near a device. As you approach a
  socket it fits, you feel a tug: the part leans toward the socket, and a faint ghost
  shows where it will sit. Keep going and it snaps home with a clunk. Pull away and the
  tug lets go.
- **Removing feels as good as fitting.** Look at a fitted part and grab it. The device
  turns that side toward you, and the part slides out the way it went in, never
  through the device. It's quick enough to swap a battery in a pinch, mid-storm.
- **Look at something to see what it does.** A device or part shows its stats briefly
  while you look at it, with no menu.
- **Parts change the device.** More hooks, a hover tray, a bigger battery, a solar
  mount. Their weight adds up too, which raises the hover draw.

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
use can't do what you're aiming at (a slot that's full, a tray in the way, a piece that
isn't bare, something too heavy), the readout says why in a few words and a soft "no"
sounds, never silence.
- **Take** picks up, takes out, puts in and puts down. One action takes and lets go
  (Hunter, 2026-10-15, at the Stage 5 gate). Taking something too heavy to carry takes
  hold of it: it follows where you face and turns as you turn, as far as your strength
  drags it, and taking again lets go. That's how you arrange a camp of floating things
  too heavy to lift. Walk off from something you can't shift and it slips from your
  hands.
- **Use** works what you're looking at, or uses what you hold: switch a shield, drive a
  stake, set a crate's hover tray floating or resting (Hunter, 2026-10-16), so a camp
  that's staying put stops spending its charge on floating. **Built** (2026-10-16): use
  at the frame of any device with a tray, empty-handed, switches it. Resting, the tray
  draws nothing and lets the device down onto the sand over two seconds, about 0.6 m/s
  at most; floating again, it lifts it back the same way. The readout says "floating"
  or "resting", the board's soft hum falls or rises, and the switch is kept in the save.
  Use at a shield seated on a crate still switches the shield, and a line or stake in
  your hands keeps its own use. A planter's use is its tray's too (Hunter, 2026-10-17:
  "it should toggle hover tray like the crate and chassis"), unless you hold a canister
  to pour. The kit's crate starts floating. A tray out of power still lets go,
  as before (Power).
- **Throw** throws what you hold.
- **Reel in and pay out** (Hunter, 2026-10-16): on a line, they shorten and lengthen it
  (Rope & tethering). **Bring near and push out** are their own actions (Hunter,
  2026-10-17: "switch rope scrolling to control + scroll so it doesnt conflict with object
  moving"): on anything you hold or have hold of, they bring it nearer or push it farther,
  within reason, and never touch a line. *As built:* a notch is 0.25 m. What you carry goes from
  0.5 m to 2 m in front of your eyes, never nearer than clears you, and still stops short
  of the sand or anything in the way; what you have hold of goes from just clear of you
  out to your 2.5 m reach, following only as far as your strength and the slip allow.
- **Rotate** (Hunter, 2026-10-16): held down, the mouse turns what you hold, or what you
  have hold of, instead of your view. It's how you right a crate, a planter or a shield
  that has tipped over: take hold of it and roll it back. While you have hold of
  something heavy it also follows where you look up and down, not only round you, so
  you can lift an edge, tip it, or drag it up a slope, still only as far as your
  strength drags it.

Walking into a loose thing pushes it, with the same strength. A floating thing you
push keeps gliding, as the wind would carry it anyway; to set one down where you want
it, take hold of it, and let go.

## How things join

1. **Fitted into a socket.** A battery into its slot, a hook onto a ring mount, a hover
   tray onto the bottom mount, a panel onto the top mount, a seedling into a planter
   slot. These are all the same mechanism with different socket types. **Once fitted,
   a part stops being a physics object.** Its shape and weight join the device, and
   there's nothing left to wobble.
2. **Resting loose on top.** Put something down on something else and it just sits
   there under plain physics. It rides along on friction, and it slides off when jolted
   or caught by a gust. People will try carrying things this way regardless, so it's
   allowed but **not balanced around**. If you want something to stay, fit a tray or
   tie it down. We'll watch how it plays.

## The chassis

(Hunter, 2026-10-17: "a larger, flatter "chassis", a modular frame that can attach to
*itself* horizontially to form a large flat chassis of varying dimensions... each chassis
part needs its own hover tray so that becomes a limiter... the same port that can be used
for rope hooks can stick chassis together... mount a crate on the chassis frame to get
more ports".) As a camp grows, one crate isn't room enough. The chassis builds a bigger
floater out of pieces:

- **A piece** is a flat, square frame, a little wider than a crate (about 1 m across)
  and thin. It's a find.
- **Pieces join edge to edge by their rings.** Each edge has a ring, and a piece brought
  edge-on to another's free ring snaps flush beside it, the same snap as fitting. Joined
  pieces are one rigid deck, flat, in whatever shape you lay out. A ring with a hook on it
  ties rope instead, so a deck is towed and moored like a crate. **Take on a deck always
  takes hold of the whole deck,** to drag it (Hunter, 2026-10-17, after playing: "trying to
  drag a chassis around disconnects whatever youre grabbing, causing you to dismantle your
  base"). A piece comes off only when it's bare, no tray and nothing standing on it, and
  the rest of the deck holds together without it: strip it first, as a crate's tray comes
  off before it stands on a deck. **A loaded piece joins from your hold:** take hold of a
  piece with a crate on it, bring its edge to a deck's free ring, and take joins it, as a
  heavy device stands on a deck mount from your hold. Two whole decks don't merge yet.
- **Trays lift where they are** (Hunter, 2026-10-17, replacing "every piece needs its own
  hover tray": "we should actually use physics, so in theory a large connected chassis
  with a light load doesnt need a tray for every chassis piece, but they will need to be
  well distributed to keep it upright"). Each tray is its own lift, pushing up under its
  own spot, harder the nearer the sand and never more than it can lift. A deck floats when
  its trays together lift its weight, and how it hangs is physics: a light load rides
  high, a heavy one sinks lower, a load over a corner with no tray under it drags that
  corner down, and trays bunched on one side let it tip. Spread them to keep it level.
  The same goes for anything on trays: a crate's one tray holds it level only while its
  load sits over it. Use on the deck sets all of it floating or resting.
- **Each piece has one deck mount on top,** which takes one device standing on it:
  usually a crate, and a condenser, a shield or a charger fit too. A planter doesn't (too
  long for a piece, and it floats on its own tray), and nor does a turbine, which works
  only standing on the sand.
  A device stands on a deck only with its own tray off (Hunter, 2026-10-17: "removing a
  crates tray before attaching could fix that"): the deck's trays carry it, and a tray
  under it would wedge it as it comes off.
- **A piece has nothing else:** no battery and no port of its own. The ports come from
  what you mount, which is why a deck usually carries crates. Everything on one deck
  shares one power pool, and its wind catch is its pieces' and what stands on them.

**As built (2026-10-17):**
- **A piece** is 1 m square and 12 cm thick, 9 kg against a crate frame's 15, with a ring
  in the middle of each edge, a bottom mount and a deck mount. The wind meets a deck's
  pieces and their trays side on, as if it were level, and what stands on it as it would
  on the sand. It's painted like the crate: gunmetal rails round a teal plate, black corner
  caps, hazard bands either side of each ring so a deck's outer edge reads, and the
  consignee's stencil on top. It's a find, one device in thirteen on the surface and one
  in ten deep, buried on its edge like a sheet the dunes half took, and the console's
  give makes one by its id, `chassis`.
- **Joining.** With a piece in your hands, a deck's free edge ring is offered the same
  way a socket is: the tug leans the piece flush beyond the ring, turned the quarter turn
  nearest how you hold it, the ghost shows it, and take joins it. Its frame, its sockets
  and whatever is in them move into the first piece's body, as a fitted part's shapes
  do, so a deck is one rigid body, never pieces on joints. A ring between two pieces
  closes and takes nothing. A ring isn't offered where something stands beyond it (a
  piece joined over a crate would throw it), where a hook on a neighbouring edge would
  stand in the new place, or for a wrecked piece. Joined on a slope, a deck lifts clear
  of the sand as a crate does onto a tray. Your hands reach a deck by its nearest piece,
  so a long deck's far end is as easy to work as its first. A deck wears as one device,
  as worn as its most worn piece when they joined.
- **Taking a deck apart.** Take aimed at an outer piece, one the rest of the deck still
  holds together without, takes it off with all that's fitted to it, its tray and hooks
  and a line tied there, out across a ring it leaves and into your hands. A piece with
  something standing on it comes off with that too, into your hold, since it's too heavy
  to carry. Aimed at a piece the deck can't lose without splitting, you take hold of the
  whole deck to drag it, as with a crate's frame. Looking at a piece, the readout says
  which take will do: "this piece comes off" or "drags the whole deck". The first piece
  joined comes off like any other: the piece beside it takes over the deck's body, so
  nothing else on the deck moves.
- **Floating.** A deck has no battery, so it floats on what stands on it. It floats once
  its trays together lift its weight, wherever they're fitted, and hangs by where they
  are (Trays lift, below): a deck three pieces by three on four trays at its corners,
  with a crate in its middle, floats level with its middle about 1.0 m up, and a few
  centimetres lower with 130 kg more on it; with its trays bunched along one edge it tips
  its far edge onto the sand, about 25°. Floating, its trays draw for what they hold up,
  so at rest a deck draws for all it floats, pieces, trays and what stands on it, 2 W a
  kilogram as a crate's tray does, and tipped onto the sand it draws less. Use on any
  piece, or on a crate or condenser standing on it, sets the whole deck floating or
  resting; use at a shield on it still switches the shield.
- **The deck mount** takes a crate frame, a condenser, either shield or a charger. A
  shield goes on from your hands as onto a top mount. The others are too heavy to carry:
  take hold of one beside a deck and the nearest free deck mount within 1.2 m of where it
  would stand is offered, with its ghost, and take stands it there instead of letting go.
  Take at it again lifts it off into your hold, and that deck offers nothing until it's
  clear. Standing on a deck, a device keeps its own sockets: batteries, top mounts, rings
  and a port all fit and come out by hand, a line on its hook pulls the deck, and a
  shield seated on a crate's top mount there still comes off whole. Having hold of one
  with its own tray in, no deck mount is offered and the readout says "take its tray off
  first"; standing on a deck, it takes no tray. One an older save left standing there
  with a tray still lifts off clear of the deck, never wedged in it. Everything on a deck
  is one power pool, and the deck's wind catch counts what stands on it.
- **Saves** keep a deck's pieces each after one it sits beside, as they joined or as
  they stand once pieces have come off, each with its place on the first piece's grid,
  its turn and all that's in it; older saves load as before.
- **Trays lift where they are** (2026-10-17). Each tray reads the sand under its face,
  on average, and pushes straight up at the face's four corners, each harder the nearer
  it is to that sand, like a cushion: all it lifts, 80 kg, with its face 0.84 m up or
  nearer, and higher up a share that falls by e every 6 cm. Nearer still, its push no
  longer grows but gathers at its lowest corners, so it still rights what it holds.
  Every load bobs at the same rate, about twice a second, and settles in about half a
  second. A light load rides a few centimetres higher than a heavy one: the kit's crate,
  46 kg, with its middle 1.20 m up, a crate with only a tray and a battery at 1.24 m, a
  deck three by three on four trays 1.03 m up with a crate on it and 0.99 m with 130 kg
  more; over its lift a tray sinks to the sand. Only where the trays are keeps a device
  upright: a crate's tray holds it level while its load sits over the tray, and an
  off-centre load leans it: a big battery in its back slot about 5°, the kit's crate
  4.5° toward the board on its rack, the planter 3.5° toward its battery. One tray
  rights its device toward level even over a dune's face, so a crate towed 2 km over the
  dunes stays within 3° of level; a deck's trays, far apart, follow the dunes under them.
  A tray pushes only while it faces the sand, so a device on its side stays there until
  you right it. Set resting, a tray's all-lifting height sinks just under the sand, so
  its device is down before the tray stops, still about 0.6 m/s at most. Its trays draw
  for what they hold up (Power). The same goes for every device on trays; the board has
  its own hover.
- **The "chassis" scenario** lays four bare pieces in a row in front of you with a tray
  before each, a crate frame with two charged batteries and a condenser with a battery
  and an empty canister, clear and calm, to build a deck from.

## The Console (proposed, not built)

*Hunter, 2026-10-17 ([session](../console-sensors-sleep-2026-10-17.md)), a voice session. Its own
framing: "Treat them as direction, not a final spec: the Console's slot layout is explicitly due
for a rework." So this is direction. Nothing here is built and no number is set. Where it clashes
with what is built, the clash is in the open questions below.*

A new device, **the Console**: "the camp's computer. It handles computation and moves data between
devices." It carries the weather instruments and the screen that shows what they read ([Wind &
storms](wind-and-storms.md#instruments-and-the-console-screen-proposed)), and it is what makes a
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

Against the crate, from what the session gives:

| Socket | Crate frame, as built | Console, from the session |
|---|---|---|
| Battery slot | 2 | "Don't remove battery slots" |
| Ring mount | 4 in `catalog.gd` (2 in the table below) | "Only one or two rope hooks" |
| Bottom mount | 1 | A hover tray, like a crate |
| Top mount | 2 | 1 regular |
| Computer-mod top | none | 1 |
| Computer-mod port | none | "Plenty" |
| Screen port | none | One side, the full face |
| Port, rack | 1 each | Not said |

**The layout is due for a rework,** so this table is a starting point, not a spec. One rule from
the session carries over whatever the layout becomes: "Sockets save by list index, so add new ones
at the end of any existing frame." The crate's rack and the planter's water socket are already
last in their lists for that reason.

**Smart devices.** A device seated on a Console, a shield first, reports its data to the screen
and can be controlled from it. What it can do depends on the Console's gear. [The smart
shield](bubble-shield-and-camp.md#the-smart-shield-proposed-not-built) has the detail. As a reading, not in
the session: any device that seats on a top mount could be smart the same way, since a seated
device already stays a body of its own on the host's power pool.

**Ending-linked Console pieces (endings session; proposed, not built).** The endings give the
Console two late uses ([the vision](../vision.md#landmarks-and-endings)):
- **A Walker taken whole (Agreed).** "Take the whole Walker onto a chassis: works as a Console
  with full weather sensing built in (like two fully modded weather Consoles), leaving its slots
  free for other mods. Important late game." A deck is one data system (above), so the Walker
  reads as a Console on the deck chassis, and it lines up with "roughly two linked Consoles" for
  a storm mini-map ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed)).
  Not said: what frame a legged robot is, or whether it stands on a deck mount, which takes one
  device the size of a crate.
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
down, not up), likely a different camp setup" ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed)).
The newest session wins, so a basic survey mod is a Console mod, and the heavier detection (the
Archaeologist's ground-penetrating radar) is read as staying separate; the session does not say.

## The patrol board as a superchassis (proposed, not built)

*Session 4, part 3 ([lore session](../lore-session-2026-10-17-part-3.md)). Direction, not a spec:
no number is set and none of it is built.* The Daventry patrol board's build note asks for "mount
points for a shield, battery, radio, condenser, bedroll and tow, as a chassis rather than
special-cased slots," and says this "also generalises the existing board."
[Movement](movement.md#the-patrol-board-a-superchassis-agreed-session-4-part-3-not-built) has the
board's side: the kit, its weakness of few slots, and the clash with "It tows nothing."

Against what is built, as readings and not in the session:
- **It is a rule this PRD already has.** A device's abilities come from its parts (rule 4), and a
  frame is a list of sockets. The built board is a frame with one battery slot and one port, and it
  fits a crate's rack (the frames table). A superchassis is a frame with more sockets of the same
  kinds, and "a chassis rather than special-cased slots" is the existing no-one-off-exceptions line.
- **Most of its gear has a socket kind already.** A battery goes in a battery slot, a radio on a
  top mount, a shield on a top mount or a deck mount, and a condenser on a deck mount (a crate-sized
  one stands on one now; a "tiny condenser" is a smaller one, which the session doesn't describe).
  A tow is a ring mount with a hook, which already ties rope, so it needs no new kind. A bedroll
  shares the crate's rack in the sleep proposal ([Survival](survival.md#sleep-proposed)), so it
  wants a rack-like mount here, the one thing the socket table doesn't have.
- **Few slots is a count, not a kind.** The rack, the deck mounts and the rest are sized for a
  crate or a 1 m piece. A 1.3 m board carrying a shield, a battery, a radio, a condenser and a
  bedroll is a question of size the session doesn't answer.
- **Sockets save by list index,** so any new socket goes at the end of the frame's list, the
  Console session's rule.
- **A new frame beside the board, or the board's frame with more sockets,** is the session's
  "generalises" and is not said. Either way the kit's board, racked on a crate, is unchanged.

## What Sand Game taught us

- **Snapping happened on contact.** Anything that bumped a sticky area got stuck, even
  by accident.
- **The snapped object froze wherever it touched,** not at a defined spot.
- **A frozen body parked under another body isn't part of it.** Its weight and shape
  never joined the parent.
- **Matching was done by name.** A crop was recognised by "carrot" appearing in its
  node name, and ropes found their ends by searching the whole scene for "rope".

## Rules

1. **Snapping needs intent.** Only a part you're holding snaps, only into a free
   socket of its type, and only when you take it home: the tug leans it in and shows the
   spot, and take seats it (Hunter, 2026-10-15: "add a little more player agency").
   Nothing snaps by being bumped, or by drifting close.
2. **Sockets are defined spots,** with a position and a facing. A fitted part sits
   exactly there.
3. **A fitted part is part of the device.** Its collision and weight merge into the
   device's body. There are never joints between a device and its parts.
4. **A device's abilities come from its parts.** Capacity, lift, hooks, protection,
   wind catch and weight are all computed from what's fitted. Change the parts and the
   device changes.
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

**As built in the skeleton (2026-10-14):**
- **The tug follows your aim, not the part's position.** A part held at arm's length
  can never get within 30 cm of a socket on a crate sitting on the sand. So a free
  socket tugs when your line of sight passes within reach of where the part would sit,
  and you're on its open side.
- **No crouching to fit** (Hunter, 2026-10-16: "im also having to crouch for a lot of
  mods, like the hover tray and hooks"). Looking at a device with a part in hand, or
  within 40 cm of its frame, offers the free socket that part fits, standing: the only
  one of its kind wherever on the device you look, or of several the one nearest where
  you aim among those facing you. Aiming right at a free socket's spot, on any device,
  still wins. An offered socket leans the part partway in with the hum, the
  ghost shows where it goes, and take seats it; nothing fits until you take. On the
  device's far side, the ghost doesn't show through it (2026-10-17); a tray's under it
  still does. A device seated on another counts as part of it, so looking at the shield
  on a crate offers the crate's sockets, and a held shield is offered a top mount the
  same way. Just after a part comes out, its device offers nothing until you look off
  it, so take puts the part down rather than straight back in. Taking out: with empty
  hands, the part you look straight at comes out. A tray, out of sight under its device
  when you stand, comes out as easily (2026-10-17): a look at the frame's lower edge, or
  just under it, within 15 cm of the tray, is a look at the tray, and use there still
  sets it floating or resting; the rest of the frame still takes hold of the device. On
  the frame itself that's only its lowest 15 cm, and never more than its lower half
  (Hunter, 2026-10-17: "its hard to select a chassis, it almost always selects its hover
  tray"), so a chassis piece, 12 cm thick, is the piece by its top and the upper half of
  its edges, and its tray by a look at its lowest 6 cm or just under it. With a
  part in hand, take near a device with a free socket of its kind fits it there, so to
  set a part down, look at the sand clear of the device.
- **Sliding a tray under a resting device** works from a standing look at it, from any
  side, and lifts the device onto it.
- **The device doesn't turn toward you on removal yet;** it holds still while the part
  slides out.
- **A hook adds a socket** (2026-10-15): a tie socket on its ring while it's fitted,
  where a line's end snaps on. Taking the hook out takes the line's end off first.
- **A small device can fit a socket** (2026-10-16, Hunter: "can we make the shield
  snappable to the crate like lights are? so we can mount and charge it and drag it
  around?"). The shield generator fits a top mount the way a lamp does: the tug leans it
  in, upright, and take seats it. Seated, it stays a body of its own, held fast on the
  device and touching nothing of it, so it carries on working as itself and the camp
  stays fully simulated: it rides with the device, adds its weight, shares the device's
  power pool through Power's own pooling, and use still switches it. It's the lamp's
  top mount, tug and take; any device with a socket kind to fit would seat the same way.
  Take lifts it straight off, whole, whatever of it you aim at. Its own sockets wait
  until it's off again.
- **The crate frame has more sockets** (2026-10-16, Hunter: "i feel like the crate
  should have more slots"): a battery slot front and back, a ring mount on every side,
  a bottom mount, two top mounts side by side and a port. The solar panel is 0.8 × 0.4 m
  now, half the crate's top, so a panel rides beside a lamp, a shield or a second panel.
  Fitted out with two big batteries, four hooks, a tray, a panel and a shield, a crate
  weighs 56 kg, under a tray's 80 kg of lift, and floating draws 112 W.
- **The crate frame has a rack** (2026-10-16, Hunter: "i like a rack"), along the top of
  its left side, where the hoverboard seats as the shield does on a top mount: the tug
  leans it in and take seats it, it stays a body of its own held fast on its seat, and
  take lifts it off whole. The board is longer than the crate, so it overhangs 25 cm at
  each end, and it stands 17 cm proud of the top so its lower edge clears the ring mount
  on that side, 2 cm over the hook. On a crate with every socket filled, a big battery in
  each slot, a hook and a line's end on every ring, the tray, the light shield and light
  panel on top and a plug in the port, it clears everything by 1 cm at least, nearest
  the crate's own side (survival probe 9 checks it by their bounds). The charge light
  stays on the right side, where the board doesn't cover it. Racked, the kit's crate
  weighs 45.5 kg and floating draws 91 W.
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
  and you put it down the way it now faces. Something you have hold of is turned as
  hard as your strength allows: a crate or planter on its side rolls back upright and
  stands within a degree of level once let go, a 40 kg crate still rolls, and a 100 kg
  one doesn't. A thing lying with its top to one side takes a turn across, then one
  up. Nothing rights itself, beyond a running tray holding its device up while it
  faces the sand.
- **Take-hold keeps its tilt and follows your look up and down** (2026-10-16). What you
  have hold of keeps the tilt it had when you took it, not only its heading, and its
  turning is held firm each tick, since on the sand it turns against friction and tips
  about an edge, lifting its own weight. It rises and sinks as you look, at the reach
  you took it at, but never higher than a little above your eyes. Your hands only lift
  and never press down, so its own weight lets it down, and dragging is no harder for
  looking at your feet. Looking up 30° lifts a bare 15 kg crate 0.76 m, about 20 cm
  short of where you look, since nothing holds its whole weight up. A 60 kg one, more
  than your strength lifts, stays on the sand.

## Where parts come from, and how they wear

- **Parts are found, never crafted,** at least for now. Salvage is the only source,
  which makes every find matter.
- **Parts wear out only from the elements:** wind, storm and temperature, through the
  felt weather. Use never wears them. A part sheltered from a harm doesn't wear from
  it, so the shield protects your parts as well as you.

## Frames by era

*Hunter, 2026-10-17 ([notes](../session-notes-2026-10-17.md)); loose, and none of it built.
Today there is one crate frame.* Era gear has trade-offs, not a ladder
([Salvage & ruins](salvage-and-ruins.md#gear-and-ruins-by-era) has the eras and the ruins).
The notes' example is the crate:

| Era | Crate |
|---|---|
| **Colonial** | Best power efficiency per kilogram |
| **Skimmer era** | Light, cheap and fragile, because Zan wasn't a desert yet and gear wasn't built for storms |
| **First age** | Practical to drag without a hover tray, still mountable, somewhat worse power efficiency per kilogram |

Where this meets what's built, as a reading and not in the notes. A tray floats everything on
it at about 2 W per kilogram (91 W for the kit's 45.5 kg, 112 W for a fully fitted 56 kg), and a
device has one durability. So "power efficiency per kilogram" reads as that draw, and "fragile"
as the durability. A frame's numbers are its own stats, as the light shield's are (Bubble
shield & camp), so an era's crate is data, not new rules. "Still mountable" reads as the
bottom mount keeping its tray socket. "Practical to drag without a hover tray" reads as a
frame that drags easier on the sand than the others, which nothing here sets per frame yet.

The notes name the third row for the societies after the collapse. Session 4, part 2 ties
reworked, low-power gear to the first age (then called the First Kingdoms: "every repair
cannibalises something else"), so the row is theirs. What a second-age crate is like is not said,
and the session's maker table below is the nearest it comes (the Sisters' hand-built crates).

Found mods ride along. First-age finds can carry mods such as tuning for low-power setups,
and a mod fits a mount and adds to the device, as the extra-hook mod does (below). Today only the
planter has a mod mount.

## Crate makers (Agreed direction, session 4, part 4; not built)

*[Session 4, part 4](../plants-worldgen-ruins-2026-10-17.md), "Agreed direction." Nothing is built, and
today there is one crate frame.* "Multiple manufacturers make crates with different slot mixes. A
crate's maker tells you its era and its job; the slot mix is the variety axis." This sits beside
frames by era above: the era sets a frame's trade-offs, and the maker sets what it is for.

| Maker | Era | Character |
|---|---|---|
| Tilg & Standard | Colonial | Standard logistics all-rounder, most common |
| Halloran Isotope | Colonial / skimmer | Industrial, rugged, heat-tolerant, few planter slots |
| Frontier Ag | Colonial | Purpose-built grow crates with deep beds and integrated misters; rare and fragile |
| First / second age (hand-built) | First, second | Crude, heavy, odd slot layouts; the Sisters' versions built for water storage |

Readings, not in the session:
- **A maker's crate is a frame, and a frame is data.** A frame is a list of sockets (rule 4), so a
  slot mix is a list. Another maker is another entry in the catalog, as an era's crate is. Sockets
  save by list index, which only matters for the frames that exist: a new maker's frame is new, and
  the rule is that nothing is inserted into an old one.
- **A maker spans eras, and an era spans makers.** Halloran's "rugged" crate is colonial and skimmer,
  where the skimmer era's own crate is "light, cheap and fragile" (frames by era). Read as a
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

## Socket types to start

| Socket | Takes | Owned by |
|---|---|---|
| Battery slot | Batteries | Power |
| Ring mount | Rope hooks; on a chassis piece, another piece's edge | Rope & tethering |
| Bottom mount | Hover trays | Bubble shield & camp |
| Top mount | Solar panels, instruments such as the radio, lamps, the shield generator | Power and others |
| Rack | The hoverboard, seated along a crate's side, riding and charging with it (Hunter, 2026-10-16) | Movement |
| Plant slot (small, large) | Seedlings | Farming |
| Plant slot (small pot, standard planter, deep bed) | Crops by the size they declare. Proposed (session 4, part 4); new kinds are appended to a frame, never inserted | Farming |
| Water socket | A canister or a hose's end, one at a time (2026-10-17) | Survival, Farming |
| Deck mount | One device standing on a chassis piece: a crate, a condenser, a shield, a charger (2026-10-17) | Devices & mods |
| Computer-mod port | Computer mods, on a Console. Proposed (2026-10-17); a kind of its own, unless it is the planter's mod mount (open questions) | Devices & mods |
| Computer-mod top | Antennas, radar and the like, on a Console's top. Proposed (2026-10-17) | Devices & mods, Wind & storms |
| Screen port | A full-face screen, one side of a Console. Proposed (2026-10-17) | Devices & mods |

**As built, what each frame has** (2026-10-16; the chassis 2026-10-17):

| Frame | Battery | Ring | Bottom | Top | Port | Other |
|---|---|---|---|---|---|---|
| Crate frame | 2 | 2 | 1 | 2 | 1 | a rack; stands on a deck mount; rings front and back only (Hunter, 2026-10-17: "shave 2 hook slots off the crate now that we have the chassis") |
| Planter | 1 | 2 | 1 | | 1 | 3 small and 1 large plant slot, a mod mount, a water socket (2026-10-17) |
| Charger | 1 | | | 1 | 1 | stands on a deck mount |
| Wind turbine | 1 | | | | 1 | |
| Condenser | 1 | 1 | 1 | 1 | 1 | a water socket; stands on a deck mount |
| Shield generator | 1 | 1 | 1 | | 1 | fits a top mount or a deck mount itself |
| Light shield generator | 1 | 1 | 1 | | 1 | fits a top mount or a deck mount itself |
| Chassis piece | | 4 | 1 | | | a deck mount; its rings join other pieces |
| Light solar panel | | | | | 1 | |
| Hoverboard | 1 | | | | 1 | fits a rack itself |
| Radio | 1 | | | | 1 | fits a top mount itself |
| Survival kit | | | | | | a water and a food socket, 2 small and 1 large plant slot |

**Carried, a device works as anywhere else** (Hunter, 2026-10-17): a carryable device goes
in with what the suit carries whole and works on its own battery, riding on you (Survival).
There's no flag for it: no device is an exception.

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
- A look-at readout of stats.
- Loose stacking left to physics.
- The probes below, all passing.

## Full version

- **The feel, polished:** the ghost, the hum, the clunk and the easing of the turn.
- **Parts that add sockets,** like the extra-hook mod.
- **Part tiers and upgrades.** Session 4 adds a second axis, the frame's era (Frames by era).
- **More part types,** as the other PRDs need them.
- **Per-part wear from the elements.** In the skeleton, wear is a single durability on
  the whole device (Bubble shield & camp).
- **The Console and its computer mods** (proposed, 2026-10-17; see above), with the smart
  devices they make.

## Probes

1. **No accidental snaps.** Drop, throw and drag parts against devices thousands of
   times. Nothing snaps unless it's held and aimed. Standing by a crate on the sand,
   looking at it offers a held tray its bottom mount, a hook the ring on your side or,
   of two facing you, the one nearer your aim, and a shield the nearer top mount; each
   waits for take. A fitted part still comes out to an empty hand.
2. **Fitted is rigid.** A fully fitted device gets thrown around, towed through gusts
   and floated. Its parts never move relative to it.
3. **Weight adds up.** A device's weight is its frame plus its parts, and its hover draw
   follows.
4. **The snap lands exactly.** A fitted part sits precisely at its socket.
5. **Out the way it went in.** Remove every part from every angle. No part ever passes
   through its device on the way out.
6. **Loose stacks are stable.** A stack of loose objects on a floating device in still
   air for ten minutes shows no jitter, no creeping and no explosions. Outside the
   shield, a gust knocks them off cleanly.
7. **Origin shifts are invisible.** Fitted parts and loose stacks come through a shift
   untouched.
8. **Nothing falls through.** No device or part ever ends up under the sand.
9. **Arranging by hand.** Walking into a floating device pushes it no faster than you
   walk. Taking hold of one, it follows as you back away and swings round as you turn,
   and let go it stops rather than flies. One too heavy to drag barely moves and slips
   from your hands.
10. **Small things come easy.** Aim at the sand beside a small loose thing and it's the
    one you'd take; between two, a wavering aim settles on one. Nothing is taken through
    something in the way.
11. **Keys come from the bindings.** Rebind an action and every key shown for it
    follows, a mouse button too, and the new key works.
12. **Turned by hand.** Holding rotate, the mouse turns what you hold and not your view;
    let go, it looks again. A crate and a planter on their sides, taken hold of, roll
    back upright and stand once let go. A shield lying on its side is turned in your
    hands and set down standing. Having hold of a crate, looking up lifts it, unless
    it's too heavy for your strength.
13. **Use rests a tray.** Use at the kit crate's frame sets it resting: it settles
    gently on the sand and its tray draws nothing, while use at the shield seated on it
    switches the shield and leaves the tray be. Use again and it floats, drawing as
    before. Saved resting, it resumes resting.
14. **Trays come out standing.** Standing by a floating crate, a look at its frame's lower
    edge or just under it is a look at its tray: use there still sets the crate resting,
    and take takes the tray out. A look at the frame's middle still takes hold of it. A
    standing look at a chassis piece's top or edge is the piece, not its tray.
15. **The ghost in sight.** A socket offered on a crate's far side shows no ghost through
    the crate; walk round and it does, and a tray's shows under it.
16. **One rigid deck.** Five pieces joined by hand into a long L sit flush on the grid,
    square to each other; a ring with a crate standing beyond it isn't offered. Floating
    with trays and a crate in a gusting storm for two minutes, moored by one line at its
    far end as a tow would hold it, its pieces never move against each other, and it
    stays level, with no jitter and nothing flung.
17. **Trays lift where they are** (replacing "every piece needs its tray"). A deck three
    pieces by three with a crate in its middle floats level on four trays at its corners.
    Loaded heavier it rides lower, still level; too heavy for four, it rests drawing
    nothing, and a tray under every piece floats it again, drawing for all it holds up.
    Use sets the whole deck resting and floating. Light again, its trays bunched along one
    edge, it tips its far edge onto the sand and draws for less than its weight.
18. **A crate on a deck.** Having hold of a crate beside a deck with its own tray in, no
    deck mount is offered and the readout says to take the tray off first; tray out, its
    nearer deck mount is offered and take stands it there. It takes a battery into its own
    slot by hand, a light shield goes onto the other piece, and the deck floats on the
    crate's batteries while the shield runs on them, one pool. Take has the crate off into
    your hold, clear of the deck, even with a tray an older save left in it.
19. **Any outer piece comes off** (replacing "last joined, first off"). Three pieces in a
    row: aimed at the middle one, the readout says take drags the whole deck, and it does,
    nothing coming off. Aimed at the first piece joined, the readout says it comes off,
    and take has it off into your hands with its hook, never through the deck; aimed at
    the last, it comes off with the crate standing on it, into your hold.
20. **A load off centre leans.** A crate on its one tray with a panel on each top mount
    floats level; one with a big battery in its back slot leans toward it and floats on,
    still, nowhere near tipping.

## Out of scope

- Crafting, for now. Parts come from Salvage & ruins.

## Open questions

- **Can pieces from different eras join freely in the chassis, or do they need adapters?**
  Open in the notes (Hunter, 2026-10-17). Here: "Pieces join edge to edge by their rings," "A
  piece... is a find," and "Trays lift where they are" (which replaced "every piece needs its
  own hover tray" the same day). Not said: whether a piece's era matters to the join at all,
  and what a first-age piece, "practical to drag without a hover tray," does in a deck
  that floats on its trays' combined lift. If adapters exist, the rules here
  would make one a typed part that is found, not crafted (rule 6, and out of scope below).
  Session 4, part 2 lists the question again among its own open ones, still unanswered. It also
  shows why it matters: the moving nomad city is "a huge tethered raft of salvaged chassis,
  shields and turbines," pieces of many eras lashed together.
- **Efficiency of what.** "Best power efficiency per kilogram" could mean the hover draw per
  kilogram floated, or something else of the frame's. The notes give no numbers for any era.
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
  "plenty" of mod ports go once the screen has a whole side.
- **Which computer mods, and which slot kinds.** Open in the session. Here: "Parts are typed"
  (rule 6), and the planter's mod mount, one kind, takes the harvester. The session: computer
  mods in "plenty of mod ports," and "antenna, radar and the like" in a computer-mod top. Not
  said: whether a computer mod fits that same mod kind (then a harvester would fit a Console and
  a radar a planter) or a kind of its own. The socket types above take the second reading, as
  a proposal. Also not said: whether the Console's antenna is the radio's
  "antenna mods" ([Radio, sound & atmosphere](radio-sound-and-atmosphere.md)) or a different part.
- **One regular top slot, three wants.** Here: a top mount takes "solar panels, instruments such
  as the radio, lamps, the shield generator," and the kit's crate fills both of its top mounts,
  with a light shield and a light panel. The session: a Console has one regular top slot, a
  shield on it "becomes 'smart'," and audio "comes from a radio on a top mount." The shield and
  the radio can't both have the one slot. Not said: whether the radio goes on the computer-mod
  top, the shield stands on a neighbouring deck piece (then it isn't "on" the Console), or a
  Console keeps two regular tops.
- **What a link reaches.** Here: everything on one deck shares one power pool, and cabled devices
  share one. The session: "a chassis connects every Console mounted on it into one system." Not
  said: whether a Console off a chassis links to anything (a cable?), whether the link takes in
  the other devices on the deck or only other Consoles, and whether a Console stands on a deck
  mount at all. The deck mount takes "a crate, a condenser, a shield, a charger," and a Console is
  "a crate variant," which reads as yes, but is a reading.
- **The name.** `Console` is taken. It is already a class (`game/dev/console.gd`), an action
  (`console`) and the Menus & UI PRD's "dev console," and this PRD's chassis section says "the
  console's give makes one by its id." Not said: whether the device keeps Hunter's name and the
  dev tool's words change, or the other way round. Until it is settled the docs say "the dev
  console" for the tool and "the Console" for the device.
- **Running a screen with four actions.** Here: "Four actions cover handling... A new device or
  tool answers these; it never adds an action of its own." The session: a shield "can be
  controlled from the screen." Menus & UI says state shows on things first, and the vision that
  most menus come as devices, so the screen is that. Not said: how a screen is operated. Use at a
  spot on it, or a look, are the candidates, and the aim has to pick one control among many on a
  full face.
- **The ring shave against "add new ones at the end."** Here: the frames table says the crate has
  two rings, "front and back only" (Hunter, 2026-10-17: "shave 2 hook slots off the crate now
  that we have the chassis"), and `catalog.gd` still lists four, the side two at entries 1 and 2
  of the list. The session: "Sockets save by list index." Taking out entries 1 and 2 moves every
  socket after them, so older saves would load the wrong sockets. Not said: how the shave keeps
  saves, by leaving the entries unused or by a migration. A Console cut from the crate's list,
  with "only one or two rope hooks," meets the same thing.

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
  with the makers: a Halloran piece and a hand-built first-age piece in one deck. Still unanswered.
