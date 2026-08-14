extends Node
# Autoload. Loads every item .tres at startup into one lookup by id, so
# gameplay code can fetch an item without knowing where it lives on disk.
# data/items.csv is only ever read by the generator, never at runtime.

const ITEMS_DIR := "res://data/items/"

var items: Dictionary = {} # id (String) -> ItemData

func _ready() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("No items directory at " + ITEMS_DIR + " - run tools/generate_items.gd")
		return

	for file_name in dir.get_files():
		if file_name.get_extension() != "tres":
			continue # Skips the .import sidecars Godot writes next to each file.
		var item: ItemData = load(ITEMS_DIR + file_name)
		items[item.id] = item

# Returns the item with this id, or null if there isn't one.
func get_item(id: String) -> ItemData:
	return items.get(id)
