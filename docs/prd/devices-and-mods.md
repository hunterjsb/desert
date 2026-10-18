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
sounds, never silence. **Built** (2026-10-17): every refusal goes through one place in the
hands, and the "no" is a dull knock cut from a Sand Game clank. Holding a part at a device
whose sockets of its kind are all full, take keeps it in your hands and says "no free
battery slot" (or top mount, ring, port and so on), where before it was dropped; at a
device with no socket of its kind, take still puts it down. A tray held to a device on a
deck says it takes none there. A piece held to a deck whose free rings are all blocked
says "no room at that ring". Having hold of a crate with its tray in beside a deck, take
lets it go saying "take its tray off first". Use at a device with nothing to work says
"nothing to use", a stake used off the sand says why as before, and something you can't
shift says "it won't shift" as it slips from your hands. Take or use at nothing stays
silent.
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
  in eleven deep (one in ten before the Console), buried on its edge like a sheet the dunes
  half took, and the dev console's give makes one by its id, `chassis`.
- **Joining.** With a piece in your hands, a deck's free edge ring is offered the same
  way a socket is: the tug leans the piece flush beyond the ring, turned the quarter turn
  nearest how you hold it, the ghost shows it, and take joins it. Its frame, its sockets
  and whatever is in them move into the first piece's body, as a fitted part's shapes
  do, so a deck is one rigid body, never pieces on joints. A ring between two pieces
  closes and takes nothing. A ring isn't offered where something stands beyond it (a
  piece joined over a crate would throw it) or for a wrecked piece. A hook in the way pops
  off instead (Hunter, 2026-10-17: "hooks should pop off when its obstructing a chassis
  snap"): a hook on a neighbouring edge, or on either ring that closes, where the new piece
  goes comes loose onto the sand as the piece snaps in, with any line on it still tied,
  where before the ring wasn't offered. A piece with something standing on it
  is too heavy to carry, so it joins from your hold: having hold of it, the free ring of a
  deck whose place beside it is within 1.2 m of the piece is offered, with its ghost, if
  the piece and all on it would sit clear there, and take joins it, turned the quarter
  turn nearest how it lies. Only a lone piece joins: two whole decks don't merge yet.
  Joined on a slope, a deck lifts clear
  of the sand as a crate does onto a tray. Your hands reach a deck by its nearest piece,
  so a long deck's far end is as easy to work as its first. A deck wears as one device,
  as worn as its most worn piece when they joined.
- **Taking a deck apart** (2026-10-17, after Hunter's playtest). Take aimed at a deck
  takes hold of the whole of it, to drag it, as with a crate's frame, unless the piece
  you aim at is bare (no tray, no hook, nothing standing on it) and the rest of the deck
  holds together without it: then it comes off, out across a ring it leaves and into
  your hands. Strip a piece first, taking out its tray and hooks and lifting off what
  stands on it, as a crate's tray comes off before it stands on a deck. Looking at a
  piece, the readout says which take will do: "this piece comes off" or "drags the whole
  deck", with "bare, this piece comes off" after it at an outer piece that isn't. The
  first piece joined comes off like any other: the piece beside it takes over the deck's
  body, so nothing else on the deck moves.
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
  and an empty canister, clear and calm, to build a deck from. The "afk" scenario's
  reference camp stands on a deck two by two (Power); it floats about 1.5° down toward its
  two crates, and in a 20 m/s storm with gusts and its bubble down it stays within 2.2°
  of level, moored.

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
shield](bubble-shield-and-camp.md#the-smart-shield-proposed-first-version-built) has the detail. As a reading, not in
the session: any device that seats on a top mount could be smart the same way, since a seated
device already stays a body of its own on the host's power pool.

**As built (2026-10-17, a first version):**
- **The name.** The device is the Console. The dev tool's class is `DevConsole` now
  (`game/dev/dev_console.gd`); its action is still the console action, its commands are
  unchanged, and the docs still call it the dev console.
- **The frame** is a crate's size, 0.8 by 0.5 by 0.8 m, and 12 kg. It's painted like the crate:
  gunmetal posts and rails, black corner caps, teal panels. Its front is wholly the screen port,
  framed in a black bezel with a hazard strip along its foot, and nothing else is on that face,
  so a screen there can't clip anything. Its back takes both battery slots, both rings (its only
  two) and the port. Each side has three computer-mod ports, with vents above them on the right
  and the fitter's tag on the left. Its top has one regular top mount over the back half and one
  computer-mod top over the front half. It has a bottom mount for a tray and stands on a deck
  mount like a crate. It has no rack.
- **What it draws.** 4 W itself, the screen 3 W more, and each instrument its own: the radar
  6 W, the particle sensor 1.5 W, the anemometer 0.5 W, the hygrometer 0.3 W and the barometer
  0.2 W. With the full set that's about 16 W, from its batteries or its deck's pool. Running
  short, it gives way before a shield, as a crate's tray does. Dark, its screen goes black and
  its instruments stop reading.
- **Where it comes from.** It's a find in the deep layer only, at the same weight as the chassis
  piece. A found one carries what the deep layer fills a screen port, computer-mod ports and a
  computer-mod top with: a screen, instruments and a radar. The screen and the instruments come
  only in found Consoles for now; none lies loose. The heaviest Console that can be found, 50.7
  kg, is under the heaviest crate, so any find still drags by hand. The dev console's give makes
  one by its id, `console`, and its parts by theirs: `screen`, `anemometer`, `barometer`,
  `hygrometer`, `particle_sensor` and `radar`.
- **The screen** is a part that fits the screen port. It shows, live, every reading the
  instruments in the Console's system give ([Wind &
  storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built) has
  each instrument). It's a terminal in the game's theme: short monospaced rows, the label in the
  accent and the values in white, anything urgent in a storm's amber. It has three pages:
  - **Weather:** every reading, the smart shield in one line, and the last three lines logged.
    With the full set it adds a storm map at the right.
  - **Shield:** a form for each smart shield, shown only when there is one.
  - **Log:** the last fourteen lines logged.
- **The radar first** (Hunter, 2026-10-18, after playing it: "the console is kind of
  information overload... we shouldnt directly drop any of it... i love the map"). Nothing is
  dropped; it's rearranged so the map leads, and readable from where you stand:
  - **Pages:** the weather radar map first, the whole screen; then stats, every reading in
    detail; then the log.
  - **The map loses resolution, not itself,** as instruments come off: the more gear, the finer
    it is; with less, it coarsens.
  - **On the map:** the wind as a gyro vector in its legend (in detail on the stats page);
    pressure as a bar (in detail on stats); humidity laid over the map itself, varying, when a
    hygrometer gives it; the front's numbers written on the map where the front is; the
    forecast as a line along the map's foot.
- **Working the screen** takes only use. Along its foot are its keys: page, and with a smart
  shield, shield and auto. Each says how it stands ("SHIELD: OFF", "AUTO: ON") and lights up as
  you aim at it, and use there presses it. Use anywhere else on the screen steps to the next page.
  Use at the frame sets its tray floating or resting, as at a crate. Dark, use on the screen says
  "no power". Take aimed at the screen takes it out, like any part.
- **Its draw cost is small.** The screen is a small canvas of its own, 768 by 448. It's drawn only
  when what it shows has changed, checked at most four times a second of world time, and only
  while someone stands within 15 m. Otherwise its last picture stays up.
- **Linking.** Every Console on one chassis deck is one system: the deck and everything standing
  or seated on it. Their instruments pool, so each screen shows every reading in the system,
  each taken from the first Console that has it. A Console off a deck is a system of its own,
  with whatever is seated on it. Nothing links by cable yet. The first running Console speaks
  for the system: it logs the storm and runs the smart shield, and every screen in the system
  shows the logs merged by time.
- **Its messages** go out through [the terminal output
  system](#the-terminal-output-system-proposed-session-4-part-5-first-piece-built), and a radio
  seated anywhere in the system sounds its tones as a line prints: that's the Console's audio.
- **Saves** keep its page, its auto switch and its log, and its parts and anything seated on it
  as any device's. Older saves load as before.
- **The "console" scenario** stands a Console on a deck of two pieces resting on the sand,
  moored to a stake upwind. The Console holds two big batteries, its screen, the four side
  instruments, the radar and a radio on its top, with its screen facing you. The base shield
  stands on the other piece with a battery, switched off. A storm is due in four to six
  minutes, so the radar sees the front coming, the shield switches itself on, and the storm
  arrives while you watch.
- **Still proposed:** the final layout, any part on the computer-mod top besides the radar (an
  antenna), the survey mod, god modules, other makers' Consoles, a Console linked by cable,
  and devices other than shields made smart.

**Ending-linked Console pieces (endings session; proposed, not built).** The endings give the
Console two late uses ([the vision](../vision.md#landmarks-and-endings)):
- **A Walker taken whole (Agreed).** "Take the whole Walker onto a chassis: works as a Console
  with full weather sensing built in (like two fully modded weather Consoles), leaving its slots
  free for other mods. Important late game." A deck is one data system (above), so the Walker
  reads as a Console on the deck chassis, and it lines up with "roughly two linked Consoles" for
  a storm mini-map ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
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
down, not up), likely a different camp setup" ([Wind & storms](wind-and-storms.md#instruments-and-the-console-screen-proposed-first-version-built)).
The newest session wins, so a basic survey mod is a Console mod, and the heavier detection (the
Archaeologist's ground-penetrating radar) is read as staying separate; the session does not say.

**Gods on the Console (session 4, part 5; proposed, not built).** A mounted god's terminal output is
what a Console's full-face screen shows, and a god module is a part of the computer-mod class
([the terminal output system](#the-terminal-output-system-proposed-session-4-part-5-first-piece-built), [god
modules](#god-modules-as-crate-modules-proposed-session-4-part-5-not-built)). A Walker taken whole is
still the Console with weather sensing built in, above.

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
  rows. Its log lines are its own messages, short and in caps, the numbers in their units: "FRONT
  1.2 km N · ETA 5 min", "SHIELD AUTO-ON", "PRESSURE FALLING · STORM ~6 min", "STORM PASSED",
  "SHIELD DOWN · NO POWER", "SHIELD OFF", "RADAR ONLINE", "LINKED · 2 CONSOLES". The storm's
  arrival is a form: "IN STORM", then its sand and when it clears.
- **The voice is in the formatting.** A "!" before a line marks it urgent, and it shows in a
  storm's amber; a row indented runs on from the one before and shows dim; the label column shows
  in the accent. That marking and the wording are all the Console's personality: data, not code.
- **On the screen** a log reads as time, sender and line ("14:03 CON SHIELD AUTO-ON"), a form's
  fields indented under its title, the newest at the foot, where the proposal had it on top.
  Linked Consoles' logs show merged, by time.
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
| Computer-mod port | Computer mods, on a Console: the anemometer, barometer, hygrometer and particle sensor. Built (2026-10-17), a kind of its own, not the planter's mod mount | Devices & mods |
| Computer-mod top | Antennas, radar and the like, on a Console's top. Built (2026-10-17) with the radar; an antenna is still proposed | Devices & mods, Wind & storms |
| Screen port | A full-face screen, the whole front of a Console. Built (2026-10-17) | Devices & mods |

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
| Console | 2 | 2 | 1 | 1 | 1 | a computer-mod top, a screen port and six computer-mod ports; stands on a deck mount (2026-10-17) |
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
- **The Console and its computer mods** (proposed, 2026-10-17; a first version built, see
  above), with the smart devices they make.

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
19. **Only a bare piece comes off** (replacing "any outer piece comes off", 2026-10-17).
    Three pieces in a row, a hook on the first and a crate on the last: aimed at the
    middle, at the first and at the last, the readout says take drags the whole deck, and
    take has hold of all of it, nothing coming off. Its hook out, the first is bare: the
    readout says it comes off, and take has it off into your hands, never through the
    deck.
20. **A load off centre leans.** A crate on its one tray with a panel on each top mount
    floats level; one with a big battery in its back slot leans toward it and floats on,
    still, nowhere near tipping.
21. **A loaded piece joins from your hold.** A piece with a crate standing on it lies just
    beyond a deck's far ring. Taken hold of, that ring is offered with its ghost, and take
    joins it there, the crate standing on the deck now, in its pool.
22. **A refusal says why.** A battery held to a crate whose slots are full stays in your
    hands; a crate with its tray in, taken hold of beside a deck, is let go with word to
    take its tray off first; a piece held to a deck whose one free ring is blocked stays
    in your hands; use at a bare crate frame has nothing to work. Each time the readout
    says why and the knock sounds.
23. **An instrument shows only when it's fitted** (2026-10-17). A Console with a battery and
    a screen reads nothing. Each instrument fitted alone puts its own reading on the screen and
    no other, a radio seated on its top the forecast; taken out, its reading goes.
24. **Consoles on a deck are one system** (2026-10-17). Two Consoles on a deck, one with an
    anemometer and one with a barometer, each show both readings; a third on the sand beside
    them shows only its own and lends them nothing. Lifted off the deck, each keeps only its own.

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
  charge light stays high on the right. It has no rack.
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
