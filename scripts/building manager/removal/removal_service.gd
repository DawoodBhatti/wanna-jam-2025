extends Node
class_name RemovalService

@onready var _rules: RemovalRules = get_node("../RemovalRules")

# -------------------------------------------------------------------
# PUBLIC API – SINGLE REMOVAL MODE
# -------------------------------------------------------------------

func commit_removal(level: Level, target_type: String, cell: Vector2i) -> void:


	if not _rules.is_removal_valid(cell, target_type):
		return

	level.structures_layer.set_cell(cell, -1)

	SignalBus.emit_logged("building_removed", [{
		"layer": "StructuresLayer",
		"cell_pos": cell,
		"target_type": target_type
	}])


# -------------------------------------------------------------------
# PUBLIC API – CLEANUP
# -------------------------------------------------------------------

func clear_preview(level: Level) -> void:
	level.ghost_layer.clear()
	level.ghost_layer.modulate = Color(1, 1, 1, 1)

# -------------------------------------------------------------------
# PREVIEW
# -------------------------------------------------------------------

func preview_removal(level: Level, target_type: String, cell: Vector2i) -> void:

	level.ghost_layer.clear()

	if _rules.is_removal_valid(cell, target_type):
		var preview_def: Dictionary = _rules.get_preview_tile_def_for_type(target_type)
		if not preview_def.is_empty():
			level.ghost_layer.set_cell(cell, preview_def["source_id"], preview_def["atlas_coords"])
			level.ghost_layer.modulate = Color(0.75, 0, 0, 0.5)
