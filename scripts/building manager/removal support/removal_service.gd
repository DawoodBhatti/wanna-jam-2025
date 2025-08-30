extends Node
class_name RemovalService

@onready var _rules: RemovalRules = get_node("../RemovalRules")

# ===================================================================
# 1. PUBLIC API – REMOVAL MODE
# ===================================================================

## Commits a single removal to the level if valid.
func commit_removal(level: Level, target_type: String, cell: Vector2i) -> void:
	_commit_removal_internal(level, target_type, cell)

## Previews a single cell in the ghost layer for removal.
func preview_removal(level: Level, target_type: String, cell: Vector2i) -> void:
	_preview_removal_internal(level, target_type, cell)


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
func _commit_removal_internal(level: Level, target_type: String, cell: Vector2i) -> void:
	if not _rules.is_removal_valid(cell, target_type):
		return

	level.structures_layer.set_cell(cell, -1)

	SignalBus.emit_logged("building_removed", [{
		"layer": "StructuresLayer",
		"cell_pos": cell,
		"target_type": target_type
	}])

## Internal: Previews a single cell in the ghost layer for removal.
func _preview_removal_internal(level: Level, target_type: String, cell: Vector2i) -> void:
	level.ghost_layer.clear()

	if _rules.is_removal_valid(cell, target_type):
		var preview_def: Dictionary = _rules.get_preview_tile_def_for_type(target_type)
		if not preview_def.is_empty():
			level.ghost_layer.set_cell(cell, preview_def["source_id"], preview_def["atlas_coords"])
			level.ghost_layer.modulate = Color(0.75, 0, 0, 0.5) # red


# ===================================================================
# 4. MULTI-CELL PREVIEW
# ===================================================================

## Previews multiple cells as one shape for removal.
## If *all* cells are valid, the whole shape is tinted red; otherwise grey.
func preview_multiple_with_data(level: Level, target_type: String, cells: Array) -> void:
	level.ghost_layer.clear()

	if target_type.is_empty():
		return

	# Check if all cells are valid for removal
	var all_valid := true
	for cell in cells:
		if not _rules.is_removal_valid(cell, target_type):
			all_valid = false
			break

	# Get the preview tile definition for this target type
	var preview_def: Dictionary = _rules.get_preview_tile_def_for_type(target_type)
	if preview_def.is_empty():
		return

	# Draw all cells in the ghost layer
	for cell in cells:
		level.ghost_layer.set_cell(cell, preview_def["source_id"], preview_def["atlas_coords"])

	# Tint the whole layer
	if all_valid:
		level.ghost_layer.modulate = Color(0.75, 0, 0, 0.5) # red tint for valid removal
	else:
		level.ghost_layer.modulate = Color(0.5, 0.5, 0.5, 0.5) # grey tint if any invalid
