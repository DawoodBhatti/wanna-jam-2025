# removal_rules
# Centralised removal validation logic.
# All actions call this before removing a tile.
extends Node
class_name RemovalRules

@onready var _level: Node = get_node("../../Level")
var debug_switch: bool = true

func debug_tile_info(layer: TileMapLayer, coords: Vector2i) -> void:
	if not debug_switch:
		return

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
				name = custom_name as String
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

# --- Main removal check ---
# --- Main removal check ---
# Returns true if the tile at `cell_pos` in StructuresLayer matches `target_type`
func is_removal_valid(cell_pos: Vector2i, target_type: String) -> bool:
	if debug_switch:
		print("[RemovalRules] Checking removal validity → type:", target_type, " cell:", cell_pos)

	var layer: TileMapLayer = _level.structures_layer

	# No tile at this position
	if layer.get_cell_source_id(cell_pos) == -1:
		if debug_switch:
			print("[RemovalRules] ❌ No tile source at", cell_pos)
		return false

	# Use BuildCatalogue's identity check
	var valid: bool = BuildCatalogue.is_tile_type(layer, cell_pos, target_type)

	if debug_switch:
		if valid:
			print("[RemovalRules] ✅ Removal valid for", target_type, "at", cell_pos)
		else:
			print("[RemovalRules] ❌ Tile does not match", target_type, "at", cell_pos)

	return valid
	
func get_preview_tile_id_for_type(target_type: String) -> int:
	if debug_switch:
		print("[RemovalRules] Getting preview tile ID for type:", target_type)

	var tile_def: Variant = BuildCatalogue.get_tile("StructuresLayer", target_type)
	if tile_def:
		if debug_switch:
			print("[RemovalRules] Preview tile ID:", tile_def.source_id)
		return tile_def.source_id

	if debug_switch:
		print("[RemovalRules] ⚠ No preview tile found for type:", target_type)
	return -1
