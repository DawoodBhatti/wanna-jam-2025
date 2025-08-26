# removal_servoce.gd
# Centralised service for handling building removal and preview logic.
# Supports both single removal (lookup by name) and multiple mode (cached build data).
# removal_servoce.gd
# Centralised service for handling building removal and preview logic.
# Supports both single removal (lookup by name) and multiple mode (cached build data).
extends Node
class_name RemovalService

@onready var _rules: RemovalRules = get_node("../RemovalRules")
var debug_switch: bool = false

func commit_removal(level: Level, target_type: String, cell: Vector2i) -> void:
	if debug_switch:
		print("[RemovalService] Commit request → type:", target_type, " cell:", cell)

	if not _rules.is_removal_valid(cell, target_type):
		if debug_switch:
			print("[RemovalService] ❌ Removal invalid for", target_type, "at", cell)
		return

	level.structures_layer.set_cell(cell, -1)

	SignalBus.emit_logged("building_removed", [{
		"layer": "StructuresLayer",
		"cell_pos": cell,
		"target_type": target_type
	}])

	if debug_switch:
		print("[RemovalService] ✅ Removed", target_type, "at", cell)


func preview_removal(level: Level, target_type: String, cell: Vector2i) -> void:
	if debug_switch:
		print("[RemovalService] Preview request → type:", target_type, " cell:", cell)

	level.ghost_layer.clear()

	if _rules.is_removal_valid(cell, target_type):
		var tile_id = _rules.get_preview_tile_id_for_type(target_type)
		if tile_id != -1:
			level.ghost_layer.set_cell(cell, tile_id)
			level.ghost_layer.modulate = Color(1, 0, 0, 0.5) # semi‑transparent red
			if debug_switch:
				print("[RemovalService] 👁 Preview tile set:", tile_id, "at", cell)
		elif debug_switch:
			print("[RemovalService] ⚠ No preview tile for type:", target_type)
	else:
		if debug_switch:
			print("[RemovalService] ❌ Preview invalid for", target_type, "at", cell)


func clear_preview(level: Level) -> void:
	level.ghost_layer.clear()
	level.ghost_layer.modulate = Color(1, 1, 1, 1) # reset tint
	if debug_switch:
		print("[RemovalService] 🧹 Cleared preview")
