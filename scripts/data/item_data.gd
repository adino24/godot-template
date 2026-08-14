class_name ItemData extends Resource
# Data shape for one item - the fields every item has. Instances live as
# .tres files in data/items/, generated from data/items.csv.
# Rename and reshape this per project; the pipeline around it is the same
# whether the things are items, enemies, weapons or upgrades.

# Which kind of extra handling this item needs at runtime. A shared
# handler branches on this, so adding items stays data entry, not code.
enum EffectType { STAT_ONLY, MULTI_HIT, OVER_TIME }

@export var id: String = "" # snake_case key, also used as the .tres filename.
@export var display_name: String = "" # Shown in UI.
@export var description: String = "" # Shown in UI.
@export var effect_type: EffectType = EffectType.STAT_ONLY
@export var power: float = 1.0 # Placeholder stat - replace with real ones per project.
@export var icon: Texture2D # Assigned by the generator from assets/items/.
