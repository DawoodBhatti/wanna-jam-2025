extends Node
class_name PlacementService

@onready var _rules: PlacementRules = get_node("../PlacementRules")

# -------------------------------------------------------------------
# PUBLIC API – PLACEMENT MODE (CACHED BUILD DATA)
# -------------------------------------------------------------------

func commit_tile_with_data(level: Level, build_data: Dictionary, cell: Vector2i) -> void:
	_commit_tile_internal(level, build_data, cell)

func preview_cell_with_data(level: Level, build_data: Dictionary, cell: Vector2i) -> void:
	_preview_cell_internal(level, build_data, cell)


# -------------------------------------------------------------------
# PUBLIC API – CLEANUP
# -------------------------------------------------------------------

func clear_preview(level: Level) -> void:
	level.ghost_layer.clear()
	level.ghost_layer.modulate = Color(1, 1, 1, 1)

# -------------------------------------------------------------------
# INTERNAL IMPLEMENTATION
# -------------------------------------------------------------------

func _commit_tile_internal(level: Level, build_data: Dictionary, cell: Vector2i) -> void:
	if build_data.is_empty():
		return

	var tile_name: String = build_data.get("tile_name", "")
	if not _rules.is_valid(cell, tile_name):
		return

	var target_layer: TileMapLayer = level.get_node_or_null(build_data.get("build_layer", "")) as TileMapLayer
	if target_layer == null:
		push_error("[PlacementService] Missing target layer for tile: %s" % tile_name)
		return

	var tile_coords: Vector2i = build_data["tiles"][0] as Vector2i
	target_layer.set_cell(cell, build_data["source_id"], tile_coords)

	SignalBus.emit_logged(
		"building_placed",
		[{"layer": build_data.get("build_layer", ""), "source": tile_name, "cell_pos": cell}]
	)

func _preview_cell_internal(level: Level, build_data: Dictionary, cell: Vector2i) -> void:
	level.ghost_layer.clear()

	if build_data.is_empty():
		return

	var tile_name: String = build_data.get("tile_name", "") 
	var valid: bool = _rules.is_valid(cell, tile_name)

	if valid:
		var tile_coords: Vector2i = build_data["tiles"][0] as Vector2i
		level.ghost_layer.set_cell(cell, build_data["source_id"], tile_coords)
		level.ghost_layer.modulate = Color(0, 0.75, 0, 0.5)
	else:
		level.ghost_layer.modulate = Color(1, 1, 1, 1)
