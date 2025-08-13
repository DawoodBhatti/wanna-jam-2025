extends Node
class_name StructureManager

signal structure_placed(data: Dictionary)
signal structure_recycled(data: Dictionary)

@onready var base_grid: Node2D = %Tiles
@onready var game_state: Gamestate = Gamestate
@onready var resources: Node = Resources

var current_structure: Dictionary = {}
var place_cost_on_success: bool = false  # if true, spend after first placement

func _ready() -> void:
	if not game_state.is_connected("structure_placement_requested", Callable(self, "_on_structure_request")):
		game_state.connect("structure_placement_requested", Callable(self, "_on_structure_request"))
		game_state.connect("recycle_mode_requested", Callable(self, "_on_recycle_request"))

	if not base_grid.is_connected("structure_tile_placed", Callable(self, "_on_tile_placed")):
		base_grid.connect("structure_tile_placed", Callable(self, "_on_tile_placed"))
		base_grid.connect("structure_tile_erased", Callable(self, "_on_tile_erased"))
		base_grid.connect("place_mode_completed", Callable(self, "_on_place_complete"))
		base_grid.connect("remove_mode_completed", Callable(self, "_on_remove_complete"))


func _on_structure_request(data: Dictionary) -> void:
	current_structure = data
	var amount : int = data.get("amount", 1)
	base_grid.enter_place_mode(data, amount)


func _on_recycle_request(data: Dictionary) -> void:
	current_structure = {}
	var amount : int = data.get("amount", 1)
	base_grid.enter_remove_mode(amount)


func _on_tile_placed(tile_info: Dictionary) -> void:
	emit_signal("structure_placed", {"structure": current_structure, "tile": tile_info})
	if place_cost_on_success and resources and resources.has_method("add_stone"):
		resources.add_stone(-1)

func _on_tile_erased(tile_info: Dictionary) -> void:
	emit_signal("structure_recycled", tile_info)
	if resources and resources.has_method("add_stone"):
		resources.add_stone(1)

func _on_place_complete() -> void:
	game_state.set_play_phase_state(GameState.PLAY_PHASE_STATE_IDLE)

func _on_remove_complete() -> void:
	game_state.set_play_phase_state(GameState.PLAY_PHASE_STATE_IDLE)

func cancel_active_mode() -> void:
	base_grid.clear_modes()
