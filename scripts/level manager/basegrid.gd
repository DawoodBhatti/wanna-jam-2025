# Level.gd
# --------
# Holds the TileMap layers that make up the playable world.
# Provides helper methods for coordinate conversion (mouse → cell).
# Does NOT contain any building logic — BuildingManager owns that.
# This keeps Level passive and reusable for procedural generation, AI, etc.

extends Node2D
class_name Level

# --- Layer references ---
@onready var structures_layer: TileMapLayer = %StructuresLayer
@onready var ghost_layer: TileMapLayer = %GhostLayer
@onready var ground_layer: TileMapLayer = %GroundLayer
@onready var water_layer: TileMapLayer = %WaterLayer

# --- Registry of gameplay layers ---
@onready var layers: Dictionary = {
	"StructuresLayer": structures_layer,
	"GroundLayer": ground_layer,
	"WaterLayer": water_layer
}

# --- Single-layer mouse → cell ---
func get_cell_under_mouse(layer: TileMapLayer) -> Vector2i:
	var local_pos: Vector2 = layer.to_local(get_global_mouse_position())
	return layer.local_to_map(local_pos)

# --- Multi-layer mouse → cell ---
func get_cells_under_mouse() -> Dictionary:
	var results: Dictionary = {}
	for layer_name in layers.keys():
		var layer: TileMapLayer = layers[layer_name]
		var local_pos: Vector2 = layer.to_local(get_global_mouse_position())
		results[layer_name] = layer.local_to_map(local_pos)
	return results

# --- Get all gameplay layers ---
func get_all_layers() -> Array[TileMapLayer]:
	return layers.values()

# --- Get a layer by its registry name ---
func get_layer_by_name(name: String) -> TileMapLayer:
	if layers.has(name):
		return layers[name]
	return null

# --- Find the first layer containing a tile with a given custom "name" ---
func find_tile_by_name(cell_pos: Vector2i, target_name: String) -> TileMapLayer:
	for layer_name in layers.keys():
		var layer: TileMapLayer = layers[layer_name]
		var tile_data: TileData = layer.get_cell_tile_data(cell_pos)
		if tile_data != null and tile_data.has_custom_data("name"):
			var custom_name: Variant = tile_data.get_custom_data("name")
			var tile_name: String = ""
			if typeof(custom_name) == TYPE_STRING:
				tile_name = custom_name as String
			else:
				tile_name = str(custom_name)

			if tile_name == target_name:
				return layer
	return null

# --- Optional: Find both the layer and the TileData for a given tile name ---
func find_tile_and_data_by_name(cell_pos: Vector2i, target_name: String) -> Dictionary:
	for layer_name in layers.keys():
		var layer: TileMapLayer = layers[layer_name]
		var tile_data: TileData = layer.get_cell_tile_data(cell_pos)
		if tile_data != null and tile_data.has_custom_data("name"):
			var custom_name: Variant = tile_data.get_custom_data("name")
			var tile_name: String = ""
			if typeof(custom_name) == TYPE_STRING:
				tile_name = custom_name as String
			else:
				tile_name = str(custom_name)

			if tile_name == target_name:
				return {
					"layer": layer,
					"tile_data": tile_data
				}
	return {}
