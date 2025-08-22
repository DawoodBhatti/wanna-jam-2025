# PlacementService.gd
# Centralised service for handling building placement and preview logic.
# Supports both single placement (lookup by name) and painting mode (cached build data).
# This keeps placement rules, tilemap updates, and signal emissions consistent.

extends Node
class_name PlacementService

@onready var _rules: Node = get_node("../PlacementRules")

# -------------------------------------------------------------------
# PUBLIC API – SINGLE PLACEMENT MODE
# -------------------------------------------------------------------

## Places a building tile by looking up its build data from the catalog.
## Use this for one‑off placements where performance is not a concern.
## @param level: The Level node containing tile layers.
## @param building_name: The string key for the building in BuildCatalog.
## @param cell: The grid cell position to place the building at.
func commit_tile(level: Node, building_name: String, cell: Vector2i) -> void:
	var build_data: Dictionary = BuildCatalogue.get_build_data(building_name)
	_commit_tile_internal(level, build_data, cell)

## Shows a ghost preview for a building by looking up its build data.
## Use this for hover previews in single placement mode.
func preview_cell(level: Node, building_name: String, cell: Vector2i) -> void:
	var build_data: Dictionary = BuildCatalogue.get_build_data(building_name)
	_preview_cell_internal(level, build_data, cell)

# -------------------------------------------------------------------
# PUBLIC API – PAINTING MODE (CACHED BUILD DATA)
# -------------------------------------------------------------------

## Places a building tile using pre‑fetched build data.
## Use this in painting mode to avoid repeated BuildCatalog lookups.
func commit_tile_with_data(level: Node, build_data: Dictionary, cell: Vector2i) -> void:
	_commit_tile_internal(level, build_data, cell)

## Shows a ghost preview using pre‑fetched build data.
## Use this in painting mode to avoid repeated BuildCatalog lookups.
func preview_cell_with_data(level: Node, build_data: Dictionary, cell: Vector2i) -> void:
	_preview_cell_internal(level, build_data, cell)

# -------------------------------------------------------------------
# PUBLIC API – CLEANUP
# -------------------------------------------------------------------

## Clears any ghost preview tiles from the ghost layer.
## Call this when exiting placement or painting mode.
func clear_preview(level: Node) -> void:
	level.ghost_layer.clear()

# -------------------------------------------------------------------
# INTERNAL IMPLEMENTATION
# -------------------------------------------------------------------

## Internal helper to commit a tile to the structures layer.
## Handles placement rules, tilemap updates, and signal emissions.
func _commit_tile_internal(level: Node, build_data: Dictionary, cell: Vector2i) -> void:
	# Validate placement
	if not _rules.is_valid(cell, build_data.source_name):
		return

	# Emit request signal (auditable)
	SignalBus.emit_logged(
		"place_building_requested",
		[{"layer": "StructuresLayer", "source": build_data.source_name, "cell_pos": cell}]
	)

	# Place tile in the structures layer
	var tile_coords: Vector2i = build_data.tiles[build_data.source_name]
	level.structures_layer.set_cell(cell, build_data.source_id, tile_coords)

	# Emit placed signal
	SignalBus.emit_logged(
		"building_placed",
		[{"layer": "StructuresLayer", "source": build_data.source_name, "cell_pos": cell}]
	)

## Internal helper to preview a tile in the ghost layer.
## This does not commit the tile — it only updates the ghost layer for visual feedback.
func _preview_cell_internal(level: Node, build_data: Dictionary, cell: Vector2i) -> void:
	level.ghost_layer.clear()
	var tile_coords: Vector2i = build_data.tiles[build_data.source_name]
	level.ghost_layer.set_cell(cell, build_data.source_id, tile_coords)
