extends Node
class_name RemovalRules

@onready var _level: Node = get_tree().get_root().get_node("Main/Level")

func debug_tile_info(layer: TileMapLayer, coords: Vector2i) -> void:

	var layer_name: String = layer.name
	var layer_path: NodePath = layer.get_path()

	var source_id: int = layer.get_cell_source_id(coords)
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(coords)
	var alt_tile: int = layer.get_cell_alternative_tile(coords)
	var tile_data: TileData = layer.get_cell_tile_data(coords)

	print("[RemovalRules] --- Inspecting layer:", layer_name, "(", layer_path, ") ---")

	if tile_data != null:
		var name: String = ""
		if tile_data.has_custom_data("name"):
			var custom_name: Variant = tile_data.get_custom_data("name")
			if typeof(custom_name) == TYPE_STRING:
				name = String(custom_name)
			else:
				name = str(custom_name)

		var output: String = "[RemovalRules] Tile @" + str(coords)
		output += " | Source:" + str(source_id)
		output += " | Atlas:" + str(atlas_coords)
		output += " | Alt:" + str(alt_tile)
		if name != "":
			output += " | Name:" + name

		print(output)
	else:
		print("[RemovalRules] No tile at", coords)


func is_removal_valid(cell_pos: Vector2i, target_type: String) -> bool:

	var layer: TileMapLayer = _level.structures_layer

	if layer.get_cell_source_id(cell_pos) == -1:
		return false

	var valid: bool = BuildCatalogue.is_tile_type(layer, cell_pos, target_type)

	return valid


# Returns a dictionary with source_id and atlas_coords for the GhostLayer preview.
# If missing, returns an empty dictionary.
func get_preview_tile_def_for_type(target_type: String) -> Dictionary:

	var def: Dictionary = BuildCatalogue.get_tile("GhostLayer", target_type)
	if def.is_empty():
		return {}

	if def["tiles"].size() == 0:
		return {}

	var def_coords: Vector2i = def["tiles"].values()[0]

	return {
		"source_id": def["source_id"],
		"atlas_coords": def_coords
	}
