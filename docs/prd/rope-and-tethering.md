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
   only sustained load past its limit does. **A line holds or parts** (2026-10-19, Hunter: "a
   line rated 1,500 N either holds or parts, consistently"): it never pulls past its strength.
   Asked for more, it gives at that and stretches; asked for more long enough, it parts.
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
faster than its 3 m/s. **Which line reels** (updated 2026-10-19): the line in your hand first;
else the waist rope chosen in the carry view (see [Waist lines](#waist-lines)). Looking around
does not change the choice. With only one rope connected, reeling works it without a choice;
with several and none chosen, reeling asks you to choose one. Losing the chosen tie clears the
choice without picking another.
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
would make you the link. The first answer was a hidden line the rope system ran on its own through
a ring at your waist. It was removed (2026-10-20) because Hunter rejected the magic of it. Lines
now run only where a real hook routes them ([Player-routed lines](#player-routed-lines-hunter-2026-10-20-built)),
and the game never ties a second load to you on its own, so tying opposed loads to yourself is a
choice that carries the fulcrum rule's cost, below. The ride keeps the camp's line tied as it
keeps the sheet. [Movement](movement.md#sailing-from-kite-to-yacht-agreed-2026-10-18-spec-built)
has the steering and the numbers.

**The fulcrum** (2026-10-18). The spec takes it as the rope's rule already ("you take damage if
you end up as the fulcrum"); it wasn't. Now your body bears what the lines on it pull against each
other plus any line's bend round you, held as long as a line's load is (0.3 s). Past your strength,
400 N (`fulcrum_n`), you lose 8 health a second for each share more (`fulcrum_hurt`), never your
last, and your view shakes. Lines still snap only past their own load. Sailing probe 9 ties a line
from the rig and a line to a moored camp both to a rider between them: a 900 N rig pull puts
937 N of opposing load on the rider and costs 21 health, and both lines hold.

**Holds or parts** (2026-10-19, Hunter: "a line rated 1,500 N either holds or parts,
consistently"). A line never pulls past its strength. What holding would take more than that (its
`asked`), it gives at its strength (its `tension`, never more) and stretches. Pulled apart past its
strength for most of the last 0.3 s (`Rope.STRAINED`, 0.7 of `rope_load_seconds`), it parts; its pull
held past its strength that long parts it too, as ever. So a snatch it can stretch through it rides
out at no more than its strength, and an overload it can't, it parts: a 0.1 s gust worth 2.5 times a
400 N line's strength asks 2,460 N of it, it pulls 400 N and holds; the wind rising past it parts it
at 397 N. A storm's gust swinging a moored deck round onto its line stays under its strength. The
rule came from the Varran rig, where the board's push took the rider past slack lines at 15 m/s and
they came taut at 7.6 m/s: 6,750 N for a tick on lines rated 1,500 N, which threw the rider. The
cause of that snatch was the board, and it's the board's rule (Movement): towed, slack in your lines
never lets the board's push take you more than 1 m/s faster than what they lead to.

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
- **A stake** is a small device you can carry. Use drives it into the sand where you look.
  Take on a driven stake pulls it into your hand with its lines still on its ring, pulling
  on you now, so one gesture unstakes them and the next stakes them again. It goes in only
  where your look meets the sand itself within reach, at the ground's height there
  (2026-10-17). Used at sand farther off, or at anything else near, like a deck or a ruin's
  wall, it stays in your hand and the readout says why; before, one with lines on it went to
  your waist instead and stood in the air in front of you. Used looking out over the sand,
  not down at it, one with lines on it ties at your waist, to tow what's on them. A downward
  aim with no collision in the camera's far range, or a level or rising look with terrain
  farther along the sight ray, is a distant planting aim too and is refused the same way;
  only an open horizon ties it at your waist (2026-10-19). The mooring hint says to aim at
  an open, level horizon or into the sky. Torn out by its lines, it lies on the sand with
  its head toward their pull (2026-10-19): stood on its point, the sand's friction caught
  it, and a strong line tore rather than drag it.
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
5. **Snaps cleanly.** A gust spike far past a line's strength never pulls it past that, and
   too brief to sustain, the line rides it out. Raise the wind until a line passes its breaking strength. It
   snaps, the object drifts downwind, and nothing spikes. A loose end that snags as
   it's dragged off is dragged free, never flung. *(Nothing on open sand snags a
   loose end, so the probe lets go of a line stretched past its stop, as a snag on something solid
   leaves one: it drags its end back at 3.1 m/s, and 52 m/s without the cap.)*
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
    the ground's height; looking out over the sand, use ties it at your waist. An aim down at sand 8 m
    off is out of reach, not an open horizon.
16. **The line you choose.** A sail's sheet and a line to a stake both at your waist: choosing
    the sheet, two notches haul half a metre of the sheet's inboard in and leave the stake's
    line be; choosing the stake's line, two notches draw it in half a metre and leave the trim
    be. With only one rope connected, it is the one reeled.

**Drawn arc keeps its length (2026-10-19).** Reeling exposed a presentation-only shortening:
blending old points and pinning the visible ends contracted a drawn strand to 3.19% short of its
paid-out line, where the simulated strand was 2.11% short and the tolerance is 3%. Interpolating a
strand's bend now preserves the current simulated strand's arc, keeping both visible rings fixed
and clamping interior points to their sampled sand planes. It changes neither the solver's points
nor momentum, and does not weaken the rendered-length tolerance. Probe 19 checks changing bends,
moved visible ends, ground contact and unchanged physical points.

Every probe is first run against a deliberately broken rope, to prove it can fail.

## Out of scope

- Ropes colliding with objects or each other, tangling and knots.
- Climbing, swinging and grappling.
- Cutting ropes to arbitrary lengths with physics. Lengths are set when you attach.

## Waist lines

Lines tied round your waist are chosen, reeled and untied from the carry view. The rules
below were settled over the 2026-10-19 playtest and the play after it.

### Explicit physical-rope choice only (agreed, 2026-10-19 playtest)

Hunter, on choosing a rope: "in your inv you mouse over the line and that shows it, you can
select it from there... i dont like having it on screen 100% of the time while you have a
waist rope. the text is also so small i can barely read it". Later, on the result: "tab
highlight and selection are awesome... when you hit tab you have a note about hovering ropes
to select them and it tells you how many ropes are connected".

The carry view selects the actual ropes in the world, not a list of names. Hover a visible
rope curve to preview and highlight it; choosing it keeps it selected, and hover never
changes the committed choice. Curves behind the camera or hidden by solid gear are not pick
targets, and the cluster by the waist is avoided. There is no gaze selection, because
aiming-based selection was unreliable, and no rope is chosen automatically.

Which rope is worked: a held line first, then the chosen rope. A sole connected rope needs
no choice. Hunter: "If you dont have a rope selected scrolling should just reel your only
rope". With several ropes and none chosen, reeling or empty-handed Use gives a readable cue
to open the carry view and choose one. Losing the chosen tie clears the choice without
switching to another, and recovering or removing a chosen rope likewise leaves the choice
empty until a new one is made. The choice is transient: it never changes saved ropes or
loads and starts empty on resume. Choosing alone never unties, releases or reels anything.

Empty-handed Use takes the chosen line back from the waist after the normal untie delay, and
once untying begins the chosen end is kept through the delay even if the view turns. A sole
waist stake with no individual reel target still returns whole by empty-handed Use, even
after its rope breaks; there the carry view keeps the real connected count and explains that
return instead of promising individual ropes to choose.

What shows is deliberately small. The carry view explains hovering ropes to select them,
shows the number of distinct live ropes connected across all waist holders (a stake counts
its ropes, orphan ends do not, and zero still shows), and shows the hovered or chosen line's
name, length and tension in readable shared-theme text. Nothing about waist lines stays on
screen outside the carry view: no crosshair waist statistics in ordinary play, with only the
countdown of an untie in progress shown in the gameplay readout, and gameplay look-at text
is hidden while the carry view or a menu covers it. Mast help and the sailing notes teach
hovering and choosing the physical rope.

As built, `WaistLines` projects each drawn strand through the player's camera, rejecting
segments across the near plane and avoiding the first metre by the eyes. Hover is a thick
accent curve and a different chosen rope a thin pale one, drawn behind the inventory cards.
Rope 18 covers choosing, keeping the choice and untying the chosen line; rope 16 covers the
sole-line fallback.

### Release all waist lines (Hunter, 2026-10-19; built)

The carry view offers a deliberate Release all waist lines action. Hunter chose normal
one-second untying with visible progress, using the existing untie duration in tuning. Lines
stay tied and apply their full normal load throughout that delay; completion drops the ends
rather than returning them to the hands. Neither player nor rig momentum is reset. Held
lines remain held: this releases waist ties only. An untie already in progress must finish
before another release can start.

The carry view shows remaining time and a progress bar, and the gameplay readout shows the
remaining time if the view closes; closing a panel or opening a menu does not pause the
untie. Stake-carried waist lines are included even when there is no individually selectable
end. Existing save fields keep an in-progress all-line release.

Cast Off records releasing two or more live lines together at actual completion, not when the
control is used or the timer starts. It uses the existing knot and rope release event, so equivalent
physical releases count, and its goal is in tuning.

### Lost line ends leave the waist (built 2026-10-19)

A line removed without ordinary parting, such as a dev teleport separating its ends, leaves
bare ends rather than a working rope. Those ends also leave waist management, so a vanished
line never leaves an untargetable permanent waist tie. Bare ends in the world and any end
already in the hands are kept, and the waist ends return to their ordinary physical state.
This is cleanup after the line is gone, not a shortcut around a player's ordinary untie or a
change to rope forces. Dev 2, rope 18 and rope 5 cover it.

### Gather waist ends in hand (Hunter, built 2026-10-21)

Hunter: "holding down f for a second with nothing in your hand continues to untie ropes...
you can hold multiple in your hand just like you would around your waist".

With empty hands and no more specific Use interaction, Use begins the one-second untie of
the chosen waist line (or the sole live line), and a tap returns that end as usual. Holding
Use after the end arrives keeps untying further waist ends, one full second each, in their
tie order. Letting go of Use, opening a menu or aiming at device or ground work cancels the
next transfer, leaving the ends already gathered in hand. There is no dedicated action,
instant waist-wide transfer, line fusion or automatic simultaneous reeling, and no dedicated
batch-mooring action. A fresh Use with the held knot keeps the ordinary waist, guide and
device interaction. A knot already formed at the waist is one physical tie: returning it
takes the existing one-second untie, like a stake carrying several lines.

The first rope end stays the carried body. Each further end is fitted into a real marked
child socket by the existing nested-part mechanism, as a loose hook carries its end, and
every line, tip, length, strength and fairlead route stays distinct. A loose knot's mass
includes all its ends, each counted once. Dropping gives the whole knot the player's normal
momentum. Fitting it to a free anchor is the ordinary take action, and taking the primary
knot returns the whole knot to the hand, while aiming at a secondary end's own geometry can
still remove that fitting alone. The picker and reel keep an individual active member; a
held group takes priority over waist ropes and its first live member is the fallback.
Gathering never changes a rope's length or applies a body impulse, and Release all stays.

A save restores the nested fittings and the active member (an optional `bundle_slots` count,
absent for an ordinary end); it never fabricates a held Use or resumes automatic
continuation. Rope 29 covers the held-input continuation, per-end delays, cancellation and
identity; rope 30 anchoring, retrieval, masses, Make Fast and drop momentum; saves 46 real
disk round-trips of held, anchored and loose knots.

### Rope around the suit's waist

Hunter: "Rope should also physically go around your waist". And on the look: "a waist coil
instead of our current coil, but our current coil looks good... keep that for the item in
general".

The waist attachment is the knot at the front of the suit's belt (`Waist.AT`), so a line
pulls where it is seen tied, and the rope is drawn wound round the waist as a waist coil. The
loose and held item coil keeps its look ([Coils](#coils)). Each waist holder carrying live rope
gets one cached plaited wrap on the rendered belt; a grouped knot is one holder and one wrap,
and the wrap clears when its holder leaves the waist. A short lead joins the knot to the line's
drawn end only where the body's pose and the physical point part, crouched or prone. The tied
end itself is not drawn at the waist, since the body draws between ticks and the end's own pose
would jitter there; it shows again in the hand. Drawing never moves a physical end or changes
length, forces, ownership or selection, and the wrap has no colliders. Rope 31 covers the
knot and the hidden end, rope 28 the ground-rest attachment.

## Player-routed lines (Hunter, 2026-10-20; built)

Physical hooks and the boom's real sheet replace the automatic invisible sailing tow
constraint, which was removed because Hunter rejected the magic of it. A route is an
ordinary line through a real guide, with force at each endpoint and the guide's bend, and
the built-in sheet runs through its block the same way.

A player can pass a real line through a physical hook. Tie the first end normally, hold the
other end, aim at a fitted rope hook and Use to pass it through; continue walking and tie
that end, or put it at the waist, with the existing actions. Use on the same guide while
holding that line removes the route. There is one guide per line: a different guide is
refused with an explanation until the existing route is removed, so a route never silently
replaces another or creates a rope. A laid line too short for a proposed path asks for more
payout rather than creating rope or snapping. A plain label names the Use action and whether
it passes through or removes the route.

The line's total paid-out length covers both legs, and a held end's reach subtracts the
other leg's length. The three-body rope constraint carries tension to both endpoints and the
actual guide holder, including its bend load, and the drawn rope runs through the same ring;
offsetting a visual line alone is not routing. A guide removed from its mounting remains the
physical guide while carried or loose, and a deleted guide releases the route cleanly. Saves
add optional route references through existing item and end identity, and old saves default
to a direct line. Moving routed lines meet their visible endpoints and guide in the same
frame, and the drawn curve follows its two legs at a sharp guide without overshooting it.
The Fairlead deed needs a player-routed line carrying at least 10 N for 1 s (tuning data).

When several rope points share one rigid body, effective mass uses their summed linear and
angular Jacobians, measured from the actual centre of mass including fitted-device offsets;
treating them as independent masses misses their cancellation and cross terms. A freely
hinged boom's response includes its carrier and every boom on that carrier, with cross terms
and parallel-axis inertia. Impulses are applied only at real rope points and Jolt supplies
the hinge reactions, so no angle target or duplicate reaction torque is imposed. Rope
strength and closing-speed limits are unchanged. The sail's side is in
[Movement](movement.md#sailing-correction-physical-boom-and-explicit-routing-agreed-and-built-2026-10-20).

## Sailing handling (Hunter, 2026-10-20)

A sole live connected rope works without a carry-view choice, as above. A held line still
wins, and with several waist ropes the chosen one is worked.

**Yank.** The yank action gives the worked rope a short, faster haul through the existing
strength-limited reel: at most 0.5 m over 0.2 s, then 0.4 s of recovery. It changes rope
length over physics ticks, never the rig's rotation or either body's velocity directly. The
normal tension and hand-strength slowdown still apply, slack takes up before a load can turn
anything, and any remainder is cancelled when the stroke ends or a menu interrupts it. It
shares the hand stroke and rope sound, and rotating a held ordinary object keeps its own
action. Quick Haul records a stroke of at least 0.1 m against a measured load of at least 20
N. Travel, duration and recovery are tuning data; rope 20 covers it.

Carry-view rope labels use the theme's UI type, with numeric readouts in the established
numeric style elsewhere.

## Taking sail gear and ground ropes apart (built 2026-10-20)

Playtest reports concerned removing the sail and detaching ropes from the board. Every
physical boom hit maps back to its removable fitted sail, and the board's visible tie ends
stay pickable through the normal take, with no new detachment action. Occupied tie knots get
bounded, front-side, occlusion-checked aiming help, and a device hit allows the existing
small-item assist, so a dropped end beside a stake no longer loses to the stake's occupied
socket. That help applies to tie sockets from fitted hooks and never replaces a hit on a
carryable stake's own frame: taking the stake whole, with its line attached, stays the
camp-towing interaction. Native tie knots stay directly pickable.

A fully loose line lying on the ground can be recovered by aiming at its strand and taking
it: it gathers back into a coil of its whole length, reopening the same line with no second
rope. A line still anchored at either end is never silently detached or reeled from an
arbitrary middle point; take its loose end instead, and snapped halves obey the same rule.
Reach and line of sight are checked. Sail 20 covers taking the physical sail, rope 21
gathering a dropped strand and rope 22 taking a board tie.

## Coils

**Coils stay usable** (2026-10-20). Ordinary pickup turns any loose rope coil into a usable
line, including a coil no longer registered as a find and an older authored coil without
rolled metadata. A stored rope length is kept and an existing line is reused. Claiming loot
and opening a coil are separate operations, so a coil already claimed does not depend on
claiming its site again. Rope 24 covers it.

**Coil ownership while laying a line** (agreed, 2026-10-20). A fresh line's remaining coil
belongs to its paying end: before the first tie that end is on the belt, and after attaching
the first end it comes into the hand. The visual coil follows that end even when an older
waist line remains chosen for reeling; line identity, endpoint ownership, paid length and
control selection are unchanged. Rope 25 covers it.

**Continuous gathered coil** (Hunter, 2026-10-20; built). Paying out and gathering change
the coil continuously, with no steps at one third or two thirds. It reads the actual
remaining rope, including line paid through a sail block, and never changes rope physics,
ownership or selection. Fibre gauge stays constant, the leading end stays fixed to the live
hand or waist end, and a loose stowed coil stays full. One shared, cached indexed tube mesh
(1,631 vertices) deforms along its winding path by an instance amount, with a coil-only
fibre shader in the sun-worn brown fibre and muted teal whipping, and no mesh or material is
created while reeling. A short response filter smooths the amount and heading but never
delays the physical attachment point. The tube's end disks are closed and face outward, and
a tangent-matched lead keeps the first winding from folding back. The `rope_end` part shows
three laid fibre cords with compact teal whipping in its original 0.05 × 0.05 × 0.08 m
envelope. Geometry and response values are in `rope_coil_visual` tuning. Rope 26 covers
continuity across the old thresholds and near empty and full, and rope 27 the closed ends.

## Open questions

- **How much rope do you carry,** and is every coil the same length? The skeleton's coils
  are all 12 m.
- **Should anything cap the force a line puts on the player?** Release all is agreed and
  built; a cap is not. In a steady 10 m/s wind a powered three-line Varran reach delivered a
  mean resultant pull of 301 N (peak 1,282 N) and a mean opposing load of 4.45 N (peak 14.43
  N). Releasing just the sheet on foot left a mean 110 N on the two bow lines, peaking at
  553 N. These are delivered solver loads, not a proposed limit. A forced overrun's injury
  was a 13.27 m/s chassis collision, with the measured opposing load below the injury
  threshold. Any release control and feedback must tell returning an end to the hands from
  dropping it, and resultant towing pull from opposing strain.
