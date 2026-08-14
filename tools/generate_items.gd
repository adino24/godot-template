@tool
extends EditorScript
# Reads data/items.csv and writes one ItemData .tres per row into
# data/items/. Run it from the Script Editor (File > Run, or
# Ctrl+Shift+X) after every CSV edit - nothing else regenerates them.
# The .tres files are output, never sources: hand-edit one and your
# change is gone the next time this runs.

const CSV_PATH := "res://data/items.csv"
const OUTPUT_DIR := "res://data/items/"
const ICON_DIR := "res://assets/items/"
const COLUMN_COUNT := 6 # Keep in sync with the CSV header row.

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open " + CSV_PATH)
		return

	file.get_csv_line() # Skip the header row - column order is fixed, see items.csv.
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < COLUMN_COUNT or row[0] == "":
			continue # Skips the blank trailing line most editors add at EOF.
		_write_item(row)

	print("Item generation done.")

# Builds one ItemData from a CSV row and saves it as its own .tres file.
func _write_item(row: PackedStringArray) -> void:
	var item := ItemData.new()
	item.id = row[0]
	item.display_name = row[1]
	item.description = row[2]
	item.effect_type = ItemData.EffectType[row[3]] # Turns "STAT_ONLY" text into the enum value.
	item.power = float(row[4])
	if row[5] != "":
		item.icon = load(ICON_DIR + row[5])
	ResourceSaver.save(item, OUTPUT_DIR + item.id + ".tres")
