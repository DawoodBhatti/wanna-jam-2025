extends IBuildAction

@onready var _level = get_node("../../Level")
@onready var _removal_service: RemovalService = get_node("../RemovalService")

# 🐞 Debug
var debug_switch: bool = false

# 🎯 State
var _target_type: String
var _limit: int
var _last_cell: Vector2i = Vector2i(-9999, -9999)

func start(params: Dictionary) -> void:
	_target_type = params.get("target_type", "")
	_limit = params.get("limit", 0)
	_last_cell = Vector2i(-9999, -9999)

	if debug_switch:
		print("[RemoveMultiple] START — target_type=%s, limit=%s" % [_target_type, _limit])

	SignalBus.emit_logged("remove_multiple_started", [
		"removal_paint",
		{"target_type": _target_type},
		_limit
	])

func process_input(event: InputEvent) -> void:
	if debug_switch:
		print("[RemoveMultiple] process_input got event:", event)

	if event is InputEventMouseMotion:
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		if debug_switch:
			print("[RemoveMultiple] MouseMotion — ghost_cell:", ghost_cell)
		_removal_service.preview_removal(_level, _target_type, ghost_cell)

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if debug_switch:
				print("[RemoveMultiple] MouseMotion + LMB held — attempting removal")
			_remove_current()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if debug_switch:
			print("[RemoveMultiple] LMB click — attempting removal")
		_remove_current()

	elif event.is_action_pressed("cancel"):
		if debug_switch:
			print("[RemoveMultiple] Cancel action pressed — stopping")
		get_parent().stop()

func _remove_current() -> void:
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)
	if debug_switch:
		print("[RemoveMultiple] _remove_current — picked cell:", cell)

	if cell == _last_cell:
		if debug_switch:
			print("[RemoveMultiple] Same as last cell — skipping")
		return

	_last_cell = cell
	_removal_service.commit_removal(_level, _target_type, cell)

	if debug_switch:
		print("[RemoveMultiple] Removal committed at:", cell)

	if _limit > 0:
		_limit -= 1
		if debug_switch:
			print("[RemoveMultiple] Limit decremented to:", _limit)
		if _limit <= 0:
			if debug_switch:
				print("[RemoveMultiple] Limit reached — stopping")
			SignalBus.emit_logged("remove_multiple_completed", [
				"removal_paint",
				{"target_type": _target_type},
				0
			])
			get_parent().stop()

func stop() -> void:
	if debug_switch:
		print("[RemoveMultiple] STOP — clearing preview and resetting last cell")
	_last_cell = Vector2i(-9999, -9999)
	_removal_service.clear_preview(_level)
