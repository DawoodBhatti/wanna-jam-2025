extends Node
class_name RemovalRules

@onready var _level: Node = get_tree().get_root().get_node("Main/Level")

# -------------------------------------------------------------------
# 🔍 Debugging helper
# -------------------------------------------------------------------
func debug_tile_info(layer: TileMapLayer, coords: Vector2i) -> void:
	var layer_name: String = layer.name
	var layer_path: NodePath = layer.get_path()

	var source_id: int = layer.get_cell_source_id(coords)
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(coords)
	var alt_tile: int = layer.get_cell_alternative_tile(coords)
	var tile_data: TileData = layer.get_cell_tile_data(coords)

	print("[RemovalRules] --- Inspecting layer:", layer_name, "(", layer_path, ") ---")

	if tile_data != null:
		var tile_name: String = ""
		if tile_data.has_custom_data("name"):
			var custom_name: Variant = tile_data.get_custom_data("name")
			if typeof(custom_name) == TYPE_STRING:
				tile_name = String(custom_name)
			else:
				tile_name = str(custom_name)

		var output: String = "[RemovalRules] Tile @" + str(coords)
		output += " | Source:" + str(source_id)
		output += " | Atlas:" + str(atlas_coords)
		output += " | Alt:" + str(alt_tile)
		if tile_name != "":
			output += " | Name:" + tile_name

		print(output)
	else:
		print("[RemovalRules] No tile at", coords)

# -------------------------------------------------------------------
# ✅ Valid removal check by tile name
# -------------------------------------------------------------------
func is_removal_valid(cell_pos: Vector2i, tile_name: String) -> bool:
	var def: Dictionary = TileCatalogue.get_tile(tile_name)
	if def.is_empty():
		push_error("[RemovalRules] Unknown tile: %s" % tile_name)
		return false

	var layer_node: TileMapLayer = _level.get_node_or_null(def.get("build_layer", "")) as TileMapLayer
	if layer_node == null:
		push_error("[RemovalRules] Layer not found for tile: %s" % tile_name)
		return false

	if layer_node.get_cell_source_id(cell_pos) == -1:
		return false

	return TileCatalogue.is_tile_type(layer_node, cell_pos, tile_name)

# -------------------------------------------------------------------
# 🖼️ Ghost preview definition lookup
# -------------------------------------------------------------------
func get_preview_tile_def_for_type(tile_name: String) -> Dictionary:
	var def: Dictionary = TileCatalogue.get_tile(tile_name)
	if def.is_empty():
		return {}

	if def["tiles"].size() == 0:
		return {}

	# We take the first Vector2i in the "tiles" array
	var def_coords: Vector2i = def["tiles"][0] as Vector2i

	return {
		"source_id": def["source_id"],
		"atlas_coords": def_coords
	}
