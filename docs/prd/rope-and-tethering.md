# PRD: Rope & tethering

*Draft, 2026-10-13. Answers to [the vision](../vision.md).*

## Why this system exists

Your home goes with you, and rope is how. It holds the camp down against the wind, it's
how you move the camp, and it ties the camp to whatever pulls it. The game's base
mechanic is built on it, so it has to be **reliable before anything else**. It should
never be laggy, never bug out, and never go crazy, from a calm afternoon to the worst
storm.

## What the player experiences

- **Tying things together is simple and physical.** A rope in use takes your hand
  slot. Snap its end onto a ring, then walk to another and snap the other end on. Pick
  up any loose end, wherever it lies. Coil a rope to stow it in your inventory.
- **You can tie a line round your waist** to free your hands for towing. The price is
  that it drags you back and the wind grabs you harder.
- **A strong gust can drag you** if you're on the end of a line. You can let go of a
  line in your hand at any time.
- **Ropes behave like rope.** Slack rope sags onto the sand and stirs in the wind. Taut
  rope goes straight, creaks and hums. You can read the load by eye and ear, with no
  meters.
- **Wind loads everything, and rope carries that load to the anchors.** A gust swings
  the floating planter out on its line, the rope takes up the strain, and it holds.
- **More rope means more strength.** Two lines share a load one line couldn't hold.
  Lines on opposite sides pin something in place instead of letting it swing.
- **When it's too much, a rope snaps. It doesn't explode.** You hear it go, and whatever
  it held is gone downwind. In a stateless world, gone means gone.

## What Sand Game taught us

The rope was three systems that disagreed:

1. **The rope you saw** was drawn by nudging points toward each other at a speed tied
   to the frame rate. At a low frame rate the nudge overshoots, which is the "going
   crazy".
2. **The pull on the far end** edited the object's speed directly. It ignored the
   object's weight and the frame rate, and only one end ever felt the pull.
3. **A separate tether component** applied its own spring to the same object, with a
   *different* rope length (10 m against the drawn rope's 5 m). It also bled 2–15% of
   the object's speed every physics tick, which also smothered the wind, hence the
   "re-enable wind when tethered" fix.

## Rules

1. **One rope, one truth.** Each rope is a single constraint that does the holding,
   plus a drawn rope that shows it. They share one length and always agree. Nothing else
   pulls on a tethered object.
2. **Rope has weight** (decided 2026-10-15). A lightly loaded line droops and
   straightens as the pull builds, so you read the load by eye. Only a line under
   real load runs straight. The look-test's weightless line looked as straight at 2%
   load as at 70%.
3. **Stiffness is a feel, not a force.** A rope is defined by how fast it springs back
   and how much it bounces. It's solved the way physics engines solve soft joints,
   from both ends' masses, so it can't gain energy. A lantern and a loaded planter on
   the same rope type both behave sanely.
4. **Equal and opposite.** A rope pulls both ends equally, at the attachment points, so
   loads twist things realistically and anchors feel what they hold.
5. **Frame-rate proof.** The same setup behaves the same at any frame rate.
6. **Too much load breaks something; it never explodes.** Every rope has a breaking
   strength and every anchor has a holding strength. A brief spike doesn't snap a rope,
   only sustained load past its limit does.
7. **Ropes only touch the sand.** Drawn rope rests on `height_at` from World & terrain.
   That's a cheap lookup with no raycasts. Ropes pass through objects and each other,
   which means no tangling and no snagging, and none of the bugs those bring.
8. **Ropes belong to the camp, not the land.** They move with origin shifts and never
   belong to a chunk.

## Attachment points

Ropes attach only at **fixed points** on each object: rings and hooks you can see. That
keeps attaching reliable and easy to read. A basic object has one or two. Upgrades add
more, like an upgraded hover planter, and so do found mods, like an extra hook you fit
yourself.

**Attaching is the snap system** (decided 2026-10-14, from the rope look-test). A rope
end is held like a part and snaps onto a ring with the magnetic snap from
[Devices & mods](devices-and-mods.md): it needs intent, lands exactly, and pulls off
the same way. That works on any ring: a stake's, an object's hook, your hand or waist.
**Any loose end can be picked up,** whether it was dropped, is dragging behind
something, or is half of a snapped rope.

**Stakes are their own item.** Equip one, drive it into the sand where you stand, and
pull it back out to move on. Its ring is just another attachment point, so staking and
tying are separate acts. In the look-test, picking up a line only worked on staked
ones, so a dragging line could never be caught.

## You on the end of a line

The player is a rope end like any other, with a weight and a wind catch, so a strong
enough pull drags you. Held in your hand, a line can be dropped instantly. Tied round
your waist, it frees your hands but slows you down and raises your wind catch.

**Reeling in** (Hunter, 2026-10-16: "scroll to pull in rope, with a nice animation and
sound"). With a line's end in your hand or at your waist, the reel-in action shortens it
a notch at a time, hand over hand, drawing what's on the other end toward you as hard as
your strength allows; against something staked or too heavy, it draws you to it instead.
Pay out gives it back, up to the line's length. Each notch shows the rope gathering in
your hands and sounds the rope working.

*As built (2026-10-16):* a notch is 0.25 m, and no line reels shorter than 1 m. Your
hands take it in at up to 1 m/s, and only the line draws, on both its ends, so what's on
it comes only as hard as your hand strength (400 N): the draw eases off from half your
strength and stops at all of it. Whatever doesn't come, a stake or something too heavy,
you step in to along the line instead, at about 0.5 m/s. Nothing on a line ever closes
faster than its 3 m/s. **Which line reels** (2026-10-18): the line in your hand first;
else, of the lines at your waist, the one whose far end you look nearest, so with a sheet
and a mooring line both there you trim by looking at the sail and reel the mooring by
looking at its stake. The line being reeled stays the one until another's far end is
30% nearer your aim; with two equally near, the last tied wins. Before, it was
always the last tied, so a stake line tied on after the sheet took the reel off the sail.
**A radio shares them** (2026-10-18): looking at a radio, and not reeling the line in your
hand, reel in and pay out tune it instead of reeling the line at your waist; holding one,
they tune it while there's no line at your waist to reel ([Radio](radio-sound-and-atmosphere.md#the-dial-and-the-gods-on-the-air-hunter-2026-10-18-built)).
Bring near and push out always move what you hold, never a line or a dial.
A floating thing drawn in keeps gliding when you stop, as anything pushed does. A
strong cable reels too, since it's a rope: its plugs keep their rules, and it pays out
to its full 6 m. Each notch dips the end in your hand and lifts it again, across the line
so the drawn line keeps its length; the rope you've taken in gathers in a coil where the
line is on you, growing as you reel; and each notch rubs, a soft creak from Sand Game's
rope recording, lower as you pay out. In a menu or with the inventory open it
does nothing. A reeled line keeps its length when you let go of it. The look-at line says a
rolled-up coil's length; a laid line says nothing more, since its length shows, the coil you
gather shows what you've taken in, and its strain creaks.

**The sheet** (2026-10-18). A line whose end is on a sail's boom is its sheet, and it's held
the way any line is: in your hand, at your waist, or made fast on a ring or a stake. It runs
through a block at the boom's end and in to a ring on the camp, and that inboard part is what
holds the boom (2026-10-18, Hunter: "having scroll magically rotate the sail along with pulling
the rope has been an issue both from a sense perspective and gameplay"). Reeling it takes line in
through the block a notch at a time, the line to you no shorter: it gathers in the coil where
the sheet is on you, and the boom comes in after it, drawn by the sheet. The draw eases off as the
sail's pull on it nears your strength, as any line's does, so a loaded sail comes in slowly or not
at all. Paying out gives line back and the wind takes the boom out after it; once the inboard is all
in, a notch reels the line itself, and once it's all out a notch pays the line out. With nothing
holding its far end it runs, and the sail swings free. Riding, a sheet at your waist stays tied as you step on, and
reeling works it there: your camp tows you by it, and the board pushes against no line.
(Before, reeling did nothing riding, and every line at your waist was untied before you
stepped on; any line but a sheet still is.) The sail's side is in
[Movement](movement.md#sailing-the-camp-hunter-2026-10-17).

**Never the link** (2026-10-18, Hunter's spec: "Never make the player the link between a heavy
sail and a heavy camp"). A sheet and a line to a camp (any device but a stake) both at your waist
would make you the link, so a hidden line runs from the sheet's tie through a ring at your waist to
the camp's tie. A line can run through a ring: the ring slides, bearing only the line's bend, never
its pull, so solved as one line the camp's pull passes you by, however light you are. The camp's
line rides on it and is drawn as it lies; the sheet's pull lands at its block on the rig's middle
line meanwhile. Untie either, or sit at a helm, and it's gone; it's never saved, only made again
from the lines. The ride keeps the camp's line tied as it keeps the sheet. [Movement](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)
has the steering and the numbers.

**The fulcrum** (2026-10-18). The spec takes it as the rope's rule already ("you take damage if
you end up as the fulcrum"); it wasn't. Now your body bears what the lines on it pull against each
other plus any line's bend round you, held as long as a line's load is (0.3 s). Past your strength,
400 N (`fulcrum_n`), you lose 8 health a second for each share more (`fulcrum_hurt`), never your
last, and your view shakes. Lines still snap only past their own load. Sailing probe 9 braces you
off the hidden line with the camp moored: it bends round you at 500 N and hurts you; the lines hold.

## Wind on tethered things

Every object that can be tethered has a **wind catch**: how much the wind grabs it,
alongside its weight. The force comes from `wind_at` (Wind & storms), so gusts and
storm outflow load the ropes for free. A floating planter catches a lot and weighs
little, while a loaded deck catches little and weighs a lot. Rope's job is to carry that load
to the anchors without drama.

## Moving the camp

Rope is how the camp travels. There are two states, and the switch between them is a
core action:

- **Camped:** staked down, with lines out against the wind.
- **Travelling:** unstaked and towed. The pieces follow on their lines, swing with the
  gusts, and pull on whatever tows them.

Early on, a **post or a ruin** to tie more of the camp to when a storm hits is worth a
lot.

**The camp stays fully simulated** (Hunter, 2026-10-16). Wind, weight and the camp's size
are the core limit on moving it, so a camp is never folded into one non-simulated
object. There's no action that gathers every nearby line for you: you arrange your own.
The design aims at small camps of well-modded gear, not large meshes of lines. A dev
scenario drops a large pre-tied cluster into a storm to see whether the physics holds;
if it doesn't, the answer is a limit inside the world (a budget of tie points per thing,
or drag that grows faster than the camp does), never a hard cap.

**What does the towing**, owned by Movement and Camp, with the rope serving all of them.
The hoverboard tows nothing.

- **You.** You hold the lead and feel the pull. You're the most reliable tower.
- **A mechanical beast.** It follows at a distance and carries or tows things. A rusty
  robot made of stiff, separate parts needs no skin rigging at all, which sidesteps the
  problem that sank Delve.
- **A sand yacht.** It rides the wind, fast. No sail goes straight into the wind, but it
  can zigzag upwind (tacking), so it makes travelling into the wind possible at speed.
  *Built (2026-10-18) as your own camp under sail, towing you on its sheet
  ([Movement](movement.md#sailing-the-camp-hunter-2026-10-17)).*

## Skeleton version

- One rope type, attachable between the player, objects and stakes.
- A constraint that's slack below its length and an elastic spring past it, defined by
  springiness and bounce, with a hard maximum stretch. It pulls both ends at their
  attachment points (rules 1–4).
- Breaking strength on ropes, and holding strength on stakes.
- A drawn rope that sags, rests on the sand, stirs in the wind and goes straight when
  taut.
- A player on the end of a line feels the pull and gets dragged by a strong one. A
  line can be held (dropped instantly) or tied round the waist (hands free, slower,
  more wind catch).
- Wind catch on objects, driven by `wind_at`.
- Fixed attachment points, with rope ends snapping on and off through the snap system.
- Stakes as their own item: equip, drive in, pull out.
- One test floater: a hovering box that stands in for camp pieces.
- Camped and travelling: stake, unstake, tow.
- A tension creak (Sand Game's recording) that rises with load.
- The probes below, all passing.

**As built in the skeleton (2026-10-15):**
- **Weight** makes each line an elastic catenary: it pulls a little short of its
  length and straightens as the pull builds, and its drawn sag is the one its weight
  and pull imply. A line slack enough to lie on the sand pulls nothing.
- **A coil** gives you its first end when you pick it up, with the rest on your belt.
  Once that end is on a ring (or tied at your waist), the coil comes to your hand and
  pays out as you walk, up to 12 m. The line's length is set wherever its second end
  goes. Paying out, either end reaches as far as the coil does, not only as far as it's
  out so far, so a stake a step or two ahead takes it from a standing look at it or its
  foot (2026-10-17). Taking up an end of a line lying loose at both ends rolls it back
  up; dropping the first end before it's on anything puts the coil down whole, and
  putting it in with what you carry stows the coil there (Survival).
- **Rings** are tie sockets: a hook adds one while it's fitted, and a stake has one on
  its eye. You're a ring in your hand, and at your waist: use with a line in your hand
  and nothing to work ties it on, and use empty-handed takes it back after a second's
  untying (`untie_seconds`). Take puts a line in your hand down at once, so letting go
  of your waist is use, then take.
- **A stake** is a small device you can carry. Use drives it into the sand where you
  look. Take on a driven stake pulls it into your hand with its lines still on its ring,
  pulling on you now, so one gesture unstakes them and the next stakes them again.
  It goes in only where your look meets the sand itself within reach, at the ground's
  height there (2026-10-17). Used at sand farther off, or at anything else near, like a
  deck or a ruin's wall, it stays in your hand and the readout says why; before, one
  with lines on it went to your waist instead and stood in the air in front of you.
  Used looking out over the sand, not down at it, one with lines on it ties at your
  waist, to tow what's on them.
- **Rings are a chassis's and a planter's** (since the chassis rework, 2026-10-18): a
  chassis piece has one on every edge, which takes a hook or the next piece, and a planter
  two, front and back; nothing else takes a hook. A deck takes as many lines as it has
  free rings with hooks on them.
- **A snapped line** parts into two lines, each with a loose end where it broke.
- **The hard stop** stops a line stretching any further at once. Nothing in a line,
  its spring or its stop, pulls its ends together faster than 3 m/s, however far it
  stretched: a loose end snagged on a dune or round your legs while the other end
  drives on is dragged free when it comes loose, never flung.
- **A line in your hand** pulls from where the last physics tick put your hand, at
  your eyes' steady height. Drawn frames show what you hold following your view and
  your head's bob and sway between ticks, and the line never feels them.

## Full version

- **More attachment points** from upgrades and found mods, like an extra hook.
- **Rope types** that trade strength, stretch, weight and length. The best one might be
  colonial cable, since history runs backwards in the ground.
- **Anchors** of different holding strengths: a stake in soft sand, a stake in hard
  flats, a post, a heavy object, a buried ruin.
- **Reeling in and out**, so a winch can pull the camp in or let it out.
- **Towing by movers:** the beast and the sand yacht.
- **Snaps with weight to them:** the whip, the crack, and whatever it held lost
  downwind.
- **Load you can read at a glance:** vibration, hum and the rope straightening.

## Probes

Reliability is the whole point here, so this list is long. All run without a window.

1. **Nothing goes crazy.** Run every combination of wind (calm up to the worst storm
   gust), weight (lightest object to heaviest) and number of lines (1 to 4) for several
   simulated minutes. No speed spikes, no energy appearing from nowhere, no invalid
   numbers, and under steady wind everything settles.
2. **Frame-rate proof.** The same setup at 30, 60 and 120 physics ticks comes to rest in
   the same place.
3. **Equal and opposite.** The force on the anchor matches the pull on the object.
4. **Lines share load.** Two identical parallel lines each carry about half. A load
   that snaps one line holds on two.
5. **Snaps cleanly.** Raise the wind until a line passes its breaking strength. It
   snaps, the object drifts downwind, and nothing spikes. A loose end that snags as
   it's dragged off is dragged free, never flung. *(2026-10-18: the probe's snag had
   been the next chunk's collision edge, not the dune face it was laid for, and
   with that edge gone nothing on open sand snags a loose end: laid before a 30° slip
   face, the end climbs it at its own pace. Taking the cap off the line's
   closing speed changed nothing the old snag measured, either. So the probe lets go
   of a line stretched past its stop, as a snag on something solid leaves one: it
   drags its end back at 3.1 m/s, and 52 m/s without the cap.)*
6. **What you see is what holds.** Drawn rope ends sit on the attachment points every
   frame, the drawn length matches the constraint, and the drawn rope hangs as its
   weight and pull say: straight only under real load.
7. **Rope rests on sand.** No drawn rope ever dips below `height_at`.
8. **Origin shifts are invisible.** A wind-loaded, staked camp crosses an origin shift
   with no jump in tension.
9. **The long tow.** Tow a floater 5 km over dunes through gusts. It arrives, and its
   tension never spikes past a set bound.
10. **Cheap enough.** Thirty ropes in storm wind update within the frame budget.
11. **Dragged, not launched.** A player on a line in the worst gust gets dragged at a
    bounded speed, with no launching and no jitter. That's held or waist-tied, on flat
    sand and on a slip face.
12. **Last on, first off.** Aimed at a hook with a line tied to it, take unties the line
    and leaves the hook; once the hook is bare, take has the hook.
13. **Reeled by hand.** Reeling in draws a floating piece in about the notches reeled,
    paying out lets it back no further than the line's length, and against a stake it
    steps you in instead.
14. **Tied standing.** A coil out of what you carry, its first end in hand, ties to a
    stake a step and a half ahead from a standing look at its foot; walked off paying
    out, its second end ties to the next stake's ring the same way, laid long enough to
    reach between them.
15. **Only into the sand.** The kit's stake, taken up with the deck's line on it, used
    at sand out of reach and then at the deck, stays in your hand each time, neither
    driven nor at your waist, and the readout says why. At sand in reach it goes in at
    the ground's height; looking out over the sand, use ties it at your waist.
16. **The line you look along.** A sail's sheet and a line to a stake both at your waist:
    looking along the sheet, two notches haul half a metre of the sheet's inboard in and
    leave the stake's line be; looking along the stake's line, two notches draw it in half a
    metre and leave the trim be.

Every probe is first run against a deliberately broken rope, to prove it can fail.

## Out of scope

- Ropes colliding with objects or each other, tangling and knots.
- Climbing, swinging and grappling.
- Cutting ropes to arbitrary lengths with physics. Lengths are set when you attach.

## Open questions

- **How much rope do you carry,** and is every coil the same length? The skeleton's
  coils are all 12 m.
