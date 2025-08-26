# removal_rules.gd
# Centralised removal validation logic.
# All actions call this before removing a tile.
extends Node
class_name RemovalRules

@onready var _level = get_node("../../Level")

func is_removal_valid(cell_pos: Vector2i, target_type: String) -> bool:
	var tile_data = _level.structures_layer.get_cell_tile_data(cell_pos)
	if tile_data == null:
		return false
	print(tile_data)
	# Placeholder: match against the source_name of the tile
	return tile_data.source_name == target_type

func get_preview_tile_id_for_type(target_type: String) -> int:
	# Optional: return a special red overlay tile ID from your tileset
	# For now, just return the actual tile ID so the ghost matches the target
	var tile_data = BuildCatalogue.get_tile("StructuresLayer", target_type)
	return tile_data.source_id if tile_data else -1
