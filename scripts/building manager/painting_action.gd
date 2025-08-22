# PaintingAction.gd
# Drag-to-paint multi-placement with GhostLayer hover preview.

extends IBuildAction

@onready var _level = get_node("../../Level")
@onready var _rules = get_node("../PlacementRules")
@onready var _placement_service: PlacementService = get_node("../PlacementService")

var _active_building: String
var _limit: int
var _last_cell: Vector2i = Vector2i(-9999, -9999)
var _build_data: Dictionary

func start(params: Dictionary) -> void:
	_active_building = params.get("building_name", "")
	_limit = params.get("limit", 0)
	_last_cell = Vector2i(-9999, -9999)

	# ✅ Cache build data once for painting mode using get_tile()
	_build_data = BuildCatalogue.get_tile("StructuresLayer", _active_building)

	SignalBus.emit_logged("paint_mode_started", ["paint", {"source": _active_building}, _limit])

func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_placement_service.preview_cell_with_data(_level, _build_data, ghost_cell)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_paint_current()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_paint_current()

	elif event.is_action_pressed("cancel"):
		get_parent().stop()

func _paint_current() -> void:
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)
	if cell == _last_cell:
		return
	if not _rules.is_valid(cell, _active_building):
		return

	_last_cell = cell
	_placement_service.commit_tile_with_data(_level, _build_data, cell)

	if _limit > 0:
		_limit -= 1
		if _limit <= 0:
			SignalBus.emit_logged("paint_mode_completed", ["paint", {"source": _active_building}, 0])
			get_parent().stop()

func stop() -> void:
	_last_cell = Vector2i(-9999, -9999)
	_placement_service.clear_preview(_level)
