# PlacementAction.gd
# ------------------
# Handles single‑click placement of a building with ghost preview.
# Uses cached build data for the active building to avoid repeated catalogue lookups.

extends IBuildAction

@onready var _level = get_node("../../Level")
@onready var _rules = get_node("../PlacementRules")

# ✅ Scene‑local reference to sibling PlacementService
@onready var _placement_service: PlacementService = get_node("../PlacementService")

var _active_building: String
var _build_data: Dictionary

func start(params: Dictionary) -> void:
	# Store the building name for this placement session
	_active_building = params.get("building_name", "")

	# ✅ Cache build data once for this session
	_build_data = BuildCatalogue.get_tile("StructuresLayer", _active_building)

	SignalBus.emit_logged("placement_mode_started", ["placement", {"source": _active_building}])

func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Show ghost preview on GhostLayer
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_placement_service.preview_cell_with_data(_level, _build_data, ghost_cell)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_commit_current()

	elif event.is_action_pressed("cancel"):
		get_parent().stop()

func _commit_current() -> void:
	# Get the cell under the mouse in the structures layer
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)

	# Validate placement
	if not _rules.is_valid(cell, _active_building):
		return

	# Commit the tile using cached build data
	_placement_service.commit_tile_with_data(_level, _build_data, cell)

	# Stop after a single placement
	get_parent().stop()

func stop() -> void:
	# Clear ghost preview when exiting placement mode
	_placement_service.clear_preview(_level)
