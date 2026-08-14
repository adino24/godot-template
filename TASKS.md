# Template Tasks

Open work on the template itself. Rules and methodology live in
`RULEBOOK.md`; this file is just status.

## Now — make the template run clean out of the box
Both are editor-side and quick. Until they're done, a fresh clone errors
on first Play, so do these before handing anyone the repo.

- [ ] **Seven Input Map actions** (Project Settings → Input Map).
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

  Per action: type the name into **Add New Action** → **Add**, then click
  **+** on its row and press the key, once per binding.

- [ ] **Register `ItemDatabase` as an autoload** — Project Settings →
  Globals → Autoload, path `res://scripts/item_database.gd`, name
  `ItemDatabase`.

## Verify once those are done
- [ ] Open `scenes/main.tscn`, press Play, choose **Select Current** to
  set it as the main scene. Expect a 640x360 window with a Godot icon
  drivable on WASD, and a clean Output panel.
- [ ] Run `tools/generate_items.gd` from the Script Editor (File → Run,
  `Ctrl+Shift+X`). Expect `data/items/example_item.tres` and
  "Item generation done."
- [ ] Confirm `data/items.csv` shows **Keep File (No Import)** in the
  Import dock. The `.import` was set by hand, so it's worth eyeballing
  once — if Godot disagrees it will have rewritten it.

## Later
- [ ] Consider a `.gitignore` entry or export-preset exclusion for
  `tools/` so EditorScripts don't ship in release builds.
