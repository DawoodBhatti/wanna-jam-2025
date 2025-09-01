# removal.gd
# Drag-to-remove interaction with GhostLayer hover preview.
# Supports both interactive (mouse-driven) and auto (batch) removal.

extends IBuildAction

# -------------------------------------------------------------------
# NODE REFERENCES
# -------------------------------------------------------------------
@onready var _level: Node = get_tree().get_root().get_node("Main/Level")
@onready var _removal_service: RemovalService = get_node("../RemovalSupport/RemovalService")
@onready var _removal_rules: RemovalRules = get_node("../RemovalSupport/RemovalRules")

# -------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------
var _active_tile: String
var _tile_data: Dictionary
var _limit: int
var _last_cell: Vector2i = Vector2i(-9999, -9999) # Tracks last removed cell to avoid duplicates
var _auto_mode := false
var _auto_locations: Array = []


# ===================================================================
# 1. LIFECYCLE
# ===================================================================

## Called when this removal action starts.
func start(params: Dictionary) -> void:
	_active_tile = params.get("tile_name", "")
	_limit = params.get("limit", 0)
	_auto_mode = params.get("auto_placement", false)
	_auto_locations = params.get("placement_locations", [])
	_last_cell = Vector2i(-9999, -9999)

	# ✅ Cache tile data once for removal logic
	_tile_data = TileCatalogue.get_tile(_active_tile)

	SignalBus.emit_logged(
		"removal_started",
		["removal", {"tile_name": _active_tile}, _limit]
	)

	if _auto_mode:
		_remove_auto()


## Called when this removal action stops.
func stop() -> void:
	_last_cell = Vector2i(-9999, -9999)
	_removal_service.clear_preview(_level)

	SignalBus.emit_logged(
		"removal_completed",
		["removal", {"target_building": _active_tile}, _limit]
	)


# ===================================================================
# 2. INPUT HANDLING (INTERACTIVE MODE)
# ===================================================================

## Processes input events when in interactive mode.
func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_removal_service.preview_cell_with_data(_level, _tile_data, ghost_cell)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_remove_current()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_remove_current()

	elif event.is_action_pressed("cancel"):
		stop()


# ===================================================================
# 3. REMOVAL LOGIC
# ===================================================================

## Removes the tile at the current mouse position if valid.
func _remove_current() -> void:
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)

	if cell == _last_cell:
		return

	if not _removal_rules.is_removal_valid(cell, _active_tile):
		return

	_last_cell = cell
	_removal_service.commit_removal_with_data(_level, _tile_data, cell)

	if _limit > 0:
		_limit -= 1
		if _limit <= 0:
			stop()


# ===================================================================
# 4. AUTO MODE
# ===================================================================

## Removes all tiles in _auto_locations without user input.
func _remove_auto() -> void:
	for cell in _auto_locations:
		if _removal_rules.is_removal_valid(cell, _active_tile):
			_removal_service.commit_removal_with_data(_level, _tile_data, cell)

	_limit = 0
	stop()
