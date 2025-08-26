# remove_single.gd
# ------------------
# Handles single‑click removal of a building with ghost preview.
# Uses cached target type for the active removal session to avoid repeated lookups.
# Delegates validation and commit logic to the central RemovalService.

extends IBuildAction

@onready var _level = get_node("../../Level")
@onready var _rules: RemovalRules = get_node("../RemovalRules")

# ✅ Scene‑local reference to sibling RemovalService
@onready var _removal_service: RemovalService = get_node("../RemovalService")

var _target_type: String   # The type of tile we are allowed to remove this session

func start(params: Dictionary) -> void:
	# Store the target type for this removal session
	_target_type = params.get("target_type", "")

	SignalBus.emit_logged("removal_mode_started", ["removal", {"target_type": _target_type}])

func process_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Show ghost preview on GhostLayer (red tint) for eligible tiles
		var ghost_cell: Vector2i = _level.get_cell_under_mouse(_level.ghost_layer)
		_removal_service.preview_removal(_level, _target_type, ghost_cell)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_commit_current()

	elif event.is_action_pressed("cancel"):
		get_parent().stop()

func _commit_current() -> void:
	# Get the cell under the mouse in the structures layer
	var cell: Vector2i = _level.get_cell_under_mouse(_level.structures_layer)

	# Validate removal
	if not _rules.is_removal_valid(cell, _target_type):
		return

	# Commit the removal
	_removal_service.commit_removal(_level, _target_type, cell)

	# Stop after a single removal
	get_parent().stop()

func stop() -> void:
	# Clear ghost preview when exiting removal mode
	_removal_service.clear_preview(_level)
