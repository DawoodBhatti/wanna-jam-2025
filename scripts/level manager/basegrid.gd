# Level.gd
# --------
# Holds the TileMap layers that make up the playable world.
# Provides helper methods for coordinate conversion (mouse → cell).
# Does NOT contain any building logic — BuildingManager owns that.
# This keeps Level passive and reusable for procedural generation, AI, etc.

extends Node2D

# References to the map layers
@onready var structures_layer: TileMapLayer = %StructuresLayer
@onready var ghost_layer: TileMapLayer = %GhostLayer
@onready var ground_layer: TileMapLayer = %GroundLayer
@onready var water_layer: TileMapLayer = %WaterLayer

# Convert mouse position to cell coordinates in a given layer
func get_cell_under_mouse(layer: TileMapLayer) -> Vector2i:
	var local_pos = layer.to_local(get_global_mouse_position())
	return layer.local_to_map(local_pos)
