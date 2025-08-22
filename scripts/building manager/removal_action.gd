# RemovalAction.gd
# Handles tile removal.

extends IBuildAction

@onready var _level = get_node("../../Level")

func start(params: Dictionary) -> void:
	SignalBus.emit_logged("removal_mode_started", ["removal", {}])

func process_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = _level.get_cell_under_mouse(_level.structures_layer)
		_commit_removal(cell)

func _commit_removal(cell_pos: Vector2i) -> void:
	SignalBus.emit_logged("remove_building_requested", [{
		"layer": "StructuresLayer",
		"cell_pos": cell_pos
	}])
	_level.structures_layer.set_cell(cell_pos, -1)
	SignalBus.emit_logged("building_removed", {
		"layer": "StructuresLayer",
		"cell_pos": cell_pos
	})

func stop() -> void:
	pass
