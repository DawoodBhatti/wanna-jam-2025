# removal_square.gd
# Removes a square of tiles in one click, with ghost preview.
# Mirrors placement_square.gd lifecycle and signalling.

extends IBuildAction

# -------------------------------------------------------------------
# NODE REFERENCES
# -------------------------------------------------------------------
@onready var _level: Node = get_tree().get_root().get_node("Main/Level")
@onready var _removal_service: RemovalService = get_node("../../RemovalSupport/RemovalService")
@onready var _removal_rules: RemovalRules = get_node("../../RemovalSupport/RemovalRules")


# -------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------
var _active_tile: String
var _tile_data: Dictionary
var _size: int
var _fill: bool
var _removed_count := 0


# ===================================================================
# 1. LIFECYCLE
# ===================================================================

## Called when this removal action starts.
## Params dictionary can contain:
## - tile_name: String
## - size: int
## - fill: bool
func start(params: Dictionary) -> void:
	_active_tile = params.get("tile_name", "")
	_tile_data = TileCatalogue.get_tile(_active_tile)
	_size = params.get("size", 1)
	_fill = params.get("fill", true)
	_removed_count = 0

	SignalBus.emit_logged(
		"removal_started",
		["square", {"target": _active_tile}, 1] # limit = 1 shape
	)


## Called when this removal action stops.
func stop() -> void:
	_removal_service.clear_preview(_level)

	SignalBus.emit_logged(
		"removal_completed",
		["square", {"target": _active_tile}, _removed_count]
	)


# ===================================================================
# 2. INPUT HANDLING
# ===================================================================

## Processes input events for square removal.
func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cells = _get_square_cells()
		_removal_service.preview_multiple_with_data(_level, _tile_data, cells)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cells = _get_square_cells()

		# Check if all cells are valid for removal
		var all_removable := true
		for cell in cells:
			if not _removal_rules.is_removal_valid(cell, _active_tile):
				all_removable = false
				break

		if all_removable:
			for cell in cells:
				_removal_service.commit_removal_with_data(_level, _tile_data, cell)
			_removed_count = cells.size()
			stop()

	elif event.is_action_pressed("cancel"):
		stop()


# ===================================================================
# 3. SHAPE LOGIC
# ===================================================================

## Returns an array of cells forming a square around the mouse.
func _get_square_cells() -> Array:
	var cells: Array = []
	var radius = _size - 1
	var center = _level.get_cell_under_mouse(_level.ghost_layer)

	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if _fill or abs(x) == radius or abs(y) == radius:
				cells.append(center + Vector2i(x, y))

	return cells
