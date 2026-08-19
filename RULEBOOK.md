# Godot Project Rulebook

How we build games in Godot. This is the methodology, not a design doc —
it should be true of every game made from this template, regardless of
genre.

**Using this template:** clone it, rename the project, then work through
"Starting a new game" at the bottom. Every rule here has a *why*; when a
rule doesn't fit your game, the why is what tells you whether breaking it
is fine or whether you're about to have a bad month.

Per-game decisions do **not** go in this file. Each game keeps its own
`wiki/` — design, technical decisions, and system knowledge, maintained
as the game is built (section 7) — plus a root `TASKS.md` (status).

---

## 1. Project setup

These are set once, in `project.godot`, and are painful to discover late.

### Rendering (2D pixel art)
```ini
textures/canvas_textures/default_texture_filter=0   # Nearest, not linear
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```
Godot defaults to **linear** filtering, which blurs every sprite the
moment it scales. It's a project-wide setting, so it's invisible when
you're looking at any one scene — you just think your art is bad. The
snap flags stop sprites shimmering when they move at sub-pixel offsets.

### Window
```ini
window/size/viewport_width=640      # per-project: pick your base res
window/size/viewport_height=360
window/stretch/mode="viewport"
window/stretch/scale_mode="integer"
```
`viewport` renders the game at the low base resolution and scales the
whole frame up — the authentic pixel look. `integer` scaling prevents
some pixels being drawn 2px wide and their neighbours 3px.

Base resolution is one of the few genuinely per-game values. 640x360 is
16:9 and integer-scales cleanly to 720p and 1080p.

**Pick it on day one.** Changing it later is not a config edit. Every
absolute coordinate, every `font_size`, and any per-project pixel scale
moves with it — and all of them have to move in the *same commit*,
because the game is broken in between. Flipping the base resolution on
its own breaks every screen laid out in the old one, and setting
`scale_mode="integer"` on its own, over a base resolution that is already
large, clamps a big display to 1x inside black borders — worse than not
setting it at all.

### Texture import defaults
Pin the pixel-art import settings **project-wide** — nearest filter, no
mipmaps, no compression — as a project import default or preset, never
file by file.

The rendering setting above governs how a texture is *drawn*. Mipmaps and
compression soften it at *import*, before drawing is involved at all, so
the two are set separately — art still comes out soft with the filter
correct and compression left on. Doing it per-file means hand-editing
`.import` sidecars, which are committed (see version control below), so
every re-import on someone else's machine becomes a diff. Set the default
once and nobody ever opens a sidecar.

### Named collision layers
Name every physics layer you use, in Project Settings → Layer Names,
*before* you build anything that collides.
```ini
[layer_names]
2d_physics/layer_1="player"
2d_physics/layer_2="enemies"
2d_physics/layer_3="player_bullets"
2d_physics/layer_4="enemy_bullets"
2d_physics/layer_5="pickups"
2d_physics/layer_6="world"
```
Names change nothing mechanically. But unnamed layers mean every
collision decision is you counting unlabeled checkboxes, and "enemy
bullets shouldn't hit enemies" becomes a debugging session instead of a
five-second edit.

**Layer vs mask, since it's the classic confusion:** *layer* is what
this body **is**. *Mask* is what it **looks for**. A player bullet is on
`player_bullets` and masks `enemies` + `world`.

### Input map
Every input goes through a named action. Define them in Project Settings
→ Input Map:

`move_up` `move_down` `move_left` `move_right` `fire` `interact` `pause`

- **Never read a raw key in gameplay code.**
  `Input.is_action_pressed("move_left")`, never
  `Input.is_key_pressed(KEY_A)`. The action name is the indirection that
  buys you rebindable controls and gamepad support later for free.
- **Never use `ui_*` actions for gameplay.** They belong to Godot's UI
  focus system — any `Control` on screen will silently consume them, and
  your player starts drifting the moment a button takes focus.

### Version control
Godot's project-creation dialog generates `.gitignore` / `.gitattributes`
— use it. Two things people get wrong:
- `.godot/` is **ignored** (import cache, machine-specific).
- `.import` and `.uid` sidecar files are **committed**. Godot 4.4+ tracks
  script identity by `.uid`; dropping them breaks references.

---

## 2. Folder structure

```
assets/              art + audio source (subfolder per kind: fonts/, music/)
assets/art/          images, one subfolder per kind: ships/, icons/, ui/
data/                content instances: .csv sources + generated .tres
scenes/              one .tscn per game object or screen
scripts/             one .gd per scene, same basename
scripts/components/  reusable components
scripts/data/        Resource subclasses (the shape of your data)
tools/               EditorScripts: generators + checkers, never at runtime
```

**`scripts/` mirrors `scenes/` by name.** `scenes/player.tscn` pairs with
`scripts/player.gd`. Lowercase, no spaces, in both.

**The exception, stated so the rule doesn't look violated:** components
and data scripts have no scene of their own. They're pure code attached
to or loaded by other things.

**`scripts/data/` vs `data/`** is the distinction people get wrong.
`scripts/data/item_data.gd` defines *what fields an item has* — code, a
class, one file forever. `data/items/big_sword.tres` is *one actual
item* — content, and there will eventually be sixty. Shape lives with
the code; instances live in `data/`.

### Art is files, not code

**Never generate shipping art in code.** No sprite built at runtime out
of string maps, no game object drawn with `draw_rect` because that was
quicker than making a file. As prototype scaffolding it's fine, and often
faster. As the art path you actually ship, it means an artist cannot
contribute one pixel without editing GDScript — which in practice means
they don't contribute at all, and you stay the bottleneck on every visual
in the game.

**The filename is the link — no registry.** Art lives at
`assets/art/<kind>/<id>.png`, where the filename *is* the value already
sitting in the data's `sprite` / `icon` column. Dropping a file in the
folder puts it in the game: no code change, no data edit, nothing to
register anywhere. It's section 5's rule pointed at images — content is
data, and a file on disk is data.

Where one shared column value has to cover entries that must look
*different*, key the file by the entry's own unique id and keep the
shared column as a fallback for art that genuinely is shared.

**`modulate` is for transient effects, not content variants.** Flashing a
sprite white on hit is exactly what tinting is for. Recolouring one shape
into three "different" things works right until the art is painted rather
than generated — at which point all three need their own file anyway, so
the trick bought nothing and cost you a migration.

---

## 3. Architecture: composition over inheritance

Build game objects out of small, reusable **component** scripts attached
as child nodes, rather than deep class hierarchies (`Enemy` →
`FastEnemy` → `FastRangedEnemy`...). Godot's node/scene system is built
for this; class trees fight it.

### What a component is
- **One script, one job.** `HealthComponent`, `MovementComponent`,
  `FireComponent`, `ContactDamageComponent`.
- **It doesn't know what it's attached to.** `HealthComponent` tracks a
  number and announces when it changes. It has no idea whether it's on
  the player, an enemy, or a destructible crate — which is exactly why
  it works on all three.
- **Every component declares `class_name`**, lives in
  `scripts/components/`, and exposes its config as `@export` vars so it's
  tunable per-instance in the Inspector without touching code.
- **A game object is a scene** that attaches whichever components it
  needs. A new enemy variant is a new scene with a different mix of
  components — not a new script in a class tree.

Only reach for scene inheritance (one `.tscn` extending another) when
something is genuinely "a type of" its parent with no behaviour swapping.

### Call down, signal up
The single most important structural rule.

- A parent **may call methods on** its children.
- A child **never reaches up or sideways.** It emits a signal; whoever
  cares connects to it.
- `get_node("../OtherThing")` is a smell. It hard-codes a tree shape,
  and it breaks the moment the scene is reorganised or reused.

A component reading `get_parent()` to move or aim its owner is fine —
that's the component's declared contract, not upward coupling. Reaching
past the parent to a *sibling* is not.

### Connect signals in code
Connect in `_ready()` via `.connect(...)` rather than editor-only
connections, so behaviour is visible when reading the script instead of
hidden in the `.tscn`.

Simple UI button presses wired in the editor are an acceptable exception
— but be deliberate about it, don't drift into it.

Name signals for **what happened**, in past tense: `died`,
`health_changed`, `wave_started`. Not `on_death`, not `do_damage`.

### How one object finds another's component
This is the crux of composition, so pick one convention and hold it:

```gdscript
var health: Node = area.get_node_or_null("HealthComponent")
if health:
    health.take_damage(damage)
```

The bullet doesn't check *what it hit* — it checks *what that thing can
do*. Anything with a `HealthComponent` is damageable, whether it's an
enemy, a barrel, or the player. Nothing needs a shared base class.

Pair it with **groups for broad categories** (`is_in_group("enemies")`)
rather than type checks like `is Enemy`. Declare groups in
`[global_group]` so they autocomplete instead of being magic strings.

### Autoloads: use sparingly
An autoload is a global singleton. They're genuinely useful and heavily
overused — Godot's own docs push back on them.

Autoload only when one is true:
- a **stateless service** every scene needs (a content database), or
- **state that must outlive a scene change** (run progress, settings).

Everything else is a node in the scene, reached by `@export` or signal.

**Any autoload holding run-scoped state needs a `reset_run()`** that
`main.gd._ready()` calls. Autoloads survive `reload_current_scene()`, so
without it your second playthrough starts with stale numbers from the
first — and it presents as a bug nowhere near the autoload.

### Who owns the run
- **`main.gd` owns the run's state machine** and is the *only* thing that
  touches `get_tree().paused`.
- **Screens are dumb.** A results/loadout/debrief screen displays what
  it's handed and emits a signal when a button is pressed. It never
  pauses the tree, never advances state, never talks to other systems.
- Any screen that must stay clickable while paused sets
  `PROCESS_MODE_ALWAYS`.

Pausing the tree freezes enemies, timers and physics for free — much
better than stopping each system by hand.

### UI is scenes, not code
"Screens are dumb" is the split. This is how the screens get built.

- **Editor-placed nodes in a `.tscn`** — `Button`, `Label`,
  `TextureRect`, `TextureProgressBar` — not a tree assembled with
  `.new()` and then painted in `_draw()`. Populate it through an explicit
  `refresh()`-style call at state-transition points.
- **No per-frame `queue_redraw()` on UI that isn't animated.** A
  `_process()` whose whole body is a redraw is polling for a change some
  signal already knows about.
- **Template + instance when the count varies at runtime.** Give the
  repeated thing its own `.tscn` and `preload().instantiate()` one per
  item. Hand-building N copies in a loop is the same mistake as a script
  per item in section 5.
- **`_draw()` + `_process()` are correct for genuinely continuous
  visuals** — anything driven by gameplay time that really does change
  every frame. Leave those alone; converting them for the sake of
  consistency is how this rule gets misapplied. The target is static UI
  impersonating an animation.
- **Anchors and containers, not absolute coordinates.** Hardcoded pixel
  positions are precisely what turns a base-resolution change (section 1)
  from a settings edit into a whole-project refactor.

### Injected targets, not hardcoded ones
A component that needs something to act on takes it as a variable:

```gdscript
var target: Node2D = null   # set by whoever owns this component
```

Not `get_global_mouse_position()` baked into the component. That one
change is what lets the same `FireComponent` serve the player (aiming at
the closest enemy) and an enemy (aiming at the player).

### Recompute, don't patch
When modifiers/buffs/equipment change, recompute effective stats from
base + all active modifiers, from scratch. Never `fire_rate += x` on
equip and `-= x` on unequip — that drifts the first time an unequip is
missed or a modifier changes while active, and the drift is untraceable.

### One RNG per run, not global `randf()`
Any random decision that affects gameplay comes from a
`RandomNumberGenerator` instance you own, not global `randf()`. Casual
runs call `rng.randomize()`; seeded/challenge runs set `rng.seed`.

Adopting this on day one is free. Retrofitting it means auditing every
random call in the project.

---

## 4. Coding conventions

Taken from working code — match it.

- **Tabs** for indentation.
- **Static typing everywhere.** `var direction := Vector2.RIGHT`,
  `func _ready() -> void:`, `@onready var body: Node2D = get_parent()`.
  Typed `@onready` references are what give you autocomplete on your own
  components.
- `snake_case` functions/variables/filenames, `PascalCase` classes and
  node names, `SCREAMING_SNAKE_CASE` constants.
- **`class_name` on components and data classes; not on scene scripts.**
  Components and `Resource` subclasses are types you reference by name.
  A `player.gd` that drives exactly one scene isn't.
- **`@export` anything tunable**, so balancing happens in the Inspector,
  not in a text editor.
- **`const preload()` for fixed internals; `@export var ... = preload()`
  for anything that might be swapped.** The exported form gives you a
  sensible default *and* per-instance override.
- **Placeholder numbers live as `const` at the top of the file**, so a
  tuning pass is greppable rather than a treasure hunt.

### Write for humans, not for the machine

Code is read far more often than it's written, and the next person to
read it is usually you, eight months later, with none of the context you
have right now.

- **Every file opens with a short header comment** — one to three lines
  on what this script is and why it exists. Not what engine class it
  extends; that's already on line 1.
- **Every function you write gets a one-line comment above it** saying
  what it does. Describe the *what* and the *why*, not the *how* — the
  code is already the how.
- **Godot's lifecycle callbacks are exempt** — `_ready()`, `_process()`,
  `_physics_process()`, `_input()` and friends. Their names already say
  when they run, and restating that is noise. Comment *inside* them only
  where the body does something non-obvious.
- **Inline comments where the next human would otherwise stop and
  wonder.** Godot-specific behaviour, non-obvious math, a deliberate
  workaround, a magic number. If you had to think about it while writing
  it, write the sentence down.
- **Don't comment the obvious.** `# add 1 to the counter` above
  `counter += 1` is noise, and noise trains people to skip comments —
  including the one that mattered.
- **A comment that explains a workaround should say what breaks without
  it.** "Extra overlap so `Area2D` reliably detects contact — exactly
  tangent circles don't always register" tells you whether it's still
  needed. "Add 2px margin" doesn't.
- **Keep comments true.** A stale comment is worse than none, because
  it's believed. If you change what a function does, fix the line above
  it in the same edit.

### Simple over clever

Write like an experienced developer, which mostly means writing *boring*
code and using the engine instead of fighting it.

- **Prefer the obvious solution.** If two approaches work, take the one
  that can be read top to bottom without pausing. Cleverness is a cost
  paid by every future reader.
- **One function, one job.** If you need a paragraph to explain a
  function, it's probably doing two things — split it.
- **Guard clauses over nesting.** Return early on the cases that don't
  apply, then write the real logic unindented at the bottom.
- **Name things in the game's language.** `fire_rate`, `stop_distance`,
  `contact_margin` — not `val`, `tmp`, `data2`. A good name removes the
  need for a comment.
- **Use what Godot already gives you** — signals, groups, `Tween`,
  `Timer`, `move_toward`, `lerp`, `clamp`. Reimplementing engine
  features by hand is the most common way a project gets hard to read.
- **Don't build for the second case until the second case exists.** No
  abstraction layers, config systems, or manager classes for hypothetical
  future needs. Refactor when the second case actually shows up — you'll
  understand the problem much better then.
- **Unpack dense expressions.** Two named intermediate variables beat one
  clever chained line, and cost nothing at runtime.

**Testing:** no framework by default; verification is manual playtesting.
If a project grows logic worth testing (damage math, save/load, seeded
determinism), GUT and GdUnit4 are the two established options — decide
per project and write it down.

---

## 5. Data-driven content

The moment a game has more than a handful of items/enemies/upgrades,
stop writing a script per thing.

**The pipeline:**
```
data/things.csv          hand-edited source of truth
  → tools/generate_things.gd   (an EditorScript you run in-editor)
    → data/things/*.tres       one Resource per row — never hand-edited
      → ThingDatabase autoload loads them all into a lookup by id
```

**Why each stage exists:**
- **CSV as source of truth** — balancing sixty items means comparing them
  side by side. That's a spreadsheet job, not a fifty-file-clicking job.
- **Generated `.tres`** — Godot-native, so icons, references and the
  FileSystem dock all work normally. Regenerated, never hand-edited; an
  edit made directly to a `.tres` is lost on the next generate.
- **Autoload database** — gameplay fetches by id and never knows where
  anything is stored on disk.

**One sheet per kind.** The moment a single CSV serves several kinds of
thing and half its columns are blank on any given row, split it — one
sheet per kind, each carrying only the columns that kind actually uses.
Same generator, same database API, and every sheet becomes narrow enough
to read without scrolling sideways, which is the whole reason it's a
spreadsheet.

**Define the shape as a `Resource` subclass** in `scripts/data/`, with
`@export` fields — not a Dictionary and not JSON. You get static typing,
Inspector editing, and `preload`-ability.

**Static data holds no runtime state.** A `Resource` defines what a thing
*is* — shared by every run and every player. Anything per-run (owned,
level, equipped) lives in a separate structure that resets each run. Put
run state on a shared resource and it will leak between runs.

**Behaviour is data, resolved by a registry.** The rule underneath it:
*no content id ever appears in simulation code.* A bare `special` string
the sim tests for (`if thing.special == "shield"`) means every new
behaviour is an edit in every file that tests it, and those files are
never all in one place. Give the row an effects column instead —
pipe-separated `verb:args` (`shield:5`, `push:8`, `pierce`) — resolved
through one registry script where each verb is defined exactly once.
Several verbs per row, so variety comes from combinations instead of from
new code. Scaling from 3 to 60 should be data entry.

**Fail loudly at generation.** An unknown verb, an unknown column, or an
out-of-range value aborts the generator and names the row number. The
alternative is a silently inert entry that ships and gets found by a
playtester three weeks later, when nobody remembers touching it.

**Hot reload in dev mode.** A dev-only key that re-reads the sources and
rebuilds the database in the running game. It turns the tuning loop from
edit → regenerate → relaunch → replay back to where you were, into
edit → keypress. It costs an afternoon, and on a data-driven project it
is the largest workflow win available.

**`tools/` holds checkers, not just generators.** Make them
headless-runnable:
- a **balance report** — the whole pool as one table (cost, output, tier,
  weight) with rule breaks flagged: tier 1 out-performing tier 3, values
  out of band for their tier, weight 0, duplicate ids, verbs nothing
  uses.
- an **asset checker** — every `sprite`/`icon` value has a matching file;
  orphan files nothing references; files at the wrong canvas size.

Generation catches content that is *malformed*. These catch content that
is *wrong*, and wrong is the kind that ships.

**Prose is CSV's weak spot** — description and flavour text are quoted
strings full of commas. If it starts costing you, move the text to a
strings file keyed by id. Never move the *numbers* out: side-by-side
comparison is the reason the table exists at all.

---

## 6. Gotchas learned the hard way

- **Never spawn or free nodes synchronously inside a physics callback.**
  A bullet's `area_entered` killing the last enemy, which starts the next
  wave, which spawns an `Area2D` — crashes Godot's physics server
  ("can't change state while flushing queries"). Use
  `spawn_thing.call_deferred()`.
- **`queue_free()`, not `free()`.** `free()` deletes immediately, mid-
  frame, while other code may still hold the reference.
- **Check `is_instance_valid()`** before touching a node you stored
  earlier — especially anything from a signal that may have fired as part
  of a chain of deaths.
- **Don't let a node free itself in response to its own component's
  signal** if anything else is still listening to that component.
- **Autoloads survive `reload_current_scene()`.** See `reset_run()` above.
- **Instantiated projectiles are added to the current scene**, not to the
  shooter — otherwise they inherit the shooter's transform and drag along
  behind it.
- **Set any data `.csv` to "Keep File (No Import)".** Godot's default
  importer for `.csv` is *CSV Translation*, so a data file gets silently
  turned into `.translation` files — either junk in your `data/` folder,
  or a permanent `valid=false` in the `.import`. Select the file →
  Import dock → Import As → **Keep File (No Import)** → Reimport. Only
  the generator reads the CSV anyway; Godot should leave it alone.
- **A migration fallback needs its deletion criterion written down the
  day you add it.** Falling through to the old path for anything not yet
  converted is the right way to migrate — no long-lived branch, nothing
  ever broken, one entry converted at a time. But it is scaffolding, not
  a second permanent path. Left in, you keep a whole system nobody
  maintains, plus a silent failure mode: a typo'd filename quietly serves
  the old thing and looks like it worked. Say up front what "done" means,
  delete the old path when you reach it, and log when the fallback fires
  in dev so a typo is visible instead of invisible.

---

## 7. The game wiki

Every game keeps a `wiki/` — a small markdown knowledge base maintained
*as the game is built*, never written up afterwards. The code says
**how**; the wiki says **what exists and why**. Without it, every
return to the project starts by re-reading the codebase to reconstruct
intent, and that reconstruction is thrown away when the session ends.
The wiki is where it compounds instead.

The model is Karpathy's "LLM wiki" pattern, adapted: **sources** you
never edit (the code, scenes, and data — the truth), **synthesis** you
always maintain (the wiki), and a **schema** that keeps the maintainer
disciplined (this section). The wiki describes the sources; it never
contradicts them and never substitutes for them.

This replaces the separate `GDD.md` / `DECISIONS.md` files: design and
decisions are wiki pages. `TASKS.md` stays at the project root — it's
status and future work, not knowledge.

### Layout
```
wiki/
  index.md      every page, one line each, grouped by category
  log.md        append-only history: what changed and when
  design.md     what this game is — pitch, pillars, core loop, scope
  decisions.md  this game's technical choices and their why
  systems/      one page per game system: combat.md, waves.md, economy.md
```

**One page per system, not per file.** `scripts/` already mirrors
`scenes/`; the wiki mirrors the game's *mental model* — the layer the
folder structure can't show. A `combat.md` explains how damage,
i-frames, and knockback interact even though they live in five scripts.

### The three operations

- **Ingest — update in the same session the change lands.** A feature
  is finished when its wiki pages are revised, its `index.md` line is
  current, and a `log.md` entry is appended — not before. A wiki
  updated "later" is a wiki that lies, and a lying wiki is worse than
  none because it's believed. Same principle as "keep comments true."
- **Query — read `index.md` first, always.** Any work session, any new
  feature: open the index, then only the pages it points to. This is
  the whole payoff — resuming after eight months (or onboarding an
  agent cold) costs three pages, not the codebase.
- **Lint — sweep for rot occasionally.** Pages that contradict each
  other, claims the code has outgrown, pages nothing links to, file
  pointers that got renamed out from under you. Do a pass when the wiki
  starts feeling unreliable — roughly monthly during active work.

### What a page contains

- What the system does, how its parts connect, and which decisions
  shaped it — with the *why*, since that's the part the code can't say.
- **Pointers to files, never pasted code.**
  `scripts/components/health_component.gd` stays true when its contents
  change; a quoted snippet silently rots.
- **Cross-links to related pages.** A page nothing links to is a page
  nobody finds — the lint pass hunts these.
- **When a page restates a document that lives outside the wiki** — an
  art spec, an audio list, a brief someone else works from — say which of
  the two wins. The wiki is synthesis, and synthesis that silently
  disagrees with its source is worse than no page. Same principle as
  "keep comments true."

### log.md entries

Append-only, one entry per ingest, a consistent grep-able prefix:
```
## [2026-08-16] feature | Dash with i-frames
- Added DashComponent (scripts/components/dash_component.gd)
- Updated: systems/combat.md, systems/movement.md, index.md
- Decision: i-frames exist only during dash — see decisions.md
```
`index.md` tells you where things are; `log.md` tells you what happened
recently — the first thing to read when coming back after a gap.

---

## 8. Starting a new game from this template

1. Copy the template folder; rename it.
2. `project.godot` → `config/name`, and set your base resolution.
   Settle it now — section 1 says why moving it later is expensive.
3. Pin the project-wide texture import default (nearest, no mipmaps,
   no compression) before any art lands.
4. Adjust `[layer_names]` to the collisions your game actually has.
5. Adjust the Input Map to your control scheme.
6. Create the `assets/art/<kind>/` folders this game needs, so the
   first sprite has somewhere to go that isn't a script.
7. Delete the example component/data pipeline if the game doesn't need
   them; keep the folder skeleton.
8. Seed the `wiki/` (section 7): write `design.md` — pitch, pillars,
   core loop — *before* writing code, and put the first entry in
   `log.md`. Create a root `TASKS.md` (status).
9. Leave this file alone. Rules that turn out to be wrong get fixed
   **here**, in the template, so the next game inherits the fix.
