extends IBuildAction

@onready var _level = get_node("../../Level")
@onready var _removal_service: RemovalService = get_node("../RemovalService")


# 🎯 State
var _target_type: String
var _limit: int
var _last_cell: Vector2i = Vector2i(-9999, -9999)

func start(params: Dictionary) -> void:
	_target_type = params.get("target_type", "")
	_limit = params.get("limit", 0)
	_last_cell = Vector2i(-9999, -9999)


	SignalBus.emit_logged("remove_multiple_started", [
		"removal_paint",
		{"target_type": _target_type},
		_limit
	])

func process_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_removal_service.preview_removal(_level, _target_type, ghost_cell)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_remove_current()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_remove_current()

	elif event.is_action_pressed("cancel"):
		get_parent().stop()

func _remove_current() -> void:
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)

	if cell == _last_cell:
		return

	_last_cell = cell
	_removal_service.commit_removal(_level, _target_type, cell)


	if _limit > 0:
		_limit -= 1
		if _limit <= 0:
			SignalBus.emit_logged("remove_multiple_completed", [
				"removal_paint",
				{"target_type": _target_type},
				0
			])
			get_parent().stop()

func stop() -> void:
	_last_cell = Vector2i(-9999, -9999)
	_removal_service.clear_preview(_level)
