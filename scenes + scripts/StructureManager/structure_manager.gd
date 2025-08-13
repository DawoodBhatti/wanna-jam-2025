extends Node
class_name StructureManager

signal structure_placed(data: Dictionary)
signal structure_recycled(data: Dictionary)

@onready var base_grid: Node2D = get_node("../Tiles")
@onready var game_state: GameState = get_node("/root/Gamestate")
@onready var resources: Node = get_node("/root/Resources")

var placing: bool = false
var recycling: bool = false
var current_structure: Dictionary = {}

func _ready() -> void:
	game_state.connect("structure_placement_requested", Callable(self, "_on_structure_request"))
	game_state.connect("recycle_mode_requested", Callable(self, "_on_recycle_request"))
	base_grid.connect("structure_tile_placed", Callable(self, "_on_tile_placed"))
	base_grid.connect("structure_tile_erased", Callable(self, "_on_tile_erased")) # new signal below

func _on_structure_request(data: Dictionary) -> void:
	placing = true
	recycling = false
	current_structure = data
	base_grid.enter_structure_mode(data)

func _on_recycle_request() -> void:
	recycling = true
	placing = false
	current_structure = {}
	base_grid.enter_recycle_mode()

func _on_tile_placed(tile_info: Dictionary) -> void:
	if not placing:
		return
	placing = false
	emit_signal("structure_placed", {"structure": current_structure, "tile": tile_info})
	# If you prefer spend-on-successful-placement, do cost here (e.g., resources.add_stone(-1))
	game_state.set_play_phase_state(GameState.PLAY_PHASE_STATE_IDLE)
	current_structure = {}

func _on_tile_erased(tile_info: Dictionary) -> void:
	if not recycling:
		return
	recycling = false
	emit_signal("structure_recycled", tile_info)
	# Refund example: +1 stone
	if resources and resources.has_method("add_stone"):
		resources.add_stone(1)
	game_state.set_play_phase_state(GameState.PLAY_PHASE_STATE_IDLE)
