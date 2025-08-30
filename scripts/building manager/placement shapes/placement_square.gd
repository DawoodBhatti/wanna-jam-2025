extends IBuildAction

# -------------------------------------------------------------------
# NODE REFERENCES
# -------------------------------------------------------------------
@onready var _level: Node = get_tree().get_root().get_node("Main/Level")
@onready var _rules = get_node("../PlacementSupport/PlacementRules")
@onready var _placement_service: PlacementService = get_node("../PlacementSupport/PlacementService")

# -------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------
var _active_building: String
var _size: int
var _fill: bool
var _build_data: Dictionary
var _placed_count := 0

# ===================================================================
# 1. LIFECYCLE
# ===================================================================

func start(params: Dictionary) -> void:
	_active_building = params.get("building_name", "")
	_size = params.get("size", 1)
	_fill = params.get("fill", true)
	_build_data = BuildCatalogue.get_tile(_active_building)
	_placed_count = 0

	SignalBus.emit_logged(
		"placement_started",
		["square", {"source": _active_building}, 1] # limit = 1 shape
	)

func stop() -> void:
	_placement_service.clear_preview(_level)
	SignalBus.emit_logged(
		"placement_completed",
		["square", {"source": _active_building}, _placed_count]
	)

# ===================================================================
# 2. INPUT HANDLING
# ===================================================================

func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cells = _get_square_cells()
		_placement_service.preview_multiple_with_data(_level, _build_data, cells)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cells = _get_square_cells()

		# Check if all cells are valid
		var all_valid := true
		for cell in cells:
			if not _rules.is_valid(cell, _active_building):
				all_valid = false
				break

		if all_valid:
			for cell in cells:
				_placement_service.commit_tile_with_data(_level, _build_data, cell)
			_placed_count = cells.size()
			get_parent().stop() # exit after one full valid placement

	elif event.is_action_pressed("cancel"):
		get_parent().stop()

# ===================================================================
# 3. SHAPE LOGIC
# ===================================================================

func _get_square_cells() -> Array:
	var cells: Array = []
	var radius = _size - 1
	var center = _level.get_cell_under_mouse(_level.ghost_layer)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if _fill or abs(x) == radius or abs(y) == radius:
				cells.append(center + Vector2i(x, y))
	return cells
