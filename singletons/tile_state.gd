#tile_state.gd
#autoload to assist with tracking and management of tile effects

extends Node

# -------------------------------------------------------------------
# 🗂 Tile state schema (reference only)
# -------------------------------------------------------------------
# Keys are strings in the format:
#   "tile_name|layer_name|x grid pos,y grid pos"
# Example:
#   "MedusaTile|StructuresLayer|3,7"
#
# Values are dictionaries like:
#   { "effect_fired": false }
#
const TILE_STATE_SCHEMA: Dictionary = {
	"ExampleTile|StructuresLayer|3,7": {
		"effect_fired": false
	}
}

# 'incomplete' set because we only need to track tiles which apply effects
var medusa_tile_state = {}

# registry to route lookups based on tile_name
var tile_state_registry = {
	"MedusaTile": medusa_tile_state
}

# TODO can add things like progress meters for multiple turn effects
# such as terraforming local resource tiles or building structures...
# can also make the logic for effect tracking more complicated by adding
# one_shot or effect_timing keys to help decide.

# ===================================================================
# 1. Set methods to update dictionary
# ===================================================================

# add a tile entry to the dictionary
func add_tile(tile_name, level_layer, cell):
	var key = make_tile_key(tile_name, level_layer, cell)

	if tile_state_registry.has(tile_name):
		tile_state_registry[tile_name][key] = {
			"effect_fired": false
		}
		print("tracking tile: ", tile_name)
	else:
		push_error("this tile doesn't belong in the tile state....")
	

# remove a tile entry from the dictionary
func remove_tile(tile_name, level_layer, cell):
	var key = make_tile_key(tile_name, level_layer, cell)

	if tile_state_registry.has(tile_name):
		tile_state_registry[tile_name].erase(key)
	else:
		push_error("this tile doesn't belong in the tile state....")


# ===================================================================
# 2. Internal query engine
# ===================================================================

# flexible query across one or all tile dictionaries
# supports filtering by tile_names[], layer_names[], cell, and effect_fired
func _query_tile_states(tile_names = [], layer_names = [], cell = Vector2i(-999, -999), effect_fired = null):
	var results = []
	var dicts = []

	if tile_names.size() > 0:
		for tile_name in tile_names:
			if tile_state_registry.has(tile_name):
				dicts.append(tile_state_registry[tile_name])
	else:
		for d in tile_state_registry.values():
			dicts.append(d)

	for tile_dict in dicts:
		for key in tile_dict.keys():
			var meta = parse_tile_key(key)
			if meta.is_empty():
				continue

			var data = tile_dict[key]

			if layer_names.size() > 0 and not layer_names.has(meta["layer_name"]):
				continue
			if cell != Vector2i(-999, -999) and meta["cell"] != cell:
				continue
			if effect_fired != null and data.get("effect_fired", false) != effect_fired:
				continue

			results.append({
				"key": key,
				"meta": meta,
				"data": data
			})

	return results


# ===================================================================
# 3. External query wrappers - build your own!
# ===================================================================

# get all MedusaTile entries
func get_medusa_tiles():
	return _query_tile_states(["MedusaTile"])

# get all StoneTile entries
func get_stone_tiles():
	return _query_tile_states(["StoneTile"])

# get all tiles with unfired effects
func get_unfired_tiles():
	return _query_tile_states([], [], Vector2i(-999, -999), false)

# get all tiles on a specific layer
func get_tiles_on_layer(layer_name):
	return _query_tile_states([], [layer_name])

# get all tiles on multiple layers
func get_tiles_on_layers(layer_names):
	return _query_tile_states([], layer_names)

# get all unfired Medusa tiles on a specific layer
func get_pending_medusa_on_layer(layer_name):
	return _query_tile_states(["MedusaTile"], [layer_name], Vector2i(-999, -999), false)

# get tile state at a specific cell
func get_tile_at(cell):
	return _query_tile_states([], [], cell)

# get all tiles of specific types on specific layers
func get_tiles_by_type_and_layer(tile_names, layer_names):
	return _query_tile_states(tile_names, layer_names)


# ===================================================================
# 4. Utility functions
# ===================================================================

# build a composite key from tile name, layer name, and grid position
func make_tile_key(tile_name, layer, cell):
	return "%s|%s|%d,%d" % [tile_name, layer.name, cell.x, cell.y]

# parse a composite key into its components
func parse_tile_key(key):
	var parts = key.split("|")
	if parts.size() != 3:
		return {}
	var cell_parts = parts[2].split(",")
	return {
		"tile_name": parts[0],
		"layer_name": parts[1],
		"cell": Vector2i(cell_parts[0].to_int(), cell_parts[1].to_int())
	}
	# ===================================================================
# 5. Public API — State mutation helpers
# ===================================================================

## Marks the given tile's effect as fired.
## tile_key must be in the format: "tile_name|layer_name|x,y"
func set_tile_fired(tile_key: String) -> void:
	if tile_key == "":
		push_error("[TileState] set_tile_fired called with empty tile_key")
		return

	var meta: Dictionary = parse_tile_key(tile_key)
	if meta.is_empty():
		push_error("[TileState] Invalid tile key: %s" % tile_key)
		return

	var registry: Dictionary = tile_state_registry.get(meta["tile_name"], {}) as Dictionary
	if registry.is_empty():
		push_error("[TileState] No registry for tile type: %s" % meta["tile_name"])
		return

	if not registry.has(tile_key):
		push_warning("[TileState] No tracked tile found for key: %s" % tile_key)
		return

	registry[tile_key]["effect_fired"] = true
