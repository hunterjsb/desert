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
  ties rope instead, so a deck is towed and moored like a crate. Take on an outer piece,
  one the rest of the deck still holds together without, takes it off with whatever
  stands on it (2026-10-17, replacing "the last joined first").
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
  in the middle of each edge, a bottom mount and a deck mount. A deck stays level, so the
  wind meets its pieces and their trays side on, and what stands on it as it would on
  the sand. It's painted like the crate: gunmetal rails round a teal plate, black corner
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
- **Taking a deck apart.** Take aimed at the last piece joined takes it off, out along
  the ring it joined at and into your hands; aimed at any other piece, you take hold of
  the whole deck to drag it, as with a crate's frame. A piece with something standing on
  it comes off with it, into your hold, since it's too heavy to carry.
- **Floating.** A deck has no battery, so it floats on what stands on it. Its trays lift
  it only while every piece has one; the readout says how many trays it's short. It's
  held 1.2 m over the sand under its highest piece, so a long deck crossing a dune never
  drags an end, and kept level by its own inertia about each axis. Floating draws for all
  it floats, 2 W a kilogram as a crate's tray does, pieces, trays and what stands on it
  together. Use on any piece, or on a crate or condenser standing on it, sets the whole
  deck floating or resting; use at a shield on it still switches the shield.
- **The deck mount** takes a crate frame, a condenser, either shield or a charger. A
  shield goes on from your hands as onto a top mount. The others are too heavy to carry:
  take hold of one beside a deck and the nearest free deck mount within 1.2 m of where it
  would stand is offered, with its ghost, and take stands it there instead of letting go.
  Take at it again lifts it off into your hold, and that deck offers nothing until it's
  clear. Standing on a deck, a device keeps its own sockets: batteries, top mounts, rings
  and a port all fit and come out by hand, a line on its hook pulls the deck, and a
  shield seated on a crate's top mount there still comes off whole. Its own tray, if it
  has one, holds nothing up there and draws nothing. Everything on a deck is one power
  pool, and the deck's wind catch counts what stands on it.
- **Saves** keep a deck's pieces in the order they joined, each with its place on the
  first piece's grid, its turn and all that's in it; older saves load as before.
- **The "chassis" scenario** lays four bare pieces in a row in front of you with a tray
  before each, a crate frame with two charged batteries and a condenser with a battery
  and an empty canister, clear and calm, to build a deck from.

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
  sets it floating or resting; the rest of the frame still takes hold of the device. With
  a part in hand, take near a device with a free socket of its kind fits it there, so to
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
  up. Nothing rights itself, beyond a running tray keeping its device level.
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
| **First Kingdoms** | Practical to drag without a hover tray, still mountable, somewhat worse power efficiency per kilogram |

Where this meets what's built, as a reading and not in the notes. A tray floats everything on
it at about 2 W per kilogram (91 W for the kit's 45.5 kg, 112 W for a fully fitted 56 kg), and a
device has one durability. So "power efficiency per kilogram" reads as that draw, and "fragile"
as the durability. A frame's numbers are its own stats, as the light shield's are (Bubble
shield & camp), so an era's crate is data, not new rules. "Still mountable" reads as the
bottom mount keeping its tray socket. "Practical to drag without a hover tray" reads as a
frame that drags easier on the sand than the others, which nothing here sets per frame yet.

The notes name the third row for the societies after the collapse. Session 4, part 2 ties
reworked, low-power gear to the First Kingdoms ("every repair cannibalises something else"), so
the row is theirs. What a Dark Age or Second Age crate is like is not said.

Found mods ride along. First Kingdoms finds can carry mods such as tuning for low-power setups,
and a mod fits a mount and adds to the device, as the extra-hook mod does (below). Today only the
planter has a mod mount.

## Socket types to start

| Socket | Takes | Owned by |
|---|---|---|
| Battery slot | Batteries | Power |
| Ring mount | Rope hooks; on a chassis piece, another piece's edge | Rope & tethering |
| Bottom mount | Hover trays | Bubble shield & camp |
| Top mount | Solar panels, instruments such as the radio, lamps, the shield generator | Power and others |
| Rack | The hoverboard, seated along a crate's side, riding and charging with it (Hunter, 2026-10-16) | Movement |
| Plant slot (small, large) | Seedlings | Farming |
| Water socket | A canister or a hose's end, one at a time (2026-10-17) | Survival, Farming |
| Deck mount | One device standing on a chassis piece: a crate, a condenser, a shield, a charger (2026-10-17) | Devices & mods |

**As built, what each frame has** (2026-10-16; the chassis 2026-10-17):

| Frame | Battery | Ring | Bottom | Top | Port | Other |
|---|---|---|---|---|---|---|
| Crate frame | 2 | 4 | 1 | 2 | 1 | a rack; stands on a deck mount |
| Planter | 1 | 2 | 1 | | 1 | 3 small and 1 large plant slot, a mod mount |
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

Some parts **add sockets of their own**. An extra-hook mod fits a mount and provides a
hook. That's how found mods expand a device.

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
    and take takes the tray out. A look at the frame's middle still takes hold of it.
15. **The ghost in sight.** A socket offered on a crate's far side shows no ghost through
    the crate; walk round and it does, and a tray's shows under it.
16. **One rigid deck.** Five pieces joined by hand into a long L sit flush on the grid,
    square to each other; a ring with a crate standing beyond it isn't offered. Floating
    with trays and a crate in a gusting storm for two minutes, moored by one line at its
    far end as a tow would hold it, its pieces never move against each other, and it
    stays level, with no jitter and nothing flung.
17. **Every piece needs its tray.** Trays under two of three pieces would lift the deck,
    and still it rests, drawing nothing; the third in, it floats, drawing for all it
    floats. Use sets the whole deck resting and floating, and a tray out lets it down.
18. **A crate on a deck.** Having hold of a crate beside a deck, its nearer deck mount is
    offered and take stands it there. It takes a battery into its own slot by hand, a
    light shield goes onto the other piece, and the deck floats on the crate's batteries
    while the shield runs on them, one pool. Take has the crate off into your hold.
19. **Last joined, first off.** Aimed at a middle piece, take has hold of the deck and
    nothing comes off; aimed at the last joined, it comes off into your hands, never
    through the deck, and then the next.

## Out of scope

- Crafting, for now. Parts come from Salvage & ruins.

## Open questions

- **Can pieces from different eras join freely in the chassis, or do they need adapters?**
  Open in the notes (Hunter, 2026-10-17). Here: "Pieces join edge to edge by their rings," "A
  piece... is a find," and "Every piece needs its own hover tray." Not said: whether a piece's
  era matters to the join at all, and what a First Kingdoms piece, "practical to drag without a
  hover tray," does in a deck where every piece needs one. If adapters exist, the rules here
  would make one a typed part that is found, not crafted (rule 6, and out of scope below).
  Session 4, part 2 lists the question again among its own open ones, still unanswered. It also
  shows why it matters: the moving nomad city is "a huge tethered raft of salvaged chassis,
  shields and turbines," pieces of many eras lashed together.
- **Efficiency of what.** "Best power efficiency per kilogram" could mean the hover draw per
  kilogram floated, or something else of the frame's. The notes give no numbers for any era.
- **Where the tuning mods go.** A low-power tuning mod needs a mod mount, and only the planter
  has one. Whether the crate, the shield and the rest get one is not said.
