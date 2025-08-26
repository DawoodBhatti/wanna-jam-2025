# removal_servoce.gd
# Centralised service for handling building removal and preview logic.
# Supports both single removal (lookup by name) and multiple mode (cached build data).
extends Node
class_name RemovalService

@onready var _rules: RemovalRules = get_node("../RemovalRules")

func commit_removal(level: Node, target_type: String, cell: Vector2i) -> void:
	if not _rules.is_removal_valid(cell, target_type):
		return

	SignalBus.emit_logged("remove_building_requested", [{
		"layer": "StructuresLayer",
		"cell_pos": cell,
		"target_type": target_type
	}])

	level.structures_layer.set_cell(cell, -1)

	SignalBus.emit_logged("building_removed", [{
		"layer": "StructuresLayer",
		"cell_pos": cell,
		"target_type": target_type
	}])

func preview_removal(level: Node, target_type: String, cell: Vector2i) -> void:
	level.ghost_layer.clear()
	if _rules.is_removal_valid(cell, target_type):
		var tile_id = _rules.get_preview_tile_id_for_type(target_type)
		if tile_id != -1:
			level.ghost_layer.set_cell(cell, tile_id)
			level.ghost_layer.modulate = Color(1, 0, 0, 0.5) # semi‑transparent red

func clear_preview(level: Node) -> void:
	level.ghost_layer.clear()
	level.ghost_layer.modulate = Color(1, 1, 1, 1) # reset tint
