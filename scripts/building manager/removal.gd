extends IBuildAction

@onready var _level: Node = get_tree().get_root().get_node("Main/Level")
@onready var _removal_service: RemovalService = get_node("../RemovalSupport/RemovalService")

# 🎯 State
var _target_building: String
var _limit: int
var _last_cell: Vector2i = Vector2i(-9999, -9999)

func start(params: Dictionary) -> void:
	_target_building = params.get("building_name", "")
	_limit = params.get("limit", 0)
	_last_cell = Vector2i(-9999, -9999)

	SignalBus.emit_logged(
		"removal_started",
		["removal", {"building_name": _target_building}, _limit]
	)

func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_removal_service.preview_removal(_level, _target_building, ghost_cell)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_remove_current()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_remove_current()

	elif event.is_action_pressed("cancel"):
		get_parent().stop()  # cancel path

func _remove_current() -> void:
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)
	if cell == _last_cell:
		return

	_last_cell = cell
	_removal_service.commit_removal(_level, _target_building, cell)

	if _limit > 0:
		_limit -= 1
		if _limit <= 0:
			get_parent().stop()  # limit reached path

func stop() -> void:
	_last_cell = Vector2i(-9999, -9999)
	_removal_service.clear_preview(_level)
	SignalBus.emit_logged(
		"removal_completed",
		["removal", {"target_building": _target_building}, _limit]
	)
