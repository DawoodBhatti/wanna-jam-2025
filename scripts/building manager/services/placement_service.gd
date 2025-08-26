extends Node
class_name PlacementService

@onready var _rules: PlacementRules = get_node("../PlacementRules")

# -------------------------------------------------------------------
# PUBLIC API – SINGLE PLACEMENT MODE
# -------------------------------------------------------------------

func commit_tile(level: Level, building_name: String, cell: Vector2i) -> void:
	var build_data: Dictionary = BuildCatalogue.get_build_data(building_name)
	_commit_tile_internal(level, build_data, cell)

func preview_cell(level: Level, building_name: String, cell: Vector2i) -> void:
	var build_data: Dictionary = BuildCatalogue.get_build_data(building_name)
	_preview_cell_internal(level, build_data, cell)

# -------------------------------------------------------------------
# PUBLIC API – PAINTING MODE (CACHED BUILD DATA)
# -------------------------------------------------------------------

func commit_tile_with_data(level: Level, build_data: Dictionary, cell: Vector2i) -> void:
	_commit_tile_internal(level, build_data, cell)

func preview_cell_with_data(level: Level, build_data: Dictionary, cell: Vector2i) -> void:
	_preview_cell_internal(level, build_data, cell)

# -------------------------------------------------------------------
# PUBLIC API – MULTI‑MODE SIGNALS
# -------------------------------------------------------------------

func start_multiple_placement(mode: String, data: Dictionary) -> void:
	SignalBus.emit_logged("place_multiple_started", [mode, data, 0])

func complete_multiple_placement(mode: String, data: Dictionary, count: int) -> void:
	SignalBus.emit_logged("place_multiple_completed", [mode, data, count])

func cancel_multiple_placement(mode: String, data: Dictionary, count: int) -> void:
	SignalBus.emit_logged("place_multiple_completed", [mode, data, count])

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
	if not _rules.is_valid(cell, build_data.source_name):
		return

	var tile_coords: Vector2i = build_data.tiles[build_data.source_name]
	level.structures_layer.set_cell(cell, build_data.source_id, tile_coords)

	SignalBus.emit_logged(
		"building_placed",
		[{"layer": "StructuresLayer", "source": build_data.source_name, "cell_pos": cell}]
	)


func _preview_cell_internal(level: Level, build_data: Dictionary, cell: Vector2i) -> void:

	level.ghost_layer.clear()

	var valid: bool = _rules.is_valid(cell, build_data.source_name)

	if valid:
		var tile_coords: Vector2i = build_data.tiles[build_data.source_name]
		level.ghost_layer.set_cell(cell, build_data.source_id, tile_coords)
		level.ghost_layer.modulate = Color(0, 0.75, 0, 0.5)
	else:
		level.ghost_layer.modulate = Color(1, 1, 1, 1)
