# placement.gd
# Drag-to-paint placement with GhostLayer hover preview.
# Supports both interactive (mouse-driven) and auto (programmatic) placement.

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
var _limit: int
var _last_cell: Vector2i = Vector2i(-9999, -9999) # Tracks last painted cell to avoid duplicates
var _build_data: Dictionary
var _auto_mode := false
var _auto_locations: Array = []


# ===================================================================
# 1. LIFECYCLE
# ===================================================================

## Called when this build action starts.
## Params dictionary can contain:
## - building_name: String
## - limit: int
## - auto_placement: bool
## - placement_locations: Array of Vector2i
func start(params: Dictionary) -> void:
	_active_building = params.get("building_name", "")
	_limit = params.get("limit", 0)
	_auto_mode = params.get("auto_placement", false)
	_auto_locations = params.get("placement_locations", [])
	_last_cell = Vector2i(-9999, -9999)

	# ✅ Cache build data once for painting mode using get_tile()
	_build_data = BuildCatalogue.get_tile(_active_building)

	SignalBus.emit_logged(
		"placement_started",
		["paint", {"source": _active_building}, _limit]
	)

	# If in auto mode, skip input handling and place immediately
	if _auto_mode:
		_place_auto()


## Called when this build action stops.
func stop() -> void:
	_last_cell = Vector2i(-9999, -9999)
	_placement_service.clear_preview(_level)
	SignalBus.emit_logged(
		"placement_completed",
		["paint", {"source": _active_building}, _limit]
	)


# ===================================================================
# 2. INPUT HANDLING (INTERACTIVE MODE)
# ===================================================================

## Processes input events when in interactive mode.
func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Update ghost preview under mouse
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_placement_service.preview_cell_with_data(_level, _build_data, ghost_cell)

		# Paint continuously while left mouse is held
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_paint_current()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Single click placement
		_paint_current()

	elif event.is_action_pressed("cancel"):
		# Cancel placement mode
		get_parent().stop()


# ===================================================================
# 3. PLACEMENT LOGIC
# ===================================================================

## Paints the tile at the current mouse position if valid.
func _paint_current() -> void:
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)

	# Avoid re-painting the same cell
	if cell == _last_cell:
		return

	# Validate placement rules
	if not _rules.is_valid(cell, _active_building):
		return

	_last_cell = cell
	_placement_service.commit_tile_with_data(_level, _build_data, cell)

	# Decrement limit and stop if reached
	if _limit > 0:
		_limit -= 1
		if _limit <= 0:
			get_parent().stop()


# ===================================================================
# 4. AUTO MODE
# ===================================================================

## Places all tiles in _auto_locations without user input.
func _place_auto() -> void:
	for cell in _auto_locations:
		if _rules.is_valid(cell, _active_building):
			_placement_service.commit_tile_with_data(_level, _build_data, cell)

	# Auto mode always stops immediately after placing
	_limit = 0
	get_parent().stop()
	

# NOTE: Behaviour when some cells fail placement rules in auto mode:
# -------------------------------------------------------------------
# auto_place() -> placement() with auto_placement = true -> _place_auto()
# _place_auto() loops over all provided cells and calls _rules.is_valid()
# for each one. Any cell that fails the check is silently skipped — no
# error is thrown, and no tile is placed there.
#
# This means:
# - Valid cells are placed normally.
# - Invalid cells are ignored without affecting the rest of the batch.
# - There is no rollback; placement is "best effort".
# - placement_completed currently emits the original 'limit' passed in,
#   not the actual number of tiles placed. If you need the real count,
#   track it in _place_auto() and emit that instead.
