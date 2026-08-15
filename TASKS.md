# Template Tasks

Open work on the template itself. Rules and methodology live in
`RULEBOOK.md`; this file is just status.

## Now — make the template run clean out of the box
Both written directly into `project.godot` (plain text, `[input]` and
`[autoload]` sections) rather than through the editor UI — same result,
verify it stuck by opening Project Settings once.

- [x] **Seven Input Map actions** (Project Settings → Input Map).
  `scripts/player.gd` calls
  `Input.get_vector("move_left", "move_right", "move_up", "move_down")`,
  and undefined actions push an error *every physics frame* — it buries
  the Output panel within seconds.

  | Action | Bindings |
  |---|---|
  | `move_up` | W, ↑ |
  | `move_down` | S, ↓ |
  | `move_left` | A, ← |
  | `move_right` | D, → |
  | `fire` | Left Mouse Button, Space |
  | `interact` | E |
  | `pause` | Escape |

- [x] **Register `ItemDatabase` as an autoload** — path
  `res://scripts/item_database.gd`, name `ItemDatabase`.

## Verify once those are done
Needs the actual editor — no Godot CLI on this machine to check headless,
so this part is still on you:
- [x] Open the project in Godot once so it rewrites `project.godot`'s
  `[input]`/`[autoload]` blocks in its own canonical form (harmless, just
  confirms the hand-written entries parsed correctly). Confirmed —
  project opens and runs clean.
- [x] Open `scenes/main.tscn`, press Play, choose **Select Current** to
  set it as the main scene. Expect a 640x360 window with a Godot icon
  drivable on WASD, and a clean Output panel. Confirmed working.
- [x] Run `tools/generate_items.gd` from the Script Editor (File → Run,
  `Ctrl+Shift+X`). Expect `data/items/example_item.tres` and
  "Item generation done." Confirmed working.
- [x] Confirm `data/items.csv` shows **Keep File (No Import)** in the
  Import dock — already verified: `data/items.csv.import` has
  `importer="keep"`.

## Later
- [ ] Consider a `.gitignore` entry or export-preset exclusion for
  `tools/` so EditorScripts don't ship in release builds.
