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
else only the waist rope explicitly chosen by clicking its physical curve in the carry view.
Looking around does not change the choice. Without one, reeling asks you to choose a rope;
losing a selected tie clears the choice without picking another, even if only one remains.
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

**Holds or parts** (2026-10-19, Hunter: "a line rated 1,500 N either holds or parts,
consistently"). Overrunning the Varran rig on a run, the board's push took you past it at 15 m/s
while its lines lay slack, and they came taut again at 7.6 m/s: 6,750 N for a tick on lines rated
1,500 N, still holding, since only their load held for 0.3 s broke them, and a jolt like that once
threw the rider. Now a line never pulls past its strength: what holding would take more than that
(its `asked`), it gives at its strength (its `tension`, never more) and stretches. Pulled apart past
its strength for most of the last 0.3 s (`Rope.STRAINED`, 0.7 of `rope_load_seconds`), it parts;
its pull held past its strength that long parts it too, as ever. So a snatch it can stretch through
it rides out at no more than its strength, and an overload it can't, it parts: a 0.1 s gust worth
2.5 times a 400 N line's strength asks 2,460 N of it, it pulls 400 N and holds; the wind rising past
it parts it at 397 N. A storm's gust swinging a moored deck round onto its line stays under its
strength. The cause of that snatch was the board, and it's the board's rule (Movement): towed, slack
in your lines never lets the board's push take you more than 1 m/s faster than what they lead to.

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
  waist, to tow what's on them. Torn out by its lines, it lies on the sand with its head
  toward their pull (2026-10-19): stood on its point, the sand's friction caught it, and a
  strong line tore rather than drag it.
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
16. **The line you choose.** A sail's sheet and a line to a stake both at your waist:
    choosing the sheet, two notches haul half a metre of the sheet's inboard in and
    leave the stake's line be; looking along the stake's line, two notches draw it in half a
    metre and leave the trim be.

**Interpolation arc correction (2026-10-19).** Reeling exposed a presentation-only
shortening: a current simulated strand was 1.54630 m long on a 1.57957 m paid-out line
(2.11% short, within the existing 3% tolerance), but blending old points and pinning the
visible ends contracted its drawn arc to 1.52918 m (3.19% short). Preserve the current
simulated strand's arc when interpolating its bend, keeping both visible rings fixed and
clamping interior points to their sampled sand planes. This must change neither the
solver's points nor momentum, and must not weaken the existing rendered-length tolerance.
The correction skips unchanged or already accurate arcs, uses one scratch buffer, and
scales the bend with a bounded numerical search. Probe 19 checks changing bends, moved
visible ends, ground contact and unchanged physical points. The original reeling, drawn
length/sag, camera interpolation, ground-rest and thirty-loaded-line cost probes pass.

Every probe is first run against a deliberately broken rope, to prove it can fail.

## Out of scope

- Ropes colliding with objects or each other, tangling and knots.
- Climbing, swinging and grappling.
- Cutting ropes to arbitrary lengths with physics. Lengths are set when you attach.

## Sanddune: explicit waist-line selection (initial design, superseded by physical choice below)

Hunter chose carry-view selection with a gaze option. The existing carry view
lists named waist lines with their current length and tension. Choosing one keeps
that line selected while looking around; Follow gaze restores the existing automatic
selection. Reeling and empty-handed use work the same selected line. A held line
still takes priority, and a selected end that is removed or loses its live rope
returns selection to gaze. Selection alone never unties, releases or reels anything.
The untie delay still retains the end chosen when it starts. This adds no force cap
or new binding. Selection is a transient handling preference and defaults to gaze
on resume; it does not change saved ropes or their physical loads. Existing sailing
and rope-handling deeds continue to record the physical actions.

**As built:** `Reel.choose` retains a live waist end ahead of gaze selection, below
held-line priority. `WaistLines` shows the same names and live numbers as the sailing
readout in a bounded, scrolling carry-view list, using the shared theme and PageBar.
Choosing Follow gaze or losing the selected tie clears the preference. Gameplay
look-at text is hidden while the carry view or a menu covers it. Rendered
1280×720 captures show the gaze option and all three Varran lines within the view,
with the chosen sheet marked and no gameplay readout over the carried objects.
The visual helper reported teardown resource warnings; it reported no script errors.
Focused behavior probes were not added or run for this change.

**Load measurements before choosing release behavior:** in steady 10 m/s wind, a
powered three-line Varran reach had mean resultant pull 301 N and mean opposing
load 4.45 N; their independent peaks were 1,282 N and 14.43 N. Releasing just the
sheet in the on-foot case left mean 110 N resultant on the two bow lines, peaking
at 553 N; releasing every remaining end removed continuing rope force after the
existing untie delay. These are delivered solver loads, not a proposed safe-force
limit. A forced overrun's injury was a 13.27 m/s chassis collision; measured
opposing load stayed below the existing injury threshold. Release control and
feedback must distinguish returning an end to the hands from dropping it, and
resultant towing pull from opposing strain.

## Release all waist lines (Hunter, 2026-10-19; agreed)

The carry view offers a deliberate Release all waist lines action. Hunter chose
normal one-second untying with visible progress, using the existing untie duration
in tuning. Lines stay tied and apply their full normal load throughout that delay;
completion drops the ends rather than returning them to the hands. Neither player
nor rig momentum is reset. Held lines remain held: this releases waist ties only.
An untie already in progress must finish before another release can start.

Show remaining time and a progress bar in the carry view, and remaining time in
the gameplay readout if the view closes. Closing a panel or opening a menu does
not pause or cancel physical untying. Include stake-carried waist lines even when
there is no individually selectable reel end. Existing save fields retain an
in-progress all-line release; no new save state is required.

Cast Off records releasing two or more live lines together at actual completion,
not clicking the control or starting the timer. It uses the existing knot/rope
release event, so equivalent physical releases count too.

**As built:** `Waist.release_all` starts the existing timed drop operation only
when no untie is already running. The carry view shows a countdown and progress
bar; closing it leaves a countdown by the aim point. The list remains available
for a tied stake even when no single line can be selected. Cast Off counts unique
live ropes at actual drop completion, with its goal set in tuning; existing save
fields already preserve an in-progress all-line drop.

A rendered 1280×720 loaded Varran sequence used the actual carry-view click:
three ties remained at 0.717 s left, still carrying 90.9 N on the observed line.
A second click at 0.617 s left did not change the timer. All three ties dropped
after 61 physics ticks, with the rider still moving at about 5.7 m/s. Captures show
the bar and countdown fitting the carry view and the countdown continuing after
it closes. The helper reported no script errors and did report teardown resource
warnings. No new behavior probes were added for this control.

## Distant planting aim must not become a waist tie (2026-10-19 correction)

Using a held stake at sand outside reach must keep it in the hand with the existing
out-of-reach refusal, even when the sand lies beyond the short nearby-object check.
Preserve deliberate waist tying when looking level or skyward over an open horizon.
A downward look with no nearby collision is not proof of an open horizon: the aimed
sand can lie beyond streamed collision. Refuse that planting attempt conservatively.
For level or rising looks, actual terrain farther along the same sight ray also means
a distant planting aim; use the camera's existing far range, not a new reach value.

Reproduced on the played revision: aiming at sand 8 m away while holding the starter
mooring stake gave no nearby hit, silently tied it at the waist and left its middle
0.55 m above the sand, `driven=false`. It looked planted in air but was a waist tie.
A genuine near planting stayed at the correct ground height after half a second;
its passed hit point and `Stake.drive` height were not the failing path. Add a guard
before the existing horizon fallback; do not change planting height or rope physics.

As built on the later verified play base: `Hands.sand_beyond_reach` distinguishes a
downward aim (including missing streamed collision) or a farther real terrain hit from
an open horizon. `Stake.use` gives the existing refusal before generic waist tying.
The mooring hint now explicitly says to aim at an open, level horizon or into the sky.
Existing rope 15 passes with both 3 m and 8 m planting refusals, nearby sand planting,
nearby deck refusal and a deliberate skyward waist tie. Its former horizon setup used
a fixed height that could point below the actual eye; the tie case now aims explicitly
above the eye. Real Take and Use input events also kept the stake held and said "out of
reach" at 8 m in headless and unseen graphical checks. The inspected 1280×720 frame
shows that refusal and the stake still in hand. A downward aim with no collision within
the camera's far range likewise refused instead of tying. No rope forces or planting
height changed.

## Open questions

**Waist-line selection (Hunter playtest, 2026-10-19; agreed follow-up).** Several lines need
one understandable target. Keep the existing gaze selection for reeling, show that line's
name, length and current tension while a waist line is selected, and make empty-handed use
take that same line back from the waist. Once untying begins, retain that chosen end through
the untie delay even if the view turns. A held line still takes priority when reeling. That first follow-up added no binding, release-all interaction or force cap. Release all
is now agreed above; a player-force cap remains open.

- **How much rope do you carry,** and is every coil the same length? The skeleton's
  coils are all 12 m.

### Physical waist-line selection (agreed, 2026-10-19)

The carry view selects the actual ropes in the world rather than listing their names. Hover a
visible rope curve to preview and highlight it; click that curve to keep it selected. Hover
never changes the committed choice. Follow gaze restores aiming-based selection. Curves
behind the camera or hidden by solid gear are not pick targets, and the shared near-waist
cluster is avoided. The held line still takes priority and a lost tie clears its selection.

Context in the carry view uses readable shared-theme text for the hovered or selected line.
Remove the persistent crosshair waist-stat line during ordinary play; show handling progress
only while an untie is active. Keep the existing timed Release all action and progress in a
compact carry-view control. This does not implement a player body or physical storage system.

**As built:** `WaistLines` projects `Rope.strand.shown()` through the player's current camera.
It rejects segments crossing the near plane, avoids the first metre by the eyes, and checks
solid-world occlusion before hover selection or highlighting. Hover is a thick accent curve;
a different committed selection is a thin pale curve. Highlights draw behind inventory cards.
`Suit` routes tiles first, then rope/control clicks, then its existing empty-space stow action.
Follow gaze and timed Release all remain compact controls. `Hands` no longer appends waist
statistics at the crosshair; its ordinary context and active untie countdown use the shared
20 px AsideValue style with space for two lines.

A 1280×720 unseen capture of the normal three-line Varran start inspected each curve separately:
hovering left the prior selection intact, clicking selected each corresponding physical end,
and Follow gaze cleared the explicit choice. Release progress reached 0.5 while all three ties
remained attached; its active in-game countdown was readable, and ordinary play showed no
waist-stat HUD. Import and capture completed without script/runtime errors. The existing rope
18 HUD assertion follows the revised contract; no new probes or local test runs were added.

### Explicit physical-rope choice only (agreed, 2026-10-19 playtest)

Physical carry-view hover and click selection works; remove Follow gaze because automatic
aiming selection is unreliable. No waist rope is chosen automatically, even when exactly one
is connected. Hover previews; clicking chooses. Losing that tie clears the choice without
switching to another rope. Held-line reeling still takes priority. Reeling or empty-handed
untying without a chosen rope gives a readable cue to open the carry view and choose one.

The carry view always explains hovering/clicking ropes and shows the number of distinct live
ropes connected across all waist holders, including a Stake. Orphan ends do not count. Remove
the last-tied fallback in empty-handed untie; retain only the distinct return of a sole waist
Stake that has no individual reel target. Timed Release all remains. No input binding or
force rule changes; sailing notes teach the same explicit physical-rope interaction.

**As built:** `Reel.line` now resolves a held line or an explicit live choice only. Its
connected-rope count deduplicates active Rope instances with valid endpoints and holders,
including connections carried by a Stake. `Waist.give_back` refuses a missing rope choice,
retaining only the sole non-reelable Stake return. Reeling or use without a choice
shows the readable carry-view cue. The physical picker has no gaze button; its shared-theme
20 px hint and count remain visible while the carry view is open. Mast help and sailing
notes teach clicking the physical rope. Existing physics probes select their fixture rope
explicitly; the former gaze assertions now check no implicit choice and retained selection.

A 1280×720 normal Varran capture began with no selected rope and three connected ropes.
Each of the three curves was hovered and clicked independently, selecting its corresponding
physical end. The hint, count, selected context and active release countdown fit the screen;
Release all reached 0.5 progress while all three ties remained attached. Import completed
without script errors. The visual helper reported 16 ObjectDB instances and eight resources
still in use on teardown, with no gameplay script error. No local probes or suites were run.

The count also remains visible at zero after releasing the last tie; its unavailable Release
all control is hidden. A follow-up 720p capture showed zero connected ropes and no selection,
and the unselected reel attempt returned false while displaying the readable choose-a-rope
cue. That follow-up helper exited cleanly with no script or resource-teardown errors.

The sole-Stake return also works after its rope breaks: it returns that one physical object,
without selecting any rope. Its missing connections still contribute zero to the live count.

When the sole waist holder is a Stake with no individual reel target, the carry view keeps
the real connected count and explains the existing empty-handed Use return. It does not
promise clickable individual ropes for that whole-stake case.

A 1280×720 Surveyor capture with its normal mooring Stake tied at the waist showed one live
connected rope, zero individual reel targets and no selected rope. The readable whole-stake
return cue replaced the hover/click instruction and stayed above the carry tiles. Import
and the capture completed without script or teardown errors; no local probes were run.

### Removed selected ends (2026-10-19; lifetime correction)

A selected rope end can be freed while its line is recovered or removed. Clear an
invalid selected body before passing it into a typed helper: Godot rejects a freed
object at the call boundary, before that helper's own validity guard runs. Selection
then remains empty until an explicit new choice, preserving carry-view selection.
This fixes the reproduced script error during rope recovery without changing ties,
reeling forces or the selection policy. The guard is useful for ordinary line
removal independently of the kite prototype where the failure was observed.

The existing selected-line untie/save/resume check (rope18) passes in9s with the
guard. That check covers ordinary selection behavior; the freed-reference failure
was observed separately during the prototype recovery loop. No probe assertions changed.

## Lost line ends leave the waist (2026-10-19 lifecycle correction)

A line removed without ordinary parting, such as a dev teleport separating its ends,
already leaves bare ends rather than a working rope. Those ends must also leave waist
management: a vanished line must not leave an untargetable permanent waist tie. Preserve
bare ends in the world and any end already in the hands; restore the existing physical
state of waist ends through `Waist.untie`. This is cleanup after the line is gone, not a
shortcut to the duration of a player's ordinary untie or a change to rope forces.

A reproduced Varran-to-yacht console transition retained the three old waist ends after
their lines disappeared, then added the yacht sheet (four ties, one live selectable line).
`Line._lost` removed metadata and freed its line before the delayed scenario-kit cleanup
could find it and untie its surviving ends. Clean those waist ends when losing the line.
This residue reproduced in source/debug and a release diagnostic; neither reproduced the
separately reported native crash, so this correction is not evidence that crash is fixed.

As built: losing a line unties its surviving waist ends before stripping their line
metadata, reusing the ordinary physical-state restoration and leaving bare/held ends
intact. The same Varran-to-yacht diagnostic now leaves exactly one tie and one selectable
line, the new yacht sheet, including after closing the console and reopening the actual
carry view. Existing dev 2, rope 18 (selected untie) and rope 5 (clean parting) pass.
The original reported native crash was not reproduced in source, headless release or an
unseen graphical release run; this fixes the measured orphan ties, not that unconfirmed
crash cause. No force, untie duration, save format or deed behavior changed.

## Explicit sailing load paths (agreed, 2026-10-20)

Physical hooks and the boom's real sheet replace the automatic invisible sailing
tow constraint. A route is an ordinary line through a real guide, with force at
each endpoint and the guide's bend. When multiple points share one rigid body,
effective mass uses their summed linear and angular Jacobians; treating those
points as independent masses misses their cancellation and cross terms. Rope
strength and closing-speed limits remain unchanged.
## Player-routed lines (Hunter, 2026-10-20; built generic routing, sailing integration pending)

A player can pass a real line through a physical hook, as the built-in sheet runs
through its block. Tie the first end normally, hold the other end, aim at a fitted
rope hook and Use to pass it through; continue walking and tie that end or put it at
the waist using the existing actions. Use on the same guide while holding that line
removes the route. The first bounded implementation has one guide per line; trying a
different guide explains that the existing route must be removed first. It never
silently replaces a route or creates another rope.

The line's total paid-out length covers both legs. Its existing three-body rope
constraint transmits tension to both endpoints and the actual guide holder, including
its bend load. Visual rope runs through the same ring. Offsetting a visual line alone
is not routing. A guide that is removed from its mounting remains the physical guide
while carried or loose; a deleted guide releases the route cleanly. Saves add optional
route references through existing item/end identity, with old saves defaulting to a
direct line. Existing hooks and attachment sockets retain their identities and saves.


### Generic routing as built

The existing rope-end id now uses `RopeTip.route_at(player)`, also available to a
bundle's selected end. It answers only when the aim meets a fitted hook. A plain
label shows the live Use action binding and whether it passes through or removes
the route. Normal endpoint tying, magnetic sockets, placement and waist transfer
remain the physical actions. A second guide is refused until the first is removed;
a laid line too short for a proposed path asks for more payout rather than creating
rope or deliberately snapping it. Held-end reach subtracts the other leg's length.

Regular ropes initialize the real guide's solver body and draw two legs through
that guide. Optional saved through references use the existing part/end identity;
old saves have no route. Player-made routes also keep their deed eligibility and
loaded time. The Fairlead action hook requires a player-routed line carrying at
least 10 N sustained load for 1 s (tuning data); deed-table registration is combined
with the sailing work.

In an unseen 1280×720 interaction fixture: place hook by hand, take a real coil,
tie the first end, Use at the hook while holding the second, then tie the second
end normally. Both endpoint ties and routing succeeded. Its two-leg path was
4.019 m with 4.519 m paid out; the drawn physics point at the ring differed by
0.0 m. Snapshot saved the physical guide reference and an in-place restore
reconnected it to the restored physical holder. A separate headless repeat of
that restore passed without exit cleanup warnings. This is a controlled interaction
fixture, not an unassisted sailing expedition or a measured boom validation.

The old automatic hidden tow constraint has been removed from the solver. The
legacy `hidden` value remains null and `link_pair()` returns no inferred connection
until their old callers/checks are migrated with the sailing integration. Existing
`_towing()` remains solely the planter-towing deed accounting. Built-in sheets and
new boom mechanics require the separate sailing integration before full verification.

The solver's rigid-body lever arms and point velocities must be measured from
the actual centre of mass, including fitted-device mass offsets. Godot's impulse
application API still takes an offset from the body origin; these two coordinate
conventions must remain distinct. The physical-boom check exposed the previous
origin-as-centre assumption.

A freely hinged boom's rope response includes its carrier and every boom on that
carrier. The custom rope iteration uses the positive mass matrix for total-COM
translation, carrier rotation and each relative hinge spin, including cross
terms and parallel-axis inertia. Actual impulses are applied only at real rope
points; Jolt supplies the hinge reactions. This prevents the rope's stiffness
and closing prediction from crediting translations or rotations blocked by the
hinge, without imposing an angle target or duplicating reaction torque.
## Sailing handling follow-up (Hunter, 2026-10-20)

A sole live connected rope works without an explicit carry-view selection. A held
line still wins; with several waist ropes the selected line is the one worked.
Looking around does not change that choice. This supersedes the previous requirement
to select even a single rope.

The yank action gives the worked rope a short, faster haul through the existing
strength-limited reel. It changes rope length over physics ticks, never the rig's
rotation or either body's velocity directly. Its travel, duration and recovery are
tuning data; slack takes up before a load can turn anything. It shares the physical
hand stroke and rope sound. Rotating an ordinary held object keeps its existing
interaction. Carry-view rope labels use the theme's UI type, with numeric readouts
remaining in the established numeric style elsewhere.

The earlier proposed batch transfer on planting a stake is on hold. Hunter is
considering holding Use to untie successive waist ends into a hand-held bundle,
then dropping or fastening the gathered ends through the normal interactions. No
new dedicated batch-mooring key is wanted. Bundle representation and transfer
semantics are still a design discussion; the sole-rope fallback and yank do not
implement them.

As built for this follow-up: the yank requests at most 0.5 m over 0.2 s,
followed by 0.4 s recovery. The normal tension/hand-strength slowdown still
applies; any remainder is cancelled when the stroke ends or a menu interrupts
it. A held ordinary object retains its rotation action. Quick Haul records an
actual stroke of at least 0.1 m against a measured load of at least 20 N.

Focused checks on Godot 4.7.2: existing Rope 16 passed with the sole-line
fallback added (7 s), Rope 13's ordinary reeling passed (29 s), and Rope 18's
selected untie/save passed (9 s). Rope 20 exercised the actual yank binding,
selected-line isolation, recovery, end of haul and ordinary-held-object priority
(5 s). Its isolated fixture enables deed counting and earns Quick Haul through
the physical haul, without calling the deed directly. These checks do not yet
establish final Varran handling with the new articulated boom.

### Sailing disassembly and ground recovery (built 2026-10-20; integration pending)

Playtest reports concern removal of the sail and rope detachment from the board
(the board corrects the initial report of a sail-end detachment bug). Trace the
actual pick ray before assigning a cause. All physical boom hits must map back
to their removable fitted sail, and visible board tie ends must remain pickable
through normal take interactions. No new detachment action.

A fully loose line lying on the ground can be recovered by aiming at its
strand and taking it, preserving its total length as a coil. A line still
anchored at either end must not be silently detached or reeled from an arbitrary
middle point: take its loose end instead. Snapped halves obey the same rule.
Check occlusion and reach, plus persistence and no duplicate rope.

**As built and measured.** A real ray against the new articulated spar previously
returned no removable object; the focused sail-take check failed twice before
mapping the physical boom back to its fitted sail, then passed (7 s). Occupied
tie knots receive bounded, front-side, occlusion-checked aiming assistance.
A device hit now permits the existing small-item assist, fixing a reproduced
case where a dropped end beside a stake lost to the stake's occupied socket.
Board-hook detachment followed by floor-end pickup preserves the far anchor (7 s).
The original exact playtest setup is not known.

Taking the middle of a fully loose strand gathers and reopens that same Line;
its full length is retained and no second rope appears (6 s). A partly anchored
line still requires its free end. Ground-strand targeting checks reach and
line of sight. Actual pulley captures revealed spline overshoot above a sharp
guide: only the two curve links adjoining the real guide now follow their
legs, on CPU and GPU. A focused curve check keeps the displayed bend on the
pulley (9 s); rope forces and paid lengths are unchanged.


**Integration correction (2026-10-20).** Ring-hole aiming assistance applies
to tie sockets supplied by fitted hooks. It must not replace a hit on a
carryable stake's own frame: taking the stake whole, with its line attached,
remains the camp-towing interaction. Native tie knots remain directly pickable.
Sailing tow fixtures identify sheet and tow lines separately from the new
halyard, and keep the halyard in ordinary rope accounting.

The combined-candidate regression reproduced all three CI failures locally.
After restricting assistance, whole-stake pickup and a 40 m camp tow pass
(35 s), and the board's full take, mount, charging and save cycle passes
(67 s). Hook-end detachment and floor-end recovery still pass (9 s). The
corrected tow fixture passes its original steering, opposed-load injury and
selected-line reeling thresholds with all three real ropes intact (28 s).

### Coils remain usable outside their original find (2026-10-20)

Ordinary pickup must turn any loose rope coil into a usable line, including a
coil no longer registered as a find and an older authored coil without rolled
metadata. Preserve a stored rope length and reuse an existing Line when present.
Claiming loot and opening a coil are separate operations: a previously claimed
coil must not depend on claiming the original site again.

As built: pickup opens the coil independently of site claiming, and legacy
bare coils acquire the normal rolled-coil conversion. Existing Lines are reused.
Both previously owned rolled coils and authored bare coils failed the same hand
end check before the fix; both pass afterward (6 s), including stored length.
Carried-coil save/restore (13 s), board-end recovery (7 s), and all 35 salvage
part pickups (40 s) also pass. The held-end motion report is investigated
separately; these results do not establish its cause.

### Rope display frame check (2026-10-20)

Moving routed lines must meet their visible endpoints and guide in one frame.
An actual unseen moving-sheet capture checked 89 drawn frames with the current
project's physics interpolation disabled: interpolated guide queries and current
transforms matched, with zero displayed guide offset. No strand or shader change
was justified by that check. It does not establish every rope motion case.

### Coil ownership while laying a line (agreed correction, 2026-10-20)

A fresh line's remaining coil belongs to its paying end. Before the first tie
that end is on the belt; after attaching the first end, it comes into the hand.
The visual coil must follow that same end even when an older waist line remains
selected for reeling. Keep line identity, endpoint ownership, paid length and
control selection unchanged. Verify the ordinary first tie and walking handoff,
then using a fitted hook to route without tying down the held end.

**As built and measured.** With an older waist line selected, the ordinary
new-coil pickup, first tie and two-metre walk reproduced a coil 1.251 m away
from the held paying end. The end itself moved 1.953 m with the player and
retained no attachment offer. The visual coil now reads the active laying line
independently of reel selection and follows its remaining end through the handoff.
The focused check passes (9 s), as does selected-line reeling (9 s). An actual
GPU capture places the coil 0.129 m below the held tip; using a real fitted hook
routes that same line while its paying end remains free in the hand. Strand
simulation, rope length, reel selection and force response are unchanged.

The gathered display uses the same cached native coil mesh as loose rope. Three
visual fill variants correspond to thirds of gathered/full length. Choose a
variant instead of scaling fibre diameter; orient its local winding axis toward
the existing hand-facing normal and centre it from its actual mesh bounds.
This changes appearance only and retains the active-end ownership above.

With the shared mesh adapter, the paying-coil check passes again (8 s). The
actual unseen handoff/routing fixture passes and its capture shows the layered
coil aligned with its held endpoint (0.135 m hanging offset), with unchanged
1.953 m endpoint travel and successful hook routing. Native mesh bounds centre
each fill variant; their fibre diameter stays fixed.


## Continuous gathered coil (Hunter, 2026-10-20; agreed, in progress)

Paying out and gathering must change the bundle continuously, including the old
one-third and two-thirds boundaries. Read the actual remaining rope, including
line paid through a sail block; never change rope physics, ownership or selection.
Keep fibre gauge constant and the leading end fixed to the live hand/waist end,
without recentering against changing bounds. A loose stowed coil remains full.

Use one shared cached indexed tube mesh with a coil-only fibre shader. Deform
its fixed topology continuously along the winding path using an instance amount;
create no mesh or material resources while reeling. Keep the existing sun-worn
brown fibre and muted teal whipping. Smooth only presentation
amount/orientation, never delay the physical attachment point. Geometry and
response values live in `rope_coil_visual` tuning. Check small changes across the
former thresholds, near empty/full and while the paying hand moves; inspect real
unseen GPU captures before acceptance.

**As built and checked.** The cached indexed mesh has 1,631 vertices and 3,258
triangles; its raw position/normal/UV/index arrays total 91,288 bytes before GPU
packing. Each display changes one instance amount and its anchored transform;
there is no pose bank or per-frame mesh/material creation. A short response
filter smooths physics-step amount and heading while the leading end follows
the actual endpoint immediately. Existing moving-hand and hand-reeling probes
pass (9 s and 30 s); the focused continuity probe passes (9 s), including both
former thresholds and near-empty/full amounts. Real Forward+ captures at 720p
show all those states without a mesh swap. The visual-only sweep suspends rope
solving after the real handoff checks because a synthetic zero physical length
otherwise drops the held end and switches the display to an older waist line.
No rope force, paid length, attachment, control or save behavior changed.

The tube's end disks use outward clockwise winding; the focused cap probe
checks both complete disks and their outward orientation (3 s). A tangent-matched
lead avoids folding the first winding back on itself. Muted three-lobe fibre
relief and normal twist retain nominal gauge. Actual front, back and oblique
held captures show closed ends; the continuity probe still passes (8 s).

The existing `rope_end` part now shows three laid fibre cords with compact teal
whipping instead of its brown placeholder box. Catalog identity, collider,
attachment tip and controls remain unchanged. The native mesh uses the existing
worn material and fits the original 0.05 × 0.05 × 0.08 m envelope. The paying-hand
check passes again (7 s). Isolated end and front/back/oblique coil captures were
inspected; the synthetic fill sweep hides stale world strands while rope solving
is suspended, so those strands cannot obscure the coil's cap geometry.

A separate live GPU fixture uses ordinary wheel actions with the rope solver and
world strand active throughout: the held line reels from 3.463 m to 1.463 m and
pays back to 3.463 m without losing its end. It captures 150 rendered frames,
including the gathered coil and live strand together. This complements the
isolated synthetic fill sweep; neither is a GPU frame-time measurement.

## Gather waist ends in hand (Hunter, selected 2026-10-21)

With empty hands and no more specific Use interaction, begin the existing
one-second untie for the selected waist line (or the sole live line). A tap
still returns that end normally. Deliberately keep Use held after it arrives
to untie further waist ends, one full second each, in their existing tie order.
Releasing Use, opening a menu or aiming at device/ground work cancels the next
transfer, leaving ends already gathered in hand. No dedicated action, instant
waist-wide transfer, line fusion or automatic simultaneous reeling. A fresh
Use with the held knot retains the ordinary waist/guide/device interaction.
An already formed knot tied at the waist is one physical tie: returning it
uses the existing one-second untie, like a stake carrying several lines.

The first actual RopeTip remains the carried body. Each further original end
is fitted into a real marked child Socket using the existing nested-part
mechanism, as a loose hook already carries its end. Every Line/Rope, tip,
length, strength and fairlead route remains distinct. Loose knot mass includes
all its original ends; fitted ends contribute their own mass through ordinary
device sockets, exactly once. Dropping gives the whole knot the normal player
momentum. Fitting it to an existing free anchor is the ordinary take action.
Taking the primary knot uses the ordinary group-preserving pop path, so the
whole knot returns to hand; deliberately aiming at a secondary end's own
geometry can still remove that individual fitting.

The carry-view rope picker and reel retain an individual active member; a held
group takes priority over waist ropes and its first live member is the fallback.
Gathering itself never changes a rope's length or applies a body impulse. The
original timed release-all behavior remains available. A resumed game restores
physical nested fittings and the active member, but never fabricates a held
Use gesture or resumes automatic continuation.

Persistence contract: RopeBundle.prepare(primary, count) recreates the primary's
ordered own sockets before Snapshot restores its existing added fittings.
Save the count as optional bundle_slots; absent means the ordinary end.
Reuse the normal precreated Line-end refs and nested socket ownership. After
ordinary reconstruction, RopeBundle.refresh_mass(primary) restores aggregate
loose mass or own fitted mass; selection is a separate original-end ref.
Implementation and focused interaction/roundtrip checks are pending.
