# removal_service.gd
# Handles validation, preview, and commit logic for tile removal.
# Uses cached tile data and supports single-cell and multi-cell interactions.

extends Node
class_name RemovalService

# -------------------------------------------------------------------
# NODE REFERENCES
# -------------------------------------------------------------------
@onready var _rules: RemovalRules = get_node("../RemovalRules")


# ===================================================================
# 1. PUBLIC API – REMOVAL MODE (CACHED TILE DATA)
# ===================================================================

## Commits a single removal to the level using cached tile data.
func commit_removal_with_data(level: Level, tile_data: Dictionary, cell: Vector2i) -> void:
	_commit_removal_internal(level, tile_data, cell)


## Previews a single cell in the ghost layer using cached tile data.
func preview_cell_with_data(level: Level, tile_data: Dictionary, cell: Vector2i) -> void:
	_preview_cell_internal(level, tile_data, cell)


# ===================================================================
# 2. PUBLIC API – CLEANUP
# ===================================================================

## Clears the ghost layer and resets its tint.
func clear_preview(level: Level) -> void:
	level.ghost_layer.clear()
	level.ghost_layer.modulate = Color(1, 1, 1, 1)


# ===================================================================
# 3. INTERNAL IMPLEMENTATION
# ===================================================================

## Internal: Commits a single removal if valid.
func _commit_removal_internal(level: Level, tile_data: Dictionary, cell: Vector2i) -> void:
	if tile_data.is_empty():
		return

	var tile_name: String = tile_data.get("tile_name", "")
	if not _rules.is_removal_valid(cell, tile_name):
		return

	var target_layer: TileMapLayer = level.get_node_or_null(tile_data.get("build_layer", "")) as TileMapLayer
	if target_layer == null:
		push_error("[RemovalService] Missing target layer for removal: %s" % tile_name)
		return

	# Remove the tile from the level
	target_layer.set_cell(cell, -1)

	# Remove from TileState if trackable
	if tile_data.get("trackable", false):
		TileState.remove_tile(tile_name, target_layer, cell)

	SignalBus.emit_logged(
		"building_removed",
		[{"layer": tile_data.get("level_layer", ""), "target_type": tile_name, "cell_pos": cell}]
	)


## Internal: Previews a single cell in the ghost layer.
func _preview_cell_internal(level: Level, tile_data: Dictionary, cell: Vector2i) -> void:
	level.ghost_layer.clear()

	if tile_data.is_empty():
		return

	var tile_name: String = tile_data.get("tile_name", "")
	var valid: bool = _rules.is_removal_valid(cell, tile_name)

	if valid:
		var tile_coords: Vector2i = tile_data["tiles"][0] as Vector2i
		level.ghost_layer.set_cell(cell, tile_data["source_id"], tile_coords)
		level.ghost_layer.modulate = Color(0.75, 0, 0, 0.5) # red
	else:
		level.ghost_layer.modulate = Color(0.5, 0.5, 0.5, 0.5) # grey


# ===================================================================
# 4. MULTI-CELL PREVIEW
# ===================================================================

## Previews multiple cells as one shape.
## If *all* cells are valid, the whole shape is tinted red; otherwise grey.
func preview_multiple_with_data(level: Level, tile_data: Dictionary, cells: Array) -> void:
	level.ghost_layer.clear()

	if tile_data.is_empty():
		return

	var tile_name: String = tile_data.get("tile_name", "")
	var tile_coords: Vector2i = tile_data["tiles"][0] as Vector2i

	# Check if all cells are valid
	var all_valid := true
	for cell in cells:
		if not _rules.is_removal_valid(cell, tile_name):
			all_valid = false
			break

	# Draw all cells in the ghost layer
	for cell in cells:
		level.ghost_layer.set_cell(cell, tile_data["source_id"], tile_coords)

	# Tint the whole layer
	if all_valid:
		level.ghost_layer.modulate = Color(0.75, 0, 0, 0.5) # red
	else:
		level.ghost_layer.modulate = Color(0.5, 0.5, 0.5, 0.5) # grey
